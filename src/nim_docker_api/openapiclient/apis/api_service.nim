#
# Docker Engine API
# 
# The Engine API is an HTTP API served by Docker Engine. It is the API the Docker client uses to communicate with the Engine, so everything the Docker client can do can be done with the API.  Most of the client's commands map directly to API endpoints (e.g. `docker ps` is `GET /containers/json`). The notable exception is running containers, which consists of several API calls.  # Errors  The API uses standard HTTP status codes to indicate the success or failure of the API call. The body of the response will be JSON in the following format:  ``` {   \"message\": \"page not found\" } ```  # Versioning  The API is usually changed in each release, so API calls are versioned to ensure that clients don't break. To lock to a specific version of the API, you prefix the URL with its version, for example, call `/v1.30/info` to use the v1.30 version of the `/info` endpoint. If the API version specified in the URL is not supported by the daemon, a HTTP `400 Bad Request` error message is returned.  If you omit the version-prefix, the current version of the API (v1.41) is used. For example, calling `/info` is the same as calling `/v1.41/info`. Using the API without a version-prefix is deprecated and will be removed in a future release.  Engine releases in the near future should support this version of the API, so your client will continue to work even if it is talking to a newer Engine.  The API uses an open schema model, which means server may add extra properties to responses. Likewise, the server will ignore any extra query parameters and request body properties. When you write clients, you need to ignore additional properties in responses to ensure they do not break when talking to newer daemons.   # Authentication  Authentication for registries is handled client side. The client has to send authentication details to various endpoints that need to communicate with registries, such as `POST /images/(name)/push`. These are sent as `X-Registry-Auth` header as a [base64url encoded](https://tools.ietf.org/html/rfc4648#section-5) (JSON) string with the following structure:  ``` {   \"username\": \"string\",   \"password\": \"string\",   \"email\": \"string\",   \"serveraddress\": \"string\" } ```  The `serveraddress` is a domain/IP without a protocol. Throughout this structure, double quotes are required.  If you have already got an identity token from the [`/auth` endpoint](#operation/SystemAuth), you can just pass this instead of credentials:  ``` {   \"identitytoken\": \"9cbaf023786cd7...\" } ``` 
# The version of the OpenAPI document: 1.41
# 
# Generated by: https://openapi-generator.tech
#

import httpclient
import jsony
import ../utils
import options
import strformat
import strutils
import typetraits
import uri
import ../oldDockerClient

import ../models/model_service
import ../models/model_service_create_response
import ../models/model_service_create_request
import ../models/model_service_update_response
import ../models/model_service_update_request

import asyncdispatch


proc serviceCreate*(docker: Docker | AsyncDocker, body: ServiceCreateRequest, xRegistryAuth: string): Future[ServiceCreateResponse] {.multiSync.} =
  ## Create a service
  docker.client.headers["Content-Type"] = "application/json"
  docker.client.headers["X-Registry-Auth"] = xRegistryAuth

  let response = await docker.client.request(docker.basepath & "/services/create", HttpMethod.HttpPost, body.toJson())
  return await constructResult1[ServiceCreateResponse](response)


proc serviceDelete*(docker: Docker | AsyncDocker, id: string): Future[Response | AsyncResponse] {.multiSync.} =
  ## Delete a service
  return await docker.client.request(docker.basepath & fmt"/services/{id}", HttpMethod.HttpDelete)


proc serviceInspect*(docker: Docker | AsyncDocker, id: string, insertDefaults: bool): Future[Service] {.multiSync.} =
  ## Inspect a service
  var queryForApiCallarray: seq[(string, string)] = @[]
  queryForApiCallarray.addEncode("insertDefaults", insertDefaults) # Fill empty fields with default values.
  let queryForApiCall = queryForApiCallarray.encodeQuery()

  let response = await docker.client.request(docker.basepath & fmt"/services/{id}" & "?" & queryForApiCall, HttpMethod.HttpGet)
  return await constructResult1[Service](response)


proc serviceList*(docker: Docker | AsyncDocker, filters: string, status: bool): Future[seq[Service]] {.multiSync.} =
  ## List services
  var queryForApiCallarray: seq[(string, string)] = @[]
  queryForApiCallarray.addEncode("filters", filters) # A JSON encoded value of the filters (a `map[string][]string`) to process on the services list.  Available filters:  - `id=<service id>` - `label=<service label>` - `mode=[\"replicated\"|\"global\"]` - `name=<service name>` 
  queryForApiCallarray.addEncode("status", status) # Include service status, with count of running and desired tasks. 
  let queryForApiCall = queryForApiCallarray.encodeQuery()

  let response = await docker.client.request(docker.basepath & "/services" & "?" & queryForApiCall, HttpMethod.HttpGet)
  return await constructResult1[seq[Service]](response)


proc serviceLogs*(docker: Docker | AsyncDocker, id: string, details: bool, follow: bool, stdout: bool, stderr: bool, since: int, timestamps: bool, tail: string): Future[string] {.multiSync.} =
  ## Get service logs
  var queryForApiCallarray: seq[(string, string)] = @[]
  queryForApiCallarray.addEncode("details", details) # Show service context and extra details provided to logs.
  queryForApiCallarray.addEncode("follow", follow) # Keep connection after returning logs.
  queryForApiCallarray.addEncode("stdout", stdout) # Return logs from `stdout`
  queryForApiCallarray.addEncode("stderr", stderr) # Return logs from `stderr`
  queryForApiCallarray.addEncode("since", since) # Only return logs since this time, as a UNIX timestamp
  queryForApiCallarray.addEncode("timestamps", timestamps) # Add timestamps to every log line
  queryForApiCallarray.addEncode("tail", tail) # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. 
  let queryForApiCall = queryForApiCallarray.encodeQuery()

  let response = await docker.client.request(docker.basepath & fmt"/services/{id}/logs" & "?" & queryForApiCall, HttpMethod.HttpGet)
  return await constructResult1[string](response)


proc serviceUpdate*(docker: Docker | AsyncDocker, id: string, version: int, body: ServiceUpdateRequest, registryAuthFrom: string, rollback: string, xRegistryAuth: string): Future[ServiceUpdateResponse] {.multiSync.} =
  ## Update a service
  docker.client.headers["Content-Type"] = "application/json"
  docker.client.headers["X-Registry-Auth"] = xRegistryAuth
  var queryForApiCallarray: seq[(string, string)] = @[]
  queryForApiCallarray.addEncode("version", version) # The version number of the service object being updated. This is required to avoid conflicting writes. This version number should be the value as currently set on the service *before* the update. You can find the current version by calling `GET /services/{id}` 
  queryForApiCallarray.addEncode("registryAuthFrom", registryAuthFrom) # If the `X-Registry-Auth` header is not specified, this parameter indicates where to find registry authorization credentials. 
  queryForApiCallarray.addEncode("rollback", rollback) # Set to this parameter to `previous` to cause a server-side rollback to the previous service spec. The supplied spec will be ignored in this case. 
  let queryForApiCall = queryForApiCallarray.encodeQuery()

  let response = await docker.client.request(docker.basepath & fmt"/services/{id}/update" & "?" & queryForApiCall, HttpMethod.HttpPost, body.toJson())
  return await constructResult1[ServiceUpdateResponse](response)

