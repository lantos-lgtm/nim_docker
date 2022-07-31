import asyncdispatch
import deques
# import reactor


var messages = @["Hello", " ", "World", ""].toDeque()
type 
    myObject = object
        data: string

proc getMessage(): Future[string] {.async.} =
    await sleepAsync(100)
    let message = messages.popFirst()
    return message


iterator getData(myObject: myObject): string =
    var message = ""
    while true:
        message = waitFor getMessage()
        yield message
        if message == "":
            break

proc getData(myObject:  myObject): Future[myObject] {.async.} = 
    var t_object = myObject
    
    for data in t_object.getData():
        echo data
        t_object.data.add(data)

    return t_object


type 
    Sync = object
    Async = object
    SyncRes = (Sync, string)
    AsyncRes = (Async, string)

# doesn't extract tuple from multisync
# proc multiSyncTuppleResponse(val: Sync | Async): Future[(Async, string) | (sync, string)] {.multisync.} =
proc multiSyncTuppleResponse(val: Sync | Async): Future[SyncRes | AsyncRes] {.multisync.} =
    return (val, "hello")

proc main() {.async.} =
    # var myObject = myObject()

    # myObject =  await myObject.getData()
    # echo myObject.data

    var
        myAsync: Async
        res: string
    (myAsync, res) = await multiSyncTuppleResponse(myAsync)


when isMainModule:
    waitFor main()



