import ./types
import httpClient
import jsony
import libcurl
import strutils
import re

proc initDocker*(baseUrl: string): Docker =
  result.client = newHttpClient()
  result.baseUrl = baseUrl
  result.version = "v1.41"


proc request*(
        docker: Docker,
        path: string,
        httpMethod: HttpMethod,
        body: string,
        multipartData: MultipartData,
        useCurl: bool = false,
        headers: HttpHeaders = newHttpHeaders({"Accept": "application/json","Content-Type": "application/json"})
        ): string =
    # a wrapper to choose between curl and inbult nim request
    # this is needed because nim request doesn't support http://unix:// or unix://

    let useUnix = docker.baseUrl.startsWith("unix://")
    if useCurl or useUnix:
        # /var/run/docker.sock
        let socketPath = docker.baseUrl[7..docker.baseUrl.high]
        let curl = easy_init()
        # function for curl to handle the data returned
        proc curlWriteFn(
                buffer: cstring,
                size: int,
                count: int,
                outstream: pointer): int =
            let outbuf = cast[ref string](outstream)
            outbuf[] &= buffer
            result = size * count

        # memory to hold returned data
        let webData: ref string = new string

        # use unix if unix Sock is specified else use http
        if useUnix: 
            # /var/run/docker.sock
            discard curl.easy_setopt(OPT_UNIX_SOCKET_PATH, socketPath.cstring)
            # v1.41/containers/json?all=1
            discard curl.easy_setopt(OPT_URL, path.cstring)
        else:
            # http://localhost:2375/v1.41/containers/json?all=1
            discard curl.easy_setopt(OPT_URL, (docker.baseUrl & "/" & path).cstring)
        

        discard curl.easy_setopt(OPT_CUSTOMREQUEST, ($httpMethod).cstring)
        discard curl.easy_setopt(OPT_POSTFIELDSIZE, body.len)
        discard curl.easy_setopt(OPT_POSTFIELDS, body)

        var headerChunk: Pslist
        headerChunk = headerChunk.slist_append("Accept: application/json")
        headerChunk = headerChunk.slist_append("Content-Type: application/json")
        discard curl.easy_setopt(OPT_HTTPHEADER, headerChunk);


        discard curl.easy_setopt(OPT_WRITEDATA, webData)
        discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
        discard curl.easy_setopt(OPT_VERBOSE, 1)
        let ret = curl.easy_perform()

        if ret != E_OK:
            raise newException(Defect, $ret & $easy_strerror(ret))

        result = webData[]
        echo result
        curl.easy_reset()

    else:
        # echo path
        # http://127.0.0.1:2375/ + . containers/json
        let httpURL = docker.baseUrl & "/" & path
        docker.client.headers = newHttpHeaders({"Accept": "application/json","Content-Type": "application/json"}) 
        let res = docker.client.request(httpURL, httpMethod, body, headers, multipartData)
        case res.code:
        of Http200:
            result = res.body
        of Http400:
            raise newException(BadRequest, res.body)
        of Http500:
            raise newException(ServerError, res.body)
        else:
            raise newException(DockerError, res.body)

proc containers*(docker: Docker, all: bool = false): seq[Container] =
    let httpPath = "/containers/json" & (if all: "?all=true" else: "")
    let httpUrl = docker.version & httpPath
    # let res = docker.request(httpUrl, HttpGet, "", nil)
    let res = """[{"Id":"d99501398611d431a8943226daf312d3a69976d4524ed48066b77a1d8403ff5b","Names":["/gifted_austin"],"Image":"alpine:latest","ImageID":"sha256:6e30ab57aeeef1ebca8ac5a6ea05b5dd39d54990be94e7be18bb969a02d10a3f","Command":"/bin/sh","Created":1657519731,"Ports":[],"Labels":{},"State":"running","Status":"Up 3 hours","HostConfig":{"NetworkMode":"default"},"NetworkSettings":{"Networks":{"bridge":{"IPAMConfig":null,"Links":null,"Aliases":null,"NetworkID":"796f836082cd61d12992a7f2ff744e9d6642822440dc9b078295512c46a8cce0","EndpointID":"9f36cef0dffb0a7f31b21198568126dc1235dbf6f998aa602c60017cf4cc43bb","Gateway":"172.17.0.1","IPAddress":"172.17.0.2","IPPrefixLen":16,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"MacAddress":"02:42:ac:11:00:02","DriverOpts":null}}},"Mounts":[]}]"""
    res.fromJson(seq[Container])

proc containerCreate*(
        docker: Docker,
        name: string,
        config: ContainerConfig): string =

    if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
        raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")

    let httpPath = "/containers/create"
    let httpUrl = docker.version & httpPath & "?name=" & name
    docker.request(httpUrl, HttpMethod.HttpPost, config.toJson(), nil, false)
