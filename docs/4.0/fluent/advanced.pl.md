# Zaawansowane

Fluent stara się stworzyć ogólne, niezależne od bazy danych API do pracy z danymi. Ułatwia to naukę Fluent niezależnie od tego, jakiego sterownika bazy danych używasz. Tworzenie generalizowanych API może również sprawić, że praca z bazą danych będzie sprawiać wrażenie bardziej naturalnej w Swift.

Może się jednak zdarzyć, że będziesz potrzebować użyć funkcji Twojego sterownika bazy danych, która nie jest jeszcze obsługiwana przez Fluent. Ten przewodnik omawia zaawansowane wzorce i API we Fluent, które działają tylko z określonymi bazami danych.

## SQL

Wszystkie sterowniki baz danych SQL Fluent są zbudowane na [SQLKit](https://github.com/vapor/sql-kit). Ta ogólna implementacja SQL jest dostarczana razem z Fluent w module `FluentSQL`.

### SQL Database

Każdy `Database` Fluent może zostać rzutowany na `SQLDatabase`. Dotyczy to `req.db`, `app.db`, obiektu `database` przekazywanego do `Migration` itd.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

To rzutowanie zadziała tylko wtedy, gdy sterownik bazy danych jest bazą SQL. Dowiedz się więcej o metodach `SQLDatabase` w [README SQLKit](https://github.com/vapor/sql-kit).

### Konkretna baza danych SQL

Możesz również rzutować na konkretne bazy danych SQL, importując dany sterownik.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

W chwili pisania tego tekstu obsługiwane są następujące sterowniki SQL.

|Baza danych|Sterownik|Biblioteka|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Odwiedź README danej biblioteki, aby dowiedzieć się więcej o API specyficznych dla danej bazy danych.

### SQL Custom

Prawie wszystkie typy zapytań i schematów Fluent obsługują przypadek `.custom`. Pozwala on wykorzystać funkcje bazy danych, które nie są jeszcze obsługiwane przez Fluent.

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE supported.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE not supported.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

Bazy danych SQL obsługują zarówno `String`, jak i `SQLExpression` we wszystkich przypadkach `.custom`. Moduł `FluentSQL` udostępnia metody pomocnicze dla typowych przypadków użycia.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // The underlying database driver is SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // The underlying database driver is _not_ SQL.
}
```

Poniżej znajduje się przykład użycia `.custom` poprzez metodę pomocniczą `.sql(raw:)` wraz z konstruktorem schematu.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // The underlying database driver is MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // The underlying database driver is _not_ MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB to integracja pomiędzy [Fluent](../fluent/overview.md) a sterownikiem [MongoKitten](https://github.com/OpenKitten/MongoKitten/). Wykorzystuje ona silny system typów Swift oraz niezależny od bazy danych interfejs Fluent, korzystając z MongoDB.

Najczęstszym identyfikatorem w MongoDB jest ObjectId. Możesz go użyć w swoim projekcie za pomocą `@ID(custom: .id)`.
Jeśli musisz używać tych samych modeli z SQL, nie używaj `ObjectId`. Zamiast tego użyj `UUID`.

```swift
final class User: Model {
    // Name of the table or collection.
    static let schema = "users"

    // Unique identifier for this User.
    // In this case, ObjectId is used
    // Fluent recommends using UUID by default, however ObjectId is also supported
    @ID(custom: .id)
    var id: ObjectId?

    // The User's email address
    @Field(key: "email")
    var email: String

    // The User's password stores as a BCrypt hash
    @Field(key: "password")
    var passwordHash: String

    // Creates a new, empty User instance, for use by Fluent
    init() { }

    // Creates a new User with all properties set.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Modelowanie danych

W MongoDB modele definiuje się w taki sam sposób, jak w każdym innym środowisku Fluent. Główna różnica pomiędzy bazami danych SQL a MongoDB leży w relacjach i architekturze.

W środowiskach SQL bardzo powszechne jest tworzenie tabel łączących (join tables) dla relacji pomiędzy dwoma encjami. W MongoDB natomiast do przechowywania powiązanych identyfikatorów można użyć tablicy. Ze względu na sposób, w jaki zaprojektowano MongoDB, bardziej efektywne i praktyczne jest projektowanie modeli z zagnieżdżonymi strukturami danych.

### Elastyczne dane

Możesz dodawać elastyczne dane w MongoDB, jednak taki kod nie będzie działał w środowiskach SQL.
Aby utworzyć zgrupowane, dowolne przechowywanie danych, możesz użyć `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent nie może obsługiwać ściśle typowanych zapytań na tych wartościach. Do zapytań możesz użyć ścieżki klucza zapisanej z kropkami (dot notation).
Jest to akceptowane w MongoDB do uzyskiwania dostępu do zagnieżdżonych wartości.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### Użycie wyrażeń regularnych

Możesz zapytywać MongoDB, używając przypadku `.custom()` i przekazując wyrażenie regularne. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) akceptuje wyrażenia regularne zgodne z Perl.

Na przykład możesz zapytać o znaki bez rozróżniania wielkości liter w polu `name`:

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Zwróci to planety zawierające 'e' oraz 'E'. Możesz również utworzyć dowolne inne złożone wyrażenie RegEx akceptowane przez MongoDB.

### Surowy dostęp

Aby uzyskać dostęp do surowej instancji `MongoDatabase`, rzutuj instancję bazy danych na `MongoDatabaseRepresentable` w następujący sposób:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

Stąd możesz korzystać ze wszystkich API MongoKitten.
