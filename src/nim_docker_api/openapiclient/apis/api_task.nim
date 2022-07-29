#
# Docker Engine API
# 
# The Engine API is an HTTP API served by Docker Engine. It is the API the Docker client uses to communicate with the Engine, so everything the Docker client can do can be done with the API.  Most of the client's commands map directly to API endpoints (e.g. `docker ps` is `GET /containers/json`). The notable exception is running containers, which consists of several API calls.  # Errors  The API uses standard HTTP status codes to indicate the success or failure of the API call. The body of the response will be JSON in the following format:  ``` {   \"message\": \"page not found\" } ```  # Versioning  The API is usually changed in each release, so API calls are versioned to ensure that clients don't break. To lock to a specific version of the API, you prefix the URL with its version, for example, call `/v1.30/info` to use the v1.30 version of the `/info` endpoint. If the API version specified in the URL is not supported by the daemon, a HTTP `400 Bad Request` error message is returned.  If you omit the version-prefix, the current version of the API (v1.41) is used. For example, calling `/info` is the same as calling `/v1.41/info`. Using the API without a version-prefix is deprecated and will be removed in a future release.  Engine releases in the near future should support this version of the API, so your client will continue to work even if it is talking to a newer Engine.  The API uses an open schema model, which means server may add extra properties to responses. Likewise, the server will ignore any extra query parameters and request body properties. When you write clients, you need to ignore additional properties in responses to ensure they do not break when talking to newer daemons.   # Authentication  Authentication for registries is handled client side. The client has to send authentication details to various endpoints that need to communicate with registries, such as `POST /images/(name)/push`. These are sent as `X-Registry-Auth` header as a [base64url encoded](https://tools.ietf.org/html/rfc4648#section-5) (JSON) string with the following structure:  ``` {   \"username\": \"string\",   \"password\": \"string\",   \"email\": \"string\",   \"serveraddress\": \"string\" } ```  The `serveraddress` is a domain/IP without a protocol. Throughout this structure, double quotes are required.  If you have already got an identity token from the [`/auth` endpoint](#operation/SystemAuth), you can just pass this instead of credentials:  ``` {   \"identitytoken\": \"9cbaf023786cd7...\" } ``` 
# The version of the OpenAPI document: 1.41
# 
# Generated by: https://openapi-generator.tech
#

import httpclient
import ../utils
import options
import strformat
import strutils
import typetraits
import uri
import asyncdispatch
import ../oldDockerClient

import ../models/model_task



proc taskInspect*(docker: Docker | AsyncDocker, id: string): Future[Task] {.multiSync.} =
  ## Inspect a task

  let response = await docker.client.request(docker.basepath & fmt"/tasks/{id}", HttpMethod.HttpGet)
  return await constructResult1[Task](response)


proc taskList*(docker: Docker | AsyncDocker, filters: string): Future[seq[Task]] {.multiSync.} =
  ## List tasks
  let query_for_api_call = encodeQuery([
    ("filters", $filters), # A JSON encoded value of the filters (a `map[string][]string`) to process on the tasks list.  Available filters:  - `desired-state=(running | shutdown | accepted)` - `id=<task id>` - `label=key` or `label=\"key=value\"` - `name=<task name>` - `node=<node id or name>` - `service=<service name>` 
  ])

  let response = await docker.client.request(docker.basepath & "/tasks" & "?" & query_for_api_call, HttpMethod.HttpGet)
  return await constructResult1[seq[Task]](response)


proc taskLogs*(docker: Docker | AsyncDocker, id: string, details: bool, follow: bool, stdout: bool, stderr: bool, since: int, timestamps: bool, tail: string): Future[string] {.multiSync.} =
  ## Get task logs
  let query_for_api_call = encodeQuery([
    ("details", $details), # Show task context and extra details provided to logs.
    ("follow", $follow), # Keep connection after returning logs.
    ("stdout", $stdout), # Return logs from `stdout`
    ("stderr", $stderr), # Return logs from `stderr`
    ("since", $since), # Only return logs since this time, as a UNIX timestamp
    ("timestamps", $timestamps), # Add timestamps to every log line
    ("tail", $tail), # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. 
  ])

  let response = await docker.client.request(docker.basepath & fmt"/tasks/{id}/logs" & "?" & query_for_api_call, HttpMethod.HttpGet)
  return await constructResult1[string](response)

