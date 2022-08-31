import ./customHttpClient
import 
  asyncdispatch,
  net,
  asyncnet

type
    Docker* = object
        client*: HttpClient
        baseUri*: Uri
        headers*: HttpHeaders
    AsyncDocker* = object
        client*: AsyncHttpClient
        baseUri*: Uri
        headers*: HttpHeaders

let defaultDocketHeaders = {
  "Host": "v1.41",
  "User-Agent": "nim-Docker-Client",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
let uri = Uri(scheme: "unix", hostname: "/var/run/docker.sock", path: "")
proc initDocker*(baseUri = uri): Docker =
  result.headers = newHttpHeaders(defaultDocketHeaders)
  result.baseUri = baseUri

proc initAsyncDocker*(baseUri = uri): Future[AsyncDocker] {.async.} =
  result.headers = newHttpHeaders(defaultDocketHeaders)
  result.baseUri = baseUri


proc raiseHttpError*(res: Response | AsyncResponse): Future[void] {.multisync.} =
  case res.httpCode:
  of Http200, Http201, Http202, Http204:
    discard
  of Http304:
    discard
  else:
    let message = $res.httpCode & ":" & await res.body()
    raise newException(HttpError, "HTTP Error: " & message)
