import asyncdispatch
import asyncnet
import net
import httpcore
import strutils
import uri
import strformat
import tables
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


export httpcore, uri

type
    HttpClient* = object
        socket*: Socket
        headers*: HttpHeaders
        basepath: string
        responseHeaders*: HttpHeaders
        sslContext: SslContext
        # body*: string

    AsyncHttpClient* = object
        socket*: AsyncSocket
        headers*: HttpHeaders
        basepath: string
        responseHeaders*: HttpHeaders
        sslContext: SslContext
        # body*: string

    HttpError* = object of Exception

    Docker = object
        client: HttpClient
        basepath: string
    AsyncDocker = object
        client: AsyncHttpClient
        basepath: string


proc sendGreeting*(client: HttpClient | AsyncHttpClient, httpMethod: HttpMethod,
        uri: string): Future[void] {.multisync.} =
    let message = $httpMethod & " " & uri & " HTTP/1.1" & "\r\n"
    when not defined(release):
        echo "> " & message
    await client.socket.send(message)

proc sendHeaders*(client: HttpClient | AsyncHttpClient,
        headers: HttpHeaders = nil): Future[void] {.multisync.} =
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
            echo "> " & message
        await client.socket.send(message & "\r\n")
    # finish sending the headers
    await client.socket.send("\r\n")

proc sendBody*(client: HttpClient | AsyncHttpClient, httpMethod: HttpMethod, body: string): Future[void] {.multisync.} =

    when not defined(release):
        echo "> " & body
    await client.socket.send(body)

proc getChunks*(client: HttpClient | AsyncHttpClient, size: int): Future[
        string] {.multisync.} =
    var data = await client.socket.recv(size)
    # while data.len() < size:
    #     let chunk = await client.socket.recvLine()
    #     data.add(chunk)
    #     echo data.len(),"/", size, ":", cast[seq[char]](chunk)
    # TODO: FIX THIS data.len should be size but it's not becuase of the \r\n
    if data.len() != size and size != -1:
        echo cast[seq[char]](data)
        raise newException(HttpError, "Chunk size mismatch expected:" & $size &
                " but got data.len():" & $data.len & "\n data:" & $data)
    return data


proc getData*(client: HttpClient | AsyncHttpClient): Future[
        string] {.multisync.} =
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
    # < 0 This can also be \r\n
    # ENDED
    var
        chunkSize = -1
        data = ""

    if client.responseHeaders.getOrDefault("Transfer-Encoding").contains("chunked"):
        var chunkSizeData = (await client.socket.recvLine())
        when not defined(release):
            echo "< ", cast[seq[char]](chunkSizeData)
        if chunkSizeData == "\r\n":
            return chunkSizeData
        chunkSize = fromHex[int](chunkSizeData)


    if client.responseHeaders.hasKey("Content-Length"):
        chunkSize = client.responseHeaders.getOrDefault(
                "Content-Length").parseInt()

    if chunkSize != -1:
        if chunkSize == 0:
            return data
        data = await client.getChunks(chunkSize)
        echo "< ", cast[seq[char]](data)
        return data

    data = await client.socket.recvLine()

    return data


iterator getData*(client: HttpClient): string =
    var size = if client.responseHeaders.hasKey(
            "Content-Length"): client.responseHeaders.getOrDefault(
            "Content-Length").parseInt() else: -1
    while true:
        let data = client.getData()
        yield data
        if data == "" or data.len == size:
            break

iterator getData*(client: AsyncHttpClient): string =
    var size = if client.responseHeaders.hasKey(
            "Content-Length"): client.responseHeaders.getOrDefault(
            "Content-Length").parseInt() else: -1
    while true:
        let data = waitFor client.getData()
        yield data
        if data == "" or data.len == size:
            break

proc parseHeaderTupple*(val: string): (string, string) =
    let parts = val.split(": ")
    if parts.len != 2:
        raise newException(HttpError, "Invalid header: " & val)
    return (parts[0].strip(), parts[1].strip())

proc add*(headers: var HttpHeaders, val: string) =
    ## add the header to the headers
    ## Throws error when headers > 10_000
    let header = parseHeaderTupple(val)
    if headers.len > headerLimit:
        raise newException(HttpError, "Too many headers")
    headers.add(header[0], header[1])

proc parseHttpVersion*(val: string): HttpVersion =
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

proc parseWelcomeMessage*(val: string): (HttpVersion, HttpCode, string) =
    let
        parts = val.split(" ")
        version = parts[0].parseHttpVersion()
        status = HttpCode(parts[1].parseInt())
        message = parts[2..^1].join(" ")

    return (version, status, message)


proc getHeaderResponse*(client: HttpClient | AsyncHttpClient): Future[
        HttpHeaders] {.multisync.} =
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
    let (version, status, message) = welcomeMessage.parseWelcomeMessage()

    when not defined(release):
        echo "HTTP version: " & $version
        echo "Status: " & $status
        echo "Message: " & message

    for data in client.getData():
        when not defined(release):
            echo "< " & data
        if data == "\r\n":
            break
        headers.add(data)

    return headers

proc finds*(val: string, find: string): seq[int] =
    if find.len == 0:
        return
    if find.len > val.len:
        return
    for i in 0..val.high-find.len:
        if val[i..i + find.len - 1] == find:
            result.add(i)

proc uriGetUnixSocketPath*(uri: Uri): (string, string) =
    let conPath = uri.path
    # let dotPos =  conPath.find("/", conPath.find("."), conPath.len())
    let dotPoses = conPath.finds(".")
    let lastDotPos = dotPoses[dotPoses.high]
    let lastSlashAfterDot = conPath.find("/", lastDotPos)
    var lastSlashPos = conPath.high
    if lastSlashAfterDot != -1:
        lastSlashPos = lastSlashAfterDot
        return (conPath[0..lastSlashPos-1], conPath[lastSlashPos..conPath.high])
    else:
        return (conPath, "")

proc initUnixSocket*(uri: Uri | string): Socket =
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

proc initAsyncUnixSocket*(uri: Uri | string): Future[AsyncSocket] {.async.} =
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

# can I merge these two?
proc initSocket*(client: HttpClient, uri: Uri): Socket =
    var isSsl = false
    var socket: Socket

    case uri.scheme:
    of "unix":
        socket = initUnixSocket(uri)
    of "http":
        var port = Port(80)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket = net.dial(uri.hostname, port)
    of "https":
        var port = Port(443)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        isSsl = true
        socket = net.dial(uri.hostname, port)
    else:
        raise newException(HttpError, "Invalid scheme: " & uri.scheme)

    # setup the SSL certificates if SSL
    when defined(ssl):
        if isSsl:
            wrapConnectedSocket(client.sslContext, socket, handshakeAsClient, uri.hostname)

    return socket

proc initAsyncSocket*(client: AsyncHttpClient, uri: Uri): Future[
        AsyncSocket] {.async.} =
    var isSsl = false
    var socket: AsyncSocket

    case uri.scheme:
    of "unix":
        socket = await initAsyncUnixSocket(uri)
    of "http":
        var port = Port(80)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        socket = await asyncnet.dial(uri.hostname, port)
    of "https":
        var port = Port(443)
        if uri.port != "":
            port = Port(uri.port.parseInt())
        isSsl = true
        socket = await asyncnet.dial(uri.hostname, port)
    else:
        raise newException(HttpError, "Invalid scheme: " & uri.scheme)

    # setup the SSL certificates if SSL
    when defined(ssl):
        if isSsl:
            wrapConnectedSocket(client.sslContext, socket, handshakeAsClient, uri.hostname)

    return socket


proc initClient*(basepath: string, headers: HttpHeaders = nil,
        sslContext: SslContext = nil): HttpClient =

    var client: HttpClient

    client.basepath = basepath
    let uri = basepath.parseUri()

    when defined(ssl):

        if not sslContext.isNil:
            client.sslContext = sslContext
        else:
            client.sslContext = newContext(verifyMode = CVerifyPeer)
    else:
        if uri.scheme == "https":
            raise newException(HttpError, "this needs to be run with  -d:ssl")

    var socket = client.initSocket(uri)
    client.socket = socket

    client.headers = if headers.isNil: newHttpHeaders() else: headers

    if not client.headers.hasKey("Host"):
        echo "SETTING HOST NAME:", uri.hostname
        client.headers.add("Host", uri.hostname)



    client.responseHeaders = newHttpHeaders()
    return client

proc initAsyncClient*(basepath: string, headers: HttpHeaders = nil,
        sslContext: SslContext = nil): Future[AsyncHttpClient] {.async.} =
    var client: AsyncHttpClient

    client.basepath = basepath
    let uri = basepath.parseUri()

    when defined(ssl):
        if not sslContext.isNil:
            client.sslContext = sslContext
        else:
            client.sslContext = newContext(verifyMode = CVerifyPeer)
    else:
        if uri.scheme == "https":
            raise newException(HttpError, "this needs to be run with  -d:ssl")

    var socket = await client.initAsyncSocket(uri)
    client.socket = socket

    client.headers = if headers.isNil: newHttpHeaders() else: headers

    if not client.headers.hasKey("Host"):
        echo "SETTING HOST NAME:", uri.hostname
        client.headers.add("Host", uri.hostname)

# TODO: requests
# TODO: MultiPart Requests
# wish that there was no issue with async & iterators in Nim
# noLentIterators means I have to return the client and let the user modify the client
proc request*(
    client: HttpClient | AsyncHttpClient,
    httpMethod: HttpMethod = HttpGet,
    uri: Uri | string,
    body: string = "",
    headers: HttpHeaders = nil
    ): Future[HttpClient | AsyncHttpClient] {.multisync.} =
    # 1. send greeting
    # 2. add multipart len to headers || add body len to headers
    # 3. send headers
    # 4. send multipart data || body 
    # 5. get response headers
    # 6. return response headers
    # 7. user then can get body outside of this proc

    var tempUri: Uri
    var tempClient = client
    when uri is string:
        tempUri = uri.parseUri()
    when uri is Uri:
        tempUri = uri

    var path = tempUri.hostname & tempUri.path

    if tempUri.scheme == "unix":
        path = tempUri.uriGetUnixSocketPath()[1]

    await tempClient.sendGreeting(httpMethod, path)
    if body != "":
        tempClient.headers.add("Content-Length", $body.len)
        if not headers.isNil:
            headers.add("Content-Length", $body.len)
    await tempClient.sendHeaders(headers)
    await tempClient.sendBody(httpMethod, body)
    
    tempClient.responseHeaders = await tempClient.getHeaderResponse()
    return tempClient