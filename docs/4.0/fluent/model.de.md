# Models

Models repräsentieren Daten, die in Tabellen oder Collections deiner Datenbank gespeichert werden. Models haben ein oder mehrere Felder, die codierbare (codable) Werte speichern. Alle Models haben einen eindeutigen Identifier. Property Wrapper werden verwendet, um Identifier, Felder und Beziehungen zu kennzeichnen.

Im Folgenden siehst du ein Beispiel für ein einfaches Model mit einem Feld. Beachte, dass Models nicht das gesamte Datenbankschema beschreiben, wie zum Beispiel Constraints, Indizes und Fremdschlüssel. Schemas werden in [Migrationen](migration.md) definiert. Models konzentrieren sich darauf, die in deinen Datenbankschemas gespeicherten Daten zu repräsentieren.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"

    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?

    // The Planet's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Planet.
    init() { }

    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## Schema

Alle Models benötigen eine statische, nur lesbare Eigenschaft `schema`. Diese Zeichenkette referenziert den Namen der Tabelle oder Collection, die dieses Model repräsentiert.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"
}
```

Beim Abfragen dieses Models werden Daten aus dem mit `"planets"` benannten Schema abgerufen und dort gespeichert.

!!! tip
    Der Schema-Name ist üblicherweise der Klassenname im Plural und in Kleinbuchstaben.

## Identifier

Alle Models müssen eine `id`-Eigenschaft besitzen, die mit dem `@ID`-Property-Wrapper definiert ist. Dieses Feld identifiziert Instanzen deines Models eindeutig.

```swift
final class Planet: Model {
    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?
}
```

Standardmäßig sollte die `@ID`-Eigenschaft den speziellen Schlüssel `.id` verwenden, der sich zu einem passenden Schlüssel für den zugrunde liegenden Datenbanktreiber auflöst. Für SQL ist das `"id"` und für NoSQL `"_id"`.

Die `@ID` sollte außerdem vom Typ `UUID` sein. Dies ist derzeit der einzige Identifier-Wert, der von allen Datenbanktreibern unterstützt wird. Fluent generiert beim Erstellen von Models automatisch neue UUID-Identifier.

`@ID` hat einen optionalen Wert, da noch nicht gespeicherte Models möglicherweise noch keinen Identifier besitzen. Um den Identifier zu erhalten oder einen Fehler zu werfen, verwende `requireID`.

```swift
let id = try planet.requireID()
```

### Exists

`@ID` besitzt eine Eigenschaft `exists`, die angibt, ob das Model in der Datenbank existiert oder nicht. Beim Initialisieren eines Models ist der Wert `false`. Nachdem du ein Model gespeichert hast oder wenn du ein Model aus der Datenbank abrufst, ist der Wert `true`. Diese Eigenschaft ist veränderbar.

```swift
if planet.$id.exists {
    // This model exists in database.
}
```

### Custom Identifier

Fluent unterstützt benutzerdefinierte Identifier-Schlüssel und -Typen über die Überladung `@ID(custom:)`.

```swift
final class Planet: Model {
    // Unique identifier for this Planet.
    @ID(custom: "foo")
    var id: Int?
}
```

Das obige Beispiel verwendet eine `@ID` mit dem benutzerdefinierten Schlüssel `"foo"` und dem Identifier-Typ `Int`. Dies ist mit SQL-Datenbanken kompatibel, die automatisch inkrementierende Primärschlüssel verwenden, aber nicht mit NoSQL kompatibel.

Mit benutzerdefinierten `@ID`s kann der Nutzer über den Parameter `generatedBy` festlegen, wie der Identifier generiert werden soll.

```swift
@ID(custom: "foo", generatedBy: .user)
```

Der Parameter `generatedBy` unterstützt die folgenden Fälle:

|Generiert von|Beschreibung|
|-|-|
|`.user`|Es wird erwartet, dass die `@ID`-Eigenschaft vor dem Speichern eines neuen Models gesetzt wird.|
|`.random`|Der Werttyp von `@ID` muss `RandomGeneratable` entsprechen.|
|`.database`|Es wird erwartet, dass die Datenbank beim Speichern einen Wert generiert.|

Wenn der Parameter `generatedBy` weggelassen wird, versucht Fluent, anhand des Werttyps von `@ID` einen passenden Fall abzuleiten. `Int` verwendet beispielsweise standardmäßig die `.database`-Generierung, sofern nichts anderes angegeben ist.

## Initialisierer

Models müssen über eine leere Initialisierer-Methode verfügen.

```swift
final class Planet: Model {
    // Creates a new, empty Planet.
    init() { }
}
```

Fluent benötigt diese Methode intern, um Models zu initialisieren, die von Abfragen zurückgegeben werden. Sie wird außerdem für Reflection verwendet.

Du solltest deinem Model eventuell einen komfortablen Initialisierer hinzufügen, der alle Eigenschaften akzeptiert.

```swift
final class Planet: Model {
    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Die Verwendung komfortabler Initialisierer erleichtert es, dem Model in Zukunft neue Eigenschaften hinzuzufügen.

## Feld

Models können null oder mehr `@Field`-Eigenschaften zum Speichern von Daten besitzen.

```swift
final class Planet: Model {
    // The Planet's name.
    @Field(key: "name")
    var name: String
}
```

Bei Feldern muss der Datenbankschlüssel explizit definiert werden. Dieser muss nicht mit dem Namen der Eigenschaft übereinstimmen.

!!! tip
    Fluent empfiehlt, für Datenbankschlüssel `snake_case` und für Eigenschaftsnamen `camelCase` zu verwenden.

Feldwerte können jeden Typ haben, der `Codable` entspricht. Das Speichern verschachtelter Strukturen und Arrays in `@Field` wird unterstützt, aber Filteroperationen sind eingeschränkt. Eine Alternative findest du unter [`@Group`](#group).

Verwende für Felder mit einem optionalen Wert `@OptionalField`.

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! warning
    Ein nicht-optionales Feld mit einem `willSet`-Property-Observer, der auf seinen aktuellen Wert verweist, oder einem `didSet`-Property-Observer, der auf sein `oldValue` verweist, führt zu einem Fatal Error.

## Beziehungen

Models können null oder mehr Beziehungs-Eigenschaften besitzen, die auf andere Models verweisen, wie `@Parent`, `@Children` und `@Siblings`. Mehr über Beziehungen erfährst du im Abschnitt [Beziehungen](relations.md).

## Timestamp

`@Timestamp` ist ein spezieller Typ von `@Field`, der ein `Foundation.Date` speichert. Timestamps werden von Fluent automatisch gemäß dem gewählten Trigger gesetzt.

```swift
final class Planet: Model {
    // When this Planet was created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // When this Planet was last updated.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp` unterstützt die folgenden Trigger.

|Trigger|Beschreibung|
|-|-|
|`.create`|Wird gesetzt, wenn eine neue Model-Instanz in der Datenbank gespeichert wird.|
|`.update`|Wird gesetzt, wenn eine bestehende Model-Instanz in der Datenbank gespeichert wird.|
|`.delete`|Wird gesetzt, wenn ein Model aus der Datenbank gelöscht wird. Siehe [Soft-Delete](#soft-delete).|

Der Datumswert von `@Timestamp` ist optional und sollte beim Initialisieren eines neuen Models auf `nil` gesetzt werden.

### Timestamp-Format

Standardmäßig verwendet `@Timestamp` eine effiziente `datetime`-Kodierung, die auf deinem Datenbanktreiber basiert. Du kannst mit dem Parameter `format` anpassen, wie der Timestamp in der Datenbank gespeichert wird.

```swift
// Stores an ISO 8601 formatted timestamp representing
// when this model was last updated.
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

Beachte, dass die zugehörige Migration für dieses `.iso8601`-Beispiel eine Speicherung im Format `.string` erfordern würde.

```swift
.field("updated_at", .string)
```

Die verfügbaren Timestamp-Formate sind unten aufgelistet.

|Format|Beschreibung|Typ|
|-|-|-|
|`.default`|Verwendet eine effiziente `datetime`-Kodierung für die jeweilige Datenbank.|Date|
|`.iso8601`|[ISO 8601](https://en.wikipedia.org/wiki/ISO_8601)-Zeichenkette. Unterstützt den Parameter `withMilliseconds`.|String|
|`.unix`|Sekunden seit der Unix-Epoche einschließlich Bruchteil.|Double|

Du kannst über die Eigenschaft `timestamp` direkt auf den rohen Timestamp-Wert zugreifen.

```swift
// Manually set the timestamp value on this ISO 8601
// formatted @Timestamp.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### Soft-Delete

Das Hinzufügen eines `@Timestamp`, der den `.delete`-Trigger verwendet, zu deinem Model aktiviert Soft-Delete.

```swift
final class Planet: Model {
    // When this Planet was deleted.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

Soft-gelöschte Models existieren nach dem Löschen weiterhin in der Datenbank, werden aber nicht in Abfragen zurückgegeben.

!!! tip
    Du kannst einen On-Delete-Timestamp manuell auf ein Datum in der Zukunft setzen. Dies kann als Ablaufdatum verwendet werden.

Um ein Soft-löschbares Model zwangsweise aus der Datenbank zu entfernen, verwende den Parameter `force` in `delete`.

```swift
// Deletes from the database even if the model 
// is soft deletable. 
model.delete(force: true, on: database)
```

Um ein Soft-gelöschtes Model wiederherzustellen, verwende die Methode `restore`.

```swift
// Clears the on delete timestamp allowing this 
// model to be returned in queries. 
model.restore(on: database)
```

Um Soft-gelöschte Models in eine Abfrage einzubeziehen, verwende `withDeleted`.

```swift
// Fetches all planets including soft deleted.
Planet.query(on: database).withDeleted().all()
```

## Enum

`@Enum` ist ein spezieller Typ von `@Field` zum Speichern von string-repräsentierbaren Typen als native Datenbank-Enums. Native Datenbank-Enums bieten deiner Datenbank eine zusätzliche Ebene an Typsicherheit und können performanter sein als rohe Enums.

```swift
// String representable, Codable enum for animal types.
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // Stores type of animal as a native database enum.
    @Enum(key: "type")
    var type: Animal
}
```

Nur Typen, die `RawRepresentable` entsprechen und deren `RawValue` `String` ist, sind mit `@Enum` kompatibel. Enums mit `String`-Rohwerten erfüllen diese Anforderung standardmäßig.

Verwende `@OptionalEnum`, um ein optionales Enum zu speichern.

Die Datenbank muss über eine Migration darauf vorbereitet werden, Enums zu verarbeiten. Weitere Informationen findest du unter [Enum](schema.md#enum).

### Rohe Enums

Jedes Enum mit einem `Codable`-Rohwerttyp, wie `String` oder `Int`, kann in `@Field` gespeichert werden. Es wird als Rohwert in der Datenbank gespeichert.

## Gruppe

Mit `@Group` kannst du eine verschachtelte Gruppe von Feldern als einzelne Eigenschaft in deinem Model speichern. Anders als Codable-Structs, die in einem `@Field` gespeichert werden, sind die Felder in einer `@Group` abfragbar. Fluent erreicht dies, indem `@Group` als flache Struktur in der Datenbank gespeichert wird.

Um eine `@Group` zu verwenden, definiere zunächst die verschachtelte Struktur, die du mithilfe des `Fields`-Protokolls speichern möchtest. Dies ist `Model` sehr ähnlich, außer dass kein Identifier oder Schema-Name erforderlich ist. Du kannst hier viele Eigenschaften speichern, die `Model` unterstützt, wie `@Field`, `@Enum` oder sogar eine weitere `@Group`.

```swift
// A pet with name and animal type.
final class Pet: Fields {
    // The pet's name.
    @Field(key: "name")
    var name: String

    // The type of pet. 
    @Field(key: "type")
    var type: String

    // Creates a new, empty Pet.
    init() { }
}
```

Nachdem du die Felddefinition erstellt hast, kannst du sie als Wert einer `@Group`-Eigenschaft verwenden.

```swift
final class User: Model {
    // The user's nested pet.
    @Group(key: "pet")
    var pet: Pet
}
```

Auf die Felder einer `@Group` kann über Punkt-Syntax zugegriffen werden.

```swift
let user: User = ...
print(user.pet.name) // String
```

Du kannst verschachtelte Felder wie gewohnt über Punkt-Syntax auf den Property Wrappern abfragen.

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

In der Datenbank wird `@Group` als flache Struktur gespeichert, deren Schlüssel mit `_` verbunden sind. Im Folgenden siehst du ein Beispiel, wie `User` in der Datenbank aussehen würde.

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

Models entsprechen standardmäßig `Codable`. Das bedeutet, dass du deine Models mit Vapors [Content-API](../basics/content.md) verwenden kannst, indem du Konformität zum `Content`-Protokoll hinzufügst.

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // Return an array of all planets.
    try await Planet.query(on: req.db).all()
}
```

Beim Serialisieren zu bzw. von `Codable` verwenden Model-Eigenschaften ihre Variablennamen anstelle der Schlüssel. Beziehungen werden als verschachtelte Strukturen serialisiert, und alle per Eager Loading geladenen Daten werden einbezogen.

!!! info
    Wir empfehlen, dass du für nahezu alle Fälle ein DTO anstelle eines Models für deine API-Antworten und Anfrage-Bodys verwendest. Weitere Informationen findest du unter [Data Transfer Object](#data-transfer-object).

### Data Transfer Object

Die standardmäßige `Codable`-Konformität von Models kann die einfache Verwendung und das Prototyping erleichtern. Allerdings legt sie die zugrunde liegenden Datenbankinformationen gegenüber der API offen. Das ist in der Regel weder aus Sicherheitssicht wünschenswert - die Rückgabe sensibler Felder wie dem Passwort-Hash eines Nutzers ist keine gute Idee - noch aus Sicht der Benutzerfreundlichkeit. Es erschwert es, das Datenbankschema zu ändern, ohne die API zu brechen, Daten in einem anderen Format zu akzeptieren oder zurückzugeben, oder Felder zur API hinzuzufügen oder daraus zu entfernen.

In den meisten Fällen solltest du ein DTO bzw. Data Transfer Object anstelle eines Models verwenden (dies ist auch als Domain Transfer Object bekannt). Ein DTO ist ein separater `Codable`-Typ, der die Datenstruktur repräsentiert, die du kodieren oder dekodieren möchtest. Dadurch wird deine API von deinem Datenbankschema entkoppelt, sodass du Änderungen an deinen Models vornehmen kannst, ohne die öffentliche API deiner App zu brechen, unterschiedliche Versionen haben und deine API für deine Clients angenehmer nutzbar machen kannst.

Gehe in den folgenden Beispielen von dem folgenden `User`-Model aus.

```swift
// Abridged user model for reference.
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

Ein häufiger Anwendungsfall für DTOs ist die Implementierung von `PATCH`-Anfragen. Diese Anfragen enthalten nur Werte für Felder, die aktualisiert werden sollen. Der Versuch, ein `Model` direkt aus einer solchen Anfrage zu dekodieren, würde fehlschlagen, wenn eines der erforderlichen Felder fehlt. Im folgenden Beispiel siehst du, wie ein DTO verwendet wird, um Anfragedaten zu dekodieren und ein Model zu aktualisieren.

```swift
// Structure of PATCH /users/:id request.
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // Decode the request data.
    let patch = try req.content.decode(PatchUser.self)
    // Fetch the desired user from the database.
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // If first name was supplied, update it.
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // If new last name was supplied, update it.
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // Save the user and return it.
    try await user.save(on: req.db)
    return user
}
```

Ein weiterer häufiger Anwendungsfall für DTOs ist das Anpassen des Formats deiner API-Antworten. Das folgende Beispiel zeigt, wie ein DTO verwendet werden kann, um einer Antwort ein berechnetes Feld hinzuzufügen.

```swift
// Structure of GET /users response.
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // Fetch all users from the database.
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // Convert each user to GET return type.
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

Ein weiterer häufiger Anwendungsfall ist der Umgang mit Beziehungen, wie Parent- oder Children-Beziehungen. Ein Beispiel dafür, wie du ein DTO verwenden kannst, um ein Model mit einer `@Parent`-Beziehung einfach zu dekodieren, findest du in der [Parent-Dokumentation](relations.md#encoding-and-decoding-of-parents).

Selbst wenn die Struktur des DTOs identisch mit der `Codable`-Konformität des Models ist, kann es helfen, große Projekte übersichtlich zu halten, wenn es als separater Typ vorliegt. Wenn du jemals eine Änderung an den Eigenschaften deiner Models vornehmen musst, brauchst du dir keine Sorgen zu machen, die öffentliche API deiner App zu brechen. Du könntest außerdem in Erwägung ziehen, deine DTOs in ein separates Package zu packen, das mit Konsumenten deiner API geteilt werden kann, und `Content`-Konformität in deiner Vapor-App hinzuzufügen.

## Alias

Mit dem Protokoll `ModelAlias` kannst du ein Model, das mehrfach in einer Abfrage verknüpft wird, eindeutig identifizieren. Weitere Informationen findest du unter [Joins](query.md#join).

## Speichern

Um ein Model in der Datenbank zu speichern, verwende die Methode `save(on:)`.

```swift
planet.save(on: database)
```

Diese Methode ruft intern `create` oder `update` auf, je nachdem, ob das Model bereits in der Datenbank existiert.

### Erstellen

Du kannst die Methode `create` aufrufen, um ein neues Model in der Datenbank zu speichern.

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` ist auch für ein Array von Models verfügbar. Dadurch werden alle Models in einem einzigen Batch bzw. einer einzigen Abfrage in der Datenbank gespeichert.

```swift
// Example of batch create.
[earth, mars].create(on: database)
```

!!! warning
    Bei Models, die [`@ID(custom:)`](#custom-identifier) mit dem `.database`-Generator verwenden (üblicherweise automatisch inkrementierende `Int`s), sind die neu erstellten Identifier nach einem Batch-Create nicht zugänglich. Rufe für Situationen, in denen du auf die Identifier zugreifen musst, `create` für jedes Model einzeln auf.

Um ein Array von Models einzeln zu erstellen, verwende `map` + `flatten`.

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

Wenn du `async`/`await` verwendest, kannst du Folgendes verwenden:

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### Aktualisieren

Du kannst die Methode `update` aufrufen, um ein Model zu speichern, das aus der Datenbank abgerufen wurde.

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

Um ein Array von Models zu aktualisieren, verwende `map` + `flatten`.

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TOOD
```

## Query

Models stellen eine statische Methode `query(on:)` bereit, die einen Query-Builder zurückgibt.

```swift
Planet.query(on: database).all()
```

Mehr über das Abfragen erfährst du im Abschnitt [Query](query.md).

## Finden

Models besitzen eine statische Methode `find(_:on:)`, um eine Model-Instanz anhand ihres Identifiers nachzuschlagen.

```swift
Planet.find(req.parameters.get("id"), on: database)
```

Diese Methode gibt `nil` zurück, wenn kein Model mit diesem Identifier gefunden wurde.

## Lifecycle

Mit Model-Middleware kannst du dich in die Lebenszyklus-Ereignisse deines Models einklinken. Die folgenden Lebenszyklus-Ereignisse werden unterstützt.

|Methode|Beschreibung|
|-|-|
|`create`|Wird ausgeführt, bevor ein Model erstellt wird.|
|`update`|Wird ausgeführt, bevor ein Model aktualisiert wird.|
|`delete(force:)`|Wird ausgeführt, bevor ein Model gelöscht wird.|
|`softDelete`|Wird ausgeführt, bevor ein Model Soft-gelöscht wird.|
|`restore`|Wird ausgeführt, bevor ein Model wiederhergestellt wird (das Gegenteil von Soft-Delete).|

Model-Middleware wird mit dem Protokoll `ModelMiddleware` oder `AsyncModelMiddleware` deklariert. Alle Lebenszyklus-Methoden verfügen über eine Standardimplementierung, sodass du nur die Methoden implementieren musst, die du benötigst. Jede Methode erhält das betreffende Model, eine Referenz auf die Datenbank und die nächste Aktion in der Kette. Die Middleware kann sich dafür entscheiden, frühzeitig zurückzukehren, ein fehlgeschlagenes Future zurückzugeben oder die nächste Aktion aufzurufen, um normal fortzufahren.

Mit diesen Methoden kannst du Aktionen sowohl vor als auch nach dem Abschluss des jeweiligen Ereignisses ausführen. Aktionen nach Abschluss des Ereignisses kannst du ausführen, indem du das vom nächsten Responder zurückgegebene Future mappst.

```swift
// Example middleware that capitalizes names.
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // The model can be altered here before it is created.
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // Once the planet has been created, the code 
            // here will be executed.
            print ("Planet \(model.name) was created")
        }
    }
}
```

oder wenn du `async`/`await` verwendest:

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyAsyncModelResponder) async throws {
        // The model can be altered here before it is created.
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // Once the planet has been created, the code 
        // here will be executed.
        print ("Planet \(model.name) was created")
    }
}
```

Sobald du deine Middleware erstellt hast, kannst du sie mit `app.databases.middleware` aktivieren.

```swift
// Example of configuring model middleware.
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## Datenbank-Space

Fluent unterstützt das Festlegen eines Space für ein Model, wodurch einzelne Fluent-Models auf PostgreSQL-Schemas, MySQL-Datenbanken und mehrere verbundene SQLite-Datenbanken aufgeteilt werden können. MongoDB unterstützt zum Zeitpunkt der Erstellung dieses Textes keine Spaces. Um ein Model in einem anderen Space als dem Standard-Space zu platzieren, füge dem Model eine neue statische Eigenschaft hinzu:

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

Fluent verwendet dies beim Erstellen aller Datenbankabfragen.
