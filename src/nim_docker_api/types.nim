# This is just an example to get you started. Users of your library will
# import this file by writing ``import nim_docker_api/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.


import
    httpClient,
    tables,
    options,
    times,
    strutils,
    jsony

export tables, options, jsony, times, strutils, httpClient

# parse hook to convert GO time.time.rfc3339nano to nim time
proc parseHook*(s: string, i: var int, v: var DateTime) =
    var str: string
    try:
        parseHook(s, i, str)
    except ref JsonError:
        raise newException(JsonError, "Invalid time format", )
    # "0001-01-01T00:00:00Z"
    try:
        # go time.time probably has a bug and isn't always posting 9 bits of precision
        v = str.parse("yyyy-MM-dd'T'HH':'mm':'ss'Z'")
    except TimeParseError:
        if str.len() != 30:
            str = str[0..str.high-(30-str.len())]
            str.add("0".repeat(29-str.len()) & "Z")
        v = str.parse("yyyy-MM-dd'T'HH':'mm':'ss'.'fffffffff'Z'")



# Docker types
type
    Docker* = object
        client*: HttpClient
        baseUrl*: string
        version*: string

    AsyncDocker* = object
        client*: AsyncHttpClient
        baseUrl*: string
        version*: string

    Port* = object
        ip*: string
        privatePort*: uint16
        publicPort*: uint16
        `type`*: string

    ContainerHostConfig* = object
        networkMode*: string

    EndpointIPAMConfig* = object
        ipv4Address*: string
        ipv6Address*: string
        linkLocalIPs*: seq[string]

    EndpointSettings* = object
        # Configurations
        ipamConfig*: EndpointIPAMConfig
        links*: Option[seq[string]]
        aliases*: Option[seq[string]]
        # Operational data
        networkID*: string
        endpointID*: string
        gateway*: string
        ipAddress*: string
        ipPrefixLen*: int
        ipv6Gateway*: string
        globalIPv6Address*: string
        globalIPv6PrefixLen*: int
        macAddress*: string
        driverOpts*: Option[Table[string, string]]

    SummaryNetworkSettings* = object
        networks*: Option[Table[string, EndpointSettings]]

    MountPoint* = object
        `type`*: string
        name*: string
        source*: string
        destination*: string
        driver*: string
        mode*: string
        rw*: bool
        propagation*: string # todo

    Container* = object
        id*: string
        names*: seq[string]
        # `OSType`: string
        image*: string
        imageID*: string
        command*: string
        created*: int64
        orts*: seq[Port]
        sizeRw*: int64
        sizeRootFs*: int64
        labels*: Table[string, string]
        state*: string
        status*: string
        hostConfig*: ContainerHostConfig # conflicting with HostConfig below
        networkSettings*: SummaryNetworkSettings
        mounts*: seq[MountPoint]

    # errors
    DockerError* = object of CatchableError
    BadRequest* = object of DockerError
    NotFound* = object of DockerError
    Conflict* = object of DockerError
    NotModified* = object of DockerError
    ServerError* = object of DockerError



    HealthConfig* = object
        test*: seq[string]
        interval*: int
        timeout*: int
        startPeriod*: int
        retries*: int


    NetworkingConfig* = Table[string, string]
    LogConfig* = object
        `type`*: string
        config*: Table[string, string]

    RestartPolicyNames* = enum
        NO = "no"
        ALWAYS = "always"
        UNLESS_STOPPED = "unless-stopped"
        ON_FAILURE = "on-failure"

    RestartPolicy* = object
        `name`*: RestartPolicyNames
        maximumRetryCount*: int

    CgroupnsMode* = enum
        PRIVATE = "private"
        HOST = "host"

    HostConfig* = object
        cpuShares*: int
        memory*: int
        cgroupParent*: string
        blkioWeight*: int
        blkioWeightDevice*: seq[Table[string, string]]
        blkioDeviceReadBps*: seq[Table[string, string]]
        blkioDeviceWriteBps*: seq[Table[string, string]]
        blkioDeviceReadIOps*: seq[Table[string, string]]
        blkioDeviceWriteIOps*: seq[Table[string, string]]
        cpuPeriod*: int
        cpuQuota*: int
        cpusetCpus*: string
        cpusetMems*: string
        devices*: seq[Table[string, string]]
        deviceCgroupRules*: seq[Table[string, string]]
        deviceRequests*: seq[Table[string, string]]
        kernalMemory*: int
        kernalMemoryTCP*: int
        memoryReservation*: int
        memorySwap*: int
        memorySwappiness*: int
        nanoCpus*: int
        oomKillDisable*: bool
        init*: Option[bool]
        pidsLimit*: Option[int]
        ulimits*: seq[Table[string, string]]
        cpuCount*: int
        cpuPercent*: int
        ioMaximumIOps*: int
        ioMaximumBandwidth*: int
        binds*: seq[string]
        containerIDFile*: string
        logConfig*: LogConfig
        networkMode*: string
        portBindings*: Option[Table[string, seq[Table[string, string]]]]
        restartPolicy*: RestartPolicy
        autoRemove*: bool
        volumeDriver*: string
        volumesFrom*: seq[string]
        mounts*: Option[seq[Table[string, string]]]
        capAdd*: seq[string]
        capDrop*: seq[string]
        cgroupnsMode*: CgroupnsMode
        dns*: seq[string]
        dnsOptions*: seq[string]
        dnsSearch*: seq[string]
        rxtraHosts*: seq[string]
        hroupAdd*: seq[string]
        ipcMode*: string
        cgroup*: string
        links*: seq[string]
        oomScoreAdj*: int
        pidMode*: string
        privileged*: bool
        publishAllPorts*: bool
        readonlyRootfs*: bool
        securityOpt*: seq[string]
        tmpfs*: Table[string, string]
        utsMode*: string
        usernsMode*: string
        shmSize*: int
        sysctls*: Table[string, string]
        runtime*: string
        consoleSize*: seq[int]
        maskedPaths*: seq[string]
        readonlyPaths*: seq[string]


    # https://docs.docker.com/engine/api/v1.41/#tag/Container/operation/ContainerCreate
    ContainerConfig* = object
        hostname*: string
        domainname*: string
        user*: string # User that will run the command(s) inside the container, also support user:group
        attachStdin*: bool # Attach the standard input, makes possible user interaction
        attachStdout*: bool            # Attach the standard output
        attachStderr*: bool            # Attach the standard error
        exposedPorts*: Option[
            Table[string, Option[Table[string, string]]]] # {"<port>/<tcp|udp|sctp>"*: {}}
        tty*: bool # Attach standard streams to a tty, including stdin if it is not closed.
        openStdin*: bool               # Open stdin default false
        stdinOnce*: bool # If true, close stdin after the 1 attached client disconnects .  default false
        env*: seq[string]              # List of environment variable to set in the container
        cmd*: seq[string]              # Command to run when starting the container
        healthcheck*: HealthConfig # Healthcheck describes how to check the container is healthy
        argsEscaped*: Option[bool] # True if command is already escaped (meaning treat as a command line) (Windows specific).
        image*: string # Name of the image as it was passed by the operator (e.g. could be symbolic)
        volumes*: Option[
            Table[string, Option[Table[string, string]]]
            ]                          # List of volumes (mounts) used for the container
        workingDir*: string # Current directory (PWD) in the command will be launched i.g "/volumes/data"*: { }
        entrypoint*: seq[string]       # Entrypoint to run when starting the container
        networkDisabled*: Option[bool] # Is network disabled
        macAddress*: Option[string]    # Mac Address of the container
        onBuild*: Option[seq[string]] # ONBUILD metadata that were defined on the image Dockerfile
        labels*: Table[string, string] # List of labels set to this container
        stopSignal*: Option[string]    # Signal to stop a container
        stopTimeout*: Option[int]      # Timeout (in seconds) to stop a container
        shell*: seq[string]            # Shell for shell-form of RUN, CMD, ENTRYPOIN
        hostConfig*: HostConfig
        networkingConfig*: NetworkingConfig

    ContainerInspectOptions* = object
        size*: bool

    ContainerStartOptions* = object
        detatchKeys*: string

    ContainerStopOptions* = object
        t*: int
    ContainerKillOptions* = object
        signal*: string
    ContainerRemoveOptions* = object
        v*: bool
        force*: bool
        link*: bool

    CreateResponse* = object
        id*: string
        warnings*: seq[string]

    ContainerStatsOptions* = object
        stream*: bool
        oneShot*: bool


    ContainerStats* = object
        read*: DateTime
        preread*: DateTime
        pidsStats*: PidsStats
        blkioStats*: BlkioStats
        numProcs*: uint32
        storageStats*: StorageStats
        cpuStats*: CPUStats
        preCpuStats*: CPUStats
        memoryStats*: MemoryStats
        name*: string
        id*: string
        networks*: Table[string, NetworkStats]

    BlkioStats = object
        ioServiceBytesRecursive*: Option[seq[BlkioStatEntry]]
        ioServicedRecursive*: Option[seq[BlkioStatEntry]]
        ioQueueRecursive*: Option[seq[BlkioStatEntry]]
        ioServiceTimeRecursive*: Option[seq[BlkioStatEntry]]
        ioWaitTimeRecursive*: Option[seq[BlkioStatEntry]]
        ioMergedRecursive*: Option[seq[BlkioStatEntry]]
        ioTimeRecursive*: Option[seq[BlkioStatEntry]]
        sectorsRecursive*: Option[seq[BlkioStatEntry]]

    BlkioStatEntry = object
        major*: uint64
        minor*: uint64
        op*: string
        value*: uint64

    CPUStats = object
        cpuUsage*: CPUUsage
        systemCpuUsage*: uint64
        onlineCpus*: int
        throttlingData*: ThrottlingData

    CPUUsage = object
        totalUsage*: uint64
        perCpuUsage*: seq[uint64]
        usageInKernelmode*: uint64
        usageInUsermode*: uint64

    ThrottlingData = object
        periods*: uint64
        throttledPeriods*: uint64
        throttledTime*: uint64

    MemoryStats = object
        usage*: uint64
        stats*: Table[string, uint64]
        limit*: uint64

    NetworkStats = object
        rxBytes*: uint64
        rxPackets*: uint64
        rxErrors*: uint64
        rxDropped*: uint64
        txBytes*: uint64
        txPackets*: uint64
        txErrors*: uint64
        txDropped*: uint64

    PidsStats = object
        current*: uint64
        limit*: uint64

    StorageStats = object

# Custom Types
type
    HumanReadableStats* = object
        usedMemory*: uint64
        availableMemory*: uint64
        memoryUsagePercent*: float64
        cpuDelta*: uint64
        systemCpuDelta*: uint64
        numberCpus*: int
        cpuUsagePercent*: float
