import asyncdispatch
import asyncnet
import net
import httpcore
import strutils
import uri
import jsony
import algorithm

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


proc getChunks(client: HttpClient | AsyncHttpClient, size: int): Future[string] {.multisync.} =
    var data = ""
    while data.len() < size:
        let chunk = await client.socket.recvLine()
        data.add(chunk)
    # TODO: FIX THIS data.len should be size but it's not becuase of the \r\n
    if data.len() - 1 != size and size != -1:
        echo cast[seq[char]](data)
        raise newException(HttpError, "Chunk size mismatch expected:" & $size & " but got data.len():" & $data.len & "\n data:" & $data)
    return data
    

proc getData(client: HttpClient | AsyncHttpClient): Future[string] {.multisync.} =
    ## Get the data from the socket
    ## TODO: Handle gzip &  encoding 
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding
    # Transfer-Encoding: chunked
    # Transfer-Encoding: compress
    # Transfer-Encoding: deflate
    # Transfer-Encoding: gzip
    # // Several values can be listed, separated by a comma
    # Transfer-Encoding: gzip, chunked
    # response types
    # 1. chunked -> data == \r\n ? read next line as content length, then read that many bytes else chunkSize == 0 end : return the data
    # 2. content length -> read the content length and read the content 
    # 3. no content -> return empty string

    # example Chunked
    # < xA
    # this is size 10
    # < \r\n
    # < 0123456789
    # this is size 10
    # < \r\n
    # < 0
    # ENDED 
    var 
        chunkSize = -1
        data = ""
    if client.responseHeaders.getOrDefault("Transfer-Encoding").contains("chunked"):
        var chunkSizeData = (await client.socket.recvLine())
        try:
            chunkSize = fromHex[int](chunkSizeData)
        except ValueError:
            raise newException(HttpError, "Invalid chunk size value:" & chunkSizeData)
        if chunkSize == 0:
            return data
        return await client.getChunks(chunkSize)

    data = await client.socket.recvLine()

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
    ## add the header to the headers 
    ## Throws error when headers > 10_000
    let header = parseHeaderTupple(val)
    if headers.len > headerLimit:
        raise newException(HttpError, "Too many headers")
    headers.add(header[0], header[1])

proc parseHttpVersion(val: string): HttpVersion =
    ## We only support http/1.1
    ## TODO: Support http/2.0 
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

proc finds(val: string, find: string): seq[int]=
    if find.len == 0:
        return
    if find.len > val.len:
        return
    for i in 0..val.high-find.len:
        if val[i..i + find.len - 1] == find:
            result.add(i)

proc uriGetUnixSocketPath(uri: Uri): (string, string) =
    let conPath = uri.path
    # let dotPos =  conPath.find("/", conPath.find("."), conPath.len())
    let dotPoses =  conPath.finds(".")
    let lastDotPos = dotPoses[dotPoses.high]
    let lastSlashAfterDot = conPath.find("/", lastDotPos)
    var lastSlashPos = conPath.high
    if lastSlashAfterDot != -1:
        lastSlashPos = lastSlashAfterDot
        return (conPath[0..lastSlashPos-1], conPath[lastSlashPos..conPath.high])
    else:
        return (conPath, "")

proc initUnixSocket(uri: Uri | string): Socket =
    var tempUri: Uri
    when uri is string:
        tempUri = uri.parseUri()
    when uri is Uri:
        tempUri = uri
    result = newSocket(
        Domain.AF_UNIX,
        SockType.SOCK_STREAM,
        Protocol.IPPROTO_IP
    )
    result.connectUnix(tempUri.uriGetUnixSocketPath()[0])

proc initAsyncUnixSocket(uri: Uri | string): Future[AsyncSocket] {.async.} =
    var tempUri: Uri
    when uri is string:
        tempUri = uri.parseUri()
    when uri is Uri:
        tempUri = uri
    result = newAsyncSocket(
        Domain.AF_UNIX,
        SockType.SOCK_STREAM,
        Protocol.IPPROTO_IP
    )
    await result.connectUnix(tempUri.uriGetUnixSocketPath()[0])

# can I merge these two 
proc initSocket(uri: Uri): Socket =
    var socket: Socket
    if uri.scheme == "unix":
        socket =  initUnixSocket(uri) 
    if uri.scheme == "http":
        var port = Port(80)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket =  net.dial(uri.hostname, port)
    if uri.scheme == "https":
        var port = Port(443)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket =  net.dial(uri.hostname, port) 
    return socket

proc initAsyncSocket(uri: Uri): Future[AsyncSocket] {.async.} =
    var socket: AsyncSocket
    if uri.scheme == "unix":
        socket = await initAsyncUnixSocket(uri) 
    if uri.scheme == "http":
        var port = Port(80)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket = await asyncnet.dial(uri.hostname, port)
    if uri.scheme == "https":
        var port = Port(443)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket = await asyncnet.dial(uri.hostname, port) 
    return socket

proc initClient(basepath: string, headers: HttpHeaders = nil): HttpClient =
    var socket = initSocket(basepath.parseUri())
    var client: HttpClient
    client.socket = socket
    if headers.isNil:
        client.headers = newHttpHeaders()
    else:
        client.headers = headers

    client.responseHeaders = newHttpHeaders()
    return client

proc initAsyncClient(basepath: string, headers: HttpHeaders = nil): Future[AsyncHttpClient] {.async.}=
    var socket = await initAsyncSocket(basepath.parseUri())
    var client: AsyncHttpClient
    client.socket = socket
    if headers.isNil:
        client.headers = newHttpHeaders()
    else:
        client.headers = headers

    client.responseHeaders = newHttpHeaders()
    return client

# TODO: requests
# TODO: MultiPart Requests
proc request(client: AsyncHttpClient, httpMethod: HttpMethod = HttpGet, uri: Uri | string): Future[HttpHeaders] {.async.} =
    var tempUri: Uri
    when uri is string:
        tempUri = uri.parseUri()
    when uri is Uri:
        tempUri = uri
    
    var path = tempUri.hostname  & tempUri.path 

    if tempUri.scheme == "unix":
        path = tempUri.uriGetUnixSocketPath()[1]
    
    await client.sendGreeting(httpMethod, path)
    await client.sendHeaders()
    return await client.getHeaderResponse()

proc request(client: var HttpClient,  httpMethod: HttpMethod = HttpGet, uri: Uri | string): HttpHeaders =
    var tempUri: Uri
    when uri is string:
        tempUri = uri.parseUri()
    when uri is Uri:
        tempUri = uri
    
    var path = tempUri.hostname  & tempUri.path 

    if tempUri.scheme == "unix":
        path = tempUri.uriGetUnixSocketPath()[1]
    
    client.sendGreeting(httpMethod, path)
    client.sendHeaders()
    return client.getHeaderResponse()


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
    var client = initClient(basepath, headers)
    client.responseHeaders = client.request(HttpMethod.HttpGet, "/containers/myContainer/stats")

    # get the body response
    for i in 0..3:
        let data = client.getData()
        if data == "\r\n":
            break
        echo "< " & data


proc mainAsync() {.async.} =
    var client = await initAsyncClient(basepath, headers)
    client.responseHeaders = await client.request(HttpMethod.HttpGet, "/containers/myContainer/stats")
    

    # get the body response
    for i in 0..3:
        let data = await client.getData()
        if data == "\r\n":
            break
        echo "< " & data



when isMainModule:
    main()
    waitFor mainAsync()