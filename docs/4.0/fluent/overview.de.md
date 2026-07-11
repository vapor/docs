# Fluent

Fluent ist ein [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping)-Framework für Swift. Es nutzt Swifts starkes Typsystem, um eine einfach zu verwendende Schnittstelle für deine Datenbank bereitzustellen. Die Verwendung von Fluent dreht sich um die Erstellung von Modelltypen, die Datenstrukturen in deiner Datenbank repräsentieren. Diese Modelle werden anschließend verwendet, um Create-, Read-, Update- und Delete-Operationen auszuführen, anstatt rohe Abfragen zu schreiben.

## Konfiguration

Wenn du ein Projekt mit `vapor new` erstellst, antworte mit "yes", um Fluent einzuschließen, und wähle, welchen Datenbank-Treiber du verwenden möchtest. Dadurch werden die Abhängigkeiten sowie Beispielkonfigurationscode automatisch zu deinem neuen Projekt hinzugefügt.

### Bestehendes Projekt

Wenn du ein bestehendes Projekt hast, dem du Fluent hinzufügen möchtest, musst du zwei Abhängigkeiten zu deinem [Package](../getting-started/spm.md) hinzufügen:

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Einen (oder mehrere) Fluent-Treiber deiner Wahl

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

Sobald die Packages als Abhängigkeiten hinzugefügt wurden, kannst du deine Datenbanken mit `app.databases` in `configure.swift` konfigurieren.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Jeder der folgenden Fluent-Treiber hat genauere Anweisungen zur Konfiguration.

### Treiber

Fluent bietet derzeit vier offiziell unterstützte Treiber. Du kannst auf GitHub nach dem Tag [`fluent-driver`](https://github.com/topics/fluent-driver) suchen, um eine vollständige Liste offizieller und von Drittanbietern stammender Fluent-Datenbanktreiber zu erhalten.

#### PostgreSQL

PostgreSQL ist eine quelloffene, standardkonforme SQL-Datenbank. Sie lässt sich bei den meisten Cloud-Hosting-Anbietern leicht konfigurieren. Dies ist Fluents **empfohlener** Datenbank-Treiber.

Um PostgreSQL zu verwenden, füge die folgenden Abhängigkeiten zu deinem Package hinzu.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Sobald die Abhängigkeiten hinzugefügt wurden, konfiguriere die Zugangsdaten der Datenbank mit Fluent, indem du `app.databases.use` in `configure.swift` verwendest.

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

Du kannst die Zugangsdaten auch aus einem Datenbank-Connection-String auslesen.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite ist eine quelloffene, eingebettete SQL-Datenbank. Ihre einfache Natur macht sie zu einem hervorragenden Kandidaten für Prototyping und Tests.

Um SQLite zu verwenden, füge die folgenden Abhängigkeiten zu deinem Package hinzu.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Sobald die Abhängigkeiten hinzugefügt wurden, konfiguriere die Datenbank mit Fluent, indem du `app.databases.use` in `configure.swift` verwendest.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Du kannst SQLite auch so konfigurieren, dass die Datenbank flüchtig im Arbeitsspeicher gespeichert wird.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Wenn du eine In-Memory-Datenbank verwendest, stelle sicher, dass du Fluent so einstellst, dass es automatisch migriert, indem du `--auto-migrate` verwendest oder `app.autoMigrate()` aufrufst, nachdem du Migrationen hinzugefügt hast.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip
    Die SQLite-Konfiguration aktiviert automatisch Fremdschlüsselbeschränkungen (foreign key constraints) auf allen erstellten Verbindungen, ändert aber nicht die Fremdschlüsselkonfigurationen in der Datenbank selbst. Das direkte Löschen von Datensätzen in einer Datenbank könnte Fremdschlüsselbeschränkungen und Trigger verletzen.

#### MySQL

MySQL ist eine populäre quelloffene SQL-Datenbank. Sie ist bei vielen Cloud-Hosting-Anbietern verfügbar. Dieser Treiber unterstützt auch MariaDB.

Um MySQL zu verwenden, füge die folgenden Abhängigkeiten zu deinem Package hinzu.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Sobald die Abhängigkeiten hinzugefügt wurden, konfiguriere die Zugangsdaten der Datenbank mit Fluent, indem du `app.databases.use` in `configure.swift` verwendest.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Du kannst die Zugangsdaten auch aus einem Datenbank-Connection-String auslesen.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Um eine lokale Verbindung ohne beteiligtes SSL-Zertifikat zu konfigurieren, solltest du die Zertifikatsprüfung deaktivieren. Das könnte beispielsweise nötig sein, wenn du dich mit einer MySQL-8-Datenbank in Docker verbindest.

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
    Deaktiviere die Zertifikatsprüfung nicht in der Produktion. Du solltest der `TLSConfiguration` ein Zertifikat bereitstellen, gegen das geprüft werden kann. 

#### MongoDB

MongoDB ist eine populäre schemalose NoSQL-Datenbank, die für Programmierer entwickelt wurde. Der Treiber unterstützt alle Cloud-Hosting-Anbieter sowie selbst gehostete Installationen ab Version 3.4 aufwärts.

!!! note
    Dieser Treiber wird von einem community-erstellten und -gepflegten MongoDB-Client namens [MongoKitten](https://github.com/OpenKitten/MongoKitten) angetrieben. MongoDB pflegt einen offiziellen Client, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), zusammen mit einer Vapor-Integration, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Um MongoDB zu verwenden, füge die folgenden Abhängigkeiten zu deinem Package hinzu.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Sobald die Abhängigkeiten hinzugefügt wurden, konfiguriere die Zugangsdaten der Datenbank mit Fluent, indem du `app.databases.use` in `configure.swift` verwendest.

Um eine Verbindung herzustellen, übergib einen Connection-String im gängigen MongoDB-[Connection-URI-Format](https://docs.mongodb.com/docs/manual/reference/connection-string/).

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Models

Models repräsentieren feste Datenstrukturen in deiner Datenbank, wie Tabellen oder Collections. Models haben ein oder mehrere Felder, die codierbare (codable) Werte speichern. Alle Models haben außerdem einen eindeutigen Identifier. Property Wrapper werden verwendet, um Identifier und Felder sowie später erwähnte komplexere Zuordnungen zu kennzeichnen. Wirf einen Blick auf das folgende Model, das eine Galaxie repräsentiert.

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"

    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?

    // The Galaxy's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Galaxy.
    init() { }

    // Creates a new Galaxy with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Um ein neues Model zu erstellen, erstelle eine neue Klasse, die `Model` entspricht.

!!! tip
    Es wird empfohlen, Model-Klassen als `final` zu kennzeichnen, um die Performance zu verbessern und die Anforderungen an die Konformität zu vereinfachen.

Die erste Anforderung des `Model`-Protokolls ist die statische Zeichenkette `schema`.

```swift
static let schema = "galaxies"
```

Diese Eigenschaft teilt Fluent mit, welcher Tabelle oder Collection das Model entspricht. Dies kann eine Tabelle sein, die bereits in der Datenbank existiert, oder eine, die du mit einer [Migration](#migrations) erstellen wirst. Das Schema ist üblicherweise `snake_case` und im Plural.

### Identifier

Die nächste Anforderung ist ein Identifier-Feld namens `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Dieses Feld muss den `@ID`-Property-Wrapper verwenden. Fluent empfiehlt die Verwendung von `UUID` und dem speziellen `.id`-Feldschlüssel, da dies mit allen Fluent-Treibern kompatibel ist.

Wenn du einen benutzerdefinierten ID-Schlüssel oder -Typ verwenden möchtest, nutze die Überladung [`@ID(custom:)`](model.md#custom-identifier).

### Felder

Nachdem der Identifier hinzugefügt wurde, kannst du beliebig viele Felder hinzufügen, um zusätzliche Informationen zu speichern. In diesem Beispiel ist das einzige zusätzliche Feld der Name der Galaxie.

```swift
@Field(key: "name")
var name: String
```

Für einfache Felder wird der `@Field`-Property-Wrapper verwendet. Wie bei `@ID` gibt der Parameter `key` den Namen des Feldes in der Datenbank an. Das ist besonders nützlich in Fällen, in denen die Namenskonvention der Datenbankfelder von der in Swift abweicht, z. B. wenn `snake_case` anstelle von `camelCase` verwendet wird.

Als Nächstes benötigen alle Models einen leeren Init. Dies ermöglicht es Fluent, neue Instanzen des Models zu erstellen.

```swift
init() { }
```

Abschließend kannst du einen komfortablen Init für dein Model hinzufügen, der alle seine Eigenschaften setzt.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Die Verwendung komfortabler Inits ist besonders hilfreich, wenn du deinem Model neue Eigenschaften hinzufügst, da du dann Compile-Zeit-Fehler erhältst, falls sich die Init-Methode ändert.

## Migrationen

Wenn deine Datenbank vordefinierte Schemas verwendet, wie SQL-Datenbanken, benötigst du eine Migration, um die Datenbank für dein Model vorzubereiten. Migrationen sind außerdem nützlich, um Datenbanken mit Daten zu befüllen (seeding). Um eine Migration zu erstellen, definiere einen neuen Typ, der dem `Migration`- oder `AsyncMigration`-Protokoll entspricht. Wirf einen Blick auf die folgende Migration für das zuvor definierte `Galaxy`-Model.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

Die Methode `prepare` wird verwendet, um die Datenbank auf das Speichern von `Galaxy`-Models vorzubereiten.

### Schema

In dieser Methode wird `database.schema(_:)` verwendet, um einen neuen `SchemaBuilder` zu erstellen. Ein oder mehrere `field`s werden dann dem Builder hinzugefügt, bevor `create()` aufgerufen wird, um das Schema zu erstellen.

Jedes dem Builder hinzugefügte Feld hat einen Namen, einen Typ und optionale Constraints.

```swift
field(<name>, <type>, <optional constraints>)
```

Es gibt eine komfortable `id()`-Methode zum Hinzufügen von `@ID`-Eigenschaften unter Verwendung von Fluents empfohlenen Standardwerten.

Das Zurücksetzen der Migration macht alle in der `prepare`-Methode vorgenommenen Änderungen rückgängig. In diesem Fall bedeutet das, das Schema der Galaxie zu löschen.

Sobald die Migration definiert ist, musst du Fluent darüber informieren, indem du sie zu `app.migrations` in `configure.swift` hinzufügst.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrieren

Um Migrationen auszuführen, rufe `swift run App migrate` über die Kommandozeile auf oder füge `migrate` als Argument zu Xcodes App-Schema hinzu.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Abfragen

Nachdem du erfolgreich ein Model erstellt und deine Datenbank migriert hast, bist du bereit, deine erste Abfrage zu erstellen.

### Alle

Wirf einen Blick auf die folgende Route, die ein Array aller Galaxien in der Datenbank zurückgibt.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Um eine Galaxy direkt in einer Route-Closure zurückzugeben, füge Konformität zu `Content` hinzu.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` wird verwendet, um einen neuen Query-Builder für das Model zu erstellen. `req.db` ist eine Referenz auf die Standarddatenbank deiner Anwendung. Schließlich gibt `all()` alle in der Datenbank gespeicherten Models zurück.

Wenn du das Projekt kompilierst, ausführst und `GET /galaxies` anfragst, solltest du ein leeres Array zurückerhalten. Lass uns eine Route zum Erstellen einer neuen Galaxie hinzufügen.

### Erstellen


Der RESTful-Konvention folgend, verwende den Endpunkt `POST /galaxies` zum Erstellen einer neuen Galaxie. Da Models codierbar (codable) sind, kannst du eine Galaxy direkt aus dem Anfrage-Body decodieren.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    Siehe [Modelbindung &rarr; Übersicht](../basics/content.md) für weitere Informationen zum Decodieren von Anfrage-Bodys.

Sobald du eine Instanz des Models hast, speichert der Aufruf von `create(on:)` das Model in der Datenbank. Dies gibt ein `EventLoopFuture<Void>` zurück, das signalisiert, dass das Speichern abgeschlossen wurde. Sobald das Speichern abgeschlossen ist, gib das neu erstellte Model mit `map` zurück.

Wenn du `async`/`await` verwendest, kannst du deinen Code so schreiben:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

In diesem Fall gibt die async-Version nichts zurück, kehrt aber erst zurück, nachdem das Speichern abgeschlossen wurde.

Baue und starte das Projekt und sende die folgende Anfrage.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Du solltest das erstellte Model mit einem Identifier als Antwort zurückerhalten.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Wenn du nun erneut `GET /galaxies` abfragst, solltest du die neu erstellte Galaxie im zurückgegebenen Array sehen.


## Beziehungen

Was wären Galaxien ohne Sterne! Werfen wir einen kurzen Blick auf Fluents mächtige relationale Funktionen, indem wir eine Eins-zu-viele-Beziehung zwischen `Galaxy` und einem neuen `Star`-Model hinzufügen.

```swift
final class Star: Model, Content {
    // Name of the table or collection.
    static let schema = "stars"

    // Unique identifier for this Star.
    @ID(key: .id)
    var id: UUID?

    // The Star's name.
    @Field(key: "name")
    var name: String

    // Reference to the Galaxy this Star is in.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creates a new, empty Star.
    init() { }

    // Creates a new Star with all properties set.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

Das neue `Star`-Model ist dem `Galaxy`-Model sehr ähnlich, abgesehen von einem neuen Feldtyp: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

Die Parent-Eigenschaft ist ein Feld, das den Identifier eines anderen Models speichert. Das Model, das die Referenz hält, wird "Child" genannt, und das referenzierte Model wird "Parent" genannt. Diese Art von Beziehung ist auch als "Eins-zu-viele" bekannt. Der `key`-Parameter der Eigenschaft gibt den Feldnamen an, der verwendet werden soll, um den Schlüssel des Parents in der Datenbank zu speichern.

In der Init-Methode wird der Parent-Identifier mit `$galaxy` gesetzt.

```swift
self.$galaxy.id = galaxyID
```

Indem du der Parent-Eigenschaft den Namen mit `$` voranstellst, greifst du auf den zugrunde liegenden Property Wrapper zu. Dies ist erforderlich, um Zugriff auf das interne `@Field` zu erhalten, das den tatsächlichen Identifier-Wert speichert.

!!! seealso
    Schau dir den Swift-Evolution-Vorschlag für Property Wrapper an, um mehr Informationen zu erhalten: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

Erstelle als Nächstes eine Migration, um die Datenbank für die Verarbeitung von `Star` vorzubereiten.


```swift
struct CreateStar: AsyncMigration {
    // Prepares the database for storing Star models.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Dies ist größtenteils dasselbe wie die Migration der Galaxie, abgesehen von dem zusätzlichen Feld zum Speichern des Identifiers der Parent-Galaxie.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Dieses Feld gibt ein optionales Constraint an, das der Datenbank mitteilt, dass der Wert des Feldes auf das Feld "id" im Schema "galaxies" verweist. Dies wird auch als Fremdschlüssel bezeichnet und hilft, die Datenintegrität sicherzustellen.

Sobald die Migration erstellt ist, füge sie nach der `CreateGalaxy`-Migration zu `app.migrations` hinzu.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Da Migrationen der Reihe nach ausgeführt werden und `CreateStar` auf das galaxies-Schema verweist, ist die Reihenfolge wichtig. Führe abschließend [die Migrationen aus](#migrate), um die Datenbank vorzubereiten.

Füge eine Route zum Erstellen neuer Sterne hinzu.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Erstelle einen neuen Stern, der auf die zuvor erstellte Galaxie verweist, mit der folgenden HTTP-Anfrage.

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

Du solltest den neu erstellten Stern mit einem eindeutigen Identifier zurückerhalten.

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

Schauen wir uns nun an, wie du Fluents Eager-Loading-Funktion nutzen kannst, um die Sterne einer Galaxie automatisch in der Route `GET /galaxies` zurückzugeben. Füge die folgende Eigenschaft zum `Galaxy`-Model hinzu.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

Der `@Children`-Property-Wrapper ist das Gegenstück zu `@Parent`. Er nimmt einen Key-Path zum `@Parent`-Feld des Childs als `for`-Argument. Sein Wert ist ein Array von Children, da null oder mehr Child-Models existieren können. Es sind keine Änderungen an der Migration der Galaxie nötig, da alle für diese Beziehung benötigten Informationen bei `Star` gespeichert sind.

### Eager Load

Nun, da die Beziehung vollständig ist, kannst du die Methode `with` auf dem Query-Builder verwenden, um die Galaxie-Stern-Beziehung automatisch abzurufen und zu serialisieren.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Ein Key-Path zur `@Children`-Beziehung wird an `with` übergeben, um Fluent mitzuteilen, dass diese Beziehung in allen resultierenden Models automatisch geladen werden soll. Baue und starte das Projekt und sende eine weitere Anfrage an `GET /galaxies`. Du solltest die Sterne nun automatisch in der Antwort enthalten sehen.

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

## Query-Protokollierung

Die Fluent-Treiber protokollieren das generierte SQL auf der Debug-Protokollierungsebene. Manche Treiber, wie FluentPostgreSQL, erlauben es, dies bei der Konfiguration der Datenbank einzustellen.

Um die Protokollierungsebene festzulegen, füge in **configure.swift** (oder wo auch immer du deine Anwendung einrichtest) Folgendes hinzu:

```swift
app.logger.logLevel = .debug
```

Dies setzt die Protokollierungsebene auf debug. Wenn du deine App das nächste Mal baust und ausführst, werden die von Fluent generierten SQL-Anweisungen in der Konsole protokolliert.

## Nächste Schritte

Herzlichen Glückwunsch zur Erstellung deiner ersten Models und Migrationen sowie zur Ausführung grundlegender Create- und Read-Operationen. Für ausführlichere Informationen zu all diesen Funktionen, schau dir die jeweiligen Abschnitte im Fluent-Leitfaden an.
