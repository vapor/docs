# Filas

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) é um sistema de filas puro em Swift que permite descarregar a responsabilidade de tarefas para um worker separado.

Algumas das tarefas para as quais este pacote funciona bem:

- Envio de e-mails fora da thread principal de requisição
- Realização de operações complexas ou longas no banco de dados
- Garantia de integridade e resiliência de jobs
- Aceleração do tempo de resposta adiando processamento não crítico
- Agendamento de jobs para ocorrer em um horário específico

Este pacote é similar ao [Ruby Sidekiq](https://github.com/mperham/sidekiq). Ele fornece as seguintes funcionalidades:

- Tratamento seguro de sinais `SIGTERM` e `SIGINT` enviados por provedores de hospedagem para indicar shutdown, reinício ou novo deploy.
- Diferentes prioridades de filas. Por exemplo, você pode especificar um job de fila para rodar na fila de e-mail e outro job para rodar na fila de processamento de dados.
- Implementa o processo de fila confiável para ajudar com falhas inesperadas.
- Inclui uma funcionalidade `maxRetryCount` que repetirá o job até que ele tenha sucesso, até uma contagem especificada.
- Usa NIO para utilizar todos os cores e EventLoops disponíveis para jobs.
- Permite que usuários agendem tarefas recorrentes

Queues atualmente possui um driver oficialmente suportado que faz interface com o protocolo principal:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues também possui drivers baseados na comunidade:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip "Dica"
    Você não deve instalar o pacote `vapor/queues` diretamente, a menos que esteja construindo um novo driver. Instale um dos pacotes de driver em vez disso.

## Primeiros Passos

Vamos ver como você pode começar a usar o Queues.

### Package

O primeiro passo para usar o Queues é adicionar um dos drivers como dependência ao seu projeto no arquivo de manifesto do SwiftPM. Neste exemplo, usaremos o driver Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Quaisquer outras dependências...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Outras dependências
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Se você editar o manifesto diretamente dentro do Xcode, ele automaticamente detectará as mudanças e buscará a nova dependência quando o arquivo for salvo. Caso contrário, no Terminal, execute `swift package resolve` para buscar a nova dependência.

### Configuração

O próximo passo é configurar o Queues em `configure.swift`. Usaremos a biblioteca Redis como exemplo:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Registrando um `Job`

Após modelar um job, você deve adicioná-lo à sua seção de configuração assim:

```swift
// Registrar jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Executando Workers como Processos

Para iniciar um novo worker de fila, execute `swift run App queues`. Você também pode especificar um tipo específico de worker para executar: `swift run App queues --queue emails`.

!!! tip "Dica"
    Workers devem ficar rodando em produção. Consulte seu provedor de hospedagem para descobrir como manter processos de longa duração ativos. O Heroku, por exemplo, permite que você especifique "worker" dynos assim no seu Procfile: `worker: Run queues`. Com isso configurado, você pode iniciar workers na aba Dashboard/Resources, ou com `heroku ps:scale worker=1` (ou qualquer número de dynos preferido).

### Executando Workers no Processo

Para executar um worker no mesmo processo da sua aplicação (em vez de iniciar um servidor separado para lidar com isso), chame os métodos de conveniência no `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Para executar jobs agendados no processo, chame o seguinte método:

```swift
try app.queues.startScheduledJobs()
```

!!! warning "Aviso"
    Se você não iniciar o worker de fila via linha de comando ou o worker no processo, os jobs não serão despachados.

## O Protocolo `Job`

Jobs são definidos pelo protocolo `Job` ou `AsyncJob`.

### Modelando um objeto `Job`:

```swift
import Vapor
import Foundation
import Queues

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email

    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // Aqui é onde você enviaria o e-mail
        return context.eventLoop.future()
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // Se você não quiser tratar erros, pode simplesmente retornar um future. Você também pode omitir esta função inteiramente.
        return context.eventLoop.future()
    }
}
```

Se estiver usando `async`/`await`, você deve usar `AsyncJob`:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email

    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // Aqui é onde você enviaria o e-mail
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // Se você não quiser tratar erros, pode simplesmente retornar. Você também pode omitir esta função inteiramente.
    }
}
```

!!! info "Informação"
    Certifique-se de que seu tipo `Payload` implementa o protocolo `Codable`.

!!! tip "Dica"
    Não esqueça de seguir as instruções em **Primeiros Passos** para adicionar este job ao seu arquivo de configuração.

## Despachando Jobs

Para despachar um job de fila, você precisa de acesso a uma instância de `Application` ou `Request`. Você provavelmente estará despachando jobs dentro de um route handler:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// ou

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

Se, em vez disso, você precisar despachar um job de um contexto onde o objeto `Request` não está disponível (como, por exemplo, de dentro de um `Command`), você precisará usar a propriedade `queues` dentro do objeto `Application`, assim:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message")
            )
    }
}
```

### Definindo `maxRetryCount`

Jobs serão automaticamente reexecutados em caso de erro se você especificar um `maxRetryCount`. Por exemplo:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// ou

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### Especificando um Atraso

Jobs também podem ser configurados para rodar somente após uma certa `Date` ter passado. Para especificar um atraso, passe uma `Date` no parâmetro `delayUntil` no `dispatch`:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Um dia
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

Se um job for retirado da fila antes do seu parâmetro de atraso, o job será re-enfileirado pelo driver.

### Especificar uma Prioridade

Jobs podem ser classificados em diferentes tipos/prioridades de fila dependendo das suas necessidades. Por exemplo, você pode querer abrir uma fila `email` e uma fila `background-processing` para classificar jobs.

Comece estendendo `QueueName`:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Você também pode definir um `workerCount` por fila ao criar um `QueueName`:

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Definir `workerCount: 1` faz com que essa fila processe jobs consecutivamente, o que é útil quando a ordem dos jobs importa.

Então, especifique o tipo de fila ao recuperar o objeto `jobs`:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Um dia
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// ou

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Um dia
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

Ao acessar de dentro do objeto `Application`, você deve fazer o seguinte:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

Se você não especificar uma fila, o job será executado na fila `default`. Certifique-se de seguir as instruções em **Primeiros Passos** para iniciar workers para cada tipo de fila.

## Agendando Jobs

O pacote Queues também permite que você agende jobs para ocorrer em determinados momentos.

!!! warning "Aviso"
    Jobs agendados só funcionam quando configurados antes da aplicação iniciar, como em `configure.swift`. Eles não funcionarão em route handlers.

### Iniciando o Worker do Agendador

O agendador requer um processo de worker separado rodando, similar ao worker de fila. Você pode iniciar o worker executando este comando:

```sh
swift run App queues --scheduled
```

!!! tip "Dica"
    Workers devem ficar rodando em produção. Consulte seu provedor de hospedagem para descobrir como manter processos de longa duração ativos. O Heroku, por exemplo, permite que você especifique "worker" dynos assim no seu Procfile: `worker: App queues --scheduled`

### Criando um `ScheduledJob`

Para começar, crie um novo `ScheduledJob` ou `AsyncScheduledJob`:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Adicione serviços extras aqui via injeção de dependência, se necessário.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Faça algum trabalho aqui, talvez enfileire outro job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Adicione serviços extras aqui via injeção de dependência, se necessário.

    func run(context: QueueContext) async throws {
        // Faça algum trabalho aqui, talvez enfileire outro job.
    }
}
```

Então, no seu código de configuração, registre o job agendado:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

O job no exemplo acima será executado todo ano em 23 de maio às 12:00 PM.

!!! tip "Dica"
    O Agendador usa o fuso horário do seu servidor.

### Métodos Builder Disponíveis

Existem dois estilos de APIs do agendador:

- Builders estilo calendário que retornam objetos builder para encadeamento.
- Builders estilo intervalo que executam jobs a cada duração fixa.

Você deve continuar construindo uma cadeia de agendador estilo calendário até que o compilador não dê um aviso sobre resultado não utilizado. Veja abaixo todos os métodos disponíveis:

| Função Helper | Modificadores Disponíveis             | Descrição                                                                      |
|---------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`    | `in(_ month: Month) -> Monthly`       | O mês para executar o job. Retorna um objeto `Monthly` para construção adicional. |
| `monthly()`   | `on(_ day: Day) -> Daily`             | O dia para executar o job. Retorna um objeto `Daily` para construção adicional.   |
| `weekly()`    | `on(_ weekday: Weekday) -> Daily`     | O dia da semana para executar o job. Retorna um objeto `Daily`.                   |
| `daily()`     | `at(_ time: Time)`                    | O horário para executar o job. Método final da cadeia.                            |
|               | `at(_ hour: Hour24, _ minute: Minute)`| A hora e minuto para executar o job. Método final da cadeia.                      |
|               | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | A hora, minuto e período para executar o job. Método final da cadeia. |
| `hourly()`    | `at(_ minute: Minute)`                | O minuto para executar o job. Método final da cadeia.                             |
| `minutely()`  | `at(_ second: Second)`                | O segundo para executar o job. Método final da cadeia.                            |

### Métodos Builder de Intervalo (`.every(...)`)

O agendador também suporta agendamento de intervalo fixo com os métodos `.every(...)`:

| Função Helper         | Descrição                                                            |
|-----------------------|----------------------------------------------------------------------|
| `every(seconds: Int)` | Executa o job a cada número dado de segundos.                        |
| `every(minutes: Int)` | Executa o job a cada número dado de minutos.                         |
| `every(hours: Int)`   | Executa o job a cada número dado de horas.                           |
| `every(days: Int)`    | Executa o job a cada número dado de dias.                            |
| `every(weeks: Int)`   | Executa o job a cada número dado de semanas.                         |

Exemplo:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Helpers Disponíveis

O Queues vem com alguns enums helpers para facilitar o agendamento:

| Função Helper | Enum Helper Disponível                |
|---------------|---------------------------------------|
| `yearly()`    | `.january`, `.february`, `.march`, ...|
| `monthly()`   | `.first`, `.last`, `.exact(1)`        |
| `weekly()`    | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`     | `.midnight`, `.noon`                  |

Para usar o enum helper, chame o modificador apropriado na função helper e passe o valor. Por exemplo:

```swift
// Todo ano em janeiro
.yearly().in(.january)

// Todo mês no primeiro dia
.monthly().on(.first)

// Toda semana no domingo
.weekly().on(.sunday)

// Todo dia à meia-noite
.daily().at(.midnight)
```

## Event Delegates

O pacote Queues permite que você especifique objetos `JobEventDelegate` que receberão notificações quando o worker tomar ação em um job. Isso pode ser usado para monitoramento, geração de insights ou propósitos de alerta.

Para começar, conforme um objeto com `JobEventDelegate` e implemente os métodos necessários

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Chamado quando o job é despachado para o worker de fila a partir de uma rota
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chamado quando o job é colocado na fila de processamento e o trabalho começa
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chamado quando o job terminou o processamento e foi removido da fila
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chamado quando o job terminou o processamento mas teve um erro
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Então, adicione-o no seu arquivo de configuração:

```swift
app.queues.add(MyEventDelegate())
```

Existem vários pacotes de terceiros que usam a funcionalidade de delegate para fornecer insights adicionais sobre seus workers de fila:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Testes

Para evitar problemas de sincronização e garantir testes determinísticos, o pacote Queues fornece uma biblioteca `XCTQueue` e um driver `AsyncTestQueuesDriver` dedicado a testes que você pode usar da seguinte forma:

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Sobrescrever o driver sendo usado para testes
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

Veja mais detalhes no [post de blog de Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Solução de Problemas

Ao usar [queues-redis-driver](https://github.com/vapor/queues-redis-driver) com um servidor compatível com Redis baseado em cluster, como Redis ou Valkey na Amazon AWS, você pode encontrar esta mensagem de erro: `CROSSSLOT Keys in request don't hash to the same slot`.

Isso só acontece no modo cluster, porque o Redis ou Valkey não pode saber com certeza em qual nó do cluster armazenar os dados do job.

Para corrigir isso, adicione uma [hash tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) aos nomes das suas entradas de dados de job usando chaves nos nomes:

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
