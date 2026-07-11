# Serveur

Vapor inclut un serveur HTTP asynchrone hautement performant, construit sur [SwiftNIO](https://github.com/apple/swift-nio). Ce serveur prend en charge HTTP/1, HTTP/2, ainsi que les mises à niveau de protocole comme les [WebSockets](websockets.md). Le serveur prend également en charge l'activation de TLS (SSL).

## Configuration

Le serveur HTTP par défaut de Vapor peut être configuré via `app.http.server`. 

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

Le serveur HTTP prend en charge plusieurs options de configuration. 

### Hostname

Le hostname contrôle l'adresse sur laquelle le serveur acceptera les nouvelles connexions. La valeur par défaut est `127.0.0.1`.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

Le hostname de la configuration du serveur peut être remplacé en passant le flag `--hostname` (`-H`) à la commande `serve`, ou en passant le paramètre `hostname` à `app.server.start(...)`. 

```sh
# Override configured hostname.
swift run App serve --hostname dev.local
```

### Port

L'option port contrôle sur quel port de l'adresse spécifiée le serveur acceptera les nouvelles connexions. La valeur par défaut est `8080`. 

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info
    `sudo` peut être nécessaire pour se lier à des ports inférieurs à `1024`. Les ports supérieurs à `65535` ne sont pas pris en charge. 


Le port de la configuration du serveur peut être remplacé en passant le flag `--port` (`-p`) à la commande `serve`, ou en passant le paramètre `port` à `app.server.start(...)`. 

```sh
# Override configured port.
swift run App serve --port 1337
```

### Backlog

Le paramètre `backlog` définit la longueur maximale de la file d'attente des connexions en attente. La valeur par défaut est `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### Reuse Address

Le paramètre `reuseAddress` permet la réutilisation des adresses locales. La valeur par défaut est `true`.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Activer le paramètre `tcpNoDelay` tentera de minimiser le délai des paquets TCP. La valeur par défaut est `true`. 

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### Compression de la réponse

Le paramètre `responseCompression` contrôle la compression des réponses HTTP à l'aide de gzip. La valeur par défaut est `.disabled`.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

Pour spécifier une capacité de buffer initiale, utilisez le paramètre `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Décompression de la requête

Le paramètre `requestDecompression` contrôle la décompression des requêtes HTTP à l'aide de gzip. La valeur par défaut est `.disabled`.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

Pour spécifier une limite de décompression, utilisez le paramètre `limit`. La valeur par défaut est `.ratio(10)`.

```swift
// No decompression size limit
.enabled(limit: .none)
```

Les options disponibles sont :

- `size` : taille maximale décompressée en octets.
- `ratio` : taille maximale décompressée en tant que ratio des octets compressés.
- `none` : aucune limite de taille.

Définir des limites de taille de décompression peut aider à empêcher que des requêtes HTTP compressées de manière malveillante n'utilisent une grande quantité de mémoire.

### Pipelining

Le paramètre `supportPipelining` active la prise en charge du pipelining des requêtes et réponses HTTP. La valeur par défaut est `false`. 

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versions

Le paramètre `supportVersions` contrôle les versions HTTP que le serveur utilisera. Par défaut, Vapor prend en charge à la fois HTTP/1 et HTTP/2 lorsque TLS est activé. Seul HTTP/1 est pris en charge lorsque TLS est désactivé. 

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Le paramètre `tlsConfiguration` contrôle si TLS (SSL) est activé sur le serveur. La valeur par défaut est `nil`. 

```swift
// Enable TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

Pour que cette configuration compile, vous devez ajouter `import NIOSSL` en haut de votre fichier de configuration. Vous devrez peut-être également ajouter NIOSSL comme dépendance dans votre fichier Package.swift.

### Name

Le paramètre `serverName` contrôle l'en-tête `Server` sur les réponses HTTP sortantes. La valeur par défaut est `nil`.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## Commande Serve

Pour démarrer le serveur de Vapor, utilisez la commande `serve`. Cette commande s'exécute par défaut si aucune autre commande n'est spécifiée. 

```swift
swift run App serve
```

La commande `serve` accepte les paramètres suivants :

- `hostname` (`-H`) : remplace le hostname configuré.
- `port` (`-p`) : remplace le port configuré.
- `bind` (`-b`) : remplace le hostname et le port configurés, joints par `:`. 

Un exemple utilisant le flag `--bind` (`-b`) :

```swift
swift run App serve -b 0.0.0.0:80
```

Utilisez `swift run App serve --help` pour plus d'informations.

La commande `serve` écoutera les signaux `SIGTERM` et `SIGINT` pour arrêter le serveur avec élégance. Utilisez `ctrl+c` (`^c`) pour envoyer un signal `SIGINT`. Lorsque le niveau de log est réglé sur `debug` ou en dessous, des informations sur le statut de l'arrêt gracieux seront journalisées.

## Démarrage manuel

Le serveur de Vapor peut être démarré manuellement à l'aide de `app.server`.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## Servers

Le serveur utilisé par Vapor est configurable. Par défaut, le serveur HTTP intégré est utilisé.

```swift
app.servers.use(.http)
```

### Serveur personnalisé

Le serveur HTTP par défaut de Vapor peut être remplacé par n'importe quel type conforme à `Server`. 

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

Les serveurs personnalisés peuvent étendre `Application.Servers.Provider` pour la syntaxe à point de tête (leading-dot).

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
