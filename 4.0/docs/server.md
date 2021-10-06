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
	`sudo` may be required for binding to ports less than `1024`. Ports greater than `65535` are not supported. 


The server configuration's port can be overridden by passing the `--port` (`-p`) flag to the `serve` command or by passing the `port` parameter to `app.server.start(...)`. 

```sh
# Override configured port.
vapor run serve --port 1337
```

### Backlog

The `backlog` parameter defines the maximum length for the queue of pending connections. The default is `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### Reuse Address

The `reuseAddress` parameter allows for reuse of local addresses. Defaults to `true`.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Enabling the `tcpNoDelay` parameter will attempt to minimize TCP packet delay. Defaults to `true`. 

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### Response Compression

The `responseCompression` parameter controls HTTP response compression using gzip. The default is `.disabled`.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

To specify an initial buffer capacity, use the `initialByteBufferCapacity` parameter.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Request Decompression

The `requestDecompression` parameter controls HTTP request decompression using gzip. The default is `.disabled`.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

To specify a decompression limit, use the `limit` parameter. The default is `.ratio(10)`.

```swift
// No decompression size limit
.enabled(limit: .none)
```

Available options are:

- `size`: Maximum decompressed size in bytes.
- `ratio`: Maximum decompressed size as ratio of compressed bytes.
- `none`: No size limits.

Setting decompression size limits can help prevent maliciously compressed HTTP requests from using large amounts of memory.

### Pipelining

The `supportPipelining` parameter enables support for HTTP request and response pipelining. The default is `false`. 

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versions

The `supportVersions` parameter controls which HTTP versions the server will use. By default, Vapor will support both HTTP/1 and HTTP/2 when TLS is enabled. Only HTTP/1 is supported when TLS is disabled. 

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

The `tlsConfiguration` parameter controls whether TLS (SSL) is enabled on the server. The default is `nil`. 

```swift
// Enable TLS.
try app.http.server.configuration.tlsConfiguration = .forServer(
    certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .file("/path/to/key.pem")
)
```

For this configuration to compile you need to add `import NIOSSL` at the top of your configuration file. You also might need to add NIOSSL as a dependency in your Package.swift file.

### Name

The `serverName` parameter controls the `Server` header on outgoing HTTP responses. The default is `nil`.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Serve Command

To start up Vapor's server, use the `serve` command. This command will run by default if no other commands are specified. 

```swift
vapor run serve
```

The `serve` command accepts the following parameters:

- `hostname` (`-H`): Overrides configured hostname.
- `port` (`-p`): Overrides configured port.
- `bind` (`-b`): Overrides configured hostname and port joined by `:`. 

An example using the `--bind` (`-b`) flag:

```swift
vapor run serve -b 0.0.0.0:80
```

Use `vapor run serve --help` for more information.

The `serve` command will listen for `SIGTERM` and `SIGINT` to gracefully shutdown the server. Use `ctrl+c` (`^c`) to send a `SIGINT` signal. When the log level is set to `debug` or lower, information about the status of graceful shutdown will be logged.

## Manual Start

Vapor's server can be started manually using `app.server`.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## Servers

The server Vapor uses is configurable. By default, the built in HTTP server is used.

```swift
app.servers.use(.http)
```

### Custom Server

Vapor's default HTTP server can be replaced by any type conforming to `Server`. 

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

Custom servers can extend `Application.Servers.Provider` for leading-dot syntax.

```swift
extension Application.Servers.Provider {
    static var myServer: Self {
        .init {
            $0.servers.use { app in
            	MyServer()
            }
        }
    }
}

app.servers.use(.myServer)
```
