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



# # {.push raises: [].} # Always at start of module


# proc main*() =

#     var docker = initDocker("unix:///var/run/docker.sock")
#     # var docker = initDocker("unix:///Users/lyndon/Desktop/deploy.me/backend/src/nim_docker_api/remote.docker.sock")
#     echo docker.containers(all=true)

#     let containerConfig = ContainerConfig(
#         image: "nginx:alpine",
#         exposedPorts: some({
#             "80/tcp": none(Table[string,string])
#         }.newTable()[]),
#         hostConfig: (HostConfig(
#             portBindings: some({
#                 "80/tcp": (@[
#                     {"HostPort":"8081"}.newTable()[]
#                 ])
#             }.newTable()[])
#         ))
#     )
#     let containerName = "myContainer0"
#     # stopping existing container
#     try:
#         docker.containerStop(containerName)
#         echo "stopped " & containerName & " container"
#     except NotModified:
#         echo "container " & containerName & " already stopped"
#     # removing existing container
#     echo docker.containerRemove(containerName)
#     # creating new container
#     echo docker.containerCreate(containerName, containerConfig)
#     # starting new container
#     echo docker.containerStart(containerName)

# proc echoStream(name: string) {.async.} =
#     var docker = initAsyncDocker("unix:///var/run/docker.sock")
#     let futureStream = await docker.containerStats(name)
#     while true:
#         let (hasData, buff) = await futureStream.read()
#         if not hasData:
#             break
#         echo buff
    

# proc mainAsync*() {.async.}=

#     var docker = initAsyncDocker("unix:///var/run/docker.sock")
#     # var docker = initDocker("unix:///Users/lyndon/Desktop/deploy.me/backend/src/nim_docker_api/remote.docker.sock")

#     echo "getting container stats"
#     echo (await docker.containers(all=true))

#     let containerName = "myContainer0Async"
#     let containerConfig = ContainerConfig(
#         image: "nginx:alpine",
#         exposedPorts: some({
#             "80/tcp": none(Table[string,string])
#         }.newTable()[]),
#         hostConfig: (HostConfig(
#             portBindings: some({
#                 "80/tcp": (@[
#                     {"HostPort":"8082"}.newTable()[]
#                 ])
#             }.newTable()[])
#         ))
#     )
#     # stopping existing container
#     echo "stopping " & containerName & " container"
#     try:
#         await docker.containerStop(containerName)
#         echo "stopped " & containerName & " container"
#     except NotModified:
#         echo "container " & containerName & " already stopped"

#     # removing existing container
#     echo "removing " & containerName & " container"
#     echo await docker.containerRemove(containerName)
#     # creating new container
#     echo "creating " & containerName & " container"
#     echo await docker.containerCreate(containerName, containerConfig)
#     # starting new container
#     echo "starting " & containerName & " container"
#     echo await docker.containerStart(containerName)

#     # asyncCheck echoStream(containerName)
#     # asyncCheck echoStream("myContainer0")
    



# when isMainModule:
#     # main()
#     waitFor mainAsync()
#     runForever()
#     # for i in 1..20:
#     #     spawn spam(i)
#     # sync()


type Status* {.pure.} = enum
  Created = "created"
  Running
  Paused
  Restarting
  Removing
  Exited
  Dead

let test = Status.Created
echo test.toJson()