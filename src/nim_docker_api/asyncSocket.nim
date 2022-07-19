# import
#     libcurl,
#     httpClient,
#     asyncdispatch,
#     strutils,
#     os,
#     random
# import
#     asyncdispatch,
#     strutils,
#     asyncnet,
#     posix


# proc main() {.async.} =
#     var socket = newAsyncSocket(
#         AF_UNIX,
#         SOCK_STREAM,
#         0
#     )
#     await socket.connectUnix("unix:///var/run/docker.sock")

# waitFor main()

import
    # posix,
    asyncnet,
    asyncdispatch,
    httpClient,
    net,
    re

# proc posixSocket()=
#     var socketHandle = socket(posix.AF_UNIX, posix.SOCK_STREAM, 0)
#     var remote: Sockaddr_un
#     var path = "/var/run/docker.sock"

#     # if socketHandle.cint == -1:
#     #     raise newException(IOError, "could not create socket")

#     copyMem(remote.sun_path[0].addr, path[0].addr, path.len)
#     remote.sun_family = posix.AF_UNIX.TSa_Family
#     if connect(socketHandle, cast[ptr SockAddr](remote.addr), sizeof(remote).SockLen) < 0:
#         raise newException(IOError, "could not connect to socket")

#     var send_msg = "GET /v1.41/containers/json HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     # var send_msg = "GET /v1.41/containers/myContainer/stats HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"

#     if send(socketHandle, send_msg[0].addr, send_msg.len(), 0.cint) < 0:
#         raise newException(IOError, "could not send message")

#     var received_msg = newString(2000)
#     for i in 0..1:
#         let revceived_msg_len = recv(socketHandle, received_msg[0].addr, received_msg.len(), 0.cint)
#         if revceived_msg_len < 0:
#             raise newException(IOError, "could not receive message")
#         echo received_msg

# proc netSocket() =
#     let socketHandle = newSocket(Domain.AF_UNIX, SockType.SOCK_STREAM,
#             Protocol.IPPROTO_IP)
#     socketHandle.connectUnix("/var/run/docker.sock")
#     var send_msg = "GET /v1.41/containers/json HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     socketHandle.send(send_msg)

#     for i in 0..10:
#         echo socketHandle.recvLine()

proc netHttpClient() =
    let client = newHttpClient()
    client.headers = newHttpHeaders({
        "Host": "localhost",
        "Accept": "application/json",
        "Content-Type": "application/json"
    })
    let res = client.post(
        "unix:///var/run/docker.sock/v1.41/containers/myContainer/start"
    )
    # let res = client.get("http://google.com")
    echo res.body

# proc containerCreateAsync(name: string) {.async.} =
#     if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
#         raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")
#     let socketHandle = newAsyncSocket(
#             Domain.AF_UNIX,
#             SockType.SOCK_STREAM,
#             Protocol.IPPROTO_IP
#         )
#     await socketHandle.connectUnix("/var/run/docker.sock")
#     var send_msg = "GET /v1.41/containers/create?name=" & name & "HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     await socketHandle.send(send_msg)

# proc containerStopAsync(name: string) {.async.} =
#     if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
#         raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")
#     let socketHandle = newAsyncSocket(
#             Domain.AF_UNIX,
#             SockType.SOCK_STREAM,
#             Protocol.IPPROTO_IP
#         )
#     await socketHandle.connectUnix("/var/run/docker.sock")
#     var send_msg = "GET /v1.41/containers/" & name & "/start HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     await socketHandle.send(send_msg)

# proc containerStartAsync(name: string) {.async.} =
#     if not name.match(re"^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$"):
#         raise newException(Defect, "Invalid container name, name must match ^/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$")
#     let socketHandle = newAsyncSocket(
#         Domain.AF_UNIX,
#         SockType.SOCK_STREAM,
#         Protocol.IPPROTO_IP
#         )
#     await socketHandle.connectUnix("/var/run/docker.sock")
#     var send_msg = "GET /v1.41/containers/" & name & "/stats HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     await socketHandle.send(send_msg)

#     while true:
#         echo await socketHandle.recvLine()

# proc containerStatsAsync(name: string) {.async.} =
#     let socketHandle = newAsyncSocket(
#         Domain.AF_UNIX,
#         SockType.SOCK_STREAM,
#         Protocol.IPPROTO_IP)
#     await socketHandle.connectUnix("/var/run/docker.sock")
#     var send_msg = "GET /v1.41/containers/" & name & "/stats HTTP/1.1\r\nHost: v1.41\r\nAccept: application/json\r\n\r\n"
#     await socketHandle.send(send_msg)

#     while true:
#         echo await socketHandle.recvLine()

# proc netAsyncHttpClient() {.async.} =
#     let client = newAsyncHttpClient()
#     let res = await client.get("unix:///var/run/docker.run/v1.41/containers/myContainer/stats")
#     echo await res.body


# posixSocket()
# netSocket()
netHttpClient()

# waitFor netAsyncHttpClient()

# for i in 0..1:
#     echo i
#     asyncCheck containerCtreateAsync("myContainer" & $i)
#     asyncCheck containerStartAsync("myContainer" & $i)
#     asyncCheck containerStatsAsync("myContainer" & $i)

# runForever()
