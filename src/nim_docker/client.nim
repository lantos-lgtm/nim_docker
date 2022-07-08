import ./types
import httpClient
import tables
import jsony
import libcurl
import strutils

proc initDocker*(baseUrl: string): Docker =
  result.client = newHttpClient()
  result.baseUrl = baseUrl
  result.version = "v1.41"


proc request*(docker: Docker, path: string, httpMethod: HttpMethod,
        body: string, headers: HttpHeaders, multipartData: MultipartData): string =
    if docker.baseUrl.startsWith("unix://"):
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
        # set curl options
        discard curl.easy_setopt(OPT_UNIX_SOCKET_PATH, socketPath.cstring)
        case httpMethod:
        of HttpMethod.HttpGet:
            discard curl.easy_setopt(OPT_HTTPGET, 1)
        of HttpMethod.HttpPost:
            discard curl.easy_setopt(OPT_POST, 1)
            discard curl.easy_setopt(OPT_POSTFIELDS, body)
        else:
            raise newException(BadRequest, "Unsupported HTTP method")

        # discard curl.easy_setopt(OPT_HTTPGET, 1)
        discard curl.easy_setopt(OPT_URL, path)
        discard curl.easy_setopt(OPT_WRITEDATA, webData)
        discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
        # while true:
        let ret = curl.easy_perform()

        if ret != E_OK:
            raise newException(Defect, $ret)

        result = webData[]
        curl.easy_reset()
    else:
        let res = docker.client.request(path, httpMethod, body, headers, multipartData)
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
    let headers = newHttpHeaders({
        "Accept": "application/json",
        "Content-Type": "application/json"})
    let httpPath = "/containers/json"
    #   let httpUrl = docker.baseUrl & "/" & docker.version & httpPath
    let httpUrl = docker.version & httpPath
    let res = docker.request(httpUrl, HttpGet, "", headers, nil)
    echo res
    res.fromJson(seq[Container])