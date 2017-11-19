# Denial of Service

Denial of Service attacks are common and often easy to execute. They come in a few major categories.
Most of the attacks can be countered by an application. This document outlines how Vapor 3 is designed against these attacks and how you can make use of the tools available.

## Memory buffer attacks

Memory buffer attacks are achieved by draining the amount of memory a server has available.

One example in HTTP/1 is by sending an arbitrarily large POST data containing any data. The server might accept the data for an indefinite period of time causing the memory to fill up and the application to meet the hardware or virtual machine limits. This can cause swapping, a crash or both.

A second example exploits the same principle in WebSockets, where the protocol allows sending data up to `UInt64.max`.

### Solution 1

Limit the maximum amount of data on protocol level, rejecting any requests exceeding the limit. The follow-up behaviour of the server can be either closing the connection or returning a "Bad Request" response.

### Solution 2

HTTP/2 is a protocol designed against these attacks. Hosting HTTP/2 as the protocol of choice can improve performance and reduce attack vectors in many ways.

### Solution 3

NGINX is commonly used as a proxy between the public internet and an application such as a Vapor based application. Setting up a "reverse-proxy" can prevent a lot of attacks before they reach your application server.

## Opening many of connections

Opening many (hundreds or thousands) connections to a server is really heavy. There are two attacks that can follow.

- Sending a lot of data really quickly
- Sending very little data, very slowly.

The first attack targets network bandwidth, and the second attack targets the CPU.

Both are (partially) prevented by default using the `PeerValidator` which is part of the `ServerSecurity` module which is included with the Vapor framework. It is enabled by default as part of the `EngineServer` but needs to be added manually for other HTTP servers.

### How PeerValidator works

As part of Vapor 3's design goals, all notification-like I/O is implemented using [Streams](../async/streams.md). This also includes the [TCP Server](../sockets/tcp-server.md). The TCP server is seen as a stream of clients/peers that are accepted and then sent to the client. It has a hook called `willAccept`. This closure's input is a `TCPClient`, and the output is a `Bool`. If the returned boolean is `true`, the peer will be accepted where `false` will deny the peer and will close the connection.

`PeerValidator` hooks into this capability by looking the peer's address up in it's cache and keeps track of the amount of connections this peer has currently opened to this server. If the counter exceeds a threshold as specified in the `PeerValidator` initializer, the connection will be rejected.

### Using PeerValidator

PeerValidator's `willAccept` function can be hooked into the TCPServer's `willAccept`.

```swift
let validator = PeerValidator(maxConnectionsPerIP: 100)

tcpServer.willAccept = validator.willAccept
```
