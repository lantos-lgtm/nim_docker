# nim_docker_api
A nim Docker Engine client with types.

- currently WIP
- version: v1.41
- https://docs.docker.com/engine/api/v1.41/

## Todo
- [ ] container support
- [ ] image support
- [ ] network support
- [ ] volume support
- [ ] ws
Use
```nim
import nim_docker_api

proc main()=
    var docker = initDocker("unix:///var/run/docker.sock")
    var containers = docker.containers()
    echo containers

```



attempting openAPI generations
```bash
docker run --rm \
    -v $PWD:/local openapitools/openapi-generator-cli generate \
    -i https://docs.docker.com/engine/api/v1.41.yaml \
    -g nim \
    -o ./local/src/nim_docker_api/openAPI

```

openAPI has no mapping for map... fixing

find models/* "import json" replace ""
find models/* "import tables" replace ""
find models/* "import models_map" replace "import tables

<!-- need to deal with import object -->