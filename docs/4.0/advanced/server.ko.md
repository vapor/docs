# 서버

Vapor에는 [SwiftNIO](https://github.com/apple/swift-nio) 기반으로 만들어진 고성능 비동기 HTTP 서버가 내장되어 있습니다. 이 서버는 HTTP/1, HTTP/2, 그리고 [WebSockets](websockets.md)와 같은 프로토콜 업그레이드를 지원합니다. 또한 TLS(SSL) 활성화도 지원합니다.

## 설정

Vapor의 기본 HTTP 서버는 `app.http.server`를 통해 설정할 수 있습니다.

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

HTTP 서버는 여러 가지 설정 옵션을 지원합니다.

### 호스트네임

호스트네임은 서버가 새로운 연결을 수락할 주소를 결정합니다. 기본값은 `127.0.0.1`입니다.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

서버 설정의 호스트네임은 `serve` 커맨드에 `--hostname` (`-H`) 플래그를 전달하거나 `app.server.start(...)`에 `hostname` 파라미터를 전달하여 재정의할 수 있습니다.

```sh
# Override configured hostname.
swift run App serve --hostname dev.local
```

### 포트

포트 옵션은 지정된 주소에서 서버가 새로운 연결을 수락할 포트를 결정합니다. 기본값은 `8080`입니다.

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info
    `1024`보다 작은 포트에 바인딩하려면 `sudo`가 필요할 수 있습니다. `65535`보다 큰 포트는 지원되지 않습니다.


서버 설정의 포트는 `serve` 커맨드에 `--port` (`-p`) 플래그를 전달하거나 `app.server.start(...)`에 `port` 파라미터를 전달하여 재정의할 수 있습니다.

```sh
# Override configured port.
swift run App serve --port 1337
```

### Backlog

`backlog` 파라미터는 대기 중인 연결 큐의 최대 길이를 정의합니다. 기본값은 `256`입니다.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### 주소 재사용

`reuseAddress` 파라미터는 로컬 주소의 재사용을 허용합니다. 기본값은 `true`입니다.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

`tcpNoDelay` 파라미터를 활성화하면 TCP 패킷 지연을 최소화하려고 시도합니다. 기본값은 `true`입니다.

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### 응답 압축

`responseCompression` 파라미터는 gzip을 사용한 HTTP 응답 압축을 제어합니다. 기본값은 `.disabled`입니다.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

초기 버퍼 용량을 지정하려면 `initialByteBufferCapacity` 파라미터를 사용하세요.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### 요청 압축 해제

`requestDecompression` 파라미터는 gzip을 사용한 HTTP 요청 압축 해제를 제어합니다. 기본값은 `.disabled`입니다.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

압축 해제 제한을 지정하려면 `limit` 파라미터를 사용하세요. 기본값은 `.ratio(10)`입니다.

```swift
// No decompression size limit
.enabled(limit: .none)
```

사용 가능한 옵션은 다음과 같습니다.

- `size`: 압축 해제된 최대 크기(바이트).
- `ratio`: 압축된 바이트 대비 압축 해제된 최대 크기 비율.
- `none`: 크기 제한 없음.

압축 해제 크기 제한을 설정하면 악의적으로 압축된 HTTP 요청이 많은 양의 메모리를 사용하는 것을 방지하는 데 도움이 됩니다.

### 파이프라이닝

`supportPipelining` 파라미터는 HTTP 요청 및 응답 파이프라이닝 지원을 활성화합니다. 기본값은 `false`입니다.

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### 버전

`supportVersions` 파라미터는 서버가 사용할 HTTP 버전을 제어합니다. 기본적으로 Vapor는 TLS가 활성화된 경우 HTTP/1과 HTTP/2를 모두 지원합니다. TLS가 비활성화된 경우에는 HTTP/1만 지원됩니다.

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

`tlsConfiguration` 파라미터는 서버에서 TLS(SSL)를 활성화할지 여부를 제어합니다. 기본값은 `nil`입니다.

```swift
// Enable TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

이 설정이 컴파일되려면 설정 파일 맨 위에 `import NIOSSL`을 추가해야 합니다. 또한 Package.swift 파일에 NIOSSL을 의존성으로 추가해야 할 수도 있습니다.

### 이름

`serverName` 파라미터는 나가는 HTTP 응답의 `Server` 헤더를 제어합니다. 기본값은 `nil`입니다.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Serve 커맨드

Vapor의 서버를 시작하려면 `serve` 커맨드를 사용하세요. 다른 커맨드가 지정되지 않으면 이 커맨드가 기본적으로 실행됩니다.

```swift
swift run App serve
```

`serve` 커맨드는 다음과 같은 파라미터를 받습니다.

- `hostname` (`-H`): 설정된 호스트네임을 재정의합니다.
- `port` (`-p`): 설정된 포트를 재정의합니다.
- `bind` (`-b`): 설정된 호스트네임과 포트를 `:`로 결합하여 재정의합니다.

`--bind` (`-b`) 플래그를 사용하는 예시입니다.

```swift
swift run App serve -b 0.0.0.0:80
```

더 자세한 정보를 확인하려면 `swift run App serve --help`를 사용하세요.

`serve` 커맨드는 서버를 정상적으로 종료하기 위해 `SIGTERM`과 `SIGINT`를 수신 대기합니다. `SIGINT` 신호를 보내려면 `ctrl+c` (`^c`)를 사용하세요. 로그 레벨이 `debug` 이하로 설정된 경우, 정상 종료(graceful shutdown) 상태에 대한 정보가 로그로 기록됩니다.

## 수동 시작

Vapor의 서버는 `app.server`를 사용하여 수동으로 시작할 수 있습니다.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## 서버들

Vapor가 사용하는 서버는 설정 가능합니다. 기본적으로 내장 HTTP 서버가 사용됩니다.

```swift
app.servers.use(.http)
```

### 커스텀 서버

Vapor의 기본 HTTP 서버는 `Server`를 준수하는 어떤 타입으로도 교체할 수 있습니다.

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

커스텀 서버는 leading-dot 문법을 사용할 수 있도록 `Application.Servers.Provider`를 확장할 수 있습니다.

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
