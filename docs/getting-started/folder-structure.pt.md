# Estrutura de Pastas

Agora que você criou, compilou e executou sua primeira aplicação Vapor, vamos dedicar um momento para nos familiarizar com a estrutura de pastas do Vapor. A estrutura é baseada na estrutura de pastas do [SPM](spm.md), então se você já trabalhou com SPM antes, deve ser familiar.

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│
├── Tests
│   └── AppTests
└── Package.swift
```

As seções abaixo explicam cada parte da estrutura de pastas em mais detalhes.

## Public

Esta pasta contém quaisquer arquivos públicos que serão servidos pela sua aplicação se o `FileMiddleware` estiver habilitado. Geralmente são imagens, folhas de estilo e scripts de navegador. Por exemplo, uma requisição para `localhost:8080/favicon.ico` verificará se `Public/favicon.ico` existe e o retornará.

Você precisará habilitar o `FileMiddleware` no seu arquivo `configure.swift` antes que o Vapor possa servir arquivos públicos.

```swift
// Serve arquivos do diretório `Public/`
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Esta pasta contém todos os arquivos fonte Swift do seu projeto.
A pasta de nível superior, `App`, reflete o módulo do seu pacote,
conforme declarado no manifesto do [SwiftPM](spm.md).

### App

É aqui que toda a lógica da sua aplicação fica.

#### Controllers

Controllers são uma ótima maneira de agrupar a lógica da aplicação. A maioria dos controllers tem muitas funções que aceitam uma requisição e retornam algum tipo de resposta.

#### Migrations

A pasta migrations é onde ficam as migrações do seu banco de dados se você estiver usando o Fluent.

#### Models

A pasta models é um ótimo lugar para armazenar suas structs `Content` ou `Model`s do Fluent.

#### configure.swift

Este arquivo contém a função `configure(_:)`. Esse método é chamado pelo `entrypoint.swift` para configurar a `Application` recém-criada. É aqui que você deve registrar serviços como rotas, bancos de dados, providers e mais.

#### entrypoint.swift

Este arquivo contém o ponto de entrada `@main` da aplicação que configura e executa sua aplicação Vapor.

#### routes.swift

Este arquivo contém a função `routes(_:)`. Esse método é chamado perto do final de `configure(_:)` para registrar rotas na sua `Application`.

## Tests

Cada módulo não executável na sua pasta `Sources` pode ter uma pasta correspondente em `Tests`. Esta contém código construído sobre o módulo `XCTest` para testar seu pacote. Os testes podem ser executados usando `swift test` na linha de comando ou pressionando ⌘+U no Xcode.

### AppTests

Esta pasta contém os testes unitários para o código no seu módulo `App`.

## Package.swift

Por fim, temos o manifesto de pacote do [SPM](spm.md).
