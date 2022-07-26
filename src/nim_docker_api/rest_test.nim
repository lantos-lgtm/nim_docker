import std/[asyncdispatch, httpclient]
import streams


# proc myRead(stream: FutureStream[string] | Stream) {.multisync.} =
#     while true:
#         let (hasData, data) = await stream.read()
#         if not hasData:
#             break
#         echo data

proc main() =
    let client = newHttpClient()
    client.headers = newHttpHeaders ({
        "Host": "v1.41",
        "accept": "application/json",
        "content-type": "application/json",
    })
    # client.getBody = false
    # defer: client.getBody = true
    let res = client.get("unix:///var/run/docker.sock/v1.41/containers/myContainer/stats")
    # let stream = newStringStream()
    # while true:


proc mainAsync() {.async.} =
    let client = newAsyncHttpClient()
    let res = await client.get("https://github.com/nim-lang/packages/blob/master/packages.json?raw=true")
    # waitFor res.bodyStream.myRead()
    let stream = res.bodyStream
    while true:
        let (hasData, data) = await stream.read()
        if not hasData:
            break
        echo data

main()
# waitFor mainAsync()
