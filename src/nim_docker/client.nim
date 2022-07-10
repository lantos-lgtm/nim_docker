import ./types
import httpClient
import tables
import jsony
import options
import libcurl
import strutils
import re

proc initDocker*(baseUrl: string): Docker =
  result.client = newHttpClient()
  result.baseUrl = baseUrl
  result.version = "v1.41"


proc request*(
        docker: Docker,
        path: string,
        httpMethod: HttpMethod,
        body: string,
        headers: HttpHeaders,
        multipartData: MultipartData): string =


    # if docker.baseUrl.startsWith("unix://"):
    if true:
        let socketPath = docker.baseUrl[7..docker.baseUrl.high]
        let curl = easy_init()
        # function for curl to handle the data returned
        proc curlWriteFn(
                buffer: cstring,
                size: int,
                count: int,
                outstream: pointer): int =
            let outbuf = cast[ref string](outstream)
            outbuf[] &= buffer
            result = size * count

        # memory to hold returned data
        let webData: ref string = new string
        # set curl options
        # discard curl.easy_setopt(OPT_UNIX_SOCKET_PATH, socketPath.cstring)
        # echo docker.baseURL & path
        # discard curl.easy_setopt(OPT_URL, docker.baseURL & path)
        discard curl.easy_setopt(OPT_URL, "http://localhost:5000/v1.41/containers/create")
        # var headersArr: Pslist

        # for header in headers.pairs():
        #     # headersArr.add(header.key & ": " & header.value)
        #     echo header.key & ": " & header.value
        #     discard headersArr.slist_append(header.key & ": " & header.value)
        # # if headersArr.len > 0:
        # #     discard curl.easy_setopt(OPT_HEADER, headersArr) 
        discard curl.easy_setopt(OPT_HTTPHEADER, headers);

        case httpMethod:
        of HttpMethod.HttpGet:
            discard curl.easy_setopt(OPT_HTTPGET, 1)
        of HttpMethod.HttpPost:
            
            discard curl.easy_setopt(OPT_POST, 1)
            discard curl.easy_setopt(OPT_POSTFIELDS, body)
        else:
            raise newException(BadRequest, "Unsupported HTTP method")

        # discard curl.easy_setopt(OPT_HTTPGET, 1)
        # discard curl.easy_setopt(OPT_URL, path)
        discard curl.easy_setopt(OPT_WRITEDATA, webData)
        discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
        # while true:
        let ret = curl.easy_perform()

        if ret != E_OK:
            raise newException(Defect, $ret & $easy_strerror(ret))

        result = webData[]
        curl.easy_reset()
    else:
        # echo path
        let httpURL = docker.baseUrl & path
        # let httpURL =  path
        let res = docker.client.request(httpURL, httpMethod, body, headers, multipartData)
        case res.code:
        of Http200:
            result = res.body
        of Http400:
            raise newException(BadRequest, res.body)
        of Http500:
            raise newException(ServerError, res.body)
        else:
            raise newException(DockerError, res.body)

proc containers*(docker: Docker): seq[Container] =
    let headers = newHttpHeaders({
        "Accept": "application/json",
        "Content-Type": "application/json"})
    let httpPath = "/containers/json"
    let httpUrl = docker.version & httpPath
    let res = docker.request(httpUrl, HttpGet, "", headers, nil)
    res.fromJson(seq[Container])


# proc ImagePull(image: string, options: ImagePullOptions):  =

type
    HealthConfig* = object
        Test*: seq[string]
        Interval*: int
        Timeout*: int
        StartPeriod*: int
        Retries*: int


    NetworkingConfig* = Table[string, string]
    LogConfig* = object
        Type*: string
        Config*: Table[string, string]

    RestartPolicyNames* = enum
        NO = "no"
        ALWAYS = "always"
        UNLESS_STOPPED = "unless-stopped"
        ON_FAILURE = "on-failure"

    RestartPolicy* = object
        Name*: RestartPolicyNames
        MaximumRetryCount*: int

    CgroupnsMode* = enum
        PRIVATE = "private"
        HOST = "host"

    HostConfig* = object
        CpuShares*: int
        Memory*: int
        CgroupParent*: string
        BlkioWeight*: int
        BlkioWeightDevice*: seq[Table[string, string]]
        BlkioDeviceReadBps*: seq[Table[string, string]]
        BlkioDeviceWriteBps*: seq[Table[string, string]]
        BlkioDeviceReadIOps*: seq[Table[string, string]]
        BlkioDeviceWriteIOps*: seq[Table[string, string]]
        CpuPeriod*: int
        CpuQuota*: int
        CpusetCpus*: string
        CpusetMems*: string
        Devices*: seq[Table[string, string]]
        DeviceCgroupRules*: seq[Table[string, string]]
        DeviceRequests*: seq[Table[string, string]]
        KernalMemory*: int
        KernalMemoryTCP*: int
        MemoryReservation*: int
        MemorySwap*: int
        MemorySwappiness*: int
        NanoCpus*: int
        OomKillDisable*: bool
        Init*: options.Option[bool]
        PidsLimit*: options.Option[int]
        Ulimits*: seq[Table[string, string]]
        CpuCount*: int
        CpuPercent*: int
        IOMaximumIOps*: int
        IOMaximumBandwidth*: int
        Binds*: seq[string]
        ContainerIDFile*: string
        LogConfig*: LogConfig
        NetworkMode*: string
        PortBindings*: options.Option[Table[string, seq[Table[string, string]]]]
        RestartPolicy*: RestartPolicy
        AutoRemove*: bool
        VolumeDriver*: string
        VolumesFrom*: seq[string]
        Mounts*: options.Option[seq[Table[string, string]]]
        CapAdd*: seq[string]
        CapDrop*: seq[string]
        CgroupnsMode*: CgroupnsMode
        Dns*: seq[string]
        DnsOptions*: seq[string]
        DnsSearch*: seq[string]
        ExtraHosts*: seq[string]
        GroupAdd*: seq[string]
        IpcMode*: string
        Cgroup*: string
        Links*: seq[string]
        OomScoreAdj*: int
        PidMode*: string
        Privileged*: bool
        PublishAllPorts*: bool
        ReadonlyRootfs*: bool
        SecurityOpt*: Table[string, string]
        Tmpfs*: Table[string, string]
        UTSMode*: string
        UsernsMode*: string
        ShmSize*: int
        Sysctls*: Table[string, string]
        Runtime*: string
        ConsoleSize*: seq[int]
        MaskedPaths*: seq[string]
        ReadonlyPaths*: seq[string]


    # https://docs.docker.com/engine/api/v1.41/#tag/Container/operation/ContainerCreate
    ContainerConfig* = object
        Hostname*: string
        Domainname*: string
        User*: string # User that will run the command(s) inside the container, also support user:group
        AttachStdin*: bool # Attach the standard input, makes possible user interaction
        AttachStdout*: bool                    # Attach the standard output
        AttachStderr*: bool                    # Attach the standard error
        ExposedPorts*: options.Option[Table[string, Option[Table[string,
            string]]]]                         # {"<port>/<tcp|udp|sctp>"*: {}}
        Tty*: bool # Attach standard streams to a tty, including stdin if it is not closed.
        OpenStdin*: bool                       # Open stdin default false
        StdinOnce*: bool # If true, close stdin after the 1 attached client disconnects .  default false
        Env*: seq[string] # List of environment variable to set in the container
        Cmd*: seq[string]                      # Command to run when starting the container
        Healthcheck*: HealthConfig # Healthcheck describes how to check the container is healthy
        ArgsEscaped*: options.Option[bool] # True if command is already escaped (meaning treat as a command line) (Windows specific).
        Image*: string # Name of the image as it was passed by the operator (e.g. could be symbolic)
        Volumes*: options.Option[Table[string, Option[Table[string,
            string]]]]                         # List of volumes (mounts) used for the container
        WorkingDir*: string # Current directory (PWD) in the command will be launched i.g "/volumes/data"*: { }
        Entrypoint*: seq[string]               # Entrypoint to run when starting the container
        NetworkDisabled*: options.Option[bool] # Is network disabled
        MacAddress*: options.Option[string]    # Mac Address of the container
        OnBuild*: options.Option[seq[string]] # ONBUILD metadata that were defined on the image Dockerfile
        Labels*: Table[string, string]         # List of labels set to this container
        StopSignal*: options.Option[string]    # Signal to stop a container
        StopTimeout*: options.Option[int]      # Timeout (in seconds) to stop a container
        Shell*: seq[string]                    # Shell for shell-form of RUN, CMD, ENTRYPOIN
        HostConfig*: HostConfig
        NetworkingConfig*: NetworkingConfig




proc containerCreate*(
    docker: Docker,
    name: string,
    config: ContainerConfig): string =
    if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
        raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")

    let headers = newHttpHeaders({
        "Accept": "application/json",
        "Content-Type": "application/json"})
    docker.client.headers = headers
    let httpPath = "/containers/create"
    let httpUrl = docker.version & httpPath & "?name=" & name
    docker.request(httpUrl, HttpMethod.HttpPost, config.toJson(), headers, nil)
