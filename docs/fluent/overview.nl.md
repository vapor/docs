# Fluent

Fluent is een [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) framework voor Swift. Het maakt gebruik van het sterke type systeem van Swift om een eenvoudig te gebruiken interface voor je database te bieden. Het gebruik van Fluent draait om het maken van modeltypes die gegevensstructuren in je database representeren. Deze modellen worden vervolgens gebruikt om te creëren, lezen, updaten en verwijderen operaties uit te voeren in plaats van het schrijven van ruwe queries.

## Configuratie

Wanneer u een project aanmaakt met `vapor new`, antwoord dan "yes" bij het includeren van Fluent en kies welke database driver u wilt gebruiken. Dit zal automatisch de dependencies toevoegen aan uw nieuwe project, evenals voorbeeld configuratie code.

### Bestaand Project

Als u een bestaand project heeft waaraan u Fluent wilt toevoegen, dan moet u twee afhankelijkheden toevoegen aan uw [package](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Een (of meer) Fluent driver(s) van uw keuze

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

Zodra de pakketten zijn toegevoegd als dependencies, kunt u uw databases configureren met `app.databases` in `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Elk van de Fluent drivers hieronder heeft meer specifieke instructies voor configuratie.

### Drivers

Fluent heeft momenteel vier officieel ondersteunde stuurprogramma's. U kunt op GitHub zoeken naar de tag [`fluent-driver`](https://github.com/topics/fluent-driver) voor een volledige lijst van officiële en third-party Fluent database drivers.

#### PostgreSQL

PostgreSQL is een open-source SQL-database die voldoet aan de standaarden. Het is gemakkelijk te configureren op de meeste cloud hosting providers. Dit is de **aanbevolen** database driver van Fluent.

Om PostgreSQL te gebruiken, voeg de volgende dependencies toe aan uw pakket.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Als de afhankelijkheden zijn toegevoegd, configureer dan de database referenties met Fluent met `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(.postgres(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .psql)
```

Je kunt ook de credentials uit een database connection string halen.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite is een open source, ingebedde SQL database. Zijn simplistische aard maakt het een geweldige kandidaat voor prototyping en testen.

Om SQLite te gebruiken, moet u de volgende afhankelijkheden aan uw pakket toevoegen.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Als de afhankelijkheden zijn toegevoegd, configureer dan de database met Fluent met `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

U kunt SQLite ook configureren om de database vluchtig in het geheugen op te slaan.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Als u een in-memory database gebruikt, zorg er dan voor dat Fluent automatisch migreert door `--auto-migrate` te gebruiken of `app.autoMigrate()` uit te voeren na het toevoegen van migraties.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// of
try await app.autoMigrate()
```

!!! tip
    De SQLite configuratie schakelt automatisch foreign key constraints in op alle gemaakte verbindingen, maar verandert niets aan de foreign key configuraties in de database zelf. Het direct verwijderen van records in een database kan een overtreding zijn van foreign key constraints en triggers.

#### MySQL

MySQL is een populaire open source SQL-database. Het is beschikbaar op veel cloud hosting providers. Dit stuurprogramma ondersteunt ook MariaDB.

Om MySQL te gebruiken, moet u de volgende afhankelijkheden aan uw pakket toevoegen.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Als de afhankelijkheden zijn toegevoegd, configureer dan de database referenties met Fluent met `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Je kunt ook de credentials uit een database connection string halen.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Om een lokale verbinding te configureren zonder tussenkomst van een SSL certificaat, moet u de certificaatverificatie uitschakelen. U zou dit bijvoorbeeld moeten doen als u verbinding maakt met een MySQL 8 database in Docker.

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

!!! warning "Waarschuwing"
    Schakel certificaat verificatie niet uit in productie. U moet een certificaat verstrekken aan de `TLSConfiguration` om tegen te verifiëren. 

#### MongoDB

MongoDB is een populaire schemaloze NoSQL database ontworpen voor programmeurs. Het stuurprogramma ondersteunt alle cloudhostingproviders en zelf gehoste installaties vanaf versie 3.4 en hoger.

!!! note "Opmerking"
    Deze driver wordt aangedreven door een gemeenschap gemaakt en onderhouden MongoDB-client genaamd [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB onderhoudt een officiële client, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), samen met een Vapor integratie, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Om MongoDB te gebruiken, voeg de volgende afhankelijkheden toe aan je pakket.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Als de afhankelijkheden zijn toegevoegd, configureer dan de database referenties met Fluent met `app.databases.use` in `configure.swift`.

Om verbinding te maken, geeft u een verbindingsstring door in het standaardformaat van MongoDB [connection URI format](https://docs.mongodb.com/master/reference/connection-string/index.html).

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Modellen

Modellen vertegenwoordigen vaste gegevensstructuren in uw database, zoals tabellen of verzamelingen. Modellen hebben één of meer velden die codeerbare waarden opslaan. Alle modellen hebben ook een unieke identifier. Property wrappers worden gebruikt om identifiers en velden aan te duiden, alsook meer complexe mappings die later worden vermeld. Kijk eens naar het volgende model dat een sterrenstelsel voorstelt.

```swift
final class Galaxy: Model {
    // Naam van de tabel of verzameling.
    static let schema = "galaxies"

    // Unieke identificatiecode voor dit melkwegstelsel.
    @ID(key: .id)
    var id: UUID?

    // De naam van de Melkweg.
    @Field(key: "name")
    var name: String

    // Creëert een nieuwe, lege Galaxy.
    init() { }

    // Creëert een nieuwe Galaxy met alle eigenschappen ingesteld.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Om een nieuw model te maken, maak een nieuwe klasse die voldoet aan `Model`.

!!! tip
    Het wordt aanbevolen om model klassen `final` te markeren om de performance te verbeteren en de conformance eisen te vereenvoudigen.

De eerste vereiste van het `Model` protocol is de statische string `schema`.

```swift
static let schema = "galaxies"
```

Deze eigenschap vertelt Fluent met welke tabel of collectie het model correspondeert. Dit kan een tabel zijn die al bestaat in de database of een tabel die u gaat aanmaken met een [migratie](#migrations). Het schema is meestal `snake_case` en meervoud.

### Identifier

De volgende vereiste is een identifier veld genaamd `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Dit veld moet de `@ID` property wrapper gebruiken. Fluent raadt aan om `UUID` en de speciale `.id` veldsleutel te gebruiken omdat dit compatibel is met alle Fluent drivers.

Als je een aangepaste ID sleutel of type wilt gebruiken, gebruik dan de [`@ID(custom:)`](model.md#custom-identifier) overload.

### Fields

Nadat de identifier is toegevoegd, kun je zoveel velden toevoegen als je wilt om extra informatie op te slaan. In dit voorbeeld is het enige extra veld de naam van het sterrenstelsel.

```swift
@Field(key: "name")
var name: String
```

Voor eenvoudige velden wordt de `@Field` property wrapper gebruikt. Net als `@ID`, specificeert de `key` parameter de naam van het veld in de database. Dit is vooral handig voor gevallen waar de database veld naamgeving conventie anders kan zijn dan in Swift, bijvoorbeeld het gebruik van `snake_case` in plaats van `camelCase`.

Vervolgens hebben alle modellen een lege init nodig. Dit stelt Fluent in staat om nieuwe instanties van het model te maken.

```swift
init() { }
```

Tenslotte kun je een gemakkelijke init voor je model toevoegen die al zijn eigenschappen instelt.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Het gebruik van convenience inits is vooral nuttig als je nieuwe eigenschappen aan je model toevoegt, omdat je compile-time fouten kunt krijgen als de init methode verandert.

## Migraties

Als uw database voorgedefinieerde schema's gebruikt, zoals SQL databases, hebt u een migratie nodig om de database voor te bereiden op uw model. Migraties zijn ook nuttig voor het seeden van databases met data. Om een migratie te maken, definieert u een nieuw type dat voldoet aan het `Migration` of `AsyncMigration` protocol. Kijk eens naar de volgende migratie voor het eerder gedefinieerde `Galaxy` model.

```swift
struct CreateGalaxy: AsyncMigration {
    // Bereidt de database voor op het opslaan van Galaxy modellen.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Zet optioneel de wijzigingen terug die in de prepare methode zijn gemaakt.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

De `prepare` methode wordt gebruikt om de database voor te bereiden voor het opslaan van `Galaxy` modellen.

### Schema

In deze methode wordt `database.schema(_:)` gebruikt om een nieuwe `SchemaBuilder` aan te maken. Een of meer `velden` worden dan aan de bouwer toegevoegd voordat `create()` wordt aangeroepen om het schema te maken.

Elk veld dat aan de bouwer wordt toegevoegd heeft een naam, type, en optionele beperkingen.

```swift
field(<name>, <type>, <optional constraints>)
```

Er is een gemakkelijke `id()` methode om `@ID` eigenschappen toe te voegen met Fluent's aanbevolen standaardwaarden.

Het terugdraaien van de migratie maakt alle wijzigingen ongedaan die zijn aangebracht in de prepare-methode. In dit geval betekent dat het verwijderen van het schema van de Galaxy.

Zodra de migratie is gedefinieerd, moet u Fluent hierover informeren door het toe te voegen aan `app.migrations` in `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migreren

Om migraties uit te voeren, roep `swift run App migrate` op vanaf de commandoregel of voeg `migrate` toe als argument aan Xcode's App schema.

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

Nu je met succes een model hebt gemaakt en je database hebt gemigreerd, ben je klaar om je eerste query te maken.

### All

Kijk eens naar de volgende route die een array zal teruggeven van alle melkwegstelsels in de database.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Om een Galaxy direct terug te geven in een route afsluiting, voeg conformiteit toe aan `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` wordt gebruikt om een nieuwe query builder voor het model te maken. `req.db` is een verwijzing naar de standaard database voor uw applicatie. Tenslotte, `all()` geeft alle modellen terug die in de database zijn opgeslagen.

Als je het project compileert en uitvoert en `GET /galaxies` opvraagt, zou je een lege array terug moeten zien. Laten we een route toevoegen voor het creëren van een nieuw sterrenstelsel.

### Aanmaken


Volgens RESTful conventie, gebruik het `POST /galaxies` eindpunt om een nieuw sterrenstelsel te creëren. Aangezien modellen codeerbaar zijn, kun je een sterrenstelsel direct uit de request body decoderen.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso "Zie ook"
    Zie [Content &rarr; Overview](../basics/content.md) voor meer informatie over het decoderen van request bodies.

Als je eenmaal een instantie van het model hebt, kun je `create(on:)` oproepen om het model op te slaan in de database. Dit retourneert een `EventLoopFuture<Void>` die aangeeft dat het opslaan voltooid is. Zodra het opslaan is voltooid, retourneert u het nieuw gemaakte model met `map`.

Als je `async`/`await` gebruikt, kun je je code zo schrijven:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

In dit geval geeft de async versie niets terug, maar zal terugkomen zodra het opslaan voltooid is.

Bouw en draai het project en stuur het volgende verzoek.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Je zou het gemaakte model terug moeten krijgen met een identifier als antwoord.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Als je nu `GET /galaxies` opnieuw opvraagt, zou je het nieuw aangemaakte sterrenstelsel terug moeten zien in de array.

## Relaties

Wat zijn melkwegstelsels zonder sterren! Laten we eens een snelle blik werpen op Fluent's krachtige relationele mogelijkheden door een één-op-veel relatie toe te voegen tussen `Galaxy` en een nieuw `Star` model.

```swift
final class Star: Model, Content {
    // Naam van de tabel of verzameling.
    static let schema = "stars"

    // Unieke identificatiecode voor deze ster.
    @ID(key: .id)
    var id: UUID?

    // De naam van de ster.
    @Field(key: "name")
    var name: String

    // Verwijzing naar het sterrenstelsel waar deze ster in zit.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creëert een nieuwe, lege Ster.
    init() { }

    // Creëert een nieuwe Ster met alle eigenschappen ingesteld.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

Het nieuwe `Star` model lijkt veel op `Galaxy` behalve dat er een nieuw veldtype is: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

De parent eigenschap is een veld dat de identifier van een ander model opslaat. Het model dat de verwijzing bevat wordt het "child" genoemd en het model waarnaar verwezen wordt wordt de "parent" genoemd. Dit type relatie is ook bekend als " één-op-veel". De `key` parameter aan de eigenschap specificeert de veldnaam die moet worden gebruikt om de sleutel van de ouder op te slaan in de database.

In de init-methode wordt de parent identifier ingesteld met `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

 Door de naam van de bovenliggende eigenschap vooraf te laten gaan door `$`, krijgt u toegang tot de onderliggende property-wrapper. Dit is nodig om toegang te krijgen tot het interne `@Field` dat de eigenlijke identifier waarde opslaat.

!!! seealso "Zie ook"
    Bekijk het Swift Evolution voorstel voor property wrappers voor meer informatie: [SE-0258] Property Wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)

Maak vervolgens een migratie om de database voor te bereiden op de verwerking van `Star`.

```swift
struct CreateStar: AsyncMigration {
    // Bereidt de database voor op het opslaan van Ster modellen.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Zet optioneel de wijzigingen terug die in de prepare methode zijn gemaakt.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Dit is grotendeels hetzelfde als de migratie van melkwegstelsels, behalve het extra veld om de identifier van het bovenliggende melkwegstelsel op te slaan.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Dit veld specificeert een optionele beperking die de database vertelt dat de waarde van het veld verwijst naar het veld "id" in het "melkwegstelsels" schema. Dit is ook gekend als een vreemde sleutel en helpt de gegevensintegriteit te verzekeren.

Zodra de migratie is gemaakt, voeg het toe aan `app.migrations` na de `CreateGalaxy` migratie.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Omdat migraties in volgorde worden uitgevoerd, en `CreateStar` verwijst naar het schema van de melkwegstelsels, is volgorde belangrijk. Tenslotte, [voer de migraties uit](#migrate) om de database voor te bereiden.

Voeg een route toe voor het maken van nieuwe sterren.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Maak een nieuwe ster die verwijst naar de eerder gemaakte galaxy met het volgende HTTP-verzoek.

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

Je zou de nieuw aangemaakte ster terug moeten zien met een unieke identificatie.

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

Laten we nu eens kijken hoe je Fluent's eager-loading functie kunt gebruiken om automatisch de sterren van een sterrenstelsel te retourneren in de `GET /galaxies` route. Voeg de volgende eigenschap toe aan het `Galaxy` model.

```swift
// Alle sterren in dit heelal.
@Children(for: \.$galaxy)
var stars: [Star]
```

De `@Children` eigenschap wrapper is de inverse van `@Parent`. Het neemt een sleutel-pad naar het `@Parent` veld van het child als het `for` argument. De waarde is een array van children omdat er nul of meer child modellen kunnen bestaan. Er zijn geen wijzigingen nodig in de migratie van het sterrenstelsel omdat alle informatie die nodig is voor deze relatie is opgeslagen op `Star`.

### Eager Load

Nu de relatie compleet is, kun je de `with` methode op de query bouwer gebruiken om automatisch de galaxy-ster relatie op te halen en te serialiseren.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Een sleutel-pad naar de `@Children` relatie wordt doorgegeven aan `with` om Fluent te vertellen dat deze relatie automatisch wordt geladen in alle resulterende modellen. Bouw en draai het programma en stuur nog een verzoek naar `GET /galaxies`. U zou nu de sterren automatisch in het antwoord moeten zien.

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

## Volgende stappen

Gefeliciteerd met het maken van uw eerste modellen en migraties en het uitvoeren van basis create en read operaties. Voor meer diepgaande informatie over al deze functies, bekijk hun respectievelijke secties in de Fluent handleiding.
