import customHttpClient
import asyncdispatch
import jsony
import ./openapiclient/models/model_container_stats
import ./openapiclient/apis/api_utils
import strformat
import strutils 

type
    Docker* = object
        client: HttpClient
        basepath: string
    AsyncDocker* = object
        client: AsyncHttpClient
        basepath: string


let basepath = "unix:///var/run/docker.sock"
let headers = newHttpHeaders({
    "Host": "v1.41",
    "User-Agent": "nimHttp",
    "Accept": "application/json",
    "Content-Type": "application/json",
    # "Transfer-Encoding": "chunked",
        # "Content-Length": "0"
})



iterator containerStats*(docker: var Docker, id: string, stream: bool,
        oneShot: bool): ContainerStats =
    ## Get container stats based on resource usage
    let query_for_api_call = encodeQuery([
        ("stream", $stream), # Stream the output. If false, the stats will be output once and then it will disconnect.
        ("one-shot", $oneShot), # Only get a single stat instead of waiting for 2 cycles. Must be used with `stream=false`.
    ])
    docker.client = docker.client.request(HttpMethod.HttpGet, docker.basepath & fmt"/containers/{id}/stats" & "?" & query_for_api_call)
    for data in docker.client.getData():
        yield data.fromJson(ContainerStats)



proc main() =
    echo fromHex[int]("2d")
    var client = initClient(basepath, headers)
    client = client.request(HttpMethod.HttpGet, "/containers/myContainer/stats")

    # get the body response
    for i in 0..3:
        let data = client.getData()
        if data == "\r\n":
            break
        echo "< " & data


proc mainAsync() {.async.} =
    var client = await initAsyncClient(basepath, headers)
    client = await client.request(HttpMethod.HttpGet, "/containers/myContainer/stats")

    # get the body response
    for i in 0..3:
        let data = await client.getData()
        if data == "\r\n":
            break
        echo "< " & data


when isMainModule:
    main()
    # waitFor mainAsync()


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
