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
        # responseHeaders*: HttpHeaders
        sslContext: SslContext
        # body*: string

    AsyncHttpClient* = object
        socket*: AsyncSocket
        headers*: HttpHeaders
        basepath: string
        # responseHeaders*: HttpHeaders
        sslContext: SslContext
        # body*: string

    HttpError* = object of IOError


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


proc initHttpClient*(basepath: string, headers: HttpHeaders = nil,
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

    client.socket = client.initSocket(uri)

    client.headers = if headers.isNil: newHttpHeaders() else: headers

    if not client.headers.hasKey("Host"):
        echo "SETTING HOST NAME:", uri.hostname
        client.headers.add("Host", uri.hostname)

    return client

proc initHttpAsyncClient*(basepath: string, headers: HttpHeaders = nil,
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

    client.socket = await client.initAsyncSocket(uri)

    client.headers = if headers.isNil: newHttpHeaders() else: headers

    if not client.headers.hasKey("Host"):
        echo "SETTING HOST NAME:", uri.hostname
        client.headers.add("Host", uri.hostname)

    return client

proc sendGreeting*(client: HttpClient | AsyncHttpClient, httpMethod: HttpMethod,
        uri: string): Future[void] {.multisync.} =
    let message = $httpMethod & " " & uri & " HTTP/1.1" & "\r\n"
    when defined(verbose):
        echo "w> " & message
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
        when defined(verbose):
            echo "h> " & message
        await client.socket.send(message & "\r\n")
    # finish sending the headers
    await client.socket.send("\r\n")

proc sendBody*(client: HttpClient | AsyncHttpClient, httpMethod: HttpMethod,
        body: string): Future[void] {.multisync.} =

    when defined(verbose):
        echo "> " & body
    await client.socket.send(body)

proc getData(socket: Socket | AsyncSocket): Future[string] {.multisync.} =
    result = await socket.recvLine()
    when defined(verbose):
        echo "r< ", cast[seq[char]](result) 

proc getChunks*(client: HttpClient | AsyncHttpClient): Future[
        string] {.multisync.} =
    var 
        chunkSizeData = await client.socket.getData()
        chunkSize = fromHex[int](chunkSizeData)

    while result.len() < chunkSize:
        let data = await client.socket.getData()
        when defined(verbose):
            echo result.len(),"/", chunkSize, " cd< ", cast[seq[char]](data)
        result.add(data)

proc getContentLength(client: HttpClient | AsyncHttpClient, size: int): Future[string] {.multisync.} =
    return await client.socket.recv(size)

proc getData*(
    client: HttpClient | AsyncHttpClient,
    responseHeaders: HttpHeaders,
    parsedHeader: bool = true): Future[string] {.multisync.} =
    ## Get the data from the socket
    ## TODO: Handle gzip &  encoding
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding
    # Transfer-Encoding: chunked, compress, deflate, gzip

    if parsedHeader:
        if responseHeaders.getOrDefault("Transfer-Encoding").contains("chunked"):
            return await client.getChunks()

        if responseHeaders.hasKey("Content-Length"):
            return await client.getContentLength(responseHeaders.getOrDefault("Content-Length").parseInt())

    return await client.socket.getData()


iterator getData*(
    client: HttpClient,
    responseHeaders: HttpHeaders,
    parsedHeader: bool = true): string =

    var size = if responseHeaders.hasKey(
            "Content-Length"): responseHeaders.getOrDefault(
            "Content-Length").parseInt() else: -1
    while true:
        let data = client.getData(responseHeaders, parsedHeader)
        if data in ["", "0"] or data.len == size:
            break
        yield data

iterator getData*(
    client: AsyncHttpClient,
    responseHeaders: HttpHeaders,
    parsedHeader: bool = true): string =
    var size = if responseHeaders.hasKey(
            "Content-Length"): responseHeaders.getOrDefault(
            "Content-Length").parseInt() else: -1
    while true:
        let data = waitFor client.getData(responseHeaders, parsedHeader)
        if data in ["", "0"] or data.len == size:
            break
        yield data

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


type
    WelcomeMessage = object
        httpVersion: HttpVersion
        httpCode: HttpCode
        message: string

proc parseWelcomeMessage*(val: string): WelcomeMessage =
    echo val
    let parts = val.split(" ")
    result.httpVersion = parts[0].parseHttpVersion()
    result.httpCode = HttpCode(parts[1].parseInt())
    result.message = parts[2..^1].join(" ")


proc getWelcomeMessage(client: HttpClient | AsyncHttpClient, responseHeaders: HttpHeaders = nil): Future[WelcomeMessage] {.multisync.} =
    let data =  await client.getData(responseHeaders)
    let welcomeMessage = data.parseWelcomeMessage()

    when defined(verbose):
        echo "HTTP version: " & $welcomeMessage.httpVersion
        echo "Status: " & $welcomeMessage.httpCode
        echo "Message: " & welcomeMessage.message  
    return welcomeMessage

proc getHeaderResponse*(client: HttpClient | AsyncHttpClient): Future[HttpHeaders] {.multisync.} =
    var responseHeaders = newHttpHeaders()
    ## parse GET location PROTOCOL
    ## example
    ## Deal with welcome message
    ## GET /containers/myContainer/stats HTTP/1.1
    ## Then parse headers
    ## Host: localhost
    ## User-Agent: curl/7.79.1
    
    for data in client.getData(responseHeaders, false):
        when defined(verbose):
            echo "< " & data
        if data == "\r\n":
            break
        responseHeaders.add(data)

    return responseHeaders

# TODO: requests
# TODO: MultiPart Requests
# wish that there was no issue with async & iterators in Nim
# noLentIterators means I have to return the client and let the user modify the client

type
    Response = (HttpClient, HttpHeaders)
    AsyncResponse = (AsyncHttpClient, HttpHeaders)

proc openRequest*(
    client: HttpClient | AsyncHttpClient,
    uri: Uri | string,
    httpMethod: HttpMethod = HttpGet,
    body: string = "",
    headers: HttpHeaders = nil
    ): Future[Response | AsyncResponse] {.multisync.} =
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
        path = await tempUri.uriGetUnixSocketPath()[1]

    await tempClient.sendGreeting(httpMethod, path)
    if body != "":
        tempClient.headers.add("Content-Length", $body.len)
        if not headers.isNil:
            headers.add("Content-Length", $body.len)

    await tempClient.sendHeaders(headers)
    await tempClient.sendBody(httpMethod, body)

    var responseHeaders = newHttpHeaders()

    let welcomeMessage = await client.getWelcomeMessage(responseHeaders)
    responseHeaders = await tempClient.getHeaderResponse()
    

    return (tempClient, responseHeaders)
