# Fluent

Fluent é um framework [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) para Swift. Ele aproveita o forte sistema de tipos do Swift para fornecer uma interface fácil de usar para seu banco de dados. O uso do Fluent gira em torno da criação de tipos de model que representam estruturas de dados no seu banco de dados. Esses models são então usados para realizar operações de criação, leitura, atualização e exclusão em vez de escrever queries brutas.

## Configuração

Ao criar um projeto usando `vapor new`, responda "yes" para incluir o Fluent e escolha qual driver de banco de dados deseja usar. Isso adicionará automaticamente as dependências ao seu novo projeto, bem como código de configuração de exemplo.

### Projeto Existente

Se você tem um projeto existente ao qual deseja adicionar o Fluent, precisará adicionar duas dependências ao seu [package](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Um (ou mais) driver(s) Fluent de sua escolha

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

Uma vez que os pacotes são adicionados como dependências, você pode configurar seus bancos de dados usando `app.databases` em `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Cada um dos drivers Fluent abaixo possui instruções mais específicas para configuração.

### Drivers

O Fluent atualmente possui quatro drivers oficialmente suportados. Você pode pesquisar no GitHub pela tag [`fluent-driver`](https://github.com/topics/fluent-driver) para uma lista completa de drivers de banco de dados Fluent oficiais e de terceiros.

#### PostgreSQL

PostgreSQL é um banco de dados SQL open source, compatível com padrões. É facilmente configurável na maioria dos provedores de hospedagem em nuvem. Este é o driver de banco de dados **recomendado** pelo Fluent.

Para usar PostgreSQL, adicione as seguintes dependências ao seu package.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Uma vez que as dependências são adicionadas, configure as credenciais do banco de dados com o Fluent usando `app.databases.use` em `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

Você também pode analisar as credenciais a partir de uma string de conexão do banco de dados.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite é um banco de dados SQL open source, embutido. Sua natureza simplista o torna um ótimo candidato para prototipagem e testes.

Para usar SQLite, adicione as seguintes dependências ao seu package.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Uma vez que as dependências são adicionadas, configure o banco de dados com o Fluent usando `app.databases.use` em `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Você também pode configurar o SQLite para armazenar o banco de dados de forma efêmera na memória.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Se usar um banco de dados em memória, certifique-se de configurar o Fluent para migrar automaticamente usando `--auto-migrate` ou execute `app.autoMigrate()` após adicionar as migrations.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// ou
try await app.autoMigrate()
```

!!! tip
    A configuração do SQLite habilita automaticamente constraints de foreign key em todas as conexões criadas, mas não altera as configurações de foreign key no próprio banco de dados. Deletar registros em um banco de dados diretamente pode violar constraints e triggers de foreign key.

#### MySQL

MySQL é um banco de dados SQL open source popular. Está disponível em muitos provedores de hospedagem em nuvem. Este driver também suporta MariaDB.

Para usar MySQL, adicione as seguintes dependências ao seu package.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Uma vez que as dependências são adicionadas, configure as credenciais do banco de dados com o Fluent usando `app.databases.use` em `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Você também pode analisar as credenciais a partir de uma string de conexão do banco de dados.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Para configurar uma conexão local sem certificado SSL envolvido, você deve desabilitar a verificação de certificado. Pode ser necessário fazer isso, por exemplo, ao conectar a um banco de dados MySQL 8 no Docker.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none

app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning
    Não desabilite a verificação de certificado em produção. Você deve fornecer um certificado à `TLSConfiguration` para verificar.

#### MongoDB

MongoDB é um banco de dados NoSQL sem schema popular, projetado para programadores. O driver suporta todos os provedores de hospedagem em nuvem e instalações auto-hospedadas a partir da versão 3.4 em diante.

!!! note
    Este driver é alimentado por um client MongoDB criado e mantido pela comunidade chamado [MongoKitten](https://github.com/OpenKitten/MongoKitten). O MongoDB mantém um client oficial, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), junto com uma integração Vapor, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Para usar MongoDB, adicione as seguintes dependências ao seu package.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Uma vez que as dependências são adicionadas, configure as credenciais do banco de dados com o Fluent usando `app.databases.use` em `configure.swift`.

Para conectar, passe uma string de conexão no formato padrão de [URI de conexão](https://docs.mongodb.com/docs/manual/reference/connection-string/) do MongoDB.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Models

Models representam estruturas de dados fixas no seu banco de dados, como tabelas ou coleções. Models possuem um ou mais campos que armazenam valores codable. Todos os models também possuem um identificador único. Property wrappers são usados para denotar identificadores e campos, assim como mapeamentos mais complexos mencionados posteriormente. Veja o seguinte model que representa uma galáxia.

```swift
final class Galaxy: Model {
    // Nome da tabela ou coleção.
    static let schema = "galaxies"

    // Identificador único para esta Galaxy.
    @ID(key: .id)
    var id: UUID?

    // O nome da Galaxy.
    @Field(key: "name")
    var name: String

    // Cria uma nova Galaxy vazia.
    init() { }

    // Cria uma nova Galaxy com todas as propriedades definidas.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Para criar um novo model, crie uma nova classe em conformidade com `Model`.

!!! tip
    É recomendado marcar classes de model como `final` para melhorar o desempenho e simplificar requisitos de conformidade.

O primeiro requisito do protocolo `Model` é a string estática `schema`.

```swift
static let schema = "galaxies"
```

Esta propriedade diz ao Fluent a qual tabela ou coleção o model corresponde. Pode ser uma tabela que já existe no banco de dados ou uma que você criará com uma [migration](#migrations). O schema é geralmente `snake_case` e plural.

### Identifier

O próximo requisito é um campo identificador chamado `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Este campo deve usar o property wrapper `@ID`. O Fluent recomenda usar `UUID` e a chave de campo especial `.id` pois isso é compatível com todos os drivers do Fluent.

Se quiser usar uma chave ou tipo de ID personalizado, use a sobrecarga [`@ID(custom:)`](model.md#custom-identifier).

### Fields

Após o identificador ser adicionado, você pode adicionar quantos campos quiser para armazenar informações adicionais. Neste exemplo, o único campo adicional é o nome da galáxia.

```swift
@Field(key: "name")
var name: String
```

Para campos simples, o property wrapper `@Field` é usado. Como `@ID`, o parâmetro `key` especifica o nome do campo no banco de dados. Isso é especialmente útil para casos onde a convenção de nomenclatura do banco de dados pode ser diferente da do Swift, por exemplo, usando `snake_case` em vez de `camelCase`.

Em seguida, todos os models requerem um init vazio. Isso permite que o Fluent crie novas instâncias do model.

```swift
init() { }
```

Por fim, você pode adicionar um init de conveniência para seu model que defina todas as suas propriedades.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Usar inits de conveniência é especialmente útil se você adicionar novas propriedades ao seu model, pois você pode obter erros de compilação se o método init mudar.

## Migrations

Se seu banco de dados usa schemas pré-definidos, como bancos de dados SQL, você precisará de uma migration para preparar o banco de dados para seu model. Migrations também são úteis para popular bancos de dados com dados. Para criar uma migration, defina um novo tipo em conformidade com o protocolo `Migration` ou `AsyncMigration`. Veja a seguinte migration para o model `Galaxy` definido anteriormente.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepara o banco de dados para armazenar models Galaxy.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Opcionalmente reverte as alterações feitas no método prepare.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

O método `prepare` é usado para preparar o banco de dados para armazenar models `Galaxy`.

### Schema

Neste método, `database.schema(_:)` é usado para criar um novo `SchemaBuilder`. Um ou mais `field`s são então adicionados ao builder antes de chamar `create()` para criar o schema.

Cada campo adicionado ao builder tem um nome, tipo e constraints opcionais.

```swift
field(<name>, <type>, <optional constraints>)
```

Existe um método de conveniência `id()` para adicionar propriedades `@ID` usando os padrões recomendados pelo Fluent.

Reverter a migration desfaz quaisquer alterações feitas no método prepare. Neste caso, isso significa deletar o schema de Galaxy.

Uma vez que a migration é definida, você deve informar o Fluent sobre ela adicionando-a a `app.migrations` em `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrate

Para executar migrations, chame `swift run App migrate` pela linha de comando ou adicione `migrate` como argumento ao scheme App do Xcode.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Querying

Agora que você criou um model e migrou seu banco de dados com sucesso, está pronto para fazer sua primeira query.

### All

Veja a seguinte rota que retornará um array de todas as galáxias no banco de dados.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Para retornar um Galaxy diretamente em uma closure de rota, adicione conformidade a `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` é usado para criar um novo query builder para o model. `req.db` é uma referência ao banco de dados padrão para sua aplicação. Por fim, `all()` retorna todos os models armazenados no banco de dados.

Se você compilar e executar o projeto e requisitar `GET /galaxies`, você deverá ver um array vazio retornado. Vamos adicionar uma rota para criar uma nova galáxia.

### Create


Seguindo a convenção RESTful, use o endpoint `POST /galaxies` para criar uma nova galáxia. Como models são codable, você pode decodificar uma galáxia diretamente do corpo da requisição.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    Veja [Content &rarr; Overview](../basics/content.md) para mais informações sobre decodificação de corpos de requisição.

Uma vez que você tem uma instância do model, chamar `create(on:)` salva o model no banco de dados. Isso retorna um `EventLoopFuture<Void>` que sinaliza que o salvamento foi concluído. Uma vez que o salvamento é completado, retorne o model recém-criado usando `map`.

Se estiver usando `async`/`await`, você pode escrever seu código assim:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

Neste caso, a versão async não retorna nada, mas retornará uma vez que o salvamento for concluído.

Compile e execute o projeto e envie a seguinte requisição.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Você deverá receber o model criado de volta com um identificador como resposta.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Agora, se você consultar `GET /galaxies` novamente, deverá ver a galáxia recém-criada retornada no array.


## Relations

O que são galáxias sem estrelas! Vamos dar uma olhada rápida nos poderosos recursos relacionais do Fluent adicionando uma relação um-para-muitos entre `Galaxy` e um novo model `Star`.

```swift
final class Star: Model, Content {
    // Nome da tabela ou coleção.
    static let schema = "stars"

    // Identificador único para esta Star.
    @ID(key: .id)
    var id: UUID?

    // O nome da Star.
    @Field(key: "name")
    var name: String

    // Referência à Galaxy em que esta Star está.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Cria uma nova Star vazia.
    init() { }

    // Cria uma nova Star com todas as propriedades definidas.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

O novo model `Star` é muito similar a `Galaxy` exceto por um novo tipo de campo: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

A propriedade parent é um campo que armazena o identificador de outro model. O model que mantém a referência é chamado de "filho" e o model referenciado é chamado de "pai". Este tipo de relação também é conhecido como "um-para-muitos". O parâmetro `key` da propriedade especifica o nome do campo que deve ser usado para armazenar a chave do pai no banco de dados.

No método init, o identificador do pai é definido usando `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

Ao prefixar o nome da propriedade parent com `$`, você acessa o property wrapper subjacente. Isso é necessário para obter acesso ao `@Field` interno que armazena o valor real do identificador.

!!! seealso
    Confira a proposta do Swift Evolution para property wrappers para mais informações: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

Em seguida, crie uma migration para preparar o banco de dados para lidar com `Star`.


```swift
struct CreateStar: AsyncMigration {
    // Prepara o banco de dados para armazenar models Star.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Opcionalmente reverte as alterações feitas no método prepare.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Isso é basicamente o mesmo que a migration de galaxy exceto pelo campo adicional para armazenar o identificador da galáxia pai.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Este campo especifica uma constraint opcional dizendo ao banco de dados que o valor do campo referencia o campo "id" no schema "galaxies". Isso também é conhecido como foreign key e ajuda a garantir a integridade dos dados.

Uma vez que a migration é criada, adicione-a a `app.migrations` após a migration `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Como migrations são executadas em ordem, e `CreateStar` referencia o schema galaxies, a ordenação é importante. Por fim, [execute as migrations](#migrate) para preparar o banco de dados.

Adicione uma rota para criar novas estrelas.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Crie uma nova estrela referenciando a galáxia criada anteriormente usando a seguinte requisição HTTP.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

Você deverá ver a estrela recém-criada retornada com um identificador único.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

Agora vamos ver como você pode utilizar o recurso de eager-loading do Fluent para retornar automaticamente as estrelas de uma galáxia na rota `GET /galaxies`. Adicione a seguinte propriedade ao model `Galaxy`.

```swift
// Todas as Stars nesta Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

O property wrapper `@Children` é o inverso de `@Parent`. Ele recebe um key-path para o campo `@Parent` do filho como argumento `for`. Seu valor é um array de filhos, pois zero ou mais models filhos podem existir. Nenhuma alteração na migration de galaxy é necessária, pois todas as informações necessárias para esta relação estão armazenadas em `Star`.

### Eager Load

Agora que a relação está completa, você pode usar o método `with` no query builder para buscar e serializar automaticamente a relação galaxy-star.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Um key-path para a relação `@Children` é passado para `with` para dizer ao Fluent para carregar automaticamente esta relação em todos os models resultantes. Compile e execute e envie outra requisição para `GET /galaxies`. Agora você deverá ver as estrelas incluídas automaticamente na resposta.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Query Logging

Os drivers Fluent registram o SQL gerado no nível de log debug. Alguns drivers, como FluentPostgreSQL, permitem que isso seja configurado ao configurar o banco de dados.

Para definir o nível de log, em **configure.swift** (ou onde você configura sua aplicação) adicione:

```swift
app.logger.logLevel = .debug
```

Isso define o nível de log para debug. Quando você compilar e executar seu app novamente, as declarações SQL geradas pelo Fluent serão registradas no console.

## Próximos passos

Parabéns por criar seus primeiros models e migrations e realizar operações básicas de criação e leitura. Para informações mais aprofundadas sobre todos esses recursos, confira suas respectivas seções no guia do Fluent.
