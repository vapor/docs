# Serviços

A `Application` e `Request` do Vapor são construídas para serem estendidas pela sua aplicação e pacotes de terceiros. Novas funcionalidades adicionadas a esses tipos são frequentemente chamadas de serviços.

## Somente Leitura

O tipo mais simples de serviço é somente leitura. Esses serviços consistem em variáveis computadas ou métodos adicionados ao application ou request.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Serviços somente leitura podem depender de qualquer serviço pré-existente, como `client` neste exemplo. Uma vez que a extensão foi adicionada, seu serviço personalizado pode ser usado como qualquer outra propriedade na requisição.

```swift
req.myAPI.foos()
```

## Gravável

Serviços que precisam de estado ou configuração podem utilizar o storage da `Application` e `Request` para armazenar dados. Vamos supor que você queira adicionar a seguinte struct `MyConfiguration` à sua aplicação.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Para usar o storage, você deve declarar uma `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Este é um struct vazio com um typealias `Value` especificando qual tipo está sendo armazenado. Ao usar um tipo vazio como chave, você pode controlar qual código é capaz de acessar seu valor no storage. Se o tipo for internal ou private, apenas seu código poderá modificar o valor associado no storage.

Finalmente, adicione uma extensão ao `Application` para obter e definir a struct `MyConfiguration`.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Uma vez que a extensão é adicionada, você pode usar `myConfiguration` como uma propriedade normal no `Application`.

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Lifecycle

A `Application` do Vapor permite que você registre lifecycle handlers. Estes permitem que você se conecte a eventos como inicialização e encerramento.

```swift
// Imprime hello durante a inicialização.
struct Hello: LifecycleHandler {
    // Chamado antes da aplicação inicializar.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Chamado após a aplicação inicializar.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Chamado antes do encerramento da aplicação.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Adicionar lifecycle handler.
app.lifecycle.use(Hello())
```

## Locks

A `Application` do Vapor inclui conveniências para sincronizar código usando locks. Ao declarar uma `LockKey`, você pode obter um lock único e compartilhado para sincronizar o acesso ao seu código.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Fazer algo.
}
```

Cada chamada a `lock(for:)` com a mesma `LockKey` retornará o mesmo lock. Este método é thread-safe.

Para um lock de toda a aplicação, você pode usar `app.sync`.

```swift
app.sync.withLock {
    // Fazer algo.
}
```

## Request

Serviços que devem ser usados em route handlers devem ser adicionados ao `Request`. Serviços de request devem usar o logger e event loop da requisição. É importante que uma requisição permaneça no mesmo event loop ou uma asserção será disparada quando a resposta for retornada ao Vapor.

Se um serviço precisar sair do event loop da requisição para fazer trabalho, ele deve garantir o retorno ao event loop antes de finalizar. Isso pode ser feito usando o `hop(to:)` no `EventLoopFuture`.

Serviços de request que precisam de acesso a serviços da aplicação, como configurações, podem usar `req.application`. Tenha cuidado ao considerar a thread-safety ao acessar a aplicação a partir de um route handler. Geralmente, apenas operações de leitura devem ser realizadas por requisições. Operações de escrita devem ser protegidas por locks.
