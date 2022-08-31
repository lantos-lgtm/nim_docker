import jsony
# import typetraits
import customHttpClient
import macros
import options
import times
import strutils
import tables
import asyncdispatch
import net
import uri


proc addEncode*[T](dest: var seq[(string, string)], key: string, val: T) =
  when val is Option:
    if val.isSome:
      dest.addEncode(key, val)
  elif val is string:
    if val != "":
      dest.add((key, val))
  else:
    dest.add((key, $val))

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

  var tempFieldName = fieldName
  tempFieldName[0] = tempFieldName[0].toLowerAscii()
  for x, _ in v.fieldPairs():
    if tempFieldName == x:
      fieldName = tempFieldName
      return
