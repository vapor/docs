# Serveur

Vapor comporte un serveur HTTP très performant et asynchrone basé sur [SwiftNIO](https://github.com/apple/swift-nio). Ce serveur supporte HTTP/1, HTTP/2, et des protocoles plus avancés comme [WebSockets](websockets.md). Ce serveur permet aussi d'activer TLS (SSL).

## Configuration

Le serveur HTTP par défaut de Vapor peut être configuré par `app.http.server`. 

```swift
// N'activer que HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

Le serveur HTTP offre plusieurs options de configuration. 

### Nom de l'hôte

Le paramètre hostname configure l'adresse sur laquelle le serveur acceptera de nouvelles connexions. Sa valeur par défaut est `127.0.0.1`.

```swift
// Configuration d'un nom d'hôte personnalisé.
app.http.server.configuration.hostname = "dev.local"
```

La configuration hostname du serveur peut être remplacée en fournissant le drapeau `--hostname` (`-H`) à la commande `serve` ou en passant le paramètre `hostname` à `app.server.start(...)`. 

```sh
# Exécution avec une autre valeur que celle configurée.
swift run App serve --hostname dev.local
```

### Port

L'option port permet de définir sur quel port le serveur écoutera les connexions. Sa valeur par défaut est `8080`. 

```swift
// Configuration d'un port personnalisé.
app.http.server.configuration.port = 1337
```

!!! Info
    `sudo` sera peut-être nécessaire pour lier le serveur à des ports inférieurs à `1024`. Les ports supérieurs à `65535` ne sont pas supportés. 


La configuration du port du serveur peut être remplacée en fournissant le drapeau `--port` (`-p`) à la commande `serve` ou en indiquant le paramètre `port` à la méthode `app.server.start(...)`. 

```sh
# Exécution avec une autre valeur que celle configurée.
swift run App serve --port 1337
```

### Backlog

Le paramètre `backlog` définit la longueur maximale de la file d'attentes de requêtes entrantes en attente de connexion au serveur. Sa valeur par défaut est `256`.

```swift
// Configuration d'une longueur backlog personnalisée.
app.http.server.configuration.backlog = 128
```

### Ré-utilisation d'adresse

Le paramètre `reuseAddress` permet la ré-utilisation d'adresses locales. Sa valeur par défaut est `true`.

```swift
// Désactive la ré-utilisation d'adresses.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

L'activation du paramètre `tcpNoDelay` aura pour effet d'essayer de réduire le délai d'émission des paquets TCP. Sa valeur par défaut est `true`. 

```swift
// Réduit le délai.
app.http.server.configuration.tcpNoDelay = true
```

### Compression des réponses

Le paramètre `responseCompression` agit sur la compression des réponses HTTP via gzip. Sa valeur par défaut est `.disabled`.

```swift
// Active la compression des réponses HTTP.
app.http.server.configuration.responseCompression = .enabled
```

Pour indiquer une capacité de buffer initiale, utilisez le paramètre `initialByteBufferCapacity` :

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Dé-compression des requêtes

Le paramètre `requestDecompression` agit sur la dé-compression des requêtes HTTP via gzip. Sa valeur par défaut est `.disabled`.

```swift
// Active la dé-compression des requêtes HTTP.
app.http.server.configuration.requestDecompression = .enabled
```

Pour indiquer une limite de dé-compression, utilisez le paramètre `limit`. Sa valeur par défaut est `.ratio(10)`.

```swift
// Aucune taille limite de dé-compression.
.enabled(limit: .none)
```

Voici les options disponibles :

- `size` : taille dé-compressée maximale en octets.
- `ratio` : taille dé-compressée maximale exprimé en ratio relatif au nombre d'octets de la taille compressée.
- `none` : désactive la limite de taille dé-compressée.

Définir une taille limite de dé-compression peut aider à limiter les attaques par requêtes compressées qui tentent de surcharger la mémoire du serveur.

### Pipelining

Le paramètre `supportPipelining` active la gestion du mécanisme de pipelining de requêtes et réponses HTTP. Sa valeur par défaut est `false`. 

```swift
// Active le pipelining HTTP.
app.http.server.configuration.supportPipelining = true
```

### Versions

Le paramètre `supportVersions` agit sur les versions HTTP utilisées par le serveur. Par défaut, Vapor supporte HTTP/1 et HTTP/2 lorsque TLS est activé. Seul HTTP/1 est supporté lorsque TLS n'est pas activé. 

```swift
// Désactive la compatibilité HTTP/1.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

Le paramètre `tlsConfiguration` contrôle l'état de TLS (SSL) sur le serveur. Sa valeur par défaut est `nil`. 

```swift
// Activation de TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/chemin/vers/le/certificat.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/chemin/vers/la/clef.pem", format: .pem))
)
```

Pour que cette configuration puisse compiler, vous devrez ajouter `import NIOSSL` en haut de votre fichier de configuration. Vous devrez peut-être aussi ajouter NIOSSL en dépendance dans votre fichier Package.swift.

### Nom du serveur

Le paramètre `serverName` agit sur l'entête `Server` des réponses HTTP sortantes. Sa valeur par défaut est `nil`.

```swift
// Ajoute l'entête 'Server: vapor' aux réponses.
app.http.server.configuration.serverName = "vapor"
```

## Command serve

Pour démarrer le serveur Vapor, utilisez la commande `serve`. Cette commande sera celle lancée par défaut si aucune commande n'est spécifiée. 

```swift
swift run App serve
```

La commande `serve` accepte les paramètres suivants :

- `hostname` (`-H`) : remplace le nom d'hôte configuré.
- `port` (`-p`) : remplace le numéro de port configuré.
- `bind` (`-b`) : remplace la combinaison configurée par le nom d'hôte et numéro de port en les séparant par le caractère deux-points (`:`). 

Exemple d'utilisation du drapeau `--bind` (`-b`) :

```swift
swift run App serve -b 0.0.0.0:80
```

Utilisez `swift run App serve --help` pour plus d'informations.

La commande `serve` écoutera les signaux `SIGTERM` et `SIGINT` pour éteindre proprement le serveur. Vous pouvez utiliser `ctrl+c` (`^c`) pour envoyer un signal `SIGINT`. Quand le niveau de log est défini sur `debug` ou plus bas, des informations sur l'état de mise en arrêt propre seront émises.

## Démarrage manuel

Le serveur de Vapor peut être démarré manuellement via `app.server`.

```swift
// Démarre le serveur de Vapor.
try app.server.start()
// Demande l'arrêt du serveur.
app.server.shutdown()
// Attend que le serveur soit arrêté.
try app.server.onShutdown.wait()
```

## Serveurs

Il est possible de configurer quel serveur utilisera Vapor. Par défaut, le serveur HTTP embarqué dans Vapor est utilisé.

```swift
app.servers.use(.http)
```

### Serveur personnalisé

Le serveur HTTP par défaut de Vapor peut être remplacé par n'importe quel type conforme au protocole `Server`. 

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

Les serveurs personnalisés peuvent étendre `Application.Servers.Provider` pour pouvoir utiliser la syntaxe de préfixe par point :

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
