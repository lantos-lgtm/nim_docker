# This is just an example to get you started. Users of your library will
# import this file by writing ``import nim_docker/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.


import httpClient
import tables
import options

type
  Docker* = object
    client*: HttpClient
    baseUrl*: string
    version*: string

  Port* = object
    IP*: string
    PrivatePort*: uint16
    PublicPort*: uint16
    Type*: string

  HostConfig* = object
    NetworkMode*: string

  EndpointIPAMConfig* = object
    IPv4Address*: string
    IPv6Address*: string
    LinkLocalIPs*: seq[string]

  EndpointSettings* = object
    # Configurations
    IPAMConfig*: EndpointIPAMConfig
    Links*: Option[seq[string]]
    Aliases*: Option[seq[string]]
    # Operational data
    NetworkID*: string
    EndpointID*: string
    Gateway*: string
    IPAddress*: string
    IPPrefixLen*: int
    IPv6Gateway*: string
    GlobalIPv6Address*: string
    GlobalIPv6PrefixLen*: int
    MacAddress*: string
    DriverOpts*: Option[Table[string, string]]

  SummaryNetworkSettings* = object
    Networks*: Table[string, EndpointSettings]

  MountPoint* = object
    Type*: string
    Name*: string
    Source*: string
    Destination*: string
    Driver*: string
    Mode*: string
    RW*: bool
    Propagation*: string # todo

  Container* = object
    ID*: string
    Names*: seq[string]
    Image*: string
    ImageID*: string
    Command*: string
    Created*: int64
    Ports*: seq[Port]
    SizeRw*: int64
    SizeRootFs*: int64
    Labels*: Table[string, string]
    State*: string
    Status*: string
    HostConfig*: HostConfig
    NetworkSettings*: SummaryNetworkSettings
    Mounts*: seq[MountPoint]

  # errors
  DockerError* = object of Exception
  BadRequest* = object of DockerError
  ServerError* = object of DockerError
