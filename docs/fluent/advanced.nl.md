# Geavanceerd

Fluent streeft ernaar een algemene, database-agnostische API te maken voor het werken met uw data. Dit maakt het makkelijker om Fluent te leren, ongeacht welke database driver je gebruikt. Het maken van gegeneraliseerde API's kan er ook voor zorgen dat het werken met je database zich meer thuis voelt in Swift. 

Het kan echter zijn dat u een functie van uw onderliggende database driver moet gebruiken die nog niet door Fluent wordt ondersteund. Deze gids behandelt geavanceerde patronen en API's in Fluent die alleen werken met bepaalde databases.

## SQL

Alle SQL database drivers van Fluent zijn gebouwd op [SQLKit](https://github.com/vapor/sql-kit). Deze algemene SQL-implementatie wordt met Fluent meegeleverd in de `FluentSQL` module.

### SQL Database

Elke Fluent `Database` kan worden gecast naar een `SQLDatabase`. Dit omvat `req.db`, `app.db`, de `database` doorgegeven aan `Migration`, enz. 

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // Het onderliggende databasestuurprogramma is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // Het onderliggende databasestuurprogramma is _niet_ SQL.
}
```

Deze cast werkt alleen als de onderliggende database driver een SQL database is. Leer meer over `SQLDatabase`'s methodes in [SQLKit's README](https://github.com/vapor/sql-kit).

### Specifieke SQL Database

U kunt ook naar specifieke SQL-databases casten door het stuurprogramma te importeren. 

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // Het onderliggende databasestuurprogramma is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // De onderliggende database is _niet_ PostgreSQL.
}
```

Op het moment van schrijven worden de volgende SQL drivers ondersteund.

|Database|Driver|Library|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Bezoek de README van de bibliotheek voor meer informatie over de database-specifieke API's.

### SQL Custom

Bijna alle query en schema types van Fluent ondersteunen een `.custom` case. Hiermee kunt u databasefuncties gebruiken die Fluent nog niet ondersteunt. 

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE ondersteund.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE niet ondersteund.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

SQL databases ondersteunen zowel `String` als `SQLExpression` in alle `.custom` gevallen. De `FluentSQL` module biedt handige methodes voor veel voorkomende gevallen.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // Het onderliggende databasestuurprogramma is SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // Het onderliggende databasestuurprogramma is _niet_ SQL.
}
```

Hieronder staat een voorbeeld van `.custom` via het `.sql(raw:)` gemak dat wordt gebruikt met de schema bouwer.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // Het onderliggende databasestuurprogramma is MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // Het onderliggende databasestuurprogramma is _niet_ MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB is een integratie tussen [Fluent](../fluent/overview.md) en de [MongoKitten](https://github.com/OpenKitten/MongoKitten/) driver. Het maakt gebruik van het sterke typesysteem van Swift en de database agnostische interface van Fluent met MongoDB.

De meest voorkomende identifier in MongoDB is ObjectId. U kunt deze gebruiken voor uw project met `@ID(custom: .id)`.
Als u dezelfde modellen met SQL wilt gebruiken, gebruik dan niet `ObjectId`. Gebruik in plaats daarvan `UUID`.

```swift
final class User: Model {
    // Naam van de tabel of verzameling.
    static let schema = "users"

    // Unieke identificatie voor deze Gebruiker.
    // In dit geval wordt ObjectId gebruikt
    // Fluent raadt aan om standaard UUID te gebruiken, maar ObjectId wordt ook ondersteund
    @ID(custom: .id)
    var id: ObjectId?

    // Het e-mailadres van de gebruiker
    @Field(key: "email")
    var email: String

    // Het wachtwoord van de gebruiker wordt opgeslagen als een BCrypt hash
    @Field(key: "password")
    var passwordHash: String

    // Creëert een nieuwe, lege User instantie, voor gebruik door Fluent
    init() { }

    // Creëert een nieuwe Gebruiker met alle eigenschappen ingesteld.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Data Modelleren

In MongoDB worden Modellen op dezelfde manier gedefinieerd als in elke andere Fluent omgeving. Het belangrijkste verschil tussen SQL-databases en MongoDB ligt in relaties en architectuur.

In SQL-omgevingen, is het heel gebruikelijk om join tabellen voor relaties tussen twee entiteiten te creëren. In MongoDB, echter, kan een array worden gebruikt om gerelateerde identifiers op te slaan. Door het ontwerp van MongoDB is het efficiënter en praktischer om uw modellen te ontwerpen met geneste gegevensstructuren.

### Flexibele Data

U kunt flexibele gegevens toevoegen in MongoDB, maar deze code zal niet werken in SQL-omgevingen.
Om gegroepeerde willekeurige data opslag te maken kun je `Document` gebruiken.

```swift
@Field(key: "document")
var document: Document
```

Fluent kan geen query's van strikte types op deze waarden ondersteunen. U kunt een met punten genoteerd sleutelpad in uw query gebruiken om query's uit te voeren.
Dit wordt in MongoDB geaccepteerd om toegang te krijgen tot geneste waarden.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### Gebruik van reguliere expressies

Door een reguliere expressie door te geven met de `.custom()` case, kan U de MongoDB raadplegen. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) accepteert reguliere expressies die compatibel zijn met Perl. 

Zo kan U bijvoorbeeld zoeken naar hoofdletterongevoelige tekens onder het veld `naam`:

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"
let planets = try Planet.query(on: req.db).filter(.custom(nameDocument)).all()
```

Dit geeft planeten terug die 'e' en 'E' bevatten. U kunt ook elke andere complexe RegEx maken die door MongoDB wordt geaccepteerd.

### Raw Access

Om toegang te krijgen tot de ruwe `MongoDatabase` instantie, cast je de database instantie naar `MongoDatabaseRepresentable` als zodanig:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

Vanaf hier kunt u gebruik maken van alle van de MongoKitten API's.
