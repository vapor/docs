# Beziehungen

Fluents [Model-API](model.md) hilft dir dabei, Referenzen zwischen deinen Modellen zu erstellen und zu pflegen, indem sie Beziehungen (relations) nutzt. Drei Arten von Beziehungen werden unterstützt:

- [Parent](#parent) / [Child](#optional-child) (Eins-zu-eins)
- [Parent](#parent) / [Children](#children) (Eins-zu-viele)
- [Siblings](#siblings) (Viele-zu-viele)

## Parent

Die `@Parent`-Beziehung speichert eine Referenz auf die `@ID`-Eigenschaft eines anderen Modells.

```swift
final class Planet: Model {
    // Example of a parent relation.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` enthält ein `@Field` mit dem Namen `id`, das zum Setzen und Aktualisieren der Beziehung verwendet wird.

```swift
// Set parent relation id
earth.$star.id = sun.id
```

Der Initialisierer von `Planet` könnte zum Beispiel so aussehen:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

Der Parameter `key` legt den Feld-Schlüssel fest, der zum Speichern der Kennung des Parents verwendet wird. Angenommen, `Star` hat eine `UUID`-Kennung, dann ist diese `@Parent`-Beziehung mit folgender [Felddefinition](schema.md#feld) kompatibel.

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Beachte, dass die [`.references`](schema.md#field-constraint)-Einschränkung optional ist. Weitere Informationen findest du unter [Schema](schema.md).

### Optional Parent

Die `@OptionalParent`-Beziehung speichert eine optionale Referenz auf die `@ID`-Eigenschaft eines anderen Modells. Sie funktioniert ähnlich wie `@Parent`, erlaubt aber, dass die Beziehung `nil` sein kann.

```swift
final class Planet: Model {
    // Example of an optional parent relation.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

Die Felddefinition ähnelt der von `@Parent`, außer dass die `.required`-Einschränkung weggelassen werden sollte.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Enkodierung und Dekodierung von Parents

Eine Sache, auf die du bei der Arbeit mit `@Parent`-Beziehungen achten solltest, ist die Art und Weise, wie du sie sendest und empfängst. Zum Beispiel könnte ein `@Parent` für ein `Planet`-Modell in JSON so aussehen:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

Beachte, dass die Eigenschaft `star` ein Objekt ist und nicht die ID, die du vielleicht erwartest. Wenn du das Modell als HTTP-Body sendest, muss es dieser Struktur entsprechen, damit die Dekodierung funktioniert. Aus diesem Grund empfehlen wir dringend, ein DTO zu verwenden, um das Modell beim Senden über das Netzwerk zu repräsentieren. Zum Beispiel:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

Anschließend kannst du das DTO dekodieren und in ein Modell umwandeln:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

Das Gleiche gilt, wenn du das Modell an Clients zurückgibst. Deine Clients müssen entweder in der Lage sein, die verschachtelte Struktur zu verarbeiten, oder du musst das Modell vor der Rückgabe in ein DTO umwandeln. Weitere Informationen zu DTOs findest du in der [Model-Dokumentation](model.md#data-transfer-object)

## Optional Child

Die `@OptionalChild`-Eigenschaft erstellt eine Eins-zu-eins-Beziehung zwischen zwei Modellen. Sie speichert keine Werte auf dem Wurzelmodell.

```swift
final class Planet: Model {
    // Example of an optional child relation.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

Der Parameter `for` akzeptiert einen Key-Path zu einer `@Parent`- oder `@OptionalParent`-Beziehung, die auf das Wurzelmodell verweist.

Ein neues Modell kann dieser Beziehung mit der Methode `create` hinzugefügt werden.

```swift
// Example of adding a new model to a relation.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Dadurch wird die Parent-ID automatisch im Child-Modell gesetzt.

Da diese Beziehung keine Werte speichert, ist für das Wurzelmodell kein Eintrag im Datenbankschema erforderlich.

Die Eins-zu-eins-Natur der Beziehung sollte im Schema des Child-Modells mithilfe einer `.unique`-Einschränkung auf der Spalte, die auf das Parent-Modell verweist, erzwungen werden.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Example of unique constraint
    .unique(on: "planet_id")
    .create()
```
!!! warning
    Das Weglassen der Eindeutigkeitseinschränkung für das Parent-ID-Feld im Schema des Clients kann zu unvorhersehbaren Ergebnissen führen.
    Ohne Eindeutigkeitseinschränkung kann die Child-Tabelle am Ende mehr als eine Child-Zeile für einen gegebenen Parent enthalten; in diesem Fall kann eine `@OptionalChild`-Eigenschaft trotzdem immer nur auf ein Child gleichzeitig zugreifen, ohne dass gesteuert werden kann, welches Child geladen wird. Falls du für einen gegebenen Parent möglicherweise mehrere Child-Zeilen speichern musst, verwende stattdessen `@Children`.

## Children

Die `@Children`-Eigenschaft erstellt eine Eins-zu-viele-Beziehung zwischen zwei Modellen. Sie speichert keine Werte auf dem Wurzelmodell.

```swift
final class Star: Model {
    // Example of a children relation.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

Der Parameter `for` akzeptiert einen Key-Path zu einer `@Parent`- oder `@OptionalParent`-Beziehung, die auf das Wurzelmodell verweist. In diesem Fall verweisen wir auf die `@Parent`-Beziehung aus dem vorherigen [Beispiel](#parent).

Neue Modelle können dieser Beziehung mit der Methode `create` hinzugefügt werden.

```swift
// Example of adding a new model to a relation.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Dadurch wird die Parent-ID automatisch im Child-Modell gesetzt.

Da diese Beziehung keine Werte speichert, ist kein Eintrag im Datenbankschema erforderlich.

## Siblings

Die `@Siblings`-Eigenschaft erstellt eine Viele-zu-viele-Beziehung zwischen zwei Modellen. Dies geschieht über ein drittes Modell, das als Pivot bezeichnet wird.

Schauen wir uns ein Beispiel für eine Viele-zu-viele-Beziehung zwischen einem `Planet` und einem `Tag` an.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Example of a pivot model.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

Jedes Modell, das mindestens zwei `@Parent`-Beziehungen enthält, eine für jedes der zu verknüpfenden Modelle, kann als Pivot verwendet werden. Das Modell kann zusätzliche Eigenschaften enthalten, wie zum Beispiel seine ID, und sogar weitere `@Parent`-Beziehungen enthalten.

Das Hinzufügen einer [`unique`](schema.md#unique)-Einschränkung zum Pivot-Modell kann helfen, redundante Einträge zu verhindern. Weitere Informationen findest du unter [Schema](schema.md).

```swift
// Disallows duplicate relations.
.unique(on: "planet_id", "tag_id")
```

Sobald das Pivot-Modell erstellt ist, verwende die `@Siblings`-Eigenschaft, um die Beziehung zu erstellen.

```swift
final class Planet: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

Die `@Siblings`-Eigenschaft erfordert drei Parameter:

- `through`: Der Typ des Pivot-Modells.
- `from`: Key-Path vom Pivot zur Parent-Beziehung, die auf das Wurzelmodell verweist.
- `to`: Key-Path vom Pivot zur Parent-Beziehung, die auf das verknüpfte Modell verweist.

Die inverse `@Siblings`-Eigenschaft auf dem verknüpften Modell vervollständigt die Beziehung.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

Die `@Siblings`-Eigenschaft verfügt über Methoden zum Hinzufügen und Entfernen von Modellen aus der Beziehung.

Verwende die Methode `attach()`, um ein einzelnes Modell oder ein Array von Modellen zur Beziehung hinzuzufügen. Pivot-Modelle werden dabei automatisch nach Bedarf erstellt und gespeichert. Ein Callback-Closure kann angegeben werden, um zusätzliche Eigenschaften jedes erstellten Pivots zu befüllen:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Adds the model to the relation.
try await earth.$tags.attach(inhabited, on: database)
// Populate pivot attributes when establishing the relation.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Add multiple models with attributes to the relation.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Beim Anhängen eines einzelnen Modells kannst du den Parameter `method` verwenden, um zu wählen, ob die Beziehung vor dem Speichern geprüft werden soll oder nicht.

```swift
// Only attaches if the relation doesn't already exist.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Verwende die Methode `detach`, um ein Modell aus der Beziehung zu entfernen. Dadurch wird das zugehörige Pivot-Modell gelöscht.

```swift
// Removes the model from the relation.
try await earth.$tags.detach(inhabited, on: database)
```

Du kannst mit der Methode `isAttached` prüfen, ob ein Modell verknüpft ist oder nicht.

```swift
// Checks if the models are related.
earth.$tags.isAttached(to: inhabited)
```

## Get

Verwende die Methode `get(on:)`, um den Wert einer Beziehung abzurufen.

```swift
// Fetches all of the sun's planets.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Or

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Verwende den Parameter `reload`, um zu wählen, ob die Beziehung erneut aus der Datenbank abgerufen werden soll, falls sie bereits geladen wurde.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Verwende die Methode `query(on:)` auf einer Beziehung, um einen Query-Builder für die verknüpften Modelle zu erstellen.

```swift
// Fetch all of the sun's planets that have a naming starting with M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Weitere Informationen findest du unter [Query](query.md).

## Eager Loading

Der Query-Builder von Fluent ermöglicht es dir, die Beziehungen eines Modells vorzuladen, wenn es aus der Datenbank abgerufen wird. Dies wird als Eager Loading bezeichnet und erlaubt dir den synchronen Zugriff auf Beziehungen, ohne dass du zuerst [`get`](#get) aufrufen musst.

Um eine Beziehung per Eager Loading zu laden, übergib der Methode `with` des Query-Builders einen Key-Path zur Beziehung.

```swift
// Example of eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` is accessible synchronously here 
        // since it has been eager loaded.
        print(planet.star.name)
    }
}

// Or

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` is accessible synchronously here 
    // since it has been eager loaded.
    print(planet.star.name)
}
```

Im obigen Beispiel wird ein Key-Path zur [`@Parent`](#parent)-Beziehung namens `star` an `with` übergeben. Dadurch führt der Query-Builder eine zusätzliche Abfrage aus, nachdem alle Planeten geladen wurden, um alle zugehörigen Sterne abzurufen. Die Sterne sind dann synchron über die `@Parent`-Eigenschaft zugänglich.

Jede per Eager Loading geladene Beziehung erfordert nur eine zusätzliche Abfrage, unabhängig davon, wie viele Modelle zurückgegeben werden. Eager Loading ist nur mit den Methoden `all` und `first` des Query-Builders möglich.


### Verschachteltes Eager Load

Die Methode `with` des Query-Builders ermöglicht es dir, Beziehungen des abgefragten Modells per Eager Loading zu laden. Du kannst jedoch auch Beziehungen von verknüpften Modellen per Eager Loading laden.

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` is accessible synchronously here 
    // since it has been eager loaded.
    print(planet.star.galaxy.name)
}
```

Die Methode `with` akzeptiert als zweiten Parameter ein optionales Closure. Dieses Closure akzeptiert einen Eager-Load-Builder für die gewählte Beziehung. Es gibt keine Begrenzung dafür, wie tief das Eager Loading verschachtelt werden kann.

## Lazy Eager Loading

Falls du das Parent-Modell bereits abgerufen hast und eine seiner Beziehungen laden möchtest, kannst du dafür die Methode `get(reload:on:)` verwenden. Dadurch wird das verknüpfte Modell aus der Datenbank (oder, falls verfügbar, aus dem Cache) abgerufen und kann als lokale Eigenschaft zugänglich gemacht werden.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Or

try await planet.$star.get(on: database)
print(planet.star.name)
```

Falls du sicherstellen möchtest, dass die empfangenen Daten nicht aus dem Cache stammen, verwende den Parameter `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

Um zu prüfen, ob eine Beziehung geladen wurde, verwende die Eigenschaft `value`.

```swift
if planet.$star.value != nil {
    // Relation has been loaded.
    print(planet.star.name)
} else {
    // Relation has not been loaded.
    // Attempting to access planet.star will fail.
}
```

Falls du das verknüpfte Modell bereits in einer Variable hast, kannst du die Beziehung manuell mit der oben erwähnten Eigenschaft `value` setzen.

```swift
planet.$star.value = star
```

Dadurch wird das verknüpfte Modell so an das Parent angehängt, als wäre es per Eager Loading oder Lazy Loading geladen worden, ohne eine zusätzliche Datenbankabfrage.
