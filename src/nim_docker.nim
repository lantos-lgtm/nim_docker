# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import
    nim_docker/types,
    nim_docker/client,
    tables
    
export types, client


proc main*() =
    # var path = "/var/run/docker.sock"
    # var s = newSocket(Domain.AF_UNIX, SockType.SOCK_STREAM, Protocol.IPPROTO_IP)
    # defer: s.close()
    # s.connectUnix(path)
    # s.send("GET /containers/json HTTP/1.1\r\n\r\n")

    var docker = initDocker("unix:///var/run/docker.sock")
    # var docker = initDocker("http://localhost:5000")
    echo docker.containers()
    let containerConfig = ContainerConfig(
        Image: "alpine:latest"
    )
    echo docker.containerCreate("myContainer", containerConfig)
    
when isMainModule:
    main()