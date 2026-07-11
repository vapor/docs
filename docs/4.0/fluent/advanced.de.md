# Fortgeschritten

Fluent ist bestrebt, eine allgemeine, datenbankunabhängige API für die Arbeit mit deinen Daten zu schaffen. Das erleichtert das Erlernen von Fluent unabhängig davon, welchen Datenbanktreiber du verwendest. Die Erstellung generalisierter APIs kann außerdem dazu beitragen, dass sich die Arbeit mit deiner Datenbank in Swift natürlicher anfühlt.

Es kann jedoch vorkommen, dass du eine Funktion deines zugrunde liegenden Datenbanktreibers benötigst, die noch nicht durch Fluent unterstützt wird. Dieser Leitfaden behandelt fortgeschrittene Muster und APIs in Fluent, die nur mit bestimmten Datenbanken funktionieren.

## SQL

Alle SQL-Datenbanktreiber von Fluent bauen auf [SQLKit](https://github.com/vapor/sql-kit) auf. Diese allgemeine SQL-Implementierung wird zusammen mit Fluent im Modul `FluentSQL` ausgeliefert.

### SQL-Datenbank

Jede Fluent-`Database` kann in eine `SQLDatabase` umgewandelt werden. Dies gilt für `req.db`, `app.db`, die an `Migration` übergebene `database` usw.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

Diese Umwandlung funktioniert nur, wenn der zugrunde liegende Datenbanktreiber eine SQL-Datenbank ist. Mehr über die Methoden von `SQLDatabase` erfährst du in der [README von SQLKit](https://github.com/vapor/sql-kit).

### Spezifische SQL-Datenbank

Du kannst auch in bestimmte SQL-Datenbanken umwandeln, indem du den jeweiligen Treiber importierst.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

Zum Zeitpunkt der Erstellung dieses Textes werden die folgenden SQL-Treiber unterstützt.

|Datenbank|Treiber|Bibliothek|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

In der README der jeweiligen Bibliothek findest du weitere Informationen zu den datenbankspezifischen APIs.

### SQL Custom

Fast alle Query- und Schema-Typen von Fluent unterstützen einen `.custom`-Fall. Damit kannst du Datenbankfunktionen nutzen, die Fluent noch nicht unterstützt.

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

SQL-Datenbanken unterstützen sowohl `String` als auch `SQLExpression` in allen `.custom`-Fällen. Das Modul `FluentSQL` bietet komfortable Methoden für gängige Anwendungsfälle.

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

Im Folgenden ein Beispiel für `.custom` über die komfortable `.sql(raw:)`-Methode in Verbindung mit dem Schema-Builder.

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

Fluent MongoDB ist eine Integration zwischen [Fluent](../fluent/overview.md) und dem [MongoKitten](https://github.com/OpenKitten/MongoKitten/)-Treiber. Es nutzt das starke Typsystem von Swift und die datenbankunabhängige Schnittstelle von Fluent, um MongoDB zu verwenden.

Der gebräuchlichste Bezeichner in MongoDB ist ObjectId. Du kannst diesen in deinem Projekt mit `@ID(custom: .id)` verwenden.
Wenn du dieselben Modelle auch mit SQL verwenden musst, solltest du keine `ObjectId` verwenden. Nutze stattdessen `UUID`.

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

### Datenmodellierung

In MongoDB werden Modelle genauso definiert wie in jeder anderen Fluent-Umgebung. Der Hauptunterschied zwischen SQL-Datenbanken und MongoDB liegt in den Beziehungen und der Architektur.

In SQL-Umgebungen ist es sehr üblich, Verknüpfungstabellen (Join-Tabellen) für Beziehungen zwischen zwei Entitäten zu erstellen. In MongoDB hingegen kann ein Array verwendet werden, um zugehörige Bezeichner zu speichern. Aufgrund des Designs von MongoDB ist es effizienter und praktischer, deine Modelle mit verschachtelten Datenstrukturen zu gestalten.

### Flexible Daten

Du kannst in MongoDB flexible Daten hinzufügen, dieser Code funktioniert jedoch nicht in SQL-Umgebungen.
Um gruppierte, beliebige Datenspeicherung zu erstellen, kannst du `Document` verwenden.

```swift
@Field(key: "document")
var document: Document
```

Fluent kann für diese Werte keine strikt typisierten Abfragen unterstützen. Du kannst einen durch Punkte getrennten Schlüsselpfad in deiner Abfrage verwenden, um darauf zuzugreifen.
Dies wird in MongoDB akzeptiert, um auf verschachtelte Werte zuzugreifen.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### Verwendung regulärer Ausdrücke

Du kannst MongoDB abfragen, indem du den Fall `.custom()` verwendest und einen regulären Ausdruck übergibst. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) akzeptiert Perl-kompatible reguläre Ausdrücke.

Zum Beispiel kannst du nach Groß-/Kleinschreibung unabhängigen Zeichen im Feld `name` suchen:

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Dies liefert Planeten zurück, die 'e' und 'E' enthalten. Du kannst auch jeden anderen komplexen von MongoDB akzeptierten regulären Ausdruck erstellen.

### Roher Zugriff

Um auf die rohe `MongoDatabase`-Instanz zuzugreifen, wandle die Datenbankinstanz wie folgt in `MongoDatabaseRepresentable` um:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

Von hier aus kannst du alle APIs von MongoKitten verwenden.
