# Environment

A API de Environment do Vapor ajuda você a configurar seu app dinamicamente. Por padrão, seu app usará o ambiente `development`. Você pode definir outros ambientes úteis como `production` ou `staging` e alterar como seu app é configurado em cada caso. Você também pode carregar variáveis do ambiente do processo ou de arquivos `.env` (dotenv) conforme suas necessidades.

Para acessar o ambiente atual, use `app.environment`. Você pode usar um switch nesta propriedade em `configure(_:)` para executar lógica de configuração diferente.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Alterando o Ambiente

Por padrão, seu app será executado no ambiente `development`. Você pode alterar isso passando a flag `--env` (`-e`) durante a inicialização do app.

```swift
swift run App serve --env production
```

O Vapor inclui os seguintes ambientes:

|nome|abreviação|descrição|
|-|-|-|
|production|prod|Implantado para seus usuários.|
|development|dev|Desenvolvimento local.|
|testing|test|Para testes unitários.|

!!! info
    O ambiente `production` usará por padrão o nível de logging `notice`, a menos que especificado de outra forma. Todos os outros ambientes usam `info` por padrão.

Você pode passar o nome completo ou a abreviação para a flag `--env` (`-e`).

```swift
swift run App serve -e prod
```

## Variáveis de Processo

`Environment` oferece uma API simples, baseada em strings, para acessar as variáveis de ambiente do processo.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Além do `get`, `Environment` oferece uma API de busca dinâmica de membros via `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Ao executar seu app no terminal, você pode definir variáveis de ambiente usando `export`.

```sh
export FOO=BAR
swift run App serve
```

Ao executar seu app no Xcode, você pode definir variáveis de ambiente editando o scheme `App`.

## .env (dotenv)

Arquivos dotenv contêm uma lista de pares chave-valor que são automaticamente carregados no ambiente. Esses arquivos facilitam a configuração de variáveis de ambiente sem precisar defini-las manualmente.

O Vapor procurará por arquivos dotenv no diretório de trabalho atual. Se você estiver usando o Xcode, certifique-se de definir o diretório de trabalho editando o scheme `App`.

Considere o seguinte arquivo `.env` colocado na pasta raiz do seu projeto:

```sh
FOO=BAR
```

Quando sua aplicação iniciar, você poderá acessar o conteúdo deste arquivo como outras variáveis de ambiente do processo.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Variáveis especificadas em arquivos `.env` não sobrescreverão variáveis que já existam no ambiente do processo.

Além do `.env`, o Vapor também tentará carregar um arquivo dotenv para o ambiente atual. Por exemplo, quando no ambiente `development`, o Vapor carregará `.env.development`. Quaisquer valores no arquivo de ambiente específico terão precedência sobre o arquivo `.env` geral.

Um padrão típico é que projetos incluam um arquivo `.env` como template com valores padrão. Arquivos de ambiente específicos são ignorados com o seguinte padrão no `.gitignore`:

```gitignore
.env.*
```

Quando o projeto é clonado em um novo computador, o arquivo template `.env` pode ser copiado e ter os valores corretos inseridos.

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Arquivos dotenv com informações sensíveis como senhas não devem ser commitados no controle de versão.

Se você estiver tendo dificuldade para carregar arquivos dotenv, tente habilitar o logging de debug com `--log debug` para mais informações.

## Ambientes Personalizados

Para definir um nome de ambiente personalizado, estenda `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

O ambiente da aplicação é geralmente definido em `entrypoint.swift` usando `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)
        defer { app.shutdown() }

        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

O método `detect` usa os argumentos de linha de comando do processo e analisa a flag `--env` automaticamente. Você pode substituir esse comportamento inicializando uma struct `Environment` personalizada.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

O array de argumentos deve conter pelo menos um argumento que represente o nome do executável. Argumentos adicionais podem ser fornecidos para simular a passagem de argumentos via linha de comando. Isso é especialmente útil para testes.
