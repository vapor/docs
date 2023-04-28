# Server

Vapor bevat een high-performance, asynchrone HTTP server gebouwd op [SwiftNIO](https://github.com/apple/swift-nio). Deze server ondersteunt HTTP/1, HTTP/2, en protocol upgrades zoals [WebSockets](websockets.md). De server ondersteunt ook het inschakelen van TLS (SSL).

## Configuratie

De standaard HTTP server van Vapor kan worden geconfigureerd via `app.http.server`. 

```swift
// Ondersteunt alleen HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

De HTTP-server ondersteunt verschillende configuratie-opties. 

### Hostname

De hostnaam bepaalt op welk adres de server nieuwe verbindingen zal accepteren. De standaard instelling is `127.0.0.1`.

```swift
// Configureer aangepaste hostnaam.
app.http.server.configuration.hostname = "dev.local"
```

De hostnaam van de serverconfiguratie kan worden veranderd door de `--hostname` (`-H`) vlag mee te geven aan het `serve` commando of door de `hostname` parameter mee te geven aan `app.server.start(...)`. 

```sh
# Overschrijf geconfigureerde hostnaam.
swift run App serve --hostname dev.local
```

### Poort

De poort optie bepaalt op welke poort van het opgegeven adres de server nieuwe verbindingen accepteert. De standaardinstelling is `8080`. 

```swift
// Configureer aangepaste poort.
app.http.server.configuration.port = 1337
```

!!! info
	`sudo` kan nodig zijn voor het binden aan poorten kleiner dan `1024`. Poorten groter dan `65535` worden niet ondersteund. 


De poort van de server configuratie kan overschreven worden door de `--port` (`-p`) vlag mee te geven aan het `serve` commando of door de `port` parameter mee te geven aan `app.server.start(...)`. 

```sh
# Overschrijf geconfigureerde poort.
swift run App serve --port 1337
```

### Backlog

De `backlog` parameter bepaalt de maximale lengte voor de wachtrij van in behandeling zijnde verbindingen. De standaardwaarde is `256`.

```swift
// Configureer aangepaste backlog.
app.http.server.configuration.backlog = 128
```

### Reuse Address

De `reuseAddress` parameter staat het hergebruik van lokale adressen toe. Standaard ingesteld op `true`.

```swift
// Adreshergebruik uitschakelen.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Het inschakelen van de `tcpNoDelay` parameter zal proberen om TCP pakket vertraging te minimaliseren. Staat standaard op `true`. 

```swift
// Minimaliseer de pakketvertraging.
app.http.server.configuration.tcpNoDelay = true
```

### Response Compression

De `responseCompression` parameter regelt HTTP response compressie met behulp van gzip. De standaardwaarde is `.disabled`.

```swift
// HTTP-responscompressie inschakelen.
app.http.server.configuration.responseCompression = .enabled
```

Om een initiële buffercapaciteit op te geven, gebruik je de `initialByteBufferCapacity` parameter.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Request Decompression

De `requestDecompression` parameter regelt HTTP verzoek decompressie met behulp van gzip. De standaard instelling is `.disabled`.

```swift
// Inschakelen van HTTP verzoek decompressie.
app.http.server.configuration.requestDecompression = .enabled
```

Om een decompressie limiet op te geven, gebruik de `limit` parameter. De standaardwaarde is `.ratio(10)`.

```swift
// Geen decompressie grootte limiet
.enabled(limit: .none)
```

Beschikbare opties zijn:

- `size`: Maximale gedecomprimeerde grootte in bytes.
- `ratio`: Maximale gedecomprimeerde grootte als verhouding van gecomprimeerde bytes.
- `none`: Geen grootte beperkingen.

Het instellen van decompressie grootte limieten kan helpen voorkomen dat kwaadwillig gecomprimeerde HTTP verzoeken grote hoeveelheden geheugen gebruiken.

### Pipelining

De `supportPipelining` parameter schakelt ondersteuning voor HTTP request en response pipelining in. De standaard instelling is `false`. 

```swift
// Ondersteuning HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versies

De `supportVersions` parameter bepaalt welke HTTP versies de server zal gebruiken. Standaard zal Vapor zowel HTTP/1 als HTTP/2 ondersteunen wanneer TLS is ingeschakeld. Alleen HTTP/1 wordt ondersteund wanneer TLS is uitgeschakeld. 

```swift
// Schakel HTTP/1 ondersteuning uit.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

De `tlsConfiguration` parameter regelt of TLS (SSL) is ingeschakeld op de server. De standaardinstelling is `nihil`. 

```swift
// Schakel TLS in.
try app.http.server.configuration.tlsConfiguration = .forServer(
    certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .file("/path/to/key.pem")
)
```

Om deze configuratie te compileren moet u `import NIOSSL` toevoegen bovenaan uw configuratie bestand. Het kan ook nodig zijn om NIOSSL toe te voegen als een afhankelijkheid in uw Package.swift bestand.

### Name

De `serverName` parameter regelt de `Server` header op uitgaande HTTP antwoorden. De standaardwaarde is `nil`.

```swift
// Voeg "Server: vapor" header toe aan antwoorden.
app.http.server.configuration.serverName = "vapor"
```

## Serve Command

Om de server van Vapor op te starten, gebruik het `serve` commando. Dit commando wordt standaard uitgevoerd als er geen andere commando's zijn opgegeven. 

```swift
swift run App serve
```

Het `serve` commando accepteert de volgende parameters:

- `hostname` (`-H`): Vervangt de geconfigureerde hostnaam.
- `port` (`-p`): Vervangt de geconfigureerde poort.
- `bind` (`-b`): Vervangt geconfigureerde hostnaam en poort verbonden door `:`. 

Een voorbeeld met de `--bind` (`-b`) vlag:

```swift
swift run App serve -b 0.0.0.0:80
```

Gebruik `swift run App serve --help` voor meer informatie.

Het `serve` commando zal luisteren naar `SIGTERM` en `SIGINT` om de server netjes af te sluiten. Gebruik `ctrl+c` (`^c`) om een `SIGINT` signaal te sturen. Als het log level is ingesteld op `debug` of lager, zal informatie over de status van graceful shutdown worden gelogd.

## Handmatig Starten

De server van Vapor kan handmatig worden gestart met `app.server`.

```swift
// Start Vapor's server.
try app.server.start()
// Verzoek server shutdown.
app.server.shutdown()
// Wacht tot de server is afgesloten.
try app.server.onShutdown.wait()
```

## Servers

De server die Vapor gebruikt is configureerbaar. Standaard wordt de ingebouwde HTTP server gebruikt.

```swift
app.servers.use(.http)
```

### Aangepaste Server

Vapor's standaard HTTP server kan worden vervangen door elk type dat voldoet aan `Server`. 

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

Aangepaste servers kunnen `Application.Servers.Provider` uitbreiden voor leading-dot syntax.

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
