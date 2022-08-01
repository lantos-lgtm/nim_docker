import ./customHttpClient
import asyncdispatch

type
    Docker* = object
        client*: HttpClient
        basepath*: string
    AsyncDocker* = object
        client*: AsyncHttpClient
        basepath*: string

let headers = newHttpHeaders({
  "Host": "v1.41",
  "User-Agent": "nim-Docker-Client",
  "Content-Type": "application/json",
  "Accept": "application/json"
})


proc initDocker*(basepath: string = "unix:///var/run/docker.sock"): Docker =
  result.client = initHttpClient(basepath)
  result.client.headers = headers
  result.basepath = basepath

proc initAsyncDocker*(basepath: string = "unix:///var/run/docker.sock"): Future[AsyncDocker] {.async.} =
  result.client = await initAsyncHttpClient(basepath, headers)
  result.client.headers = headers
  result.basepath = basepath