import jsony
import typetraits
import httpclient
import macros
import options
import times
import strutils

# template constructResult[T](response: Response): untyped =
#   if response.code in {Http200, Http201, Http202, Http204, Http206}:
#     try:
#       when name(stripGenericParams(T.typedesc).typedesc) == name(Table):
#         (some(json.to(parseJson(response.body), T.typedesc)), response)
#       else:
#         (some(marshal.to[T](response.body)), response)
#     except JsonParsingError:
#       # The server returned a malformed response though the response code is 2XX
#       # TODO: need better error handling
#       error("JsonParsingError")
#       (none(T.typedesc), response)
#   else:
#     (none(T.typedesc), response)





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


template constructResult*[T](response: Response): untyped =
  if response.code in {Http200, Http201, Http202, Http204, Http206}:
    (some(response.body().fromJson(T.typedesc)), response)
  else:
    (none(T.typedesc), response)

template encodeQuery*(args: varargs[untyped]): string =
    var encodingStringArray: seq[(string, string)]
    for arg in args:
        if arg.type == Option:
            if arg.isSome:
                encodingStringArray.add((arg.name, arg.get()))
        else:
            encodingStringArray.add((arg.name, arg.value))



proc addEncode*[T](destination: var seq[(string, string)], name: string, value: T) =
  destination.add((name, $value))

proc addEncode*[T](destination: var seq[(string, string)], name: string, value: Option[T]) =
  if value.isSome():
    destination.add((name, $value.get()))

  

macro encode*(dest: untyped, statements: untyped): untyped =
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
