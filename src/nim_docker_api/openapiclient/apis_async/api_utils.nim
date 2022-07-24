import jsony
import typetraits
import httpclient
import macros
import options
import times
import strutils
import tables
import streams
import asyncstreams
import asyncdispatch


type
  Docker* = object
    client*: HttpClient
    basepath*: string
  AsyncDocker* = object
    client*: AsyncHttpClient
    basepath*: string

type
  DockerError* = object of CatchableError
  BadRequest* = object of DockerError
  NotFound* = object of DockerError
  Conflict* = object of DockerError
  NotModified* = object of DockerError
  ServerError* = object of DockerError

# something to help with boilerplate
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


template constructResult*[T](response: Response): untyped =
  if response.code in {Http200, Http201, Http202, Http204, Http206}:
    (some(response.body().fromJson(T.typedesc)), response)
  else:
    (none(T.typedesc), response)
    
proc addEncode*[T](destination: var seq[(string, string)], name: string, value: T) =
  destination.add((name, value.toJson()))

proc addEncode*[T](destination: var seq[(string, string)], name: string, value: Option[T]) =
  if value.isSome():
    destination.add((name, (value.get()).toJson()))


macro encode*(dest: untyped, statements: untyped): untyped =
  runnableExamples:
    # create the destination for the string
    var dest: seq[(string, string)] = @[]
    # a bunch of data to encode
    var a = "hello"
    var aOption = some("helloOption")
    var aTable = {"hello": "world"}.toTable()
    # populate the destination
    encode dest:
      a
      aOption
      aTable
    # encode the string
    echo dest.encodeQuery()

  result = newStmtList()
  for statement in statements:
    echo "statement: " & $(statement)
    let exprNode = newStmtList(
        newCall(
          newIdentNode("addEncode"),
          newIdentNode(dest.strVal),
          newStrLitNode(statement.strVal),
          newIdentNode(statement.strVal)
        )
      )
    result.add(exprNode)


# parse hook to convert GO time.time.rfc3339nano to nim time
proc parseHook*(s: string, i: var int, v: var DateTime) =
    var str: string
    try:
        parseHook(s, i, str)
    except ref JsonError:
        raise newException(JsonError, "Invalid time format", )
    # "0001-01-01T00:00:00Z"
    try:
        # go time.time probably has a bug and isn't always posting 9 bits of precision
        v = str.parse("yyyy-MM-dd'T'HH':'mm':'ss'Z'")
    except TimeParseError:
        if str.len() != 30:
            str = str[0..str.high-(30-str.len())]
            str.add("0".repeat(29-str.len()) & "Z")
        v = str.parse("yyyy-MM-dd'T'HH':'mm':'ss'.'fffffffff'Z'")


# simple coerce hook. if 1st char is Uppercase -> 1st char lowercase objectParsing then coerces to lowercase
proc renameHook*(v: object, fieldName: var string) =
  runnableExamples:
    type
      MyTest = object
        id: string
        myFancyField: string

    var myJson = """
    {
      "Id": "someId",
      "MyFancyField": "foo"
    }
    """
    let myTest =  myJson.fromJson(MyTest)
    echo myTest

  var tempFieldName = fieldName
  tempFieldName[0] = tempFieldName[0].toLowerAscii()
  for x , _  in v.fieldPairs():
    if tempFieldName == x:
      fieldName = tempFieldName
      return