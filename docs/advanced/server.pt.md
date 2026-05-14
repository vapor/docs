# Servidor

O Vapor inclui um servidor HTTP de alto desempenho e assíncrono construído sobre o [SwiftNIO](https://github.com/apple/swift-nio). Este servidor suporta HTTP/1, HTTP/2 e upgrades de protocolo como [WebSockets](websockets.md). O servidor também suporta a habilitação de TLS (SSL).

## Configuração

O servidor HTTP padrão do Vapor pode ser configurado via `app.http.server`.

```swift
// Suportar apenas HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

O servidor HTTP suporta várias opções de configuração.

### Hostname

O hostname controla em qual endereço o servidor aceitará novas conexões. O padrão é `127.0.0.1`.

```swift
// Configurar hostname personalizado.
app.http.server.configuration.hostname = "dev.local"
```

O hostname da configuração do servidor pode ser sobrescrito passando a flag `--hostname` (`-H`) ao comando `serve` ou passando o parâmetro `hostname` para `app.server.start(...)`.

```sh
# Sobrescrever hostname configurado.
swift run App serve --hostname dev.local
```

### Porta

A opção de porta controla em qual porta no endereço especificado o servidor aceitará novas conexões. O padrão é `8080`.

```swift
// Configurar porta personalizada.
app.http.server.configuration.port = 1337
```

!!! info "Informação"
	`sudo` pode ser necessário para vincular a portas menores que `1024`. Portas maiores que `65535` não são suportadas.

A porta da configuração do servidor pode ser sobrescrita passando a flag `--port` (`-p`) ao comando `serve` ou passando o parâmetro `port` para `app.server.start(...)`.

```sh
# Sobrescrever porta configurada.
swift run App serve --port 1337
```

### Backlog

O parâmetro `backlog` define o comprimento máximo para a fila de conexões pendentes. O padrão é `256`.

```swift
// Configurar backlog personalizado.
app.http.server.configuration.backlog = 128
```

### Reutilização de Endereço

O parâmetro `reuseAddress` permite a reutilização de endereços locais. O padrão é `true`.

```swift
// Desabilitar reutilização de endereço.
app.http.server.configuration.reuseAddress = false
```

### TCP No Delay

Habilitar o parâmetro `tcpNoDelay` tentará minimizar o atraso de pacotes TCP. O padrão é `true`.

```swift
// Minimizar atraso de pacotes.
app.http.server.configuration.tcpNoDelay = true
```

### Compressão de Resposta

O parâmetro `responseCompression` controla a compressão de resposta HTTP usando gzip. O padrão é `.disabled`.

```swift
// Habilitar compressão de resposta HTTP.
app.http.server.configuration.responseCompression = .enabled
```

Para especificar uma capacidade inicial de buffer, use o parâmetro `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### Descompressão de Requisição

O parâmetro `requestDecompression` controla a descompressão de requisição HTTP usando gzip. O padrão é `.disabled`.

```swift
// Habilitar descompressão de requisição HTTP.
app.http.server.configuration.requestDecompression = .enabled
```

Para especificar um limite de descompressão, use o parâmetro `limit`. O padrão é `.ratio(10)`.

```swift
// Sem limite de tamanho de descompressão
.enabled(limit: .none)
```

As opções disponíveis são:

- `size`: Tamanho máximo descomprimido em bytes.
- `ratio`: Tamanho máximo descomprimido como proporção dos bytes comprimidos.
- `none`: Sem limites de tamanho.

Definir limites de tamanho de descompressão pode ajudar a prevenir que requisições HTTP maliciosamente comprimidas usem grandes quantidades de memória.

### Pipelining

O parâmetro `supportPipelining` habilita suporte para pipelining de requisição e resposta HTTP. O padrão é `false`.

```swift
// Suportar pipelining HTTP.
app.http.server.configuration.supportPipelining = true
```

### Versões

O parâmetro `supportVersions` controla quais versões HTTP o servidor usará. Por padrão, o Vapor suportará tanto HTTP/1 quanto HTTP/2 quando TLS estiver habilitado. Apenas HTTP/1 é suportado quando TLS está desabilitado.

```swift
// Desabilitar suporte a HTTP/1.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

O parâmetro `tlsConfiguration` controla se TLS (SSL) está habilitado no servidor. O padrão é `nil`.

```swift
// Habilitar TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/caminho/do/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/caminho/da/key.pem", format: .pem))
)
```

Para esta configuração compilar, você precisa adicionar `import NIOSSL` no topo do seu arquivo de configuração. Você também pode precisar adicionar NIOSSL como dependência no seu arquivo Package.swift.

### Nome

O parâmetro `serverName` controla o header `Server` em respostas HTTP de saída. O padrão é `nil`.

```swift
// Adicionar header 'Server: vapor' às respostas.
app.http.server.configuration.serverName = "vapor"
```

## Comando Serve

Para iniciar o servidor do Vapor, use o comando `serve`. Este comando será executado por padrão se nenhum outro comando for especificado.

```swift
swift run App serve
```

O comando `serve` aceita os seguintes parâmetros:

- `hostname` (`-H`): Sobrescreve o hostname configurado.
- `port` (`-p`): Sobrescreve a porta configurada.
- `bind` (`-b`): Sobrescreve o hostname e porta configurados unidos por `:`.

Um exemplo usando a flag `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

Use `swift run App serve --help` para mais informações.

O comando `serve` ouvirá os sinais `SIGTERM` e `SIGINT` para encerrar o servidor graciosamente. Use `ctrl+c` (`^c`) para enviar um sinal `SIGINT`. Quando o nível de log está definido como `debug` ou inferior, informações sobre o status do encerramento gracioso serão registradas.

## Início Manual

O servidor do Vapor pode ser iniciado manualmente usando `app.server`.

```swift
// Iniciar o servidor do Vapor.
try app.server.start()
// Solicitar encerramento do servidor.
app.server.shutdown()
// Aguardar o servidor encerrar.
try app.server.onShutdown.wait()
```

## Servidores

O servidor que o Vapor usa é configurável. Por padrão, o servidor HTTP integrado é usado.

```swift
app.servers.use(.http)
```

### Servidor Personalizado

O servidor HTTP padrão do Vapor pode ser substituído por qualquer tipo que conforme com `Server`.

```swift
import Vapor

final class MyServer: Server {
	...
}

app.servers.use { app in
	MyServer()
}
```

Servidores personalizados podem estender `Application.Servers.Provider` para sintaxe com ponto.

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
