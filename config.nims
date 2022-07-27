# switch("threads", "on")
patchFile("stdlib", "net", "src/nim_docker_api/patches/net.nim")
patchFile("stdlib", "asyncnet", "src/nim_docker_api/patches/asyncnet.nim")
patchFile("stdlib", "httpclient", "src/nim_docker_api/patches/httpclient.nim")
