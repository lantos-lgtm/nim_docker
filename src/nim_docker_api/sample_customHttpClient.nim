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



proc main() =
    var client = initHttpClient(basepath, headers)
    var response = client.openRequest( "/containers/json", HttpMethod.HttpGet)
    
    var cs = newSeq[ContainerSummary]()
    for data in client.recvData(response.response.headers):
        cs = data.fromJson(seq[ContainerSummary])
        echo cs

    # var response = client.openRequest("/containers/myContainer/stats", HttpMethod.HttpGet)
    # echo "conatiner stats"
    # response = client.openRequest("/containers/myContainer0Async/stats", HttpMethod.HttpGet)
    # for data in client.recvData(response.response.headers):
    #     echo data.fromJson(ContainerStats)

proc containerOp(id: int) {.async.} =
    var docker = await initAsyncDocker()
    var name = "myContainer" & $id
    var createReq = ContainerCreateRequest(
        image: "nginx:alpine",
        hostConfig: HostConfig(
            portBindings: some({
                "80/tcp": @[PortBinding(hostIP: "0.0.0.0", hostPort: $(8080 + id))]
            }.toTable())
        )
    )
    echo createReq.toJson()
    try:
        var createRes = await docker.containerCreate(createReq, name)
    except:
        echo getCurrentExceptionMsg()
    

    await docker.containerStart(name)

    echo "conatiner stats"
    for stat in docker.containerStats(name):
        echo stat.cpuStats

proc mainAsync() {.async.} =
    # for i in 0..10:
    #     await containerOp(i)
    await containerOp(1)
when isMainModule:
    # main()
    try:
        waitFor mainAsync()
    except:
        let msg = getCurrentExceptionMsg()
        for line in msg.split("\n"):
            var line = line.replace("\\", "/")
            if "/lib/pure/async" in line:
                continue
            if "#[" in line:
                break
            line.removeSuffix("Iter")
            echo line

    # let headers1 = newHttpHeaders({
    #     "User-Agent": "nimHttp",
    #     "Accept": "*/*",
    #     "Content-Type": "*/*",
    # })

    # var client = initClient("http://info.cern.ch", headers1)
    # client = client.request(HttpGet, "/hypertext/WWW/TheProject.html" )
    # for data in client.getData():
    #     echo data


    # var client = initClient("https://www.york.ac.uk", headers1)
    # client = client.request(HttpGet, "/teaching/cws/wws/webpage1.html")
    # echo client.responseHeaders
    # for data in client.getData():
    #     echo data
