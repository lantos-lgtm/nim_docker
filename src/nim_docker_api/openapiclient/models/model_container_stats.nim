
import tables
import times
import options

type

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
    HumanReadableStats* = object
        usedMemory*: uint64
        availableMemory*: uint64
        memoryUsagePercent*: float64
        cpuDelta*: uint64
        systemCpuDelta*: uint64
        numberCpus*: int
        cpuUsagePercent*: float