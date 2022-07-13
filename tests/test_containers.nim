# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import nim_docker_api/types
import jsony
import tables
import options
# things we care about
# get container details
# list containers
# container
#  - start/stop/restart
#  - create/remove
#  - attach/log/exec/inspect
#  - rename
#  - pause/unpause
#  - commit/export/import

test "can jsony parse (strange behaviour)": 
    # solved you need to import tables. It removes the spam...
    let jsonStr = """
    [
       {
        "Id": "8dfafdbc3a40", 
        "labels": {
                "com.docker.compose.project": "test",
                "com.docker.compose.service": "test",
                "com.docker.compose.version": "1.24.1"
            },
        },
        {
        "Id": "8dfafdbc3a42",
        "labels": null
        }
    ]
    """
    type
        MyObject = object
            Id: string
            labels: options.Option[TableRef[string, string]]

    var myObjects = jsonStr.fromJson(seq[MyObject])
    echo myObjects

test "can jsony parse containers":
    var containersJson = """
        [
            {
                "Id": "d99501398611d431a8943226daf312d3a69976d4524ed48066b77a1d8403ff5b",
                "Names": [
                    "/gifted_austin"
                ],
                "Image": "alpine:latest",
                "ImageID": "sha256:6e30ab57aeeef1ebca8ac5a6ea05b5dd39d54990be94e7be18bb969a02d10a3f",
                "Command": "/bin/sh",
                "Created": 1657519731,
                "Ports": [],
                "Labels": {},
                "State": "running",
                "Status": "Up 2 hours",
                "HostConfig": {
                    "NetworkMode": "default"
                },
                "NetworkSettings": {
                    "Networks": {
                        "bridge": {
                            "IPAMConfig": null,
                            "Links": null,
                            "Aliases": null,
                            "NetworkID": "796f836082cd61d12992a7f2ff744e9d6642822440dc9b078295512c46a8cce0",
                            "EndpointID": "9f36cef0dffb0a7f31b21198568126dc1235dbf6f998aa602c60017cf4cc43bb",
                            "Gateway": "172.17.0.1",
                            "IPAddress": "172.17.0.2",
                            "IPPrefixLen": 16,
                            "IPv6Gateway": "",
                            "GlobalIPv6Address": "",
                            "GlobalIPv6PrefixLen": 0,
                            "MacAddress": "02:42:ac:11:00:02",
                            "DriverOpts": null
                        }
                    }
                },
                "Mounts": []
            }
        ]
    """
    let containersA = containersJson.fromJson(seq[Container])
    let networks =  {
                "bridge": EndpointSettings(
                    NetworkID: " ",
                    EndpointID: "9f36cef0dffb0a7f31b21198568126dc1235dbf6f998aa602c60017cf4cc43bb",
                    Gateway: "172.17.0.1",
                    IPAddress: "172.17.0.2",
                    IPPrefixLen: 16,
                    GlobalIPv6PrefixLen: 0,
                    MacAddress: "02:42:ac:11:00:02")
            }.newTable()
    let containersB: seq[Container] = @[
        Container(
            Id: "d99501398611d431a8943226daf312d3a69976d4524ed48066b77a1d8403ff5b",
            Names: @["/gifted_austin"],
            Image: "alpine:latest",
            ImageID: "sha256:6e30ab57aeeef1ebca8ac5a6ea05b5dd39d54990be94e7be18bb969a02d10a3f",
            Command: "/bin/sh",
            Created: 1657519731,
            Ports: @[],
            Labels: initTable[string, string](),
            State: "running",
            Status: "Up 2 hours",
            HostConfig: ContainerHostConfig(
                NetworkMode: "default"
        ),
        NetworkSettings: SummaryNetworkSettings(
            Networks: some(networks[])
        ),
        Mounts: @[]
        )
    ]
    check containersA == containersB
