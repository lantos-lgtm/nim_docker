# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import
    nim_docker_api/types,
    nim_docker_api/client,
    tables,
    jsony,
    options,
    threadpool
    
export types, client, tables, jsony, options, threadpool

# {.push raises: [].} # Always at start of module


proc main*() =
    # var path = "/var/run/docker.sock"
    # var s = newSocket(Domain.AF_UNIX, SockType.SOCK_STREAM, Protocol.IPPROTO_IP)
    # defer: s.close()
    # s.connectUnix(path)
    # s.send("GET /containers/json HTTP/1.1\r\n\r\n")

    var docker = initDocker("unix:///var/run/docker.sock")

    echo docker.containers(all=true).toJson()

    let containerConfig = ContainerConfig(
        image: "nginx:alpine",
        exposedPorts: some({
            "80/tcp": none(Table[string,string])
        }.newTable()[]),
        hostConfig: (HostConfig(
            portBindings: some({
                "80/tcp": (@[
                    {"HostPort":"8080"}.newTable()[]
                ])
            }.newTable()[])
        ))
    )
    # stopping existing container
    echo docker.containerStop("myContainer")
    # removing existing container
    echo docker.containerRemove("myContainer")
    # creating new container
    echo docker.containerCreate("myContainer", containerConfig)
    # starting new container
    echo docker.containerStart("myContainer")


    # getting stats from container (with threads)
    # 1. create a channel to pass info between threads
    # 2. create a thread function to read from the channel
    # 3. create a callback function to write to the channel from libcurl
    # 4. spawn a thread to run libcurl in
    # 5. spawn a thread to run the thread function in
    # 6. wait for the threads to finish

    type
        MyCallbackDataRef = ref object
            channel: Channel[string]
        
    proc echoThread(myCallbackDataRef: MyCallbackDataRef) {.thread.} =
        while true:
            var channelRes = myCallbackDataRef[].channel.tryRecv()
            if channelRes.dataAvailable:
                # echo channelRes.msg
                let containerStats = channelRes.msg.fromJson(ContainerStats)
                echo containerStats.getHumanReadableStats()


    proc curlWriteFn(
            buffer: cstring,
            size: int,
            count: int,
            outstream: pointer
        ): int =
        var myCallbackDataRef = cast[MyCallbackDataRef](outstream)
        myCallbackDataRef.channel.send($buffer)
        result = size * count

    var myCallbackDataRef = MyCallbackDataRef()
    myCallbackDataRef[].channel.open()

    discard spawn docker.containerStats("myContainer", 
        ContainerStatsOptions(
            stream: true,
            oneShot: false
        ),
        curlWriteFn,
        myCallbackDataRef[].unsafeAddr
      )

    spawn echoThread(myCallbackDataRef)

    sync()
    
when isMainModule:
    main()