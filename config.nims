switch("threads", "on")
patchFile("stdlib", "net", "src/nim_docker_api/patches/net.nim")
# patchFile("jsony", "jsony", "src/nim_docker_api/patches/jsony.nim")
patchFile("stdlib", "httpclient", "src/nim_docker_api/patches/httpclient.nim")
const useragent* = "OpenAPI-Generator/1.41/nim"
