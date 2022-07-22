
import jsony
import httpclient
import streams
import asyncstreams
import asyncdispatch

type
    MyObject = object
        id: int
        name: string

let basepath = "unix:///var/run/docker.sock/v1.41"


type
  DockerError* = object of CatchableError
  BadRequest* = object of DockerError
  NotFound* = object of DockerError
  Conflict* = object of DockerError
  NotModified* = object of DockerError
  ServerError* = object of DockerError

proc constructResult1*[T](response: Response): T =
  case response.code():
  of{Http200, Http201, Http202, Http204, Http206, Http304}:
    when T is void:
      return
    elif T is Stream:
      return response.bodyStream
    else:
      let body = response.body()
      return (body).fromJson(T.typedesc)
  of Http404:
    raise newException(NotFound, response.body())
  else:
    raise newException(ServerError, response.body())

  
proc constructResult1*[T](response: AsyncResponse): Future[T] {.async.}  =
  case response.code():
  of{Http200, Http201, Http202, Http204, Http206, Http304}:
    when T is void:
      return
    elif T is FutureStream[string]:
      return response.bodyStream
    else:
        let body = await response.body()
        return (body).fromJson(T.typedesc)
  of Http404:
    raise newException(NotFound, await response.body())
  else:
    raise newException(ServerError, await response.body())

proc constructResult2*[T](response: Response | AsyncResponse): Future[T] {.multisync.}  =
  case response.code():
  of{Http200, Http201, Http202, Http204, Http206, Http304}:
    when T is void:
      return
    elif T is string:
      let body = await response.body()
      return body
    elif T is Stream or T is FutureStream[string]:
      return response.bodyStream
    else:
        let body = await response.body()
        return (body).fromJson(T.typedesc)
  of Http404:
    raise newException(NotFound, await response.body())
  else:
    raise newException(ServerError, await response.body())

proc getMyObjects*(client: HttpClient | AsyncHttpClient): Future[MyObject] {.multiSync.} =
  let response = await client.get(basepath & "/containers/json")
  return await constructResult1[MyObject](response)


proc getMyObjects2*(client: HttpClient | AsyncHttpClient): Future[string] {.multiSync.} =
  let response = await client.get(basepath & "/containers/json")
  return await constructResult2[string](response)

var client = newHttpClient()
client.headers = newHttpHeaders({
        "Host": "v1.41",
        "User-Agent": "NimDocker-Client/1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
    })

echo client.getMyObjects2()