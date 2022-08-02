import ./customHttpClient
import asyncdispatch

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
