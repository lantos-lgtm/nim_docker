# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import
    nim_docker_api/types,
    nim_docker_api/client,
    tables,
    jsony,
    options,
    asyncdispatch

export types, client, tables, jsony, options



# {.push raises: [].} # Always at start of module


proc main*() =

    var docker = initDocker("unix:///var/run/docker.sock")
    # var docker = initDocker("unix:///Users/lyndon/Desktop/deploy.me/backend/src/nim_docker_api/remote.docker.sock")
    echo docker.containers(all=true)

    let containerConfig = ContainerConfig(
        image: "nginx:alpine",
        exposedPorts: some({
            "80/tcp": none(Table[string,string])
        }.newTable()[]),
        hostConfig: (HostConfig(
            portBindings: some({
                "80/tcp": (@[
                    {"HostPort":"8081"}.newTable()[]
                ])
            }.newTable()[])
        ))
    )
    let containerName = "myContainer0"
    # stopping existing container
    echo docker.containerStop(containerName)
    # removing existing container
    echo docker.containerRemove(containerName)
    # creating new container
    echo docker.containerCreate(containerName, containerConfig)
    # starting new container
    echo docker.containerStart(containerName)

proc mainAsync*() {.async.}=

    var docker = initAsyncDocker("unix:///var/run/docker.sock")
    # var docker = initDocker("unix:///Users/lyndon/Desktop/deploy.me/backend/src/nim_docker_api/remote.docker.sock")
    echo (await docker.containers(all=true))

    # let containerConfig = ContainerConfig(
    #     image: "nginx:alpine",
    #     exposedPorts: some({
    #         "80/tcp": none(Table[string,string])
    #     }.newTable()[]),
    #     hostConfig: (HostConfig(
    #         portBindings: some({
    #             "80/tcp": (@[
    #                 {"HostPort":"8081"}.newTable()[]
    #             ])
    #         }.newTable()[])
    #     ))
    # )
    # let containerName = "myContainer0Async"
    # # stopping existing container
    # echo await docker.containerStop(containerName)
    # # removing existing container
    # echo await docker.containerRemove(containerName)
    # # creating new container
    # echo await docker.containerCreate(containerName, containerConfig)
    # # starting new container
    # echo await docker.containerStart(containerName)



when isMainModule:
    # main()
    waitFor mainAsync()
    # runForever()
    # for i in 1..20:
    #     spawn spam(i)
    # sync()