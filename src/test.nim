
import jsony
import httpclient
import streams
import asyncstreams
import asyncdispatch
import ./nim_docker_api/openapiclient/models/model_container_summary

let basepath = "unix:///var/run/docker.sock/v1.41"
type
  DockerError* = object of CatchableError
  BadRequest* = object of DockerError
  NotFound* = object of DockerError
  Conflict* = object of DockerError
  NotModified* = object of DockerError
  ServerError* = object of DockerError

# proc constructResult1*[T](response: Response): T =
#   case response.code():
#   of{Http200, Http201, Http202, Http204, Http206, Http304}:
#     when T is void:
#       return
#     elif T is Stream:
#       return response.bodyStream
#     elif T is string:
#       return response.body()
#     else:
#       let body = response.body()
#       return (body).fromJson(T.typedesc)
#   of Http404:
#     raise newException(NotFound, response.body())
#   else:
#     raise newException(ServerError, response.body())


proc constructResult1*[T](response: Response | AsyncResponse): Future[T] {.multiSync.} =
  case response.code():
  of{Http200, Http201, Http202, Http204, Http206, Http304}:
    when T is void:
      return
    elif T is Stream or T is FutureStream[string]:
      return response.bodyStream
    elif T is string:
      return await response.body()
    else:
      return (await response.body()).fromJson(T.typedesc)
  of Http400:
    raise newException(BadRequest, await response.body())
  of Http404:
    raise newException(NotFound, await response.body())
  else:
    raise newException(ServerError, await response.body())


proc getMyObjects*(client: HttpClient | AsyncHttpClient): Future[seq[
    ContainerSummary]] {.multiSync.} =
  let response = await client.get(basepath & "/containers/json")
  return await constructResult1[seq[ContainerSummary]](response)

proc getMyObjects1*(client: HttpClient | AsyncHttpClient): Future[
    string] {.multiSync.} =
  let response = await client.get(basepath & "/containers/json")
  return await constructResult1[string](response)

proc getMyObjects2*(client: HttpClient | AsyncHttpClient): Future[
    void] {.multiSync.} =
  let response = await client.get(basepath & "/containers/json")
  await constructResult1[void](response)

var client = newHttpClient()
var clientAsync = newAsyncHttpClient()
client.headers = newHttpHeaders({
        "Host": "v1.41",
        "User-Agent": "NimDocker-Client/1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
  })


clientAsync.headers = newHttpHeaders({
        "Host": "v1.41",
        "User-Agent": "NimDocker-Client/1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
  })


proc main() {.async.} =
  echo client.getMyObjects()
  echo client.getMyObjects1()
  client.getMyObjects2()
  echo await clientAsync.getMyObjects()
  echo await clientAsync.getMyObjects1()
  await clientAsync.getMyObjects2()


waitFor main()