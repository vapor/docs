# Testes

## VaporTesting

O Vapor inclui um módulo chamado `VaporTesting` que fornece helpers de teste construídos sobre o `Swift Testing`. Esses helpers de teste permitem que você envie requisições de teste para sua aplicação Vapor programaticamente ou executando através de um servidor HTTP.

!!! note "Nota"
    Para projetos mais novos ou equipes adotando concorrência Swift, o `Swift Testing` é altamente recomendado em vez do `XCTest`.

### Primeiros Passos

Para usar o módulo `VaporTesting`, certifique-se de que ele foi adicionado ao target de teste do seu pacote.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning "Aviso"
    Certifique-se de usar o módulo de teste correspondente, pois não fazê-lo pode resultar em falhas de teste do Vapor não sendo reportadas corretamente.

Então, adicione `import VaporTesting` e `import Testing` no topo dos seus arquivos de teste. Crie structs com um nome `@Suite` para escrever casos de teste.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
    	// Teste aqui.
    }
}
```

Cada função marcada com `@Test` será executada automaticamente quando sua aplicação for testada.

Para garantir que seus testes rodem de forma serializada (ex: ao testar com um banco de dados), inclua a opção `.serialized` na declaração do test suite:

```swift
@Suite("App Tests with DB", .serialized)
```

### Testable Application

Para fornecer uma configuração e desmontagem padronizadas e simplificadas dos testes, o `VaporTesting` oferece a função helper `withApp`. Este método encapsula o gerenciamento de ciclo de vida da instância `Application`, garantindo que a aplicação seja devidamente inicializada, configurada e encerrada para cada teste.

Passe o método `configure(_:)` da sua aplicação para a função helper `withApp` para garantir que todas as suas rotas sejam corretamente registradas:

```swift
@Test func someTest() async throws {
    try await withApp(configure: configure) { app in
        // seu teste real
    }
}
```

#### Enviar Requisição

Para enviar uma requisição de teste para sua aplicação, use o método privado `withApp` e dentro use o método `app.testing().test()`:

```swift
@Test("Testar Rota Hello World")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Olá, mundo!")
        }
    }
}
```

Os dois primeiros parâmetros são o método HTTP e a URL a requisitar. A closure final aceita a resposta HTTP que você pode verificar usando a macro `#expect`.

Para requisições mais complexas, você pode fornecer uma closure `beforeRequest` para modificar headers ou codificar conteúdo. A [API de Conteúdo](../basics/content.md) do Vapor está disponível tanto na requisição de teste quanto na resposta.

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### Método de Teste

A API de teste do Vapor suporta enviar requisições de teste programaticamente e via um servidor HTTP ativo. Você pode especificar qual método deseja usar através do método `testing`.

```swift
// Usar teste programático.
app.testing(method: .inMemory).test(...)

// Executar testes através de um servidor HTTP ativo.
app.testing(method: .running).test(...)
```

A opção `inMemory` é usada por padrão.

A opção `running` suporta passar uma porta específica para usar. Por padrão, `8080` é usada.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Testes de Integração com Banco de Dados

Configure o banco de dados especificamente para testes para garantir que seu banco de dados de produção nunca seja usado durante os testes. Por exemplo, ao usar SQLite, você poderia configurar seu banco de dados na função `configure(_:)` da seguinte forma:

```swift
public func configure(_ app: Application) async throws {
    // Todas as outras configurações...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning "Aviso"
    Certifique-se de executar seus testes contra o banco de dados correto, para evitar sobrescrever acidentalmente dados que você não quer perder.

Então você pode aprimorar seus testes usando `autoMigrate()` e `autoRevert()` para gerenciar o schema do banco de dados e o ciclo de vida dos dados durante os testes. Para isso, você deve criar sua própria função helper `withAppIncludingDB` que inclui os ciclos de vida do schema e dados do banco:

```swift
private func withAppIncludingDB(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

E então use este helper nos seus testes:
```swift
@Test func myDatabaseIntegrationTest() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Olá, mundo!")
        }
    }
}
```

Ao combinar esses métodos, você pode garantir que cada teste comece com um estado de banco de dados limpo e consistente, tornando seus testes mais confiáveis e reduzindo a probabilidade de falsos positivos ou negativos causados por dados remanescentes.


## XCTVapor

O Vapor inclui um módulo chamado `XCTVapor` que fornece helpers de teste construídos sobre o `XCTest`. Esses helpers de teste permitem que você envie requisições de teste para sua aplicação Vapor programaticamente ou executando através de um servidor HTTP.

### Primeiros Passos

Para usar o módulo `XCTVapor`, certifique-se de que ele foi adicionado ao target de teste do seu pacote.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Então, adicione `import XCTVapor` no topo dos seus arquivos de teste. Crie classes estendendo `XCTestCase` para escrever casos de teste.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Teste aqui.
    }
}
```

Cada função começando com `test` será executada automaticamente quando sua aplicação for testada.

### Testable Application

Inicialize uma instância de `Application` usando o environment `.testing`. Você deve chamar `app.shutdown()` antes que esta aplicação seja desinicializada.

O shutdown é necessário para ajudar a liberar os recursos que a aplicação requisitou. Em particular, é importante liberar as threads que a aplicação solicita na inicialização. Se você não chamar `shutdown()` na aplicação após cada teste unitário, você pode encontrar sua suite de testes falhando com uma precondition failure ao alocar threads para uma nova instância de `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Passe a `Application` para o método `configure(_:)` do seu pacote para aplicar sua configuração. Quaisquer configurações somente para teste podem ser aplicadas após.

#### Enviar Requisição

Para enviar uma requisição de teste para sua aplicação, use o método `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Olá, mundo!")
}
```

Os dois primeiros parâmetros são o método HTTP e a URL a requisitar. A closure final aceita a resposta HTTP que você pode verificar usando métodos `XCTAssert`.

Para requisições mais complexas, você pode fornecer uma closure `beforeRequest` para modificar headers ou codificar conteúdo. A [API de Conteúdo](../basics/content.md) do Vapor está disponível tanto na requisição de teste quanto na resposta.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Método Testable

A API de teste do Vapor suporta enviar requisições de teste programaticamente e via um servidor HTTP ativo. Você pode especificar qual método deseja usar utilizando o método `testable`.

```swift
// Usar teste programático.
app.testable(method: .inMemory).test(...)

// Executar testes através de um servidor HTTP ativo.
app.testable(method: .running).test(...)
```

A opção `inMemory` é usada por padrão.

A opção `running` suporta passar uma porta específica para usar. Por padrão, `8080` é usada.

```swift
.running(port: 8123)
```
