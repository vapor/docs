# Server

Vapor enthält einen HTTP-Server auf Basis von [SwiftNIO](https://github.com/apple/swift-nio). Der Server unterstützt die Protokolle HTTP/1, HTTP/2 und Protokollerweiterungen wie [WebSockets](websockets.md).

## Einstellungen

Die Einstellungen des Servers können über _app.http.server_ eingerichtet oder verändert werden.

### Servername

Der _Hostname_ ist die Bezeichnung des Servers. Standardmäßig lautet der Name "_127.0.0.1_".

```swift
/// [configure.swift]

// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

### Serverport

Der _Port_ ist die Portnummer des Servers. Der Standard-Port lautet "_8080_". 

```swift
/// [configure.swift]

// Configure custom port.
app.http.server.configuration.port = 1337
```

### Backlog

Der Parameter _Backlog_ definiert die maximale Anzahl an ausstehenden Verbindungen zum Server. Der Standardwert lautet "_256_".

```swift
/// [configure.swift]

// custom backlog.
app.http.server.configuration.backlog = 128
```

### Reuse Address

Der Parameter _Reuse Adress_ allows for reuse of local addresses. Standardmäßig ist der Parameter aktiviert.

```swift
/// [configure.swift]

// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Mit Aktivieren des Parameters _TCP No Delay_ wird versucht die Paketverzögerung so gering wie möglich zu halten. Standardmäßig ist der Parameter aktiviert. 

```swift
/// [configure.swift]

// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### Antwortkomprimierung

Der Parameter _responseCompression_ legt die Komprimierung einer Serverantwort fest. Der Parameter ist standardmäßig deaktiviert. Für die Komprimierung wird Gzip verwendet.

```swift
/// [configure.swift]

// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled

// Enable HTTP response compression with an initial buffer capacity
app.http.server.configuration.responseCompression = .enabled(initialByteBufferCapacity: 1024)
```

### Anfragedekomprimierung

Der Parameter _requestDecompression_ legt die Dekomprimierung einer Serveranfrage fest. Der Parameter ist standardmäßig deaktiviert. Für die Komprimierung wird Gzip verwendet.

```swift
/// [configure.swift]

// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled

// Enable HTTP request decompression with size limit
app.http.server.configuration.requestDecompression = .enabled(limit: .ratio(10))

// Enable HTTP request decompression with no size limit
app.http.server.configuration.requestDecompression = .enabled(limit: .none)
```

Available options are:

- `size`: Maximum decompressed size in bytes.
- `ratio`: Maximum decompressed size as ratio of compressed bytes.
- `none`: No size limits.

Setting decompression size limits can help prevent maliciously compressed HTTP requests from using large amounts of memory.

### Pipelining

Der Parameter _supportPipelining_ aktiviert die Unterstützung für HTTP-Pipeling. Der Parameter ist ständardmäßig deaktiviert. 

```swift
/// [configure.swift]

// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versions

Der Parameter _supportVersions_ legt fest, welche HTTP-Versionen vom Server verwendet werden soll. Wenn TLS aktiviert ist, unterstützt Vapor standardmäßig die beiden Protokolle HTTP/1 und HTTP/2. Sobald TLS deaktiviert wird, wird nur HTTP/1 unterstützt.

```swift
/// [configure.swift]

// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Der Parameter _tlsConfiguration_ legt fest, ob TLS (SSL) verwendet werden soll. Standardmäßig ist kein TLS angegeben. 

```swift
/// [configure.swift]

// Enable TLS.
try app.http.server.configuration.tlsConfiguration = .forServer(
    certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .file("/path/to/key.pem")
)
```

For this configuration to compile you need to add `import NIOSSL` at the top of your configuration file. You also might need to add NIOSSL as a dependency in your Package.swift file.

### Name

Der Parameter _serverName_ legt das Feld _Server_ in der Kopfzeile einer Serverantwort fest. Standardmäßig ist kein Name angegeben.

```swift
/// [configure.swift]

// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Funktionen

### Start

Der Server kann manuell gestartet werden.

```swift
// Start Vapor's server.
try app.server.start()
```

### Shutdown

```swift
// Request server shutdown.
app.server.shutdown()

// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## Befehle

### Serve

Um den Server zu starten, kannst du Terminal-Befehl _serve_ verwenden. Der Befehl wird automatisch ausgeführt, wenn keine anderen Befehle mitangegeben werden.

```swift
vapor run serve
```

Es können folgende Parameter mitangegeben werden:

| Name          	| Befehl         | Beschreibung                         		| Beispiel 			| 
|-----------------------|----------------|------------------------------------------------------|-------------------------------| 
| hostname           	| -H             | Überschreibt den vordefinierten Hostname		| vapor run serve -H dev.local	|
| port           	| -p             | Überschreibt den vordefinierten Port			| vapor run serve -p 1337	|
| bind           	| -b             | Überschreibt den vordefinierten Hostnamen und Port	| vapor run serve -b 0.0.0.0:80	|
| help           	| --help         | Hilfe						| vapor run serve --help	|

## Hinweis

Der Server von Vapor kann grundsätzlich ersetzt werden. Dazu muss der neue Server von Typ `Server` sein.

```swift
app.servers.use(.http)
```

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