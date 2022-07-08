# Docker engine API in nim
- v1.41

## Todo
- [ ] container support
- [ ] image support
- [ ] network support
- [ ] volume support
- [ ] ws

## how to use

```nim
import nim_docker

proc main() =
    var docker = initDocker("unix:///var/run/docker.sock")
    echo docker.containers

```