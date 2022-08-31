import
  httpcore,
  net,
  asyncnet,
  asyncdispatch,
  streams,
  uri,
  strutils,
  os

export httpcore, uri, net, asyncnet

type
  HttpClient* = object
    sslContext*: SslContext

  AsyncHttpClient* = object
    sslContext: SslContext

  Greeting* = object
    httpVersion: HttpVersion
    httpCode: HttpCode
    ok: bool
    message: string

  Response* = object
    httpCode*: HttpCode
    headers*: HttpHeaders
    stream*: Stream
    socket*: Socket

  AsyncResponse* = object
    httpCode*: HttpCode
    headers*: HttpHeaders
    stream*: Stream
    socket*: AsyncSocket

  Chunk = object
    size: int
    ext: HttpHeaders
    data: string

  HttpError* = object of IOError


proc initAsyncUnixSocket*(uri: Uri | string): Future[AsyncSocket] {.async.} =
  var uri = when uri is string: uri.parseUri() else: uri
  result = newAsyncSocket(
    Domain.AF_UNIX,
    SockType.SOCK_STREAM,
    Protocol.IPPROTO_IP
  )
  await result.connectUnix(uri.hostname)

proc initUnixSocket*(uri: Uri | string): Socket =
  var uri = when uri is string: uri.parseUri() else: uri
  result = newSocket(
    Domain.AF_UNIX,
    SockType.SOCK_STREAM,
    Protocol.IPPROTO_IP
  )
  result.connectUnix(uri.hostname)

proc initSocket(uri: Uri): Socket =
  var uri = uri
  var port = if uri.port != "": Port(uri.port.parseInt())
    elif uri.scheme == "https": Port(443)
    else: Port(80)
  if uri.scheme == "unix":
    return initUnixSocket(uri)
  return net.dial(uri.hostname, port)

proc initAsyncSocket(uri: Uri): Future[AsyncSocket] {.async.} =
  var uri = uri
  var port = if uri.port != "": Port(uri.port.parseInt())
    elif uri.scheme == "https": Port(443)
    else: Port(80)
  if uri.scheme == "unix":
    return await initAsyncUnixSocket(uri)
  return await asyncnet.dial(uri.hostname, port)

proc sendGreeting(socket: Socket | AsyncSocket, httpMethod: HttpMethod,
    path: string): Future[void] {.multisync.} =
  let message = $httpMethod & " " & path & " HTTP/1.1\r\n"
  when defined(verbose): echo "> ", message
  await socket.send(message)

proc sendHeaders(socket: Socket | AsyncSocket, headers: HttpHeaders): Future[
    void] {.multisync.} =
  for key, value in headers:
    let message = key & ": " & value
    when defined(verbose): echo "h> " & message
    await socket.send(message & "\r\n")
  when defined(verbose): echo "h> \\r\\n"
  await socket.send("\r\n")

proc sendBody(socket: Socket | AsyncSocket, body: string): Future[
    void] {.multisync.} =
  # TODO: chunked encoding
  when defined(verbose): echo "b> ", body
  await socket.send(body)

proc recvGreeting(socket: Socket | AsyncSocket): Future[
    Greeting] {.multisync.} =

  var line = await socket.recvLine()
  when defined(verbose): echo "g< ", line
  var parts = line.split(" ")
  if not parts.len >= 3:
    raise newException(HttpError, "Invalid greeting: " & line)
  if parts[0] != "HTTP/1.1":
    raise newException(HttpError, "Invalid greeting: " & line)

  result.httpVersion = HttpVer11
  result.httpCode = HttpCode(parts[1].parseInt())
  result.ok = result.httpCode == Http200
  result.message = parts[2..parts.high].join(" ")

proc recvHeaders(socket: Socket | AsyncSocket): Future[
    HttpHeaders] {.multisync.} =
  result = newHttpHeaders()
  while true:
    var line = await socket.recvLine()
    when defined(verbose): echo "h< ", line
    if line == "\r\n":
      break
    var posSplit = line.find(":")
    if posSplit < 0:
      raise newException(HttpError, "Invalid header: " & line)
    result.add(line[0..posSplit-1].strip(), line[posSplit+1..line.high].strip())

proc recvChunk*(socket: Socket | AsyncSocket): Future[Chunk] {.multisync.} =
  let chunkHeader = await socket.recvLine()
  when defined(verbose): echo "ch< ", cast[seq[char]](chunkHeader)
  let chunkHeaderSpacePos = chunkHeader.find(' ')

  if chunkHeaderSpacePos == -1:
    result.size = fromHex[int](chunkHeader)
  else:
    result.size = fromHex[int](chunkHeader[0..chunkHeaderSpacePos-1])
    let chunkExtention = chunkHeader[chunkHeaderSpacePos+1..chunkHeader.high]
    raise newException(HttpError, "chunk extention not supported: " & chunkExtention)

  # pass the data of expected size
  result.data = await socket.recv(result.size)
  when defined(verbose): echo "cd< ", cast[seq[char]](result.data)

  # then receve the trailing \r\n
  let expectedNewLine = await socket.recvLine()
  when defined(verbose): echo "enl< ", cast[seq[char]](expectedNewLine)

  if expectedNewLine != "\r\n":
    raise newException(HttpError, "expected \\r\\n but got: " & expectedNewLine)

proc recvData*(response: Response | AsyncResponse): Future[
    string] {.multisync.} =
  ## recv one part of return data
  ## use proc body() to get all data
  ## use iterator body() to stream data from chunks
  var chunked = response.headers.getOrDefault("Transfer-Encoding").contains("chunked")
  var contentLength = if response.headers.hasKey(
      "Content-Length"): response.headers["Content-Length"].parseInt() else: -1
  if chunked:
    var chunk = await response.socket.recvChunk()
    return chunk.data

  if contentLength > 0:
    let line = await response.socket.recv(contentLength)
    when defined(verbose): echo "cl< ", cast[seq[char]](line)
    return line

  while true:
    let line = await response.socket.recvLine()
    when defined(verbose): echo "r< ", cast[seq[char]](line)
    if line.len == 0 or line == "\r\n":
      break
    return line

iterator body*(response: Response | AsyncResponse): string =
  ## iterator over the data of the response
  ## if you want to work with streams use recvStream instead which implements this iterator
  while true:
    let line = when response is Response: response.recvData() else: waitFor response.recvData()
    if line.len == 0 or line in ["", "\r\n"]:
      break
    yield line

proc body*(response: Response | AsyncResponse): Future[string] {.multisync.} =
  ## get body all at once
  for data in response.body():
    result.add(data)

proc recvStream*(response: Response): void =
  ## use this to return a stream of data
  ## this will block until finished if using in a sync context
  ## use recvData if you want to do something with the data as it comes in
  ## Note: Errors are returned as httpCodes in response
  defer: response.stream.close()
  for data in response.recvData():
    response.stream.write(data)

let defaultHeaders = {
  "user-agent": "nim-httpclient/0.1",
  "Accept": "*/*",
}

proc fetch*(
    client: HttpClient | AsyncHttpClient,
    uri: Uri | string,
    httpMethod: HttpMethod,
    body: string = "",
    # multiPart: MultiPart
    headers: HttpHeaders = newHttpHeaders(defaultHeaders),
    sslContext: SslContext = nil
  ): Future[Response | AsyncResponse] {.multisync.} =
  # set up the uri
  var uri = when uri is string: parseUri(uri) else: uri
  # set up the socket
  var socket = when client is HttpClient: initSocket(
      uri) else: await initAsyncSocket(uri)

  when defined(ssl):
    if uri.scheme == "https":
      var sslContext = if client.sslContext !=
          nil: client.sslContext else: newContext()
      sslContext = if sslContext != nil: sslContext else: newContext()
      wrapConnectedSocket(sslContext, socket, handshakeAsClient, uri.hostname)


  # make sure we have a host header
  if not headers.hasKey("Host"):
    headers.add("Host", uri.hostname)

  # make sure we have a host header
  if body != "":
    headers["Content-length"] = $body.len

  # construct path
  var path = if uri.path == "": "/" else: uri.path
  path = if uri.query != "": path & "?" & uri.query else: path

  await socket.sendGreeting(httpMethod, path)
  await socket.sendHeaders(headers)
  if body != "":
    await socket.sendBody(body)

  let greeting = await socket.recvGreeting()
  let headers = await socket.recvHeaders()

  result.httpCode = greeting.httpCode
  result.headers = headers
  result.socket = socket

proc mainAsync() {.async.} =
  var client: AsyncHttpClient
  
  var response = await client.fetch("http://info.cern.ch/hypertext/WWW/TheProject.html", HttpGet)
  for data in response.body():
    echo data

  let headers = newHttpHeaders({
    "user-agent": "nim-httpclient/0.1",
    "Accept": "*/*",
    "Host": "v1.41",
  })
  let uri = Uri(
    scheme: "unix",
    hostname: "/var/run/docker.sock",
    path: "/v1.41/containers/json"
  )
  response = await client.fetch(uri, HttpGet, headers = headers)
  for data in response.body():
    echo data

when isMainModule:
  waitFor mainAsync()
