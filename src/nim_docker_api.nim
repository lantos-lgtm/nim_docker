# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import
    nim_docker_api/openapiclient,
    tables,
    jsony,
    options,
    asyncdispatch

export openapiclient, tables, jsony, options


proc mainAsync*() {.async.} =

    var docker = initAsyncDocker()
    # var docker = initDocker("unix:///Users/lyndon/Desktop/deploy.me/backend/src/nim_docker_api/remote.docker.sock")

    echo "getting container stats"
    echo (await docker.containerList())

    let containerName = "myContainer0Async"

    var res: AsyncResponse
    # stopping existing container
    echo "stopping " & containerName & " container"
    res = await docker.containerStop(containerName)
    case res.code():
    of Http204:
        echo "stopped " & containerName & " container"
    of Http304:
        echo "container " & containerName & " already stopped"
    else:
        echo "error:", res.code()


    echo "delete " & containerName & " container"
    res = await docker.containerDelete(containerName, false, true, false)
    case res.code():
    of Http204:
        echo "deleted " & containerName & " container"
    of Http304:
        echo "container " & containerName & " already deleted"
    else:
        echo "error:", res.code()



    let containerCreateRequest = ContainerCreateRequest(
        image: "nginx:alpine",
        exposedPorts: some({
            "80/tcp": none(Table[string, string])
        }.newTable()[]),
        hostConfig: (HostConfig(
            portBindings: some({
                "80/tcp": (@[
                    PortBinding(
                        hostIp: "",
                        hostPort: "8080"
                    )
                let queryForApiCall = queryForApiCallarray.encodeQuery()
            }.newTable()[])
        ))
    )

    # creating new container    
    echo "creating " & containerName & " container"
    try:
        var containerCreateResponse = await docker.containerCreate(containerCreateRequest, containerName)
        echo containerCreateResponse
    except:
        echo "error:", res.code()

    # starting new container
    echo "starting " & containerName & " container"
    res = await docker.containerStart(containerName)
    case res.code():
    of Http204:
        echo "stopped " & containerName & " container"
    of Http304:
        echo "container " & containerName & " already stopped"
    else:
        echo "error:", res.code()

when isMainModule:
    waitFor mainAsync()
    # runForever()