# Serwer

Vapor zawiera wydajny, asynchroniczny serwer HTTP zbudowany na [SwiftNIO](https://github.com/apple/swift-nio). Ten serwer obsługuje HTTP/1, HTTP/2 oraz aktualizacje protokołu, takie jak [WebSockets](websockets.md). Serwer obsługuje również włączanie TLS (SSL).

## Konfiguracja

Domyślny serwer HTTP Vapora można skonfigurować za pomocą `app.http.server`.

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

Serwer HTTP obsługuje kilka opcji konfiguracyjnych.

### Hostname

Hostname kontroluje, na jakim adresie serwer będzie akceptował nowe połączenia. Domyślną wartością jest `127.0.0.1`.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

Hostname skonfigurowany w serwerze można nadpisać, przekazując flagę `--hostname` (`-H`) do komendy `serve` lub przekazując parametr `hostname` do `app.server.start(...)`.

```sh
# Override configured hostname.
swift run App serve --hostname dev.local
```

### Port

Opcja portu kontroluje, na jakim porcie pod wskazanym adresem serwer będzie akceptował nowe połączenia. Domyślną wartością jest `8080`.

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info
    Do bindowania portów mniejszych niż `1024` może być wymagane `sudo`. Porty większe niż `65535` nie są obsługiwane.


Port skonfigurowany w serwerze można nadpisać, przekazując flagę `--port` (`-p`) do komendy `serve` lub przekazując parametr `port` do `app.server.start(...)`.

```sh
# Override configured port.
swift run App serve --port 1337
```

### Backlog

Parametr `backlog` definiuje maksymalną długość kolejki oczekujących połączeń. Domyślną wartością jest `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### Ponowne użycie adresu

Parametr `reuseAddress` umożliwia ponowne użycie lokalnych adresów. Domyślnie ustawiony na `true`.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Włączenie parametru `tcpNoDelay` spowoduje próbę zminimalizowania opóźnień pakietów TCP. Domyślnie ustawiony na `true`.

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### Kompresja odpowiedzi

Parametr `responseCompression` kontroluje kompresję odpowiedzi HTTP przy użyciu gzip. Domyślną wartością jest `.disabled`.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

Aby określić początkową pojemność bufora, użyj parametru `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Dekompresja żądań

Parametr `requestDecompression` kontroluje dekompresję żądań HTTP przy użyciu gzip. Domyślną wartością jest `.disabled`.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

Aby określić limit dekompresji, użyj parametru `limit`. Domyślną wartością jest `.ratio(10)`.

```swift
// No decompression size limit
.enabled(limit: .none)
```

Dostępne opcje to:

- `size`: Maksymalny rozmiar po dekompresji w bajtach.
- `ratio`: Maksymalny rozmiar po dekompresji jako stosunek do rozmiaru skompresowanego.
- `none`: Brak limitów rozmiaru.

Ustawienie limitów rozmiaru dekompresji może pomóc zapobiec sytuacji, w której złośliwie skompresowane żądania HTTP zużywają duże ilości pamięci.

### Pipelining

Parametr `supportPipelining` włącza obsługę pipeliningu żądań i odpowiedzi HTTP. Domyślną wartością jest `false`.

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Wersje

Parametr `supportVersions` kontroluje, których wersji HTTP będzie używał serwer. Domyślnie Vapor obsługuje zarówno HTTP/1, jak i HTTP/2, gdy TLS jest włączone. Gdy TLS jest wyłączone, obsługiwane jest tylko HTTP/1.

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Parametr `tlsConfiguration` kontroluje, czy TLS (SSL) jest włączone w serwerze. Domyślną wartością jest `nil`.

```swift
// Enable TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

Aby ta konfiguracja mogła się skompilować, musisz dodać `import NIOSSL` na początku pliku konfiguracyjnego. Może być również konieczne dodanie NIOSSL jako zależności w pliku Package.swift.

### Nazwa

Parametr `serverName` kontroluje nagłówek `Server` w wychodzących odpowiedziach HTTP. Domyślną wartością jest `nil`.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Komenda serve

Aby uruchomić serwer Vapora, użyj komendy `serve`. Ta komenda uruchamia się domyślnie, jeśli nie podano żadnej innej komendy.

```swift
swift run App serve
```

Komenda `serve` przyjmuje następujące parametry:

- `hostname` (`-H`): Nadpisuje skonfigurowany hostname.
- `port` (`-p`): Nadpisuje skonfigurowany port.
- `bind` (`-b`): Nadpisuje skonfigurowany hostname i port połączone znakiem `:`.

Przykład użycia flagi `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

Użyj `swift run App serve --help`, aby uzyskać więcej informacji.

Komenda `serve` nasłuchuje sygnałów `SIGTERM` i `SIGINT`, aby łagodnie zamknąć serwer. Użyj `ctrl+c` (`^c`), aby wysłać sygnał `SIGINT`. Gdy poziom logowania jest ustawiony na `debug` lub niższy, informacje o stanie łagodnego zamykania będą logowane.

## Ręczne uruchamianie

Serwer Vapora można uruchomić ręcznie za pomocą `app.server`.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## Serwery

Serwer, którego używa Vapor, jest konfigurowalny. Domyślnie używany jest wbudowany serwer HTTP.

```swift
app.servers.use(.http)
```

### Własny serwer

Domyślny serwer HTTP Vapora może zostać zastąpiony przez dowolny typ zgodny z `Server`.

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

Własne serwery mogą rozszerzać `Application.Servers.Provider`, aby korzystać ze składni z wiodącą kropką.

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
