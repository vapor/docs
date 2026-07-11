# Schema

Fluents Schema-API ermöglicht es dir, dein Datenbankschema programmatisch zu erstellen und zu aktualisieren. Sie wird häufig zusammen mit [Migrationen](migration.md) verwendet, um die Datenbank für die Verwendung mit [Models](model.md) vorzubereiten.

```swift
// An example of Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Um einen `SchemaBuilder` zu erstellen, verwendest du die Methode `schema` auf der Datenbank. Übergib den Namen der Tabelle oder Collection, die du bearbeiten möchtest. Wenn du das Schema für ein Model bearbeitest, stelle sicher, dass dieser Name mit dem [`schema`](model.md#schema) des Models übereinstimmt.

## Aktionen

Die Schema-API unterstützt das Erstellen, Aktualisieren und Löschen von Schemas. Jede Aktion unterstützt eine Teilmenge der verfügbaren Methoden der API.

### Erstellen

Der Aufruf von `create()` erstellt eine neue Tabelle oder Collection in der Datenbank. Alle Methoden zum Definieren neuer Felder und Constraints werden unterstützt. Methoden zum Aktualisieren oder Löschen werden ignoriert.

```swift
// An example schema creation.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Falls bereits eine Tabelle oder Collection mit dem gewählten Namen existiert, wird ein Fehler ausgelöst. Um dies zu ignorieren, verwende `.ignoreExisting()`.

### Aktualisieren

Der Aufruf von `update()` aktualisiert eine bestehende Tabelle oder Collection in der Datenbank. Alle Methoden zum Erstellen, Aktualisieren und Löschen von Feldern und Constraints werden unterstützt.

```swift
// An example schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Löschen

Der Aufruf von `delete()` löscht eine bestehende Tabelle oder Collection aus der Datenbank. Es werden keine weiteren Methoden unterstützt.

```swift
// An example schema deletion.
database.schema("planets").delete()
```

## Feld

Felder können beim Erstellen oder Aktualisieren eines Schemas hinzugefügt werden.

```swift
// Adds a new field
.field("name", .string, .required)
```

Der erste Parameter ist der Name des Felds. Dieser sollte mit dem Key übereinstimmen, der für die zugehörige Model-Eigenschaft verwendet wird. Der zweite Parameter ist der [Datentyp](#data-type) des Felds. Schließlich können null oder mehr [Constraints](#field-constraint) hinzugefügt werden.

### Data Type

Die unterstützten Datentypen für Felder sind unten aufgelistet.

|DataType|Swift Type|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (empfohlen)|
|`.date`|`Date` (ohne Tageszeit)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Siehe [dictionary](#dictionary)|
|`.array`|Siehe [array](#array)|
|`.enum`|Siehe [enum](#enum)|

### Field Constraint

Die unterstützten Feld-Constraints sind unten aufgelistet.

|FieldConstraint|Beschreibung|
|-|-|
|`.required`|Verbietet `nil`-Werte.|
|`.references`|Erfordert, dass der Wert dieses Felds mit einem Wert im referenzierten Schema übereinstimmt. Siehe [foreign key](#foreign-key).|
|`.identifier`|Kennzeichnet den Primärschlüssel. Siehe [identifier](#identifier).|
|`.sql(SQLColumnConstraintAlgorithm)`|Definiert jeden nicht unterstützten Constraint (z. B. `default`). Siehe [SQL](#sql) und [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/).|

### Identifier

Wenn dein Model eine Standard-`@ID`-Eigenschaft verwendet, kannst du den `id()`-Helper verwenden, um dessen Feld zu erstellen. Dabei wird der spezielle Feld-Key `.id` und der Werttyp `UUID` verwendet.

```swift
// Adds field for default identifier.
.id()
```

Für benutzerdefinierte Identifier-Typen musst du das Feld manuell angeben.

```swift
// Adds field for custom identifier.
.field("id", .int, .identifier(auto: true))
```

Der Constraint `identifier` kann auf ein einzelnes Feld angewendet werden und kennzeichnet den Primärschlüssel. Das `auto`-Flag legt fest, ob die Datenbank diesen Wert automatisch generieren soll.

### Update Field

Du kannst den Datentyp eines Felds mit `updateField` aktualisieren.

```swift
// Updates the field to `double` data type.
.updateField("age", .double)
```

Weitere Informationen zu fortgeschrittenen Schema-Updates findest du unter [advanced](advanced.md#sql).

### Delete Field

Du kannst ein Feld mit `deleteField` aus einem Schema entfernen.

```swift
// Deletes the field "age".
.deleteField("age")
```

## Constraint

Constraints können beim Erstellen oder Aktualisieren eines Schemas hinzugefügt werden. Im Gegensatz zu [Feld-Constraints](#field-constraint) können Constraints auf oberster Ebene mehrere Felder betreffen.

### Unique

Ein Unique-Constraint erfordert, dass es in einem oder mehreren Feldern keine doppelten Werte gibt.

```swift
// Disallow duplicate email addresses.
.unique(on: "email")
```

Wenn mehrere Felder eingeschränkt werden, muss die konkrete Kombination der Werte jedes Felds eindeutig sein.

```swift
// Disallow users with the same full name.
.unique(on: "first_name", "last_name")
```

Um einen Unique-Constraint zu löschen, verwende `deleteUnique`.

```swift
// Removes duplicate email constraint.
.deleteUnique(on: "email")
```

### Constraint Name

Fluent generiert standardmäßig eindeutige Constraint-Namen. Du kannst jedoch auch einen benutzerdefinierten Constraint-Namen übergeben. Das geht mit dem Parameter `name`.

```swift
// Disallow duplicate email addresses.
.unique(on: "email", name: "no_duplicate_emails")
```

Um einen benannten Constraint zu löschen, musst du `deleteConstraint(name:)` verwenden.

```swift
// Removes duplicate email constraint.
.deleteConstraint(name: "no_duplicate_emails")
```

## Foreign Key

Fremdschlüssel-Constraints (Foreign Key Constraints) erfordern, dass der Wert eines Felds mit einem der Werte im referenzierten Feld übereinstimmt. Das ist nützlich, um zu verhindern, dass ungültige Daten gespeichert werden. Fremdschlüssel-Constraints können sowohl als Feld- als auch als Constraint auf oberster Ebene hinzugefügt werden.

Um einem Feld einen Fremdschlüssel-Constraint hinzuzufügen, verwende `.references`.

```swift
// Example of adding a field foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

Der obige Constraint erfordert, dass alle Werte im Feld "star_id" mit einem der Werte im Feld "id" von Star übereinstimmen müssen.

Derselbe Constraint kann mit `foreignKey` als Constraint auf oberster Ebene hinzugefügt werden.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

Im Gegensatz zu Feld-Constraints können Constraints auf oberster Ebene bei einem Schema-Update hinzugefügt werden. Sie können außerdem [benannt](#constraint-name) werden.

Fremdschlüssel-Constraints unterstützen optionale `onDelete`- und `onUpdate`-Aktionen.

|ForeignKeyAction|Beschreibung|
|-|-|
|`.noAction`|Verhindert Fremdschlüsselverletzungen (Standard).|
|`.restrict`|Wie `.noAction`.|
|`.cascade`|Gibt Löschvorgänge über Fremdschlüssel weiter.|
|`.setNull`|Setzt das Feld auf null, wenn die Referenz unterbrochen ist.|
|`.setDefault`|Setzt das Feld auf den Standardwert, wenn die Referenz unterbrochen ist.|

Unten ist ein Beispiel für die Verwendung von Fremdschlüssel-Aktionen.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    Fremdschlüssel-Aktionen finden ausschließlich in der Datenbank statt und umgehen Fluent.
    Das bedeutet, dass Dinge wie Model-Middleware und Soft-Delete möglicherweise nicht korrekt funktionieren.

## SQL

Mit dem Parameter `.sql` kannst du beliebiges SQL zu deinem Schema hinzufügen. Das ist nützlich, um bestimmte Constraints oder Datentypen hinzuzufügen.
Ein häufiger Anwendungsfall ist das Definieren eines Standardwerts für ein Feld:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

oder sogar eines Standardwerts für einen Zeitstempel:

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary

Der Datentyp dictionary kann verschachtelte Dictionary-Werte speichern. Dazu gehören Structs, die `Codable` entsprechen, sowie Swift-Dictionaries mit einem `Codable`-Wert.

!!! note
    Fluents SQL-Datenbanktreiber speichern verschachtelte Dictionaries in JSON-Spalten.

Nimm das folgende `Codable`-Struct.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Da dieses `Pet`-Struct `Codable` ist, kann es in einem `@Field` gespeichert werden.

```swift
@Field(key: "pet")
var pet: Pet
```

Dieses Feld kann mit dem Datentyp `.dictionary(of:)` gespeichert werden.

```swift
.field("pet", .dictionary, .required)
```

Da `Codable`-Typen heterogene Dictionaries sind, geben wir den Parameter `of` nicht an.

Wenn die Dictionary-Werte homogen wären, zum Beispiel `[String: Int]`, würde der Parameter `of` den Werttyp angeben.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Dictionary-Keys müssen immer Strings sein.

## Array

Der Datentyp array kann verschachtelte Arrays speichern. Dazu gehören Swift-Arrays, die `Codable`-Werte enthalten, sowie `Codable`-Typen, die einen ungekeyten Container (unkeyed container) verwenden.

Nimm das folgende `@Field`, das ein Array von Strings speichert.

```swift
@Field(key: "tags")
var tags: [String]
```

Dieses Feld kann mit dem Datentyp `.array(of:)` gespeichert werden.

```swift
.field("tags", .array(of: .string), .required)
```

Da das Array homogen ist, geben wir den Parameter `of` an.

Codable-`Array`s in Swift haben immer einen homogenen Werttyp. Benutzerdefinierte `Codable`-Typen, die heterogene Werte in ungekeyte Container serialisieren, sind die Ausnahme und sollten den Datentyp `.array` verwenden.

## Enum

Der Datentyp enum kann string-basierte Swift-Enums nativ speichern. Native Datenbank-Enums bieten eine zusätzliche Sicherheitsebene für deine Datenbank in Bezug auf Typsicherheit und sind unter Umständen performanter als rohe Enums.

Um ein natives Datenbank-Enum zu definieren, verwende die Methode `enum` auf `Database`. Verwende `case`, um jeden Case des Enums zu definieren.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Sobald ein Enum erstellt wurde, kannst du die Methode `read()` verwenden, um einen Datentyp für dein Schema-Feld zu generieren.

```swift
// An example of reading an enum and using it to define a new field.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Or

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Um ein Enum zu aktualisieren, rufe `update()` auf. Cases können aus bestehenden Enums gelöscht werden.

```swift
// An example of enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Um ein Enum zu löschen, rufe `delete()` auf.

```swift
// An example of enum deletion.
database.enum("planet_type").delete()
```

## Model Coupling

Der Schema-Aufbau ist absichtlich von Models entkoppelt. Im Gegensatz zum Query Building verwendet der Schema-Aufbau keine Key Paths und ist vollständig string-typisiert. Das ist wichtig, da Schema-Definitionen, insbesondere jene, die für Migrationen geschrieben werden, möglicherweise auf Model-Eigenschaften verweisen müssen, die nicht mehr existieren.

Um das besser zu verstehen, wirf einen Blick auf die folgende Beispiel-Migration.

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Nehmen wir an, dass diese Migration bereits in die Produktion übernommen wurde. Nehmen wir nun an, dass wir die folgende Änderung am User-Model vornehmen müssen.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Wir können die notwendigen Anpassungen am Datenbankschema mit der folgenden Migration vornehmen.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // It is not currently possible to express this update without using custom SQL.
        // This also doesn't try to deal with splitting the name into first and last,
        // as that requires database-specific syntax.
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

Beachte, dass wir für diese Migration sowohl das entfernte Feld `name` als auch die neuen Felder `firstName` und `lastName` gleichzeitig referenzieren können müssen. Außerdem muss die ursprüngliche `UserMigration` weiterhin gültig bleiben. Mit Key Paths wäre das nicht möglich.

## Setting Model Space

Um den [Space für ein Model](model.md#datenbank-space) zu definieren, übergib den Space beim Erstellen der Tabelle an `schema(_:space:)`. Z. B.

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
