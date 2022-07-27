




type

    
export interface ContainerStats {

        read: Date
        preread: Date
        pidsStats: PidsStats
        blkioStats: BlkioStats
        numProcs:Number
        storageStats: StorageStats
        cpuStats: CPUStats
        preCpuStats: CPUStats
        memoryStats: MemoryStats
        name: string
        id: string
        networks: {[key:string]: NetworkStats}
}
    
export interface BlkioStats {

        ioServiceBytesRecursive?: [BlkioStatEntry]
        ioServicedRecursive?: [BlkioStatEntry]
        ioQueueRecursive?: [BlkioStatEntry]
        ioServiceTimeRecursive?: [BlkioStatEntry]
        ioWaitTimeRecursive?: [BlkioStatEntry]
        ioMergedRecursive?: [BlkioStatEntry]
        ioTimeRecursive?: [BlkioStatEntry]
        sectorsRecursive?: [BlkioStatEntry]
}
    
export interface BlkioStatEntry {

        major:Number
        minor:Number
        op: string
        value:Number
}
    
export interface CPUStats {

        cpuUsage: CPUUsage
        systemCpuUsage:Number
        onlineCpus:Number
        throttlingData: ThrottlingData
}
    
export interface CPUUsage {

        totalUsage:Number
        perCpuUsage: [uint64]
        usageInKernelmode:Number
        usageInUsermode:Number
}
    
export interface ThrottlingData {

        periods:Number
        throttledPeriods:Number
        throttledTime:Number
}
    
export interface MemoryStats {

        usage:Number
        stats: Table[string,Number]
        limit:Number
}
    
export interface NetworkStats {

        rxBytes:Number
        rxPackets:Number
        rxErrors:Number
        rxDropped:Number
        txBytes:Number
        txPackets:Number
        txErrors:Number
        txDropped:Number
}
    
export interface PidsStats {

        current:Number
        limit:Number
}
    
export interface StorageStats {

}
// Custom Types
    
export interface HumanReadableStats {

        usedMemory:Number
        availableMemory:Number
        memoryUsagePercent:Number
        cpuDelta:Number
        systemCpuDelta:Number
        numberCpus:Number
        cpuUsagePercent:Number
}
    