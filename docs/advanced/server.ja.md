# Server

Vaporには[SwiftNIO](https://github.com/apple/swift-nio)上に構築された高性能で非同期のHTTPサーバーが含まれています。このサーバーはHTTP/1、HTTP/2、および[WebSockets](websockets.md)などのプロトコルアップグレードをサポートしています。サーバーはTLS（SSL）の有効化もサポートしています。

## 設定 {#configuration}

VaporのデフォルトHTTPサーバーは`app.http.server`を介して設定できます。

```swift
// HTTP/2のみをサポート
app.http.server.configuration.supportVersions = [.two]
```

HTTPサーバーはいくつかの設定オプションをサポートしています。

### ホスト名 {#hostname}

ホスト名は、サーバーが新しい接続を受け入れるアドレスを制御します。デフォルトは`127.0.0.1`です。

```swift
// カスタムホスト名を設定
app.http.server.configuration.hostname = "dev.local"
```

サーバー設定のホスト名は、`serve`コマンドに`--hostname`（`-H`）フラグを渡すか、`app.server.start(...)`に`hostname`パラメーターを渡すことでオーバーライドできます。

```sh
# 設定されたホスト名をオーバーライド
swift run App serve --hostname dev.local
```

### ポート {#port}

ポートオプションは、指定されたアドレスでサーバーが新しい接続を受け入れるポートを制御します。デフォルトは`8080`です。

```swift
// カスタムポートを設定
app.http.server.configuration.port = 1337
```

!!! info
	`1024`未満のポートにバインドするには`sudo`が必要な場合があります。`65535`を超えるポートはサポートされていません。

サーバー設定のポートは、`serve`コマンドに`--port`（`-p`）フラグを渡すか、`app.server.start(...)`に`port`パラメーターを渡すことでオーバーライドできます。

```sh
# 設定されたポートをオーバーライド
swift run App serve --port 1337
```

### バックログ {#backlog}

`backlog`パラメーターは、保留中の接続のキューの最大長を定義します。デフォルトは`256`です。

```swift
// カスタムバックログを設定
app.http.server.configuration.backlog = 128
```

### アドレスの再利用 {#reuse-address}

`reuseAddress`パラメーターは、ローカルアドレスの再利用を許可します。デフォルトは`true`です。

```swift
// アドレスの再利用を無効化
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay {#tcp-no-delay}

`tcpNoDelay`パラメーターを有効にすると、TCPパケットの遅延を最小限に抑えようとします。デフォルトは`true`です。

```swift
// パケットの遅延を最小化
app.http.server.configuration.tcpNoDelay = true
```

### レスポンス圧縮 {#response-compression}

`responseCompression`パラメーターは、gzipを使用したHTTPレスポンスの圧縮を制御します。デフォルトは`.disabled`です。

```swift
// HTTPレスポンス圧縮を有効化
app.http.server.configuration.responseCompression = .enabled
```

初期バッファ容量を指定するには、`initialByteBufferCapacity`パラメーターを使用します。

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### リクエスト解凍 {#request-decompression}

`requestDecompression`パラメーターは、gzipを使用したHTTPリクエストの解凍を制御します。デフォルトは`.disabled`です。

```swift
// HTTPリクエスト解凍を有効化
app.http.server.configuration.requestDecompression = .enabled
```

解凍制限を指定するには、`limit`パラメーターを使用します。デフォルトは`.ratio(10)`です。

```swift
// 解凍サイズ制限なし
.enabled(limit: .none)
```

利用可能なオプション：

- `size`：バイト単位での最大解凍サイズ
- `ratio`：圧縮バイトに対する比率としての最大解凍サイズ
- `none`：サイズ制限なし

解凍サイズ制限を設定することで、悪意のある圧縮されたHTTPリクエストが大量のメモリを使用することを防ぐことができます。

### パイプライニング {#pipelining}

`supportPipelining`パラメーターは、HTTPリクエストとレスポンスのパイプライニングのサポートを有効にします。デフォルトは`false`です。

```swift
// HTTPパイプライニングをサポート
app.http.server.configuration.supportPipelining = true
```

### バージョン {#versions}

`supportVersions`パラメーターは、サーバーが使用するHTTPバージョンを制御します。デフォルトでは、TLSが有効な場合、VaporはHTTP/1とHTTP/2の両方をサポートします。TLSが無効な場合はHTTP/1のみがサポートされます。

```swift
// HTTP/1サポートを無効化
app.http.server.configuration.supportVersions = [.two]
```

### TLS {#tls}

`tlsConfiguration`パラメーターは、サーバーでTLS（SSL）が有効かどうかを制御します。デフォルトは`nil`です。

```swift
// TLSを有効化
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

この設定をコンパイルするには、設定ファイルの先頭に`import NIOSSL`を追加する必要があります。また、Package.swiftファイルにNIOSSLを依存関係として追加する必要がある場合もあります。

### 名前 {#name}

`serverName`パラメーターは、送信されるHTTPレスポンスの`Server`ヘッダーを制御します。デフォルトは`nil`です。

```swift
// レスポンスに 'Server: vapor' ヘッダーを追加
app.http.server.configuration.serverName = "vapor"
```

## Serveコマンド {#serve-command}

Vaporのサーバーを起動するには、`serve`コマンドを使用します。他のコマンドが指定されていない場合、このコマンドはデフォルトで実行されます。

```swift
swift run App serve
```

`serve`コマンドは以下のパラメーターを受け入れます：

- `hostname` (`-H`)：設定されたホスト名をオーバーライド
- `port` (`-p`)：設定されたポートをオーバーライド
- `bind` (`-b`)：`:`で結合された設定済みホスト名とポートをオーバーライド

`--bind`（`-b`）フラグを使用した例：

```swift
swift run App serve -b 0.0.0.0:80
```

詳細については`swift run App serve --help`を使用してください。

`serve`コマンドは、サーバーを正常にシャットダウンするために`SIGTERM`と`SIGINT`をリッスンします。`SIGINT`シグナルを送信するには`ctrl+c`（`^c`）を使用します。ログレベルが`debug`以下に設定されている場合、正常なシャットダウンのステータスに関する情報がログに記録されます。

## 手動起動 {#manual-start}

Vaporのサーバーは`app.server`を使用して手動で起動できます。

```swift
// Vaporのサーバーを起動
try app.server.start()
// サーバーのシャットダウンをリクエスト
app.server.shutdown()
// サーバーのシャットダウンを待機
try app.server.onShutdown.wait()
```

## サーバー {#servers}

Vaporが使用するサーバーは設定可能です。デフォルトでは、組み込みのHTTPサーバーが使用されます。

```swift
app.servers.use(.http)
```

### カスタムサーバー {#custom-server}

Vaporのデフォルトのサーバーは、`Server`に準拠する任意の型で置き換えることができます。

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

カスタムサーバーは、先頭ドット構文のために`Application.Servers.Provider`を拡張できます。

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