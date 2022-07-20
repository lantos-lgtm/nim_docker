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

find models/* "import json" replace "#import json"
find models/* "import tables" replace "#import tables"
find models/* "import models_map" replace "#import models_map
import tables"


fix all enums in models, find % or $ and comment out json boiler plate
e.g

```nim
# type Protocol* {.pure.} = enum
#   Tcp
#   Udp
#   Sctp

# type PublishMode* {.pure.} = enum
#   Ingress
#   Host

type Protocol* {.pure.} = enum
  Tcp = "tcp"
  Udp = "udp"
  Sctp = "sctp"

type PublishMode* {.pure.} = enum
  Ingress = "ingress"
  Host = "host"

type EndpointPortConfig* = object
  ## 
  name*: string
  protocol*: Protocol
  targetPort*: int ## The port inside the container.
  publishedPort*: int ## The port on the swarm hosts.
  publishMode*: PublishMode ## The mode in which port is published.  <p><br /></p>  - \"ingress\" makes the target port accessible on every node,   regardless of whether there is a task for the service running on   that node or not. - \"host\" bypasses the routing mesh and publish the port directly on   the swarm node where that service is running. 


# func `%`*(v: PublishMode): JsonNode =
#   let str = case v:
#     of PublishMode.Ingress: "ingress"
#     of PublishMode.Host: "host"

#   JsonNode(kind: JString, str: str)

# func `$`*(v: PublishMode): string =
#   result = case v:
#     of PublishMode.Ingress: "ingress"
#     of PublishMode.Host: "host"
```

fix object type
find import model_object in models





<!-- need to deal with import object -->