import os
import strutils

let file = "src/nim_docker_api/openapiclient/models/model_container_summary.nim"
var data = file.readFile()

echo data 
data = data.replace("##", "//")
data = data.replace("*:", ":")
echo data