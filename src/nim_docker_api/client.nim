import
    ./types,
    httpClient,
    jsony,
    strutils,
    tables,
    streams,
    asyncstreams,
    asyncdispatch,
    re

proc initDocker*(baseUrl: string): Docker =
    result.client = newHttpClient()
    result.client.headers = newHttpHeaders({
        "Host": "v1.41",
        "User-Agent": "NimDocker-Client/1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
    })
    result.baseUrl = baseUrl
    result.version = "v1.41"

proc initAsyncDocker*(baseUrl: string): AsyncDocker =
    result.client = newAsyncHttpClient()
    result.client.headers = newHttpHeaders({
        "Host": "v1.41",
        "User-Agent": "AsyncNimDocker-Client/1.0.0",
        "Accept": "application/json",
        "Content-Type": "application/json"
    })
    result.baseUrl = baseUrl
    result.version = "v1.41"




proc containersList*(
            docker: Docker | AsyncDocker,
            all: bool = false
        ): Future[seq[Container]] {.multiSync.} =

    let httpPath = "/containers/json" & (if all: "?all=true" else: "")
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(httpUrl, HttpGet, "", nil)
    echo docker.client.headers
    echo res.headers
    case res.code():
    of Http200:
        return (await res.body()).fromJson(seq[Container])
    of Http404:
        raise newException(Notfound, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())


proc containerCreate*(
            docker: Docker | AsyncDocker,
            name: string,
            config: ContainerConfig
        ): Future[CreateResponse] {.multiSync.} =

    if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
        raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")

    let httpPath = "/containers/create" & "?name=" & name
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath 
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpPost,
            config.toJson(), nil)
    case res.code():
    of Http201:
        echo await res.body()
        return (await res.body()).fromJson(CreateResponse)
    of Http400:
        raise newException(BadRequest, await res.body())
    of Http404:
        raise newException(NotFound, await res.body())
    of Http409:
        raise newException(Conflict, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())
 

proc containerInspect*(
            docker: Docker | AsyncDocker,
            name: string,
            config: ContainerInspectOptions
        ): Future[Container] {.multiSync.} =

    let httpPath = "/containers/" & name & "/create"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpPost,
            config.toJson()
    )
    case res.code():
    of Http201:
        return (await res.body()).fromJson(Container)
    of Http400:
        raise newException(BadRequest, await res.body())
    of Http404:
        raise newException(NotFound, await res.body())
    of Http409:
        raise newException(Conflict, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())

proc containerStart*(
            docker: Docker | AsyncDocker,
            id: string, # name or id
            options = ContainerStartOptions(detatchKeys: "ctrl-c")
        ): Future[void] {.multiSync.} =

    let httpPath = "/containers/" & id & "/start"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpPost,
            # options.toJson(), options in start is depreciated
        "",
    )
    case res.code():
    of Http204:
        return
    of Http304:
        raise newException(NotModified, "Container already started")
    of Http404:
        raise newException(NotFound, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())

proc containerStop*(
            docker: Docker | AsyncDocker,
            id: string, # name or id
            options = ContainerStopOptions(t: 10)
        ): Future[void] {.multiSync.} =
    let httpPath = "/containers/" & id & "/stop"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpPost,
            options.toJson(),
        )
    case res.code():
    of Http204:
        return
    of Http304:
        raise newException(NotModified, "Container already stopped")
    of Http404:
        raise newException(BadRequest, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())

proc containerRestart*(
            docker: Docker | AsyncDocker,
            id: string, # name or id
            options = ContainerStopOptions(t: 10)
        ): Future[void] {.multiSync.} =

    let httpPath = "/containers/" & id & "/restart"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl, HttpMethod.HttpPost,
            options.toJson(),
        )
    case res.code()
    of Http204:
        return
    of Http304:
        raise newException(NotModified, "Container already stopped")
    of Http404:
        raise newException(BadRequest, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())

proc containerRemove*(
            docker: Docker | AsyncDocker,
            id: string, # name or id
            options = ContainerRemoveOptions(v: true, force: true, link: true)
    ): Future[void] {.multiSync.} =

    let httpPath = "/containers/" & id
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpDelete,
            options.toJson(),
        )
    case res.code()
    of Http204:
        return
    of Http404:
        raise newException(BadRequest, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())


# this is a stream need to change it to a stream
proc containerStats*(
            docker: Docker,
            id: string, # name or id
            options = ContainerStatsOptions(stream: true),
    ): Stream =

    let httpPath = "/containers/" & id & "/stats"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = docker.client.request(
            httpUrl,
            HttpMethod.HttpGet,
            options.toJson(),
        )
    case res.code():
    of Http200:
        return res.bodyStream
    of Http404:
        raise newException(BadRequest, res.body())
    of Http500:
        raise newException(ServerError, res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())


# this is a stream need to change it to a stream
proc containerStats*(
            docker: AsyncDocker,
            id: string, # name or id
            options = ContainerStatsOptions(stream: true),
    ): Future[FutureStream[string]] {.async.} =
    let httpPath = "/containers/" & id & "/stats"
    let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let res = await docker.client.request(
            httpUrl,
            HttpMethod.HttpGet,
            options.toJson(),
        )
    case res.code():
    of Http200:
        return res.bodyStream
    of Http404:
        raise newException(BadRequest, await res.body())
    of Http500:
        raise newException(ServerError, await res.body())
    else:
        raise newException(DockerError, "Unexpected response code: " & $res.code())

proc calculateCPUPercentUNIX(stats: ContainerStats): float64 =
    var
        cpuPercent = 0.0
        # calculate the change for the cpu usage of the container in between readings
        cpuDelta = float64(stats.cpuStats.cpuUsage.totalUsage -
                stats.preCpuStats.cpuUsage.totalUsage)
        # calculate the change for the entire system between readings
        systemDelta = float64(stats.cpuStats.systemCpuUsage -
                stats.preCpuStats.systemCpuUsage)
        onlineCPUs = float64(stats.cpuStats.onlineCpus)


    if onlineCPUs == 0.0:
        onlineCPUs = float64(len(stats.cpuStats.cpuUsage.perCpuUsage))

    if systemDelta > 0.0 and cpuDelta > 0.0:
        cpuPercent = (cpuDelta / systemDelta) * onlineCpus * 100.0
    cpuPercent


proc getHumanReadableStats*(stats: ContainerStats): HumanReadableStats =
    # https://docs.docker.com/engine/api/v1.41/#tag/Container/operation/ContainerStats
    # used_memory = memory_stats.usage - memory_stats.stats.cache
    # available_memory = memory_stats.limit
    # Memory usage % = (used_memory / available_memory) * 100.0
    # cpu_delta = cpu_stats.cpu_usage.total_usage - precpu_stats.cpu_usage.total_usage
    # system_cpu_delta = cpu_stats.system_cpu_usage - precpu_stats.system_cpu_usage
    # number_cpus = lenght(cpu_stats.cpu_usage.percpu_usage) or cpu_stats.online_cpus
    # CPU usage % = (cpu_delta / system_cpu_delta) * number_cpus * 100.0


    # https://github.com/docker/cli/blob/53f8ed4bec07084db4208f55987a2ea94b7f01d6/cli/command/container/stats_helpers.go#L227-L249
    try:
        result.usedMemory = stats.memoryStats.usage - stats.memoryStats.stats["cache"]
    except:
        try:
            result.usedMemory = stats.memoryStats.usage -
                    stats.memoryStats.stats["total_inactive_file"]
        except:
            result.usedMemory = stats.memoryStats.usage -
                    stats.memoryStats.stats["inactive_file"]

    result.availableMemory = stats.memoryStats.limit
    result.memoryUsagePercent = (float(result.usedMemory) / float(
            result.availableMemory)) * 100.0
    result.cpuDelta = stats.cpuStats.cpuUsage.totalUsage -
            stats.preCpuStats.cpuUsage.totalUsage
    result.systemCpuDelta = stats.cpuStats.systemCpuUsage -
            stats.preCpuStats.systemCpuUsage
    result.numberCpus = len(stats.cpuStats.cpuUsage.percpuUsage) or
            stats.cpuStats.onlineCpus
    # unix and windows have two different ways of calculating cpu usage. We need to handle both.

    result.cpuUsagePercent = stats.calculateCPUPercentUNIX()
