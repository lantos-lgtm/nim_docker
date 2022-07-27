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
        if message == "":
            break
        yield message

proc getData(myObject:  myObject): Future[myObject] {.async.} = 
    var t_object = myObject
    
    for data in t_object.getData():
        echo data
        t_object.data.add(data)

    return t_object

proc main() {.async.} =
    var myObject = myObject()

    myObject =  await myObject.getData()
    echo myObject.data


when isMainModule:
    waitFor main()

