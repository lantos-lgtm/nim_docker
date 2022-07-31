import httpclient




type
  Docker* = object
    client*: HttpClient
    basepath*: string
  AsyncDocker* = object
    client*: AsyncHttpClient
    basepath*: string

type
    # errors
    DockerError* = object of CatchableError
    BadRequest* = object of DockerError
    NotFound* = object of DockerError
    Conflict* = object of DockerError
    NotModified* = object of DockerError
    ServerError* = object of DockerError


let headers = newHttpHeaders({
  "Host": "v1.41",
  "User-Agent": "nim-Docker-Client",
  "Content-Type": "application/json",
  "Accept": "application/json"
})


proc initDocker*(basepath: string = "unix:///var/run/docker.sock"): Docker =
  result.client = newHttpClient()
  result.client.headers = headers
  result.basepath = basepath

proc initAsyncDocker*(basepath: string = "unix:///var/run/docker.sock"): AsyncDocker =
  result.client = newAsyncHttpClient()
  result.client.headers = headers
  result.basepath = basepath