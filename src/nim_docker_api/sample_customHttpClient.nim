import ./openapiclient/customHttpClient
import asyncdispatch
import jsony
import ./openapiclient/models/model_container_stats
import ./openapiclient/models/model_container_summary
import ./openapiclient/utils
import strformat
import strutils 
import tables

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



iterator containerStats*(
    docker: Docker,
    id: string,
    stream: bool,
    oneShot: bool): ContainerStats =

    ## Get container stats based on resource usage
    let query_for_api_call = encodeQuery([
        ("stream", $stream), # Stream the output. If false, the stats will be output once and then it will disconnect.
        ("one-shot", $oneShot), # Only get a single stat instead of waiting for 2 cycles. Must be used with `stream=false`.
    ])
    var (_, responseHeader) = docker.client.openRequest( docker.basepath & fmt"/containers/{id}/stats" & "?" & query_for_api_call, HttpMethod.HttpGet)
    for data in docker.client.getData(responseHeader):
        yield data.fromJson(ContainerStats)



proc main() =
    var client = initHttpClient(basepath, headers)
    var responseHeaders: HttpHeaders
    (client, responseHeaders) = client.openRequest( "/containers/json", HttpMethod.HttpGet)


    for data in client.getData(responseHeaders):
        echo "b< ",data
        
        # if data != "\r\n":
        #     let containerStats = data.fromJson(ContainerStats)


    # # get the body response
    # var containerSummarys = newSeq[ContainerSummary]()
    # for i in 0..3:
    #     let data = client.getData(responseHeaders)
    #     echo "< " & data
    #     if data == "\r\n":
    #         break
    #     containerSummarys = data.fromJson(seq[ContainerSummary])

    # echo containerSummarys

    # client.socket.send()
    # (client, responseHeaders) = client.openRequest("/containers/myContainer/stats", HttpMethod.HttpGet)
    # for data in client.getData(responseHeaders):
    #     if data != "\r\n":
    #         let containerStats = data.fromJson(ContainerStats)
    #         echo containerStats


# proc mainAsync() {.async.} =
#     var client = await initAsyncClient(basepath, headers)
#     client = await client.request(HttpMethod.HttpGet, "/containers/myContainer/stats")

#     # get the body response
#     for i in 0..3:
#         let data = await client.getData()
#         if data == "\r\n":
#             break
#         echo "< " & data


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
