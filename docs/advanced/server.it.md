# Server

Vapor include un server HTTP asincrono ad alte prestazioni costruito su [SwiftNIO](https://github.com/apple/swift-nio). Questo server supporta HTTP/1, HTTP/2 e aggiornamenti di protocollo come i [WebSocket](websockets.it.md). Il server supporta anche l'abilitazione di TLS (SSL).

## Configurazione

Il server HTTP predefinito di Vapor può essere configurato tramite `app.http.server`.

```swift
// Supporta solo HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

Il server HTTP supporta diverse opzioni di configurazione.

### Hostname

L'hostname controlla l'indirizzo su cui il server accetterà nuove connessioni. Il valore predefinito è `127.0.0.1`.

```swift
// Configura un hostname personalizzato.
app.http.server.configuration.hostname = "dev.local"
```

L'hostname della configurazione del server può essere sovrascritto passando il flag `--hostname` (`-H`) al comando `serve` o passando il parametro `hostname` a `app.server.start(...)`.

```sh
# Sovrascrive l'hostname configurato.
swift run App serve --hostname dev.local
```

### Porta

L'opzione `port` controlla su quale porta all'indirizzo specificato il server accetterà nuove connessioni. Il valore predefinito è `8080`.

```swift
// Configura una porta personalizzata.
app.http.server.configuration.port = 1337
```

!!! info "Informazione"
    Per il binding a porte inferiori a `1024` potrebbe essere richiesto `sudo`. Le porte superiori a `65535` non sono supportate.

La porta della configurazione del server può essere sovrascritta anche passando il flag `--port` (`-p`) al comando `serve` o passando il parametro `port` a `app.server.start(...)`.

```sh
# Sovrascrive la porta configurata.
swift run App serve --port 1337
```

### Backlog

Il parametro `backlog` definisce la lunghezza massima per la coda delle connessioni in attesa. Il valore predefinito è `256`.

```swift
// Configura un backlog personalizzato.
app.http.server.configuration.backlog = 128
```

Configurare un backlog più grande può essere utile per le applicazioni che si aspettano un alto volume di traffico, ma tieni presente che un backlog più grande può anche aumentare l'uso della memoria.

### Riutilizzo Indirizzo

Il parametro `reuseAddress` consente il riutilizzo degli indirizzi locali. Il valore predefinito è `true`.

```swift
// Disabilita il riutilizzo degli indirizzi.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Abilitare il parametro `tcpNoDelay` tenterà di minimizzare il ritardo dei pacchetti TCP. Il valore predefinito è `true`.

```swift
// Minimizza il ritardo dei pacchetti.
app.http.server.configuration.tcpNoDelay = true
```

### Compressione delle Risposte

Il parametro `responseCompression` controlla la compressione delle risposte HTTP usando gzip. Il valore predefinito è `.disabled`.

```swift
// Abilita la compressione delle risposte HTTP.
app.http.server.configuration.responseCompression = .enabled
```

Per specificare una capacità iniziale del buffer, usa il parametro `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Decompressione delle Richieste

Il parametro `requestDecompression` controlla la decompressione delle richieste HTTP usando gzip. Il valore predefinito è `.disabled`.

```swift
// Abilita la decompressione delle richieste HTTP.
app.http.server.configuration.requestDecompression = .enabled
```

Per specificare un limite di decompressione, usa il parametro `limit`. Il valore predefinito è `.ratio(10)`.

```swift
// Nessun limite di dimensione per la decompressione
.enabled(limit: .none)
```

Le opzioni disponibili sono:

- `size`: Dimensione massima decompressa in byte.
- `ratio`: Dimensione massima decompressa come rapporto dei byte compressi.
- `none`: Nessun limite di dimensione.

Impostare limiti di dimensione per la decompressione può aiutare a prevenire che richieste HTTP compresse in modo malevolo usino grandi quantità di memoria.

### Pipelining

Il parametro `supportPipelining` abilita il supporto per il pipelining di richieste e risposte HTTP. Il valore predefinito è `false`.

```swift
// Supporta il pipelining HTTP.
app.http.server.configuration.supportPipelining = true
```

### Versioni

Il parametro `supportVersions` controlla quali versioni HTTP il server utilizzerà. Per impostazione predefinita, Vapor supporterà sia HTTP/1 che HTTP/2 quando TLS è abilitato. Solo HTTP/1 è supportato quando TLS è disabilitato.

```swift
// Disabilita il supporto HTTP/1.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Il parametro `tlsConfiguration` controlla se TLS (SSL) è abilitato sul server. Il valore predefinito è `nil`.

```swift
// Abilita TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

Affinché questa configurazione venga compilata è necessario aggiungere `import NIOSSL` in cima al file di configurazione. Potrebbe anche essere necessario aggiungere NIOSSL come dipendenza nel file Package.swift.

### Nome

Il parametro `serverName` controlla l'header `Server` nelle risposte HTTP in uscita. Il valore predefinito è `nil`.

```swift
// Aggiunge l'header 'Server: vapor' alle risposte.
app.http.server.configuration.serverName = "vapor"
```

## Comando Serve

Per avviare il server di Vapor, usa il comando `serve`. Questo comando viene eseguito per impostazione predefinita se non vengono specificati altri comandi.

```swift
swift run App serve
```

Il comando `serve` accetta i seguenti parametri:

- `hostname` (`-H`): Sovrascrive l'hostname configurato.
- `port` (`-p`): Sovrascrive la porta configurata.
- `bind` (`-b`): Sovrascrive l'hostname e la porta configurati, uniti da `:`.

Un esempio usando il flag `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

Usa `swift run App serve --help` per ulteriori informazioni.

Il comando `serve` ascolterà `SIGTERM` e `SIGINT` per uno shutdown graceful del server. Usa `ctrl+c` (`^c`) per inviare un segnale `SIGINT`. Quando il livello di log è impostato su `debug` o inferiore, verranno registrate informazioni sullo stato dello shutdown graceful.

## Avvio Manuale

Il server di Vapor può essere avviato manualmente usando `app.server`.

```swift
// Avvia il server di Vapor.
try app.server.start()
// Richiede lo shutdown del server.
app.server.shutdown()
// Attende lo shutdown del server.
try app.server.onShutdown.wait()
```

## Server

Il server che Vapor utilizza è configurabile. Come impostazione predefinita viene usato il server HTTP integrato.

```swift
app.servers.use(.http)
```

### Server Personalizzato

Il server HTTP predefinito di Vapor può essere sostituito da qualsiasi tipo conforme a `Server`.

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

I server personalizzati possono estendere `Application.Servers.Provider` per la sintassi con punto iniziale.

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
