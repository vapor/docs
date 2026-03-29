# Async

## Async Await

O Swift 5.5 introduziu concorrência na linguagem na forma de `async`/`await`. Isso fornece uma maneira de primeira classe de lidar com código assíncrono em aplicações Swift e Vapor.

O Vapor é construído sobre o [SwiftNIO](https://github.com/apple/swift-nio.git), que fornece tipos primitivos para programação assíncrona de baixo nível. Estes foram (e ainda são) usados em todo o Vapor antes da chegada do `async`/`await`. No entanto, a maior parte do código de aplicação agora pode ser escrita usando `async`/`await` em vez de usar `EventLoopFuture`s. Isso simplificará seu código e tornará muito mais fácil raciocinar sobre ele.

A maioria das APIs do Vapor agora oferece tanto versões `EventLoopFuture` quanto `async`/`await` para você escolher qual é melhor. Em geral, você deve usar apenas um modelo de programação por handler de rota e não misturar no seu código. Para aplicações que precisam de controle explícito sobre event loops, ou aplicações de alto desempenho, você deve continuar usando `EventLoopFuture`s até que executores personalizados sejam implementados. Para todos os outros, você deve usar `async`/`await`, pois os benefícios de legibilidade e manutenibilidade superam em muito qualquer pequena penalidade de desempenho.

### Migrando para async/await

Existem alguns passos necessários para migrar para async/await. Para começar, se estiver usando macOS, você deve estar no macOS 12 Monterey ou superior e Xcode 13.1 ou superior. Para outras plataformas, você precisa estar executando Swift 5.5 ou superior. Em seguida, certifique-se de que atualizou todas as suas dependências.

No seu Package.swift, defina a versão de tools para 5.5 no topo do arquivo:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Em seguida, defina a versão da plataforma para macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Por fim, atualize o target `Run` para marcá-lo como um target executável:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Nota: se você está fazendo deploy no Linux, certifique-se de atualizar a versão do Swift lá também, ex: no Heroku ou no seu Dockerfile. Por exemplo, seu Dockerfile mudaria para:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Agora você pode migrar o código existente. Geralmente, funções que retornam `EventLoopFuture`s agora são `async`. Por exemplo:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Agora se torna:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Trabalhando com APIs antigas e novas

Se você encontrar APIs que ainda não oferecem uma versão `async`/`await`, pode chamar `.get()` em uma função que retorna um `EventLoopFuture` para convertê-lo.

Ex.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

Pode se tornar

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Se você precisar ir na direção contrária, pode converter

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

para

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`s

Você pode ter notado que algumas APIs no Vapor esperam ou retornam um tipo genérico `EventLoopFuture`. Se esta é a primeira vez que você ouve sobre futures, eles podem parecer um pouco confusos no início. Mas não se preocupe, este guia mostrará como aproveitar suas poderosas APIs.

Promises e futures são tipos relacionados, mas distintos. Promises são usadas para _criar_ futures. Na maior parte do tempo, você estará trabalhando com futures retornados pelas APIs do Vapor e não precisará se preocupar em criar promises.

|tipo|descrição|mutabilidade|
|-|-|-|
|`EventLoopFuture`|Referência a um valor que pode não estar disponível ainda.|somente leitura|
|`EventLoopPromise`|Uma promessa de fornecer algum valor assincronamente.|leitura/escrita|

Futures são uma alternativa a APIs assíncronas baseadas em callbacks. Futures podem ser encadeados e transformados de maneiras que simples closures não conseguem.

## Transformando

Assim como optionals e arrays no Swift, futures podem ser mapeados e flat-mapped. Estas são as operações mais comuns que você realizará em futures.

|método|argumento|descrição|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Mapeia um valor de future para um valor diferente.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Mapeia um valor de future para um valor diferente ou um erro.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Mapeia um valor de future para um valor de _future_ diferente.|
|[`transform`](#transform)|`U`|Mapeia um future para um valor já disponível.|

Se você observar as assinaturas dos métodos `map` e `flatMap` em `Optional<T>` e `Array<T>`, verá que são muito similares aos métodos disponíveis em `EventLoopFuture<T>`.

### map

O método `map` permite que você transforme o valor do future em outro valor. Como o valor do future pode não estar disponível ainda (pode ser o resultado de uma tarefa assíncrona), precisamos fornecer uma closure para aceitar o valor.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

O método `flatMapThrowing` permite que você transforme o valor do future em outro valor _ou_ lance um erro.

!!! info
    Como lançar um erro deve criar um novo future internamente, este método é prefixado com `flatMap` mesmo que a closure não aceite um retorno de future.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

O método `flatMap` permite que você transforme o valor do future em outro valor de future. Ele recebe o nome "flat" map porque é o que permite evitar a criação de futures aninhados (ex: `EventLoopFuture<EventLoopFuture<T>>`). Em outras palavras, ele ajuda a manter seus generics planos.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ...

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    Se ao invés disso usássemos `map` no exemplo acima, teríamos acabado com: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Para chamar um método que lança erro dentro de um `flatMap`, use as palavras-chave `do` / `catch` do Swift e crie um [future completado](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```

### transform

O método `transform` permite que você modifique o valor de um future, ignorando o valor existente. Isso é especialmente útil para transformar os resultados de `EventLoopFuture<Void>` onde o valor real do future não é importante.

!!! tip
    `EventLoopFuture<Void>`, às vezes chamado de sinal, é um future cujo único propósito é notificá-lo sobre a conclusão ou falha de alguma operação assíncrona.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```

Mesmo que tenhamos fornecido um valor já disponível para `transform`, isso ainda é uma _transformação_. O future não será completado até que todos os futures anteriores tenham sido completados (ou falhado).

### Encadeamento

A grande vantagem das transformações em futures é que elas podem ser encadeadas. Isso permite que você expresse muitas conversões e subtarefas facilmente.

Vamos modificar os exemplos acima para ver como podemos aproveitar o encadeamento.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ...

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

Após a chamada inicial ao map, um `EventLoopFuture<URL>` temporário é criado. Este future é então imediatamente flat-mapped para um `EventLoopFuture<Response>`.

## Future

Vamos dar uma olhada em alguns outros métodos para usar `EventLoopFuture<T>`.

### makeFuture

Você pode usar um event loop para criar futures pré-completados com o valor ou um erro.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Você pode usar `whenComplete` para adicionar um callback que será executado quando o future for bem-sucedido ou falhar.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    Você pode adicionar quantos callbacks quiser a um future.

### Get

No caso de não haver uma alternativa baseada em concorrência para uma API, você pode aguardar o valor do future usando `try await future.get()`.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Wait for the string to be ready
let string: String = try await futureString.get()
print(string) /// String
```

### Wait

!!! warning
    A função `wait()` está obsoleta, veja [`Get`](#get) para a abordagem recomendada.

Você pode usar `.wait()` para aguardar sincronamente até que o future seja completado. Como um future pode falhar, esta chamada pode lançar erros.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` só pode ser usado em uma thread de background ou na thread principal, ou seja, em `configure.swift`. Ele _não_ pode ser usado em uma thread de event loop, ou seja, em closures de rota.

!!! warning
    Tentar chamar `wait()` em uma thread de event loop causará uma falha de asserção.

## Promise

Na maior parte do tempo, você estará transformando futures retornados por chamadas às APIs do Vapor. No entanto, em algum momento você pode precisar criar uma promise por conta própria.

Para criar uma promise, você precisará de acesso a um `EventLoop`. Você pode obter acesso a um event loop de `Application` ou `Request` dependendo do contexto.

```swift
let eventLoop: EventLoop

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    Uma promise só pode ser completada uma vez. Quaisquer completações subsequentes serão ignoradas.

Promises podem ser completadas (`succeed` / `fail`) de qualquer thread. É por isso que promises requerem um event loop para serem inicializadas. Promises garantem que a ação de completação seja retornada ao seu event loop para execução.

## Event Loop

Quando sua aplicação inicia, ela geralmente criará um event loop para cada core da CPU em que está sendo executada. Cada event loop possui exatamente uma thread. Se você está familiarizado com event loops do Node.js, os do Vapor são similares. A principal diferença é que o Vapor pode executar múltiplos event loops em um único processo, já que o Swift suporta multi-threading.

Cada vez que um client se conecta ao seu servidor, ele será atribuído a um dos event loops. Desse ponto em diante, toda a comunicação entre o servidor e aquele client acontecerá no mesmo event loop (e por associação, na thread daquele event loop).

O event loop é responsável por manter o controle do estado de cada client conectado. Se houver uma requisição do client esperando para ser lida, o event loop dispara uma notificação de leitura, fazendo com que os dados sejam lidos. Uma vez que toda a requisição é lida, quaisquer futures aguardando os dados daquela requisição serão completados.

Em closures de rota, você pode acessar o event loop atual via `Request`.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    O Vapor espera que closures de rota permaneçam no `req.eventLoop`. Se você trocar de threads, deve garantir que o acesso à `Request` e o future de resposta final aconteçam no event loop da requisição.

Fora de closures de rota, você pode obter um dos event loops disponíveis via `Application`.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Você pode alterar o event loop de um future usando `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Bloqueio

Chamar código bloqueante em uma thread de event loop pode impedir que sua aplicação responda a requisições recebidas em tempo hábil. Um exemplo de chamada bloqueante seria algo como `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)

    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` é um comando que bloqueia a thread atual pelo número de segundos fornecido. Se você fizer trabalho bloqueante como este diretamente em um event loop, o event loop será incapaz de responder a quaisquer outros clients atribuídos a ele durante a duração do trabalho bloqueante. Em outras palavras, se você fizer `sleep(5)` em um event loop, todos os outros clients conectados àquele event loop (possivelmente centenas ou milhares) serão atrasados por pelo menos 5 segundos.

Certifique-se de executar qualquer trabalho bloqueante em background. Use promises para notificar o event loop quando este trabalho for concluído de forma não-bloqueante.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)

        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

Nem todas as chamadas bloqueantes serão tão óbvias quanto `sleep(_:)`. Se você suspeita que uma chamada que está usando pode ser bloqueante, pesquise sobre o método em si ou pergunte a alguém. As seções abaixo detalham como métodos podem bloquear.

### I/O Bound

Bloqueio I/O bound significa aguardar um recurso lento como uma rede ou disco rígido, que podem ser ordens de magnitude mais lentos que a CPU. Bloquear a CPU enquanto você espera por esses recursos resulta em tempo desperdiçado.

!!! danger
    Nunca faça chamadas bloqueantes I/O bound diretamente em um event loop.

Todos os pacotes do Vapor são construídos sobre SwiftNIO e usam I/O não-bloqueante. No entanto, existem muitos pacotes Swift e bibliotecas C por aí que usam I/O bloqueante. As chances são de que, se uma função está fazendo I/O de disco ou rede e usa uma API síncrona (sem callbacks ou futures), ela é bloqueante.

### CPU Bound

A maior parte do tempo durante uma requisição é gasta aguardando recursos externos como consultas ao banco de dados e requisições de rede serem carregadas. Como o Vapor e o SwiftNIO são não-bloqueantes, esse tempo ocioso pode ser usado para atender outras requisições recebidas. No entanto, algumas rotas na sua aplicação podem precisar fazer trabalho pesado vinculado à CPU como resultado de uma requisição.

Enquanto um event loop está processando trabalho vinculado à CPU, ele será incapaz de responder a outras requisições recebidas. Isso normalmente está ok, pois CPUs são rápidas e a maioria do trabalho de CPU que aplicações web fazem é leve. Mas isso pode se tornar um problema se rotas com trabalho de CPU de longa duração estão impedindo que requisições para rotas mais rápidas sejam respondidas rapidamente.

Identificar trabalho de CPU de longa duração na sua aplicação e movê-lo para threads de background pode ajudar a melhorar a confiabilidade e responsividade do seu serviço. Trabalho vinculado à CPU é mais uma área cinzenta do que trabalho I/O bound, e cabe a você determinar onde quer traçar a linha.

Um exemplo comum de trabalho pesado vinculado à CPU é o hashing Bcrypt durante o cadastro e login de usuários. O Bcrypt é deliberadamente muito lento e intensivo em CPU por razões de segurança. Este pode ser o trabalho mais intensivo em CPU que uma aplicação web simples realmente faz. Mover o hashing para uma thread de background pode permitir que a CPU intercale trabalho do event loop enquanto calcula hashes, resultando em maior concorrência.
