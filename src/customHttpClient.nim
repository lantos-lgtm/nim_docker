import asyncdispatch
import asyncnet
import net
import httpcore
import strutils
import options

# > GET /containers/myContainer/stats HTTP/1.1
# > Host: localhost
# > User-Agent: curl/7.79.1
# > Accept: */*
# >
# * Mark bundle as not supporting multiuse
# < HTTP/1.1 200 OK
# < Api-Version: 1.41
# < Date: Mon, 25 Jul 2022 05:39:34 GMT
# < Docker-Experimental: true
# < Ostype: linux
# < Server: Docker/20.10.17 (linux)
# < Transfer-Encoding: chunked

type
    HttpClient = object
        socket: Socket
        headers: HttpHeaders
        responseHeaders: HttpHeaders
        body: string
    AsyncHttpClient = object
        socket: AsyncSocket
        headers: HttpHeaders
        responseHeaders: HttpHeaders
        body: string
    
    HttpError = object of Exception
    

proc sendGreeting(client: HttpClient | AsyncHttpClient, httpMethod: HttpMethod, uri: string): Future[void] {.multisync.} =
    let message = $httpMethod & " " & uri & " HTTP/1.1" & "\r\n"
    when not defined(release):
        echo  "> " & message
    await client.socket.send(message)

proc sendHeaders(client: HttpClient | AsyncHttpClient, headers: HttpHeaders = nil ): Future[void] {.multisync.} =
    ## Will send the headers param first otherwise default to the client's headers
    var tempHeaders = newHttpHeaders()

    if not client.headers.isNil():
        tempHeaders = client.headers
    if not headers.isNil():
        tempHeaders = headers 
    # send the headers
    for k, v in tempHeaders.pairs():
        let message = k & ": " & v
        when not defined(release):
            echo  "> " & message
        await client.socket.send( message & "\r\n")
    # finish sending the headers
    await client.socket.send("\r\n")

proc getData(client: HttpClient | AsyncHttpClient): Future[string] {.multisync.} =
    # response types
    # 1. chunked -> data == \r\n ? read next line as content length, then read that many bytes else chunkSize == 0 end : return the data
    # 2. content length -> read the content length and read the content 
    # 3. no content -> return empty string

    var 
        chunkSize = -1
        data = ""
    
    if client.responseHeaders.getOrDefault("Transfer-Encoding").contains("chunked"):
        var chunkSizeData = (await client.socket.recvLine())
        if chunkSizeData == "\r\n":
            chunkSizeData = (await client.socket.recvLine())
        try:
            chunkSize = fromHex[int](chunkSizeData)
        except ValueError:
            raise newException(HttpError, "Invalid chunk size: " & chunkSizeData)

        if chunkSize == 0:
            return data

    data = await client.socket.recvLine()
    if data.len() + 1 != chunkSize and chunkSize != -1:
        raise newException(HttpError, "Chunk size mismatch")

    return data

proc getDataFull(client: HttpClient | AsyncHttpClient): Future[string] {.multisync.} =
    var temp = "" 
    while true:
        var data = ""
        when client is AsyncHttpClient:
            data = await client.getData() 
        else:
            data = client.getData() 
        # if data == "":
        #     break
        temp.add(data)
    return temp


iterator getData(client: HttpClient): string =
    while true:
        let data = client.getData() 
        if data == "":
            break
        yield data 

iterator getData(client: AsyncHttpClient): string =
    while true:
        let data = waitFor client.getData() 
        if data == "":
            break
        yield data

proc parseHeaderTupple(val: string): (string, string) =
    let parts = val.split(": ")
    if parts.len != 2:
        raise newException(HttpError, "Invalid header: " & val)
    return (parts[0].strip(), parts[1].strip())

proc add(headers:var HttpHeaders, val: string) =
    let header = parseHeaderTupple(val)
    if headers.len > headerLimit:
        raise newException(HttpError, "Too many headers")
    headers.add(header[0], header[1])

proc parseHttpVersion(val: string): HttpVersion =
    case val:
    of "HTTP/1.0":
        # return HttpVer10
        raise newException(HttpError, "HTTP/1.0 is not supported")
    of "HTTP/1.1":
        return HttpVer11
    # of "HTTP/2.0":
    #     return Http2
    else:
        raise newException(HttpError, "Invalid HTTP version: " & val)

proc parseWelcomeMessage(val: string): (HttpVersion, HttpCode) =
    let 
        parts = val.split(" ")
        version = parts[0].parseHttpVersion()
        status = HttpCode(parts[1].parseInt())
        ok = parts[2]
    if parts.len != 3:
        raise newException(HttpError, "Invalid welcome message: " & val)
    if ok.toLower() != "ok":
        raise newException(HttpError, "Invalid welcome message: " & val)
    return (version, status)

proc getHeaderResponse(client: HttpClient | AsyncHttpClient): Future[HttpHeaders] {.multisync.} =
    var headers = newHttpHeaders()
    ## parse GET location PROTOCOL
    ## example 
    ## Deal with welcome message
    ## GET /containers/myContainer/stats HTTP/1.1
    ## Then parse headers
    ## Host: localhost
    ## User-Agent: curl/7.79.1
    let welcomeMessage = await client.getData()
    echo welcomeMessage
    let (version, status) = welcomeMessage.parseWelcomeMessage()
    when not defined(release):
        echo "HTTP version: " & $version
        echo "Status: " & $status

    for data in client.getData():
        when defined(release):
            echo "< " & data
        if data == "\r\n":
            break
        headers.add(data)

    return headers

let basepath = "unix:///var/run/docker.sock"
let headers = newHttpHeaders({
    "Host": "v1.41",
    "User-Agent": "nimHttp",
    "Accept": "application/json",
    "Content-Type": "application/json",
    # "Transfer-Encoding": "chunked",
    # "Content-Length": "0"
})


proc main() =
    let socket = newSocket(
        Domain.AF_UNIX,
        SockType.SOCK_STREAM,
        Protocol.IPPROTO_IP
    )
    var client: HttpClient
    client.socket = socket
    client.headers = headers
    client.responseHeaders = newHttpHeaders()
    client.socket.connectUnix(basepath[7..basepath.high])

    client.sendGreeting(HttpMethod.HttpGet, "/containers/myContainer/stats")
    # client.sendGreeting(HttpMethod.HttpGet, "/containers/json")
    client.sendHeaders()

    let responseHeaders = client.getHeaderResponse()
    client.responseHeaders = responseHeaders
    

    # get the body response
    for data in client.getData():
        if data == "\r\n":
            break
        echo "< " & data


proc mainAsync() {.async.} =
    let socket = newAsyncSocket(
        Domain.AF_UNIX,
        SockType.SOCK_STREAM,
        Protocol.IPPROTO_IP
    )
    var client:  AsyncHttpClient
    client.socket = socket
    client.headers = headers
    await client.socket.connectUnix(basepath[7..basepath.high])
    # await client.sendGreeting(HttpMethod.HttpGet, "/containers/myContainer/stats")
    await client.sendGreeting(HttpMethod.HttpGet, "/containers/json")
    await client.sendHeaders()

    echo await client.getHeaderResponse()

    # get the body response
    # for data in socket.getData():
        # if data == "\r\n":
        #     break
        # echo "< " & data

when isMainModule:
    main()
    # waitFor mainAsync()