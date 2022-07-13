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