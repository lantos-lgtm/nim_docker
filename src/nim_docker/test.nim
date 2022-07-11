# import net

# let sock = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
# sock.bindUnix("my.sock")
# sock.listen()

# while true:
#   var client = new(Socket)
#   sock.accept(client)
#   var output = ""
#   output.setLen 32
#   client.readLine(output)
#   echo "got ", output
#   client.close()

# # import net

# let sock = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)

# sock.connectUnix("my.sock")
# sock.send("hello\n")

import nativesockets
import strutils

var errno* {.importc: "errno", header: "<errno.h>".}: int

var unix_socket = createNativeSocket(ord(AF_UNIX), ord(SOCK_STREAM), 0)
var s: Sockaddr

# ['.','/','s','o','c','k','e','t']

s.sa_family = ord(AF_UNIX)
s.sa_data = cast[array[0..13, char]](['.', '/', 's', 'o', 'c', 'k', 'e', 't',
        '\x00', '\x00', '\x00', '\x00', '\x00'])


var f: SockLen = cast[uint32](sizeof(Sockaddr_un))

var buffer: array[0..27910, char]
echo unix_socket.bindAddr(s.addr, f)
echo errno

if errno != 0:
    quit(errno)

echo unix_socket.listen()

echo errno

if errno != 0:
    quit(errno)
