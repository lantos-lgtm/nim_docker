import
    times,
    strutils,
    jsony


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
