import ./openapiclient/customHttpClient
import asyncdispatch
import jsony
import ./openapiclient
import ./openapiclient/utils
import ./openapiclient/newDockerClient
import strformat
import strutils 
import tables
import options
import print




let basepath = "unix:///var/run/docker.sock"
let headers = newHttpHeaders({
    "Host": "v1.41",
    "User-Agent": "nimHttp",
    "Accept": "application/json",
    "Content-Type": "application/json",
    # "Transfer-Encoding": "chunked",
        # "Content-Length": "0"
})




proc containerOp(docker: Docker | AsyncDocker, id: int): Future[void] {.multisync.} =

    var name = "myContainer" & $id
    var createReq = ContainerCreateRequest(
        image: "nginx:alpine",
        tty: false,
        attatchStdin: false,
        attatchStdout: false,
        attatchStderr: false,
        
        hostConfig: HostConfig(
            portBindings: some({
                "80/tcp": @[PortBinding(hostIP: "0.0.0.0", hostPort: $(8080 + id))]
            }.toTable())
        )
    )

    try:
        let res = await docker.containerCreate(createReq, name)
    except:
        echo getCurrentExceptionMsg()

    # try:
    #     await docker.containerStop(name)
    # except:
    #     echo getCurrentExceptionMsg()


    # try:
    #     await docker.containerStart(name)
    # except:
    #     echo getCurrentExceptionMsg()


    for stat in docker.containerStats(name):
        print stat.cpuStats
        print stat.precpuStats

proc main() =
    var docker = initDocker()
    docker.containerOp(1)

proc mainAsync() {.async.} =
    var docker = await initAsyncDocker()
    for i in 0..10:
        await docker.containerOp(i)

when isMainModule:
    main()

    # try:
    #     waitFor mainAsync()
    # except:
    #     let msg = getCurrentExceptionMsg()
    #     for line in msg.split("\n"):
    #         var line = line.replace("\\", "/")
    #         if "/lib/pure/async" in line:
    #             continue
    #         if "#[" in line:
    #             break
    #         line.removeSuffix("Iter")
    #         echo line