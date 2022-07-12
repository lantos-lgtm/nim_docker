# This is just an example to get you started. Users of your library will
# import this file by writing ``import nim_docker/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.


import 
    httpClient,
    tables,
    options,
    times

type
    Docker* = object
        client*: HttpClient
        baseUrl*: string
        version*: string

    Port* = object
        IP*: string
        PrivatePort*: uint16
        PublicPort*: uint16
        Type*: string

    ContainerHostConfig* = object
        NetworkMode*: string

    EndpointIPAMConfig* = object
        IPv4Address*: string
        IPv6Address*: string
        LinkLocalIPs*: seq[string]

    EndpointSettings* = object
        # Configurations
        IPAMConfig*: EndpointIPAMConfig
        Links*: Option[seq[string]]
        Aliases*: Option[seq[string]]
        # Operational data
        NetworkID*: string
        EndpointID*: string
        Gateway*: string
        IPAddress*: string
        IPPrefixLen*: int
        IPv6Gateway*: string
        GlobalIPv6Address*: string
        GlobalIPv6PrefixLen*: int
        MacAddress*: string
        DriverOpts*: Option[Table[string, string]]

    SummaryNetworkSettings* = object
        Networks*: options.Option[Table[string, EndpointSettings]]

    MountPoint* = object
        Type*: string
        Name*: string
        Source*: string
        Destination*: string
        Driver*: string
        Mode*: string
        RW*: bool
        Propagation*: string # todo

    Container* = object
        ID*: string
        Names*: seq[string]
        Image*: string
        ImageID*: string
        Command*: string
        Created*: int64
        Ports*: seq[Port]
        SizeRw*: int64
        SizeRootFs*: int64
        Labels*: Table[string, string]
        State*: string
        Status*: string
        HostConfig*: ContainerHostConfig # conflicting with HostConfig below
        NetworkSettings*: SummaryNetworkSettings
        Mounts*: seq[MountPoint]

    # errors
    DockerError* = object of Defect
    BadRequest* = object of DockerError
    ServerError* = object of DockerError



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
        SecurityOpt*: seq[string]
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
        AttachStdout*: bool                 # Attach the standard output
        AttachStderr*: bool                 # Attach the standard error
        ExposedPorts*: options.Option[
            Table[string, Option[Table[string, string]]]] # {"<port>/<tcp|udp|sctp>"*: {}}
        Tty*: bool # Attach standard streams to a tty, including stdin if it is not closed.
        OpenStdin*: bool                    # Open stdin default false
        StdinOnce*: bool # If true, close stdin after the 1 attached client disconnects .  default false
        Env*: seq[string] # List of environment variable to set in the container
        Cmd*: seq[string]                   # Command to run when starting the container
        Healthcheck*: HealthConfig # Healthcheck describes how to check the container is healthy
        ArgsEscaped*: options.Option[bool] # True if command is already escaped (meaning treat as a command line) (Windows specific).
        Image*: string # Name of the image as it was passed by the operator (e.g. could be symbolic)
        Volumes*: options.Option[
            Table[string, Option[Table[string, string]]]
            ]                               # List of volumes (mounts) used for the container
        WorkingDir*: string # Current directory (PWD) in the command will be launched i.g "/volumes/data"*: { }
        Entrypoint*: seq[string]            # Entrypoint to run when starting the container
        NetworkDisabled*: options.Option[bool] # Is network disabled
        MacAddress*: options.Option[string] # Mac Address of the container
        OnBuild*: options.Option[seq[string]] # ONBUILD metadata that were defined on the image Dockerfile
        Labels*: Table[string, string]      # List of labels set to this container
        StopSignal*: options.Option[string] # Signal to stop a container
        StopTimeout*: options.Option[int]   # Timeout (in seconds) to stop a container
        Shell*: seq[string]                 # Shell for shell-form of RUN, CMD, ENTRYPOIN
        HostConfig*: HostConfig
        NetworkingConfig*: NetworkingConfig

    ContainerStartOptions* = object
        detatchKeys*: string

    ContainerStopOptions* =  object
        t*: int
    ContainerKillOptions* =  object
        signal*: string
    ContainerRemoveOptions* =  object
        v*: bool
        force*: bool
        link*: bool
     
    CreateResponse* = object
        Id*: string
        Warnings*: seq[string]

    ContainerStatsOptions* = object
        stream*: bool
        oneShot*: bool

    ReadCloser* = object
        
    ContainerStats* = object
        Body*: ReadCloser
        OSType*: string
    

    Stats* = object
        Read: DateTime
        Preread: DateTime
        PidsStats: PidsStats
        BlkioStats: BlkioStats
        NumProcs: uint32
        StorageStats: StorageStats
        CPUStats: CPUStats
        PrecpuStats: CPUStats
        MemoryStats: MemoryStats
        Name: string
        ID: string
        Networks: Table[string, NetworkStats] 

    BlkioStats = object
        IoServiceBytesRecursive: seq[BlkioStatEntry]
        IoServicedRecursive: seq[BlkioStatEntry]
        IoQueueRecursive: seq[BlkioStatEntry]
        IoServiceTimeRecursive: seq[BlkioStatEntry]
        IoWaitTimeRecursive: seq[BlkioStatEntry]
        IoMergedRecursive: seq[BlkioStatEntry]
        IoTimeRecursive: seq[BlkioStatEntry]
        SectorsRecursive: seq[BlkioStatEntry]

    BlkioStatEntry = object
        Major: uint64
        Minor: uint64
        Op: string
        Value: uint64

    CPUStats = object
        CPUUsage: CPUUsage
        SystemCPUUsage: uint64
        OnlineCpus: uint32
        ThrottlingData: ThrottlingData

    CPUUsage = object
        TotalUsage: uint64
        PercpuUsage: seq[uint64]
        UsageInKernelmode: uint64
        UsageInUsermode: uint64

    ThrottlingData = object
        Periods: uint64
        ThrottledPeriods: uint64
        ThrottledTime: uint64

    MemoryStats = object
        Usage: uint64
        Stats: Table[string, uint64]
        Limit: uint64

    NetworkStats = object
        RxBytes: uint64
        RxPackets: uint64
        RxErrors: uint64
        RxDropped: uint64
        TxBytes: uint64
        TxPackets: uint64
        TxErrors: uint64
        TxDropped: uint64

    PidsStats = object
        Current: uint64
        Limit: uint64

    StorageStats = object
