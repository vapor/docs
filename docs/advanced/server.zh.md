# 服务器

Vapor 包含一个基于 [SwiftNIO](https://github.com/apple/swift-nio) 构建的高性能异步 HTTP 服务器。该服务器支持 HTTP/1、HTTP/2 和协议升级，如 [WebSockets](websockets.zh.md)。服务器还支持启用 TLS (SSL)。

## 配置

Vapor 的默认 HTTP 服务器可以通过 `app.http.server` 来配置。

```swift
// 仅支持 HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

HTTP 服务器支持多种配置选项。

### 主机名

hostname 控制服务器将在哪个地址上接受新连接。默认地址为`127.0.0.1`。

```swift
// 配置自定义主机名
app.http.server.configuration.hostname = "dev.local"
```

终端运行 `serve` 命令添加 `--hostname` (`-H`) 标志来修改服务器主机名或将 `hostname` 参数传递给 `app.server.start(...)` 来修改配置。

```sh
# 重写主机名配置
swift run App serve --hostname dev.local
```

### 端口

port 选项控制服务器将在指定地址上的哪个端口接受新连接。默认值为`8080`。

```swift
// 配置自定义端口。
app.http.server.configuration.port = 1337
```

!!! info "信息"
    绑定小于`1024`的端口可能需要 `sudo` 提权。不支持大于`65535`的端口。

终端运行 `serve` 命令添加 `--port` (`-p`) 标志来修改服务器端口或将 `port` 参数传递给 `app.server.start(...)` 来修改配置。

```sh
# 重写端口配置
swift run App serve --port 1337
```

### Backlog

`backlog` 参数定义待处理连接队列的最大长度。默认值为`256`。

```swift
// 自定义积压队列长度
app.http.server.configuration.backlog = 128
```

### 地址复用

`reuseAddress` 参数允许重用本地地址。默认为 `true`。

```swift
// 禁用地址复用
app.http.server.configuration.reuseAddress = false
```

### TCP 无延迟

启用 `tcpNoDelay` 参数将尝试 TCP 数据包延迟最小化。默认为 `true`。

```swift
// 降低数据包延迟。
app.http.server.configuration.tcpNoDelay = true
```

### 响应压缩

`responseCompression` 参数使用 gzip 控制 HTTP 响应压缩。默认值为 `.disabled`。

```swift
// 启用 HTTP 响应压缩。
app.http.server.configuration.responseCompression = .enabled
```

要指定初始缓冲区容量，请使用 `initialByteBufferCapacity` 参数。

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### 请求解压

`requestDecompression` 参数使用 gzip 控制 HTTP 请求解压。默认值为 `.disabled`。

```swift
// 启用 HTTP 请求解压
app.http.server.configuration.requestDecompression = .enabled
```

要指定解压限制，请使用 `limit` 参数。默认值为 `.ratio(10)`。

```swift
// 无解压大小限制
.enabled(limit: .none)
```

可用选项有：

- `size`：以字节为单位的最大解压缩大小。
- `ratio`：最大解压缩大小为压缩字节的比率。
- `none`：没有大小限制。

设置解压缩大小限制有助于防止恶意压缩的 HTTP 请求使用大量内存。

### 管道

`supportPipelining` 参数启用对 HTTP 请求和响应管道的支持。默认值为 `false`。

```swift
// 启用管道支持。
app.http.server.configuration.supportPipelining = true
```

### 版本

`supportVersions` 参数控制服务器使用的 HTTP 版本。默认情况下，启用 TLS 时，Vapor 将同时支持 HTTP/1 和 HTTP/2。禁用 TLS 时仅支持 HTTP/1。

```swift
// 禁用 HTTP/1 。
app.http.server.configuration.supportVersions = [.two]
```

### TLS

`tlsConfiguration` 参数控制是否在服务器上启用 TLS (SSL)。默认值为 `nil`。

```swift
// 启用 TLS.
try app.http.server.configuration.tlsConfiguration = .forServer(
    certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .file("/path/to/key.pem")
)
```

要编译此配置，你需要在配置文件的顶部添加 `import NIOSSL` 导入包。你可能还需要在 Package.swift 文件中添加 NIOSSL 依赖项。

### 名称

`serverName` 参数控制 `Server` 传出 HTTP 响应的报头。默认值为 `nil`。

```swift
// 添加 'Server: vapor' 到响应头。
app.http.server.configuration.serverName = "vapor"
```

## 服务命令

要启动 Vapor 的服务器，请在终端使用 `serve` 命令。如果没有指定其他命令，该命令将默认运行。

```swift
swift run App serve
```

`serve` 命令接受以下参数：

- `hostname` (`-H`)：重写主机名配置。
- `port` (`-p`)：重写端口号配置。
- `bind` (`-b`)：重写由`:`连接的主机名和端口号配置。

下面是使用 `--bind` (`-b`) 标志的一个示例：

```swift
swift run App serve -b 0.0.0.0:80
```

使用 `swift run App serve --help` 以获取更多信息。

`serve` 命令将侦听 `SIGTERM` 和 `SIGINT` 信号，以正常关闭服务器。使用 `ctrl+c` (`^c`) 发送 `SIGINT` 信号。当日志级别设置为 `debug` 或更低时，将记录有关安全关机状态的信息。

## 手动启动

Vapor 的服务器可以使用 `app.server` 手动启动。

```swift
// 启动 Vapor 服务器。
try app.server.start()
// 请求服务器关闭。
app.server.shutdown()
// 等待服务器关闭。
try app.server.onShutdown.wait()
```

## 服务器

Vapor 使用的服务器是可配置的。默认情况下，使用内置的 HTTP 服务器。

```swift
app.servers.use(.http)
```

### 自定义服务器

Vapor 的默认 HTTP 服务器可以替换为任何遵循 `Server` 的服务器。

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

自定义服务器可以扩展 `Application.Servers.Provider` 以使用点语法。

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
