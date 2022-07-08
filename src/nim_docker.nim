# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import
  nim_docker/types,
  nim_docker/client,
  options,
  tables,
  jsony

export
  types,
  client

proc main() =
  var docker = initDocker("unix:///var/run/docker.sock")
  echo docker.containers()

when isMainModule:
  main()
