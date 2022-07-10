import ./types
import httpClient
import tables
import jsony
import options
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

        # var headersArr: Pslist
        # for header in headers.pairs():
        #     # headersArr.add(header.key & ": " & header.value)
        #     echo header.key & ": " & header.value
        #     discard headersArr.slist_append(header.key & ": " & header.value)
        # # if headersArr.len > 0:
        # #     discard curl.easy_setopt(OPT_HEADER, headersArr) 
        # discard curl.easy_setopt(OPT_HTTPHEADER, headers);

        case httpMethod:
        of HttpMethod.HttpGet:
            discard curl.easy_setopt(OPT_HTTPGET, 1)
        of HttpMethod.HttpPost:
            discard curl.easy_setopt(OPT_POST, 1)
            # discard curl.easy_setopt(OPT_POSTFIELDS, multipartData)
        else:
            raise newException(BadRequest, "Unsupported HTTP method")

        # use unix if unix Sock is specified else use http
        if useUnix: 
            # /var/run/docker.sock
            discard curl.easy_setopt(OPT_UNIX_SOCKET_PATH, socketPath.cstring)
            # v1.41/containers/json?all=1
            discard curl.easy_setopt(OPT_URL, path.cstring)
        else:
            # http://localhost:2375/v1.41/containers/json?all=1
            discard curl.easy_setopt(OPT_URL, (docker.baseUrl & "/" & path).cstring)

        discard curl.easy_setopt(OPT_WRITEDATA, webData)
        discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)

        let ret = curl.easy_perform()

        if ret != E_OK:
            raise newException(Defect, $ret & $easy_strerror(ret))

        result = webData[]
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

proc containers*(docker: Docker): seq[Container] =
    let httpPath = "/containers/json"
    let httpUrl = docker.version & httpPath
    let res = docker.request(httpUrl, HttpGet, "", nil)
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
