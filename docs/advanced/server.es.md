# Servidor

Vapor incluye un servidor HTTP asíncrono de alto rendimiento construido sobre [SwiftNIO](https://github.com/apple/swift-nio). Este servidor admite HTTP/1, HTTP/2 y actualizaciones de protocolo como [WebSockets](websockets.md). El servidor también admite la activación de TLS (SSL).

## Configuración

El servidor HTTP predeterminado de Vapor se puede configurar a través de `app.http.server`.

```swift
// Solo soporta HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

El servidor HTTP admite varias opciones de configuración.

### Hostname

El hostname controla en qué dirección el servidor aceptará nuevas conexiones. El valor predeterminado es `127.0.0.1`.

```swift
// Configura un hostname personalizado.
app.http.server.configuration.hostname = "dev.local"
```

El hostname de la configuración del servidor se puede sobrescribir pasando el flag `--hostname` (`-H`) al comando `serve` o pasando el parámetro `hostname` a `app.server.start(...)`.

```sh
# Sobreescribiendo la configuración de hostname.
swift run App serve --hostname dev.local
```

### Port

La opción port controla en qué puerto de la dirección especificada el servidor aceptará nuevas conexiones. El valor predeterminado es `8080`.

```swift
// Configura un port personalizado.
app.http.server.configuration.port = 1337
```

!!! info "Información"
    Es posible que se requiera `sudo` para vincular puertos inferiores a `1024`. No se admiten puertos superiores a `65535`.

El puerto de la configuración del servidor se puede sobrescribir pasando el flag `--port` (`-p`) al comando `serve` o pasando el parámetro `port` a `app.server.start(...)`.

```sh
# Sobreescribiendo la configuración de port.
swift run App serve --port 1337
```

### Backlog

El parámetro `backlog` define la longitud máxima de la cola de conexiones pendientes. El valor predeterminado es `256`.

```swift
// Configura un backlog personalizado.
app.http.server.configuration.backlog = 128
```

### Reutilizar una Dirección

El parámetro `reuseAddress` permite la reutilización de direcciones locales. El valor predeterminado es `true`.

```swift
// Deshabilitar la reutilización de direcciones.
app.http.server.configuration.reuseAddress = false
```

### TCP Sin Retraso

Habilitar el parámetro `tcpNoDelay` intentará minimizar el retraso de los paquetes TCP. El valor predeterminado es `true`.

```swift
// Minimizar el retraso de los paquetes.
app.http.server.configuration.tcpNoDelay = true
```

### Compresión de Respuesta

El parámetro `responseCompression` controla la compresión de la respuesta HTTP usando gzip. El valor predeterminado es `.disabled`.

```swift
// Habilite la compresión de respuesta HTTP.
app.http.server.configuration.responseCompression = .enabled
```

Para especificar una capacidad de búfer inicial, utiliza el parámetro `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Descompresión de Solicitudes

El parámetro `requestDecompression` controla la descompresión de solicitudes HTTP mediante gzip. El valor predeterminado es `.disabled`.

```swift
// Habilite la descompresión de solicitudes HTTP.
app.http.server.configuration.requestDecompression = .enabled
```

Para especificar un límite de descompresión, utiliza el parámetro `limit`. El valor predeterminado es `.ratio(10)`.

```swift
// Sin límite de tamaño de descompresión
.enabled(limit: .none)
```

Las opciones disponibles son:

- `size`: Tamaño máximo descomprimido en bytes.
- `ratio`: Tamaño máximo descomprimido como proporción de bytes comprimidos.
- `none`: Sin límites de tamaño.

Establecer límites de tamaño de descompresión puede ayudar a evitar que las solicitudes HTTP comprimidas maliciosamente utilicen grandes cantidades de memoria.

### Pipelining

El parámetro `supportPipelining` habilita la compatibilidad con la canalización de solicitudes y respuestas HTTP (pipelining). El valor predeterminado es `false`.

```swift
// Admite HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### Versiones

El parámetro `supportVersions` controla qué versiones de HTTP utilizará el servidor. De forma predeterminada, Vapor admitirá HTTP/1 y HTTP/2 cuando TLS esté habilitado. Solo se admite HTTP/1 cuando TLS está deshabilitado.

```swift
// Deshabilitar la compatibilidad con HTTP/1.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

El parámetro `tlsConfiguration` controla si TLS (SSL) está habilitado en el servidor. El valor predeterminado es `nil`.

```swift
// Habilitar TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .file("/path/to/key.pem")
)
```

Para que se compile esta configuración, debes agregar `import NIOSSL` en la parte superior de tu archivo de configuración. Es posible que también debas agregar NIOSSL como dependencia en tu archivo Package.swift.

### Nombre

El parámetro `serverName` controla la cabecera `Server` en las respuestas HTTP salientes. El valor predeterminado es `nil`.

```swift
// Agregue la cabecera 'Servidor: vapor' a las respuestas.
app.http.server.configuration.serverName = "vapor"
```

## Comando Serve

Para iniciar el servidor de Vapor, usa el comando `serve`. Este comando se ejecutará de forma predeterminada si no se especifica ningún otro comando.

```swift
swift run App serve
```

El comando `serve` acepta los siguientes parámetros:

- `hostname` (`-H`): Sobrescribe el nombre de host configurado.
- `port` (`-p`): Sobresribe el puerto configurado.
- `bind` (`-b`): Sobrescribe el nombre de host configurado y el puerto unidos por `:`.

Un ejemplo que utiliza el flag `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

Utiliza `swift run App serve --help` para obtener más información.

El comando `serve` escuchará `SIGTERM` y `SIGINT` para apagar correctamente el servidor. Utiliza `ctrl+c` (`^c`) para enviar una señal `SIGINT`. Cuando el nivel de log se establece en `debug` o menor, se registrará información sobre el estado del correcto apagado.

## Inicio Manual

El servidor de Vapor se puede iniciar manualmente usando `app.server`.

```swift
// Inicia el servidor de Vapor.
try app.server.start()
// Solicita el cierre del servidor.
app.server.shutdown()
// Espera a que se apague el servidor.
try app.server.onShutdown.wait()
```

## Servidores

El servidor que utiliza Vapor es configurable. De forma predeterminada, se utiliza el servidor HTTP integrado.

```swift
app.servers.use(.http)
```

### Servidor Personalizado

El servidor HTTP predeterminado de Vapor se puede reemplazar por cualquier tipo que cumpla con `Server`.

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

Los servidores personalizados pueden extender `Application.Servers.Provider` para usar la sintaxis de punto.

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
