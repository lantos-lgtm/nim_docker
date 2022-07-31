#
# Docker Engine API
# 
# The Engine API is an HTTP API served by Docker Engine. It is the API the Docker client uses to communicate with the Engine, so everything the Docker client can do can be done with the API.  Most of the client's commands map directly to API endpoints (e.g. `docker ps` is `GET /containers/json`). The notable exception is running containers, which consists of several API calls.  # Errors  The API uses standard HTTP status codes to indicate the success or failure of the API call. The body of the response will be JSON in the following format:  ``` {   \"message\": \"page not found\" } ```  # Versioning  The API is usually changed in each release, so API calls are versioned to ensure that clients don't break. To lock to a specific version of the API, you prefix the URL with its version, for example, call `/v1.30/info` to use the v1.30 version of the `/info` endpoint. If the API version specified in the URL is not supported by the daemon, a HTTP `400 Bad Request` error message is returned.  If you omit the version-prefix, the current version of the API (v1.41) is used. For example, calling `/info` is the same as calling `/v1.41/info`. Using the API without a version-prefix is deprecated and will be removed in a future release.  Engine releases in the near future should support this version of the API, so your client will continue to work even if it is talking to a newer Engine.  The API uses an open schema model, which means server may add extra properties to responses. Likewise, the server will ignore any extra query parameters and request body properties. When you write clients, you need to ignore additional properties in responses to ensure they do not break when talking to newer daemons.   # Authentication  Authentication for registries is handled client side. The client has to send authentication details to various endpoints that need to communicate with registries, such as `POST /images/(name)/push`. These are sent as `X-Registry-Auth` header as a [base64url encoded](https://tools.ietf.org/html/rfc4648#section-5) (JSON) string with the following structure:  ``` {   \"username\": \"string\",   \"password\": \"string\",   \"email\": \"string\",   \"serveraddress\": \"string\" } ```  The `serveraddress` is a domain/IP without a protocol. Throughout this structure, double quotes are required.  If you have already got an identity token from the [`/auth` endpoint](#operation/SystemAuth), you can just pass this instead of credentials:  ``` {   \"identitytoken\": \"9cbaf023786cd7...\" } ``` 
# The version of the OpenAPI document: 1.41
# 
# Generated by: https://openapi-generator.tech
#

# import httpclient
import jsony
import ../utils
import options
import strformat
import strutils
import tables
import typetraits
import uri
import asyncdispatch
import ../customHttpClient
import ../newDockerClient

import ../models/model_container_change_response_item
import ../models/model_container_create_response
import ../models/model_container_create_request
import ../models/model_container_inspect_response
import ../models/model_container_prune_response
import ../models/model_container_summary
import ../models/model_container_stats
import ../models/model_container_top_response
import ../models/model_container_update_response
import ../models/model_container_update_request
import ../models/model_container_wait_response


# proc containerArchive*(docker: var Docker | var AsyncDocker, id: string, path: string): Future[Docker | AsyncDocker] {.multiSync.} =
#   ## Get an archive of a filesystem resource in a container
#   let queryForApiCall = encodeQuery([
#     ("path", $path), # Resource in the container’s filesystem to archive.
#   ])
#   docker.client = await docker.client.request(docker.basepath & fmt"/containers/{id}/archive" & "?" & queryForApiCall, HttpMethod.HttpGet)
#   return docker

# proc containerArchiveInfo*(docker: Docker | AsyncDocker, id: string, path: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Get information about files in a container
#   let queryForApiCall = encodeQuery([
#     ("path", $path), # Resource in the container’s filesystem to archive.
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/archive" & "?" & queryForApiCall, HttpMethod.HttpHead)


# proc containerAttach*(docker: Docker | AsyncDocker, id: string, detachKeys: string, logs: bool, stream: bool, stdin: bool, stdout: bool, stderr: bool): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Attach to a container
#   let queryForApiCall = encodeQuery([
#     ("detachKeys", $detachKeys), # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
#     ("logs", $logs), # Replay previous logs from the container.  This is useful for attaching to a container that has started and you want to output everything since the container started.  If `stream` is also enabled, once all the previous output has been returned, it will seamlessly transition into streaming current output.
#     ("stream", $stream), # Stream attached streams from the time the request was made onwards.
#     ("stdin", $stdin), # Attach to `stdin`
#     ("stdout", $stdout), # Attach to `stdout`
#     ("stderr", $stderr), # Attach to `stderr`
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/attach" & "?" & queryForApiCall, HttpMethod.HttpPost)


# proc containerAttachWebsocket*(docker: Docker | AsyncDocker, id: string, detachKeys: string, logs: bool, stream: bool): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Attach to a container via a websocket
#   let queryForApiCall = encodeQuery([
#     ("detachKeys", $detachKeys), # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,`, or `_`.
#     ("logs", $logs), # Return logs
#     ("stream", $stream), # Return stream
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/attach/ws" & "?" & queryForApiCall, HttpMethod.HttpGet)


# proc containerChanges*(docker: Docker | AsyncDocker, id: string): Future[seq[ContainerChangeResponseItem]] {.multiSync.} =
#   ## Get changes on a container’s filesystem

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/changes", HttpMethod.HttpGet)
#   return await constructResult1[seq[ContainerChangeResponseItem]](response)


# proc containerCreate*(docker: Docker | AsyncDocker, body: ContainerCreateRequest, name: string): Future[ContainerCreateResponse] {.multiSync.} =
#   ## Create a container
#   docker.client.headers["Content-Type"] = "application/json"
#   let queryForApiCall = encodeQuery([
#     ("name", $name), # Assign the specified name to the container. Must match `/?[a-zA-Z0-9][a-zA-Z0-9_.-]+`.
#   ])

#   let response = await docker.client.request(docker.basepath & "/containers/create" & "?" & queryForApiCall, HttpMethod.HttpPost, body.toJson())
#   return await constructResult1[ContainerCreateResponse](response)


# proc containerDelete*(docker: Docker | AsyncDocker, id: string, v: bool, force: bool, link: bool): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Remove a container
#   let queryForApiCall = encodeQuery([
#     ("v", $v), # Remove anonymous volumes associated with the container.
#     ("force", $force), # If the container is running, kill it before removing it.
#     ("link", $link), # Remove the specified link associated with the container.
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}" & "?" & queryForApiCall, HttpMethod.HttpDelete)


# proc containerExport*(docker: Docker | AsyncDocker, id: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Export a container
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/export", HttpMethod.HttpGet)


# proc containerInspect*(docker: Docker | AsyncDocker, id: string, size: bool): Future[ContainerInspectResponse] {.multiSync.} =
#   ## Inspect a container
#   let queryForApiCall = encodeQuery([
#     ("size", $size), # Return the size of container as fields `SizeRw` and `SizeRootFs`
#   ])

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/json" & "?" & queryForApiCall, HttpMethod.HttpGet)
#   return await constructResult1[ContainerInspectResponse](response)


# proc containerKill*(docker: Docker | AsyncDocker, id: string, signal: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Kill a container
#   let queryForApiCall = encodeQuery([
#     ("signal", $signal), # Signal to send to the container as an integer or string (e.g. `SIGINT`)
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/kill" & "?" & queryForApiCall, HttpMethod.HttpPost)

# proc test(a: Docker | AsyncDocker): Future[void] {.multisync.} =


proc containerList*(
  # docker: Docker | AsyncDocker,
  docker:  AsyncDocker,
  all: bool = false,
  limit: Option[int] = none(int),
  size: bool = false,
  filters: Option[Table[string, seq[string]]] = none(Table[string, seq[string]])
# ): Future[(Docker, seq[ContainerSummary]) | (AsyncDocker, seq[ContainerSummary])] {.multisync.} =
): Future[(AsyncHttpClient, seq[ContainerSummary])] {.async.} =

    var queryForApiCall_array: seq[(string, string)] = @[]
    queryForApiCall_array.addEncode("all",
        all) # Return all containers. By default, only running containers are shown.
    queryForApiCall_array.addEncode("limit",
        limit) # Return this number of most recently created containers, including non-running ones.
    queryForApiCall_array.addEncode("size",
        size) # Return the size of container as fields `SizeRw` and `SizeRootFs`.
    queryForApiCall_array.addEncode("filters",
        filters) # Filters to process on the container list, encoded as JSON (a `map[string][]string`). For example, `{\"status\": [\"paused\"]}` will only return paused containers.  Available filters:  - `ancestor`=(`<image-name>[:<tag>]`, `<image id>`, or `<image@digest>`) - `before`=(`<container id>` or `<container name>`) - `expose`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `exited=<int>` containers with exit code of `<int>` - `health`=(`starting`|`healthy`|`unhealthy`|`none`) - `id=<ID>` a container's ID - `isolation=`(`default`|`process`|`hyperv`) (Windows daemon only) - `is-task=`(`true`|`false`) - `label=key` or `label=\"key=value\"` of a container label - `name=<name>` a container's name - `network`=(`<network id>` or `<network name>`) - `publish`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `since`=(`<container id>` or `<container name>`) - `status=`(`created`|`restarting`|`running`|`removing`|`paused`|`exited`|`dead`) - `volume`=(`<volume name>` or `<mount point destination>`)
    let queryForApiCall = queryForApiCall_array.encodeQuery()
    var (tempHttpClient, responseHeaders) = await docker.client.openRequest(
            docker.basepath &"/containers/json" & "?" & queryForApiCall,
            HttpMethod.HttpGet)

    let data = await tempHttpClient.getData(responseHeaders)
    # return (tempDocker, data.fromJson(seq[ContainerSummary]))
    return data.fromJson(seq[ContainerSummary])

    # return

# proc containerLogs*(docker: Docker | AsyncDocker, id: string, follow: bool, stdout: bool, stderr: bool, since: int, until: int, timestamps: bool, tail: string): Future[string] {.multiSync.} =
#   ## Get container logs

#   var queryForApiCall_array: seq[(string, string)] = @[
#     ("follow", $follow), # Keep connection after returning logs.
#     ("stdout", $stdout), # Return logs from `stdout`
#     ("stderr", $stderr), # Return logs from `stderr`
#     ("since", $since), # Only return logs since this time, as a UNIX timestamp
#     ("until", $until), # Only return logs before this time, as a UNIX timestamp
#     ("timestamps", $timestamps), # Add timestamps to every log line
#     ("tail", $tail), # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines.
#   ]
#   let queryForApiCall = queryForApiCall_array.encodeQuery()

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/logs" & "?" & queryForApiCall, HttpMethod.HttpGet)
#   return await constructResult1[string](response)


# proc containerPause*(docker: Docker | AsyncDocker, id: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Pause a container
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/pause", HttpMethod.HttpPost)


# proc containerPrune*(docker: Docker | AsyncDocker, filters: string): Future[ContainerPruneResponse] {.multiSync.} =
#   ## Delete stopped containers
#   let queryForApiCall = encodeQuery([
#     ("filters", $filters), # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters: - `until=<timestamp>` Prune containers created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune containers with (or without, in case `label!=...` is used) the specified labels.
#   ])

#   let response = await docker.client.request(docker.basepath & "/containers/prune" & "?" & queryForApiCall, HttpMethod.HttpPost)
#   return await constructResult1[ContainerPruneResponse](response)


# proc containerRename*(docker: Docker | AsyncDocker, id: string, name: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Rename a container
#   let queryForApiCall = encodeQuery([
#     ("name", $name), # New name for the container
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/rename" & "?" & queryForApiCall, HttpMethod.HttpPost)


# proc containerResize*(docker: Docker | AsyncDocker, id: string, h: int, w: int): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Resize a container TTY
#   let queryForApiCall = encodeQuery([
#     ("h", $h), # Height of the TTY session in characters
#     ("w", $w), # Width of the TTY session in characters
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/resize" & "?" & queryForApiCall, HttpMethod.HttpPost)


# proc containerRestart*(docker: Docker | AsyncDocker, id: string, t: int): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Restart a container
#   let queryForApiCall = encodeQuery([
#     ("t", $t), # Number of seconds to wait before killing the container
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/restart" & "?" & queryForApiCall, HttpMethod.HttpPost)


# proc containerStart*(docker: Docker | AsyncDocker, id: string, detachKeys: string = "ctrl-z"): Future[Docker| AsyncDocker] {.multisync.} =
#   ## Start a container
#   let queryForApiCall = encodeQuery([
#     ("detachKeys", $detachKeys), # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/start" & "?" & queryForApiCall, HttpMethod.HttpPost)


iterator containerStats*(docker: AsyncDocker, id: string, stream: bool,
    oneShot: bool): ContainerStats =
    ## Get container stats based on resource usage
    let queryForApiCall = encodeQuery([
      ("stream", $stream), # Stream the output. If false, the stats will be output once and then it will disconnect.
        ("one-shot", $oneShot), # Only get a single stat instead of waiting for 2 cycles. Must be used with `stream=false`.
    ])
    let (client, responseHeader) = waitFor docker.client.openRequest(
        docker.basepath &
        fmt"/containers/{id}/stats" & "?" & queryForApiCall,
        HttpMethod.HttpGet)

    for data in docker.client.getData(responseHeader):
        yield data.fromJson(ContainerStats)

# proc containerStop*(docker: Docker | AsyncDocker, id: string, t: int = 0): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Stop a container
#   let queryForApiCall = encodeQuery([
#     ("t", $t), # Number of seconds to wait before killing the container
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/stop" & "?" & queryForApiCall, HttpMethod.HttpPost)


# proc containerTop*(docker: Docker | AsyncDocker, id: string, psArgs: string): Future[ContainerTopResponse] {.multiSync.} =
#   ## List processes running inside a container
#   let queryForApiCall = encodeQuery([
#     ("ps_args", $psArgs), # The arguments to pass to `ps`. For example, `aux`
#   ])

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/top" & "?" & queryForApiCall, HttpMethod.HttpGet)
#   return await constructResult1[ContainerTopResponse](response)


# proc containerUnpause*(docker: Docker | AsyncDocker, id: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Unpause a container
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/unpause", HttpMethod.HttpPost)


# proc containerUpdate*(docker: Docker | AsyncDocker, id: string, update: ContainerUpdateRequest): Future[ContainerUpdateResponse] {.multiSync.} =
#   ## Update a container
#   docker.client.headers["Content-Type"] = "application/json"

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/update", HttpMethod.HttpPost, update.toJson())
#   return await constructResult1[ContainerUpdateResponse](response)


# proc containerWait*(docker: Docker | AsyncDocker, id: string, condition: string): Future[ContainerWaitResponse] {.multiSync.} =
#   ## Wait for a container
#   let queryForApiCall = encodeQuery([
#     ("condition", $condition), # Wait until a container state reaches the given condition.  Defaults to `not-running` if omitted or empty.
#   ])

#   let response = await docker.client.request(docker.basepath & fmt"/containers/{id}/wait" & "?" & queryForApiCall, HttpMethod.HttpPost)
#   return await constructResult1[ContainerWaitResponse](response)


# proc putContainerArchive*(docker: Docker | AsyncDocker, id: string, path: string, inputStream: string, noOverwriteDirNonDir: string, copyUIDGID: string): Future[Docker| AsyncDocker] {.multiSync.} =
#   ## Extract an archive of files or folders to a directory in a container
#   docker.client.headers["Content-Type"] = "application/json"
#   let queryForApiCall = encodeQuery([
#     ("path", $path), # Path to a directory in the container to extract the archive’s contents into.
#     ("noOverwriteDirNonDir", $noOverwriteDirNonDir), # If `1`, `true`, or `True` then it will be an error if unpacking the given content would cause an existing directory to be replaced with a non-directory and vice versa.
#     ("copyUIDGID", $copyUIDGID), # If `1`, `true`, then it will copy UID/GID maps to the dest file or dir
#   ])
#   return await docker.client.request(docker.basepath & fmt"/containers/{id}/archive" & "?" & queryForApiCall, HttpMethod.HttpPut, inputStream.toJson())
