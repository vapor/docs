# Abfrage

Die Query-API von Fluent ermöglicht es dir, Models in der Datenbank zu erstellen, zu lesen, zu aktualisieren und zu löschen. Sie unterstützt das Filtern von Ergebnissen, Joins, Chunking, Aggregate und mehr.

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Query-Builder sind an einen einzelnen Model-Typ gebunden und können mit der statischen Methode [`query`](model.md#query) erstellt werden. Sie können auch erstellt werden, indem der Model-Typ an die `query`-Methode eines Datenbankobjekts übergeben wird.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note
    Du musst `import Fluent` in der Datei mit deinen Abfragen angeben, damit der Compiler die Hilfsfunktionen von Fluent sehen kann.

## All

Die Methode `all()` gibt ein Array von Models zurück.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

Die Methode `all` unterstützt außerdem das Abrufen nur eines einzelnen Felds aus der Ergebnismenge.

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

Die Methode `first()` gibt ein einzelnes, optionales Model zurück. Falls die Abfrage mehr als ein Model ergibt, wird nur das erste zurückgegeben. Falls die Abfrage keine Ergebnisse liefert, wird `nil` zurückgegeben.

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    Wenn du `EventLoopFuture`s verwendest, kann diese Methode mit [`unwrap(or:)`](../basics/errors.md#abort) kombiniert werden, um ein nicht-optionales Model zurückzugeben oder einen Fehler zu werfen.

## Filter

Die Methode `filter` ermöglicht es dir, die in der Ergebnismenge enthaltenen Models einzuschränken. Es gibt mehrere Überladungen dieser Methode.

### Value Filter

Die am häufigsten verwendete `filter`-Methode akzeptiert einen Operatorausdruck mit einem Wert.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Diese Operatorausdrücke akzeptieren auf der linken Seite einen Field-Key-Path und auf der rechten Seite einen Wert. Der angegebene Wert muss dem erwarteten Werttyp des Felds entsprechen und wird an die resultierende Abfrage gebunden. Filterausdrücke sind stark typisiert, wodurch die führende Punktsyntax verwendet werden kann.

Nachfolgend eine Liste aller unterstützten Value-Operatoren.

|Operator|Beschreibung|
|-|-|
|`==`|Gleich.|
|`!=`|Ungleich.|
|`>=`|Größer oder gleich.|
|`>`|Größer als.|
|`<`|Kleiner als.|
|`<=`|Kleiner oder gleich.|

### Field Filter

Die Methode `filter` unterstützt den Vergleich zweier Felder.

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Field-Filter unterstützen dieselben Operatoren wie [Value-Filter](#value-filter).

### Subset Filter

Die Methode `filter` unterstützt die Prüfung, ob der Wert eines Felds in einer gegebenen Menge von Werten enthalten ist.

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

Die angegebene Wertemenge kann jede Swift-`Collection` sein, deren `Element`-Typ dem Werttyp des Felds entspricht.

Nachfolgend eine Liste aller unterstützten Subset-Operatoren.

|Operator|Beschreibung|
|-|-|
|`~~`|Wert in Menge enthalten.|
|`!~`|Wert nicht in Menge enthalten.|

### Contains Filter

Die Methode `filter` unterstützt die Prüfung, ob der Wert eines String-Felds einen bestimmten Teilstring enthält.

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Diese Operatoren sind nur bei Feldern mit String-Werten verfügbar.

Nachfolgend eine Liste aller unterstützten Contains-Operatoren.

|Operator|Beschreibung|
|-|-|
|`~~`|Enthält Teilstring.|
|`!~`|Enthält Teilstring nicht.|
|`=~`|Entspricht Präfix.|
|`!=~`|Entspricht Präfix nicht.|
|`~=`|Entspricht Suffix.|
|`!~=`|Entspricht Suffix nicht.|

### Group

Standardmäßig müssen alle einer Abfrage hinzugefügten Filter zutreffen. Der Query-Builder unterstützt das Erstellen einer Gruppe von Filtern, bei der nur ein Filter zutreffen muss.

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

Die Methode `group` unterstützt das Kombinieren von Filtern mittels `and`- oder `or`-Logik. Diese Gruppen können beliebig tief verschachtelt werden. Filter der obersten Ebene können als in einer `and`-Gruppe befindlich betrachtet werden.

## Aggregate

Der Query-Builder unterstützt mehrere Methoden zum Durchführen von Berechnungen auf einer Menge von Werten, etwa Zählen oder Mitteln.

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

Alle Aggregatmethoden außer `count` erfordern die Übergabe eines Key-Paths zu einem Feld.

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

Nachfolgend eine Liste aller verfügbaren Aggregatmethoden.

|Aggregat|Beschreibung|
|-|-|
|`count`|Anzahl der Ergebnisse.|
|`sum`|Summe der Ergebniswerte.|
|`average`|Durchschnitt der Ergebniswerte.|
|`min`|Minimaler Ergebniswert.|
|`max`|Maximaler Ergebniswert.|

Alle Aggregatmethoden außer `count` geben als Ergebnis den Werttyp des Felds zurück. `count` gibt immer eine Ganzzahl zurück.

## Chunk

Der Query-Builder unterstützt die Rückgabe einer Ergebnismenge in separaten Chunks. Dies hilft dir, den Speicherverbrauch beim Verarbeiten großer Datenbankabfragen zu kontrollieren.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

Der übergebene Closure wird abhängig von der Gesamtzahl der Ergebnisse null- oder mehrmals aufgerufen. Jedes zurückgegebene Element ist ein `Result`, das entweder das Model oder einen beim Versuch, den Datenbankeintrag zu dekodieren, aufgetretenen Fehler enthält.

## Field

Standardmäßig werden alle Felder eines Models bei einer Abfrage aus der Datenbank gelesen. Du kannst mit der Methode `field` wählen, nur eine Teilmenge der Felder eines Models auszuwählen.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Alle Model-Felder, die bei einer Abfrage nicht ausgewählt wurden, befinden sich in einem uninitialisierten Zustand. Der Versuch, direkt auf uninitialisierte Felder zuzugreifen, führt zu einem Fatal Error. Um zu prüfen, ob der Wert eines Model-Felds gesetzt ist, verwende die Eigenschaft `value`.

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

Die Methode `unique` des Query-Builders sorgt dafür, dass nur eindeutige Ergebnisse (ohne Duplikate) zurückgegeben werden.

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` ist besonders nützlich, wenn ein einzelnes Feld mit `all` abgerufen wird. Du kannst jedoch auch mehrere Felder mit der Methode [`field`](#field) auswählen. Da Model-Identifier immer eindeutig sind, solltest du es vermeiden, sie bei Verwendung von `unique` auszuwählen.

## Range

Die `range`-Methoden des Query-Builders ermöglichen es dir, mithilfe von Swift-Ranges eine Teilmenge der Ergebnisse auszuwählen.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

Range-Werte sind vorzeichenlose Ganzzahlen, die bei null beginnen. Erfahre mehr über [Swift-Ranges](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
.range(2...)
```

## Join

Die `join`-Methode des Query-Builders ermöglicht es dir, die Felder eines anderen Models in deine Ergebnismenge einzubeziehen. Es können mehrere Models mit deiner Abfrage verknüpft werden.

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

Der Parameter `on` akzeptiert einen Gleichheitsausdruck zwischen zwei Feldern. Eines der Felder muss bereits in der aktuellen Ergebnismenge vorhanden sein. Das andere Feld muss auf dem zu verknüpfenden Model existieren. Diese Felder müssen denselben Werttyp haben.

Die meisten Query-Builder-Methoden, wie `filter` und `sort`, unterstützen verknüpfte Models. Wenn eine Methode verknüpfte Models unterstützt, akzeptiert sie den Typ des verknüpften Models als ersten Parameter.

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

Abfragen, die Joins verwenden, geben weiterhin ein Array des Basis-Models zurück. Um auf das verknüpfte Model zuzugreifen, verwende die Methode `joined`.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Mit Model-Aliassen kannst du dasselbe Model mehrfach mit einer Abfrage verknüpfen. Um einen Model-Alias zu deklarieren, erstelle einen oder mehrere Typen, die dem Protokoll `ModelAlias` entsprechen.

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Diese Typen referenzieren das zu aliasierende Model über die Eigenschaft `model`. Einmal erstellt, kannst du Model-Aliasse wie normale Models in einem Query-Builder verwenden.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Alle Model-Felder sind über den Model-Alias-Typ mittels `@dynamicMemberLookup` zugänglich.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

Der Query-Builder unterstützt das Aktualisieren mehrerer Models gleichzeitig mit der Methode `update`.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` unterstützt die Methoden `set`, `filter` und `range`.

## Delete

Der Query-Builder unterstützt das Löschen mehrerer Models gleichzeitig mit der Methode `delete`.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` unterstützt die Methode `filter`.

## Paginate

Die Query-API von Fluent unterstützt automatische Paginierung der Ergebnisse mit der Methode `paginate`.

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

Die Methode `paginate(for:)` verwendet die in der Request-URI verfügbaren Parameter `page` und `per`, um die gewünschte Ergebnismenge zurückzugeben. Metadaten über die aktuelle Seite und die Gesamtzahl der Ergebnisse sind im Schlüssel `metadata` enthalten.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

Die obige Anfrage würde eine Antwort mit folgendem Aufbau liefern.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Die Seitennummerierung beginnt bei `1`. Du kannst auch eine manuelle Seitenanfrage stellen.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

Abfrageergebnisse können mithilfe der Methode `sort` nach Feldwerten sortiert werden.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

Zusätzliche Sortierungen können als Fallback für den Fall eines Gleichstands hinzugefügt werden. Fallbacks werden in der Reihenfolge verwendet, in der sie dem Query-Builder hinzugefügt wurden.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
