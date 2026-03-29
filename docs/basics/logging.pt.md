# Logging

A API de logging do Vapor é construída sobre o [SwiftLog](https://github.com/apple/swift-log). Isso significa que o Vapor é compatível com todas as [implementações de backend](https://github.com/apple/swift-log#backends) do SwiftLog.

## Logger

Instâncias de `Logger` são usadas para emitir mensagens de log. O Vapor fornece algumas maneiras fáceis de obter acesso a um logger.

### Request

Cada `Request` recebida possui um logger único que você deve usar para quaisquer logs específicos daquela requisição.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

O logger da requisição inclui um UUID único identificando a requisição recebida para facilitar o rastreamento de logs.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
	Os metadados do logger só serão exibidos no nível de log debug ou inferior.

### Application

Para mensagens de log durante a inicialização e configuração do app, use o logger da `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Logger Personalizado

Em situações onde você não tem acesso a `Application` ou `Request`, você pode inicializar um novo `Logger`.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Embora loggers personalizados ainda enviem a saída para o backend de logging configurado, eles não terão metadados importantes anexados como o UUID da requisição. Use os loggers específicos da requisição ou da aplicação sempre que possível.

## Nível

O SwiftLog suporta vários níveis de logging diferentes.

|nome|descrição|
|-|-|
|trace|Apropriado para mensagens que contêm informações normalmente úteis apenas ao rastrear a execução de um programa.|
|debug|Apropriado para mensagens que contêm informações normalmente úteis apenas ao depurar um programa.|
|info|Apropriado para mensagens informativas.|
|notice|Apropriado para condições que não são erros, mas que podem exigir tratamento especial.|
|warning|Apropriado para mensagens que não são condições de erro, mas mais severas que notice.|
|error|Apropriado para condições de erro.|
|critical|Apropriado para condições críticas de erro que geralmente requerem atenção imediata.|

Quando uma mensagem `critical` é registrada, o backend de logging pode realizar operações mais pesadas para capturar o estado do sistema (como capturar stack traces) para facilitar a depuração.

Por padrão, o Vapor usará o nível de logging `info`. Quando executado com o ambiente `production`, `notice` será usado para melhorar o desempenho.

### Alterando o Nível de Log

Independentemente do modo de ambiente, você pode substituir o nível de logging para aumentar ou diminuir a quantidade de logs produzidos.

O primeiro método é passar a flag opcional `--log` ao iniciar sua aplicação.

```sh
swift run App serve --log debug
```

O segundo método é definir a variável de ambiente `LOG_LEVEL`.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Ambos podem ser feitos no Xcode editando o scheme `App`.

## Configuração

O SwiftLog é configurado através do bootstrap do `LoggingSystem` uma vez por processo. Projetos Vapor tipicamente fazem isso em `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` é um método auxiliar fornecido pelo Vapor que configurará o handler de log padrão com base nos argumentos de linha de comando e variáveis de ambiente. O handler de log padrão suporta a emissão de mensagens para o terminal com suporte a cores ANSI.

### Handler Personalizado

Você pode substituir o handler de log padrão do Vapor e registrar o seu próprio.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Todos os backends suportados pelo SwiftLog funcionarão com o Vapor. No entanto, a alteração do nível de log com argumentos de linha de comando e variáveis de ambiente só é compatível com o handler de log padrão do Vapor.
