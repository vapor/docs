# Avançado

O Fluent se esforça para criar uma API geral e agnóstica de banco de dados para trabalhar com seus dados. Isso torna mais fácil aprender o Fluent independentemente de qual driver de banco de dados você está usando. Criar APIs generalizadas também pode fazer com que trabalhar com seu banco de dados pareça mais natural em Swift.

No entanto, você pode precisar usar um recurso do seu driver de banco de dados subjacente que ainda não é suportado pelo Fluent. Este guia cobre padrões avançados e APIs no Fluent que funcionam apenas com determinados bancos de dados.

## SQL

Todos os drivers de banco de dados SQL do Fluent são construídos sobre o [SQLKit](https://github.com/vapor/sql-kit). Esta implementação SQL geral é fornecida com o Fluent no módulo `FluentSQL`.

### SQL Database

Qualquer `Database` do Fluent pode ser convertida para um `SQLDatabase`. Isso inclui `req.db`, `app.db`, o `database` passado para `Migration`, etc.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // O driver de banco de dados subjacente é SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // O driver de banco de dados subjacente _não_ é SQL.
}
```

Esta conversão só funcionará se o driver de banco de dados subjacente for um banco de dados SQL. Saiba mais sobre os métodos do `SQLDatabase` no [README do SQLKit](https://github.com/vapor/sql-kit).

### Banco de Dados SQL Específico

Você também pode converter para bancos de dados SQL específicos importando o driver.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // O driver de banco de dados subjacente é PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // O banco de dados subjacente _não_ é PostgreSQL.
}
```

No momento da escrita, os seguintes drivers SQL são suportados.

|Banco de Dados|Driver|Biblioteca|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Visite o README da biblioteca para mais informações sobre as APIs específicas de cada banco de dados.

### SQL Custom

Quase todos os tipos de query e schema do Fluent suportam um caso `.custom`. Isso permite que você utilize recursos do banco de dados que o Fluent ainda não suporta.

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE suportado.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE não suportado.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

Bancos de dados SQL suportam tanto `String` quanto `SQLExpression` em todos os casos `.custom`. O módulo `FluentSQL` fornece métodos de conveniência para casos de uso comuns.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // O driver de banco de dados subjacente é SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // O driver de banco de dados subjacente _não_ é SQL.
}
```

Abaixo está um exemplo de `.custom` via a conveniência `.sql(raw:)` sendo usado com o schema builder.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // O driver de banco de dados subjacente é MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // O driver de banco de dados subjacente _não_ é MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB é uma integração entre [Fluent](../fluent/overview.md) e o driver [MongoKitten](https://github.com/OpenKitten/MongoKitten/). Ele aproveita o forte sistema de tipos do Swift e a interface agnóstica de banco de dados do Fluent usando MongoDB.

O identificador mais comum no MongoDB é ObjectId. Você pode usar isso no seu projeto usando `@ID(custom: .id)`.
Se precisar usar os mesmos models com SQL, não use `ObjectId`. Use `UUID` em vez disso.

```swift
final class User: Model {
    // Nome da tabela ou coleção.
    static let schema = "users"

    // Identificador único para este User.
    // Neste caso, ObjectId é usado
    // O Fluent recomenda usar UUID por padrão, porém ObjectId também é suportado
    @ID(custom: .id)
    var id: ObjectId?

    // O endereço de email do User
    @Field(key: "email")
    var email: String

    // A senha do User armazenada como hash BCrypt
    @Field(key: "password")
    var passwordHash: String

    // Cria uma nova instância vazia de User, para uso pelo Fluent
    init() { }

    // Cria um novo User com todas as propriedades definidas.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Modelagem de Dados

No MongoDB, Models são definidos da mesma forma que em qualquer outro ambiente Fluent. A principal diferença entre bancos de dados SQL e MongoDB está nas relações e arquitetura.

Em ambientes SQL, é muito comum criar tabelas de junção para relações entre duas entidades. No MongoDB, no entanto, um array pode ser usado para armazenar identificadores relacionados. Devido ao design do MongoDB, é mais eficiente e prático projetar seus models com estruturas de dados aninhadas.

### Dados Flexíveis

Você pode adicionar dados flexíveis no MongoDB, mas este código não funcionará em ambientes SQL.
Para criar armazenamento de dados arbitrários agrupados, você pode usar `Document`.

```swift
@Field(key: "document")
var document: Document
```

O Fluent não pode suportar queries com tipagem estrita nesses valores. Você pode usar um key path com notação de ponto na sua query.
Isso é aceito no MongoDB para acessar valores aninhados.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### Uso de expressões regulares

Você pode consultar o MongoDB usando o caso `.custom()`, passando uma expressão regular. O [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) aceita expressões regulares compatíveis com Perl.

Por exemplo, você pode consultar caracteres insensíveis a maiúsculas e minúsculas no campo `name`:

```swift
import FluentMongoDriver

var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Isso retornará planetas contendo 'e' e 'E'. Você também pode criar qualquer outra RegEx complexa aceita pelo MongoDB.

### Acesso Direto

Para acessar a instância `MongoDatabase` diretamente, converta a instância do banco de dados para `MongoDatabaseRepresentable` da seguinte forma:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

A partir daqui você pode usar todas as APIs do MongoKitten.
