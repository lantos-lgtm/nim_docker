#
# Docker Engine API
# 
# The Engine API is an HTTP API served by Docker Engine. It is the API the Docker client uses to communicate with the Engine, so everything the Docker client can do can be done with the API.  Most of the client's commands map directly to API endpoints (e.g. `docker ps` is `GET /containers/json`). The notable exception is running containers, which consists of several API calls.  # Errors  The API uses standard HTTP status codes to indicate the success or failure of the API call. The body of the response will be JSON in the following format:  ``` {   \"message\": \"page not found\" } ```  # Versioning  The API is usually changed in each release, so API calls are versioned to ensure that clients don't break. To lock to a specific version of the API, you prefix the URL with its version, for example, call `/v1.30/info` to use the v1.30 version of the `/info` endpoint. If the API version specified in the URL is not supported by the daemon, a HTTP `400 Bad Request` error message is returned.  If you omit the version-prefix, the current version of the API (v1.41) is used. For example, calling `/info` is the same as calling `/v1.41/info`. Using the API without a version-prefix is deprecated and will be removed in a future release.  Engine releases in the near future should support this version of the API, so your client will continue to work even if it is talking to a newer Engine.  The API uses an open schema model, which means server may add extra properties to responses. Likewise, the server will ignore any extra query parameters and request body properties. When you write clients, you need to ignore additional properties in responses to ensure they do not break when talking to newer daemons.   # Authentication  Authentication for registries is handled client side. The client has to send authentication details to various endpoints that need to communicate with registries, such as `POST /images/(name)/push`. These are sent as `X-Registry-Auth` header as a [base64url encoded](https://tools.ietf.org/html/rfc4648#section-5) (JSON) string with the following structure:  ``` {   \"username\": \"string\",   \"password\": \"string\",   \"email\": \"string\",   \"serveraddress\": \"string\" } ```  The `serveraddress` is a domain/IP without a protocol. Throughout this structure, double quotes are required.  If you have already got an identity token from the [`/auth` endpoint](#operation/SystemAuth), you can just pass this instead of credentials:  ``` {   \"identitytoken\": \"9cbaf023786cd7...\" } ``` 
# The version of the OpenAPI document: 1.41
# 
# Generated by: https://openapi-generator.tech
#

import httpclient
import json
import jsony
import api_utils
import options
import strformat
import strutils
import tables
import typetraits
import uri

import ../models/model_config
import ../models/model_config_create_request
import ../models/model_config_spec
import ../models/model_id_response

import asyncdispatch



proc configCreate*(docker: Docker | AsyncDocker, body: ConfigCreateRequest): Future[IdResponse] {.multiSync.} =
  ## Create a config
  docker.client.headers["Content-Type"] = "application/json"

  let response = await docker.client.post(docker.basepath & "/configs/create", $(%body))
  return await constructResult1[IdResponse](response)


proc configDelete*(docker: Docker | AsyncDocker, id: string): Future[Response | AsyncResponse] {.multiSync.} =
  ## Delete a config
  return await docker.client.delete(docker.basepath & fmt"/configs/{id}")


proc configInspect*(docker: Docker | AsyncDocker, id: string): Future[Config] {.multiSync.} =
  ## Inspect a config

  let response = await docker.client.get(docker.basepath & fmt"/configs/{id}")
  return await constructResult1[Config](response)


proc configList*(docker: Docker | AsyncDocker, filters: string): Future[seq[Config]] {.multiSync.} =
  ## List configs
  let query_for_api_call = encodeQuery([
    ("filters", $filters), # A JSON encoded value of the filters (a `map[string][]string`) to process on the configs list.  Available filters:  - `id=<config id>` - `label=<key> or label=<key>=value` - `name=<config name>` - `names=<config name>` 
  ])

  let response = await docker.client.get(docker.basepath & "/configs" & "?" & query_for_api_call)
  return await constructResult1[seq[Config]](response)


proc configUpdate*(docker: Docker | AsyncDocker, id: string, version: int64, body: ConfigSpec): Future[Response | AsyncResponse] {.multiSync.} =
  ## Update a Config
  docker.client.headers["Content-Type"] = "application/json"
  let query_for_api_call = encodeQuery([
    ("version", $version), # The version number of the config object being updated. This is required to avoid conflicting writes. 
  ])
  return await docker.client.post(docker.basepath & fmt"/configs/{id}/update" & "?" & query_for_api_call, $(%body))

