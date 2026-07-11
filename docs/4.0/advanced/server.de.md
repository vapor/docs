# Server

Vapor enthält einen hochperformanten, asynchronen HTTP-Server auf Basis von [SwiftNIO](https://github.com/apple/swift-nio). Der Server unterstützt HTTP/1, HTTP/2 und Protokollerweiterungen wie [WebSockets](websockets.md). Außerdem unterstützt der Server die Aktivierung von TLS (SSL).

## Konfiguration

Vapors Standard-HTTP-Server kann über `app.http.server` konfiguriert werden. 

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

Der HTTP-Server unterstützt mehrere Konfigurationsoptionen. 

### Hostname

Der Hostname legt fest, auf welcher Adresse der Server neue Verbindungen akzeptiert. Der Standardwert ist `127.0.0.1`.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

Der in der Konfiguration festgelegte Hostname kann überschrieben werden, indem das Flag `--hostname` (`-H`) an den Befehl `serve` übergeben wird, oder indem der Parameter `hostname` an `app.server.start(...)` übergeben wird. 

```sh
# Override configured hostname.
swift run App serve --hostname dev.local
```

### Port

Die Portoption legt fest, auf welchem Port der angegebenen Adresse der Server neue Verbindungen akzeptiert. Der Standardwert ist `8080`. 

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info
    Für die Bindung an Ports kleiner als `1024` kann `sudo` erforderlich sein. Ports größer als `65535` werden nicht unterstützt. 


Der in der Konfiguration festgelegte Port kann überschrieben werden, indem das Flag `--port` (`-p`) an den Befehl `serve` übergeben wird, oder indem der Parameter `port` an `app.server.start(...)` übergeben wird. 

```sh
# Override configured port.
swift run App serve --port 1337
```

### Backlog

Der Parameter `backlog` definiert die maximale Länge der Warteschlange für ausstehende Verbindungen. Der Standardwert ist `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### Reuse Address

Der Parameter `reuseAddress` erlaubt die Wiederverwendung lokaler Adressen. Der Standardwert ist `true`.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Wird der Parameter `tcpNoDelay` aktiviert, wird versucht, die TCP-Paketverzögerung so gering wie möglich zu halten. Der Standardwert ist `true`. 

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### Response Compression

Der Parameter `responseCompression` steuert die Komprimierung von HTTP-Antworten mittels Gzip. Der Standardwert ist `.disabled`.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

Um eine anfängliche Puffergröße festzulegen, verwende den Parameter `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Request Decompression

Der Parameter `requestDecompression` steuert die Dekomprimierung von HTTP-Anfragen mittels Gzip. Der Standardwert ist `.disabled`.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

Um ein Dekomprimierungslimit festzulegen, verwende den Parameter `limit`. Der Standardwert ist `.ratio(10)`.

```swift
// No decompression size limit
.enabled(limit: .none)
```

Verfügbare Optionen sind:

- `size`: Maximale dekomprimierte Größe in Bytes.
- `ratio`: Maximale dekomprimierte Größe als Verhältnis zu den komprimierten Bytes.
- `none`: Keine Größenbeschränkung.

Das Festlegen von Dekomprimierungslimits kann verhindern, dass böswillig komprimierte HTTP-Anfragen große Mengen an Speicher verbrauchen.

### Pipelining

Der Parameter `supportPipelining` aktiviert die Unterstützung für HTTP-Request- und Response-Pipelining. Der Standardwert ist `false`. 

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versions

Der Parameter `supportVersions` legt fest, welche HTTP-Versionen der Server verwendet. Standardmäßig unterstützt Vapor sowohl HTTP/1 als auch HTTP/2, wenn TLS aktiviert ist. Ist TLS deaktiviert, wird nur HTTP/1 unterstützt. 

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Der Parameter `tlsConfiguration` legt fest, ob TLS (SSL) auf dem Server aktiviert ist. Der Standardwert ist `nil`. 

```swift
// Enable TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

Damit diese Konfiguration kompiliert werden kann, musst du `import NIOSSL` am Anfang deiner Konfigurationsdatei hinzufügen. Möglicherweise musst du NIOSSL außerdem als Abhängigkeit in deiner Package.swift-Datei hinzufügen.

### Name

Der Parameter `serverName` legt den `Server`-Header der ausgehenden HTTP-Antworten fest. Der Standardwert ist `nil`.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Serve-Befehl

Um Vapors Server zu starten, verwende den Befehl `serve`. Dieser Befehl wird standardmäßig ausgeführt, wenn kein anderer Befehl angegeben wird. 

```swift
swift run App serve
```

Der Befehl `serve` akzeptiert die folgenden Parameter:

- `hostname` (`-H`): Überschreibt den konfigurierten Hostnamen.
- `port` (`-p`): Überschreibt den konfigurierten Port.
- `bind` (`-b`): Überschreibt den konfigurierten Hostnamen und Port, verbunden durch `:`. 

Ein Beispiel mit dem Flag `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

Verwende `swift run App serve --help` für weitere Informationen.

Der Befehl `serve` wartet auf `SIGTERM` und `SIGINT`, um den Server geordnet herunterzufahren. Verwende `ctrl+c` (`^c`), um ein `SIGINT`-Signal zu senden. Ist der Log-Level auf `debug` oder niedriger eingestellt, werden Informationen zum Status des geordneten Herunterfahrens protokolliert.

## Manueller Start

Vapors Server kann manuell mit `app.server` gestartet werden.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## Server

Der von Vapor verwendete Server ist konfigurierbar. Standardmäßig wird der eingebaute HTTP-Server verwendet.

```swift
app.servers.use(.http)
```

### Eigener Server

Vapors Standard-HTTP-Server kann durch jeden Typ ersetzt werden, der `Server` entspricht.

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

Eigene Server können `Application.Servers.Provider` erweitern, um die Punktnotation (leading-dot syntax) zu ermöglichen.

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
