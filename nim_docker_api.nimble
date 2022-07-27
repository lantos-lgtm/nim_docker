# Package

version       = "0.1.0"
author        = "lantos-lgtm"
description   = "A new awesome nimble package"
license       = "Proprietary"
srcDir        = "src"
binDir        = "bin"
bin           = @["nim_docker_api"]
# Dependencies

requires "nim >= 1.6.6"
requires "jsony"
requires "libcurl"
requires "puppy"
requires "reactor"