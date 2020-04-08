# Server

Vapor includes a high-performance, asynchronous HTTP server built on [SwiftNIO](https://github.com/apple/swift-nio). This server supports HTTP/1, HTTP/2, and protocol upgrades like [WebSockets](websockets.md). The server also supports enabling TLS (SSL).

## Configuration

Vapor's default HTTP server can be configured via `app.http.server`. 

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

The HTTP server supports several configuration options. 

### Hostname

The hostname controls which address the server will accept new connections on. The default is `127.0.0.1`.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

The server configuration's hostname can be overridden by passing the `--hostname` (`-H`) flag to the `serve` command or by passing the `hostname` parameter to `app.server.start(...)`. 

```sh
# Override configured hostname.
vapor run serve --hostname dev.local
```

### Port

The port option controls which port at the specified address the server will accept new connections on. The default is `8080`. 

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info
	`sudo` may be required for binding to ports less than `1024`. Ports greater than `65536` are not supported. 


The server configuration's port can be overridden by passing the `--port` (`-p`) flag to the `serve` command or by passing the `port` parameter to `app.server.start(...)`. 

```sh
# Override configured port.
vapor run serve --port 1337
```

### Backlog

The backlog parameter defines the maximum length for the queue of pending connections. The default is `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

## Serve Command

## Start