# Migrationen

Migrationen sind wie ein Versionskontrollsystem für deine Datenbank. Jede Migration definiert eine Änderung an der Datenbank sowie, wie diese rückgängig gemacht werden kann. Indem du deine Datenbank über Migrationen veränderst, schaffst du eine konsistente, testbare und teilbare Möglichkeit, deine Datenbanken im Laufe der Zeit weiterzuentwickeln.

```swift
// An example migration.
struct MyMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // Make a change to the database.
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // Undo the change made in `prepare`, if possible.
    }
}
```

Wenn du `async`/`await` verwendest, solltest du das `AsyncMigration`-Protokoll implementieren:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Make a change to the database.
    }

    func revert(on database: any Database) async throws {
        // Undo the change made in `prepare`, if possible.
    }
}
```

In der Methode `prepare` nimmst du Änderungen an der übergebenen `Database` vor. Dabei kann es sich um Änderungen am Datenbankschema handeln, wie das Hinzufügen oder Entfernen einer Tabelle bzw. Collection, eines Felds oder einer Constraint. Es können auch Änderungen am Datenbankinhalt sein, etwa das Erstellen neuer Model-Instanzen, das Aktualisieren von Feldwerten oder das Durchführen von Aufräumarbeiten.

In der Methode `revert` machst du diese Änderungen rückgängig, sofern möglich. Migrationen rückgängig machen zu können, erleichtert das Prototyping und Testen. Außerdem hast du dadurch einen Rückfallplan, falls ein Deployment in die Produktion nicht wie geplant verläuft.

## Registrieren

Migrationen werden über `app.migrations` bei deiner Anwendung registriert.

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Du kannst eine Migration mit dem Parameter `to` einer bestimmten Datenbank zuordnen, andernfalls wird die Standarddatenbank verwendet.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Migrationen sollten in der Reihenfolge ihrer Abhängigkeiten aufgeführt werden. Wenn beispielsweise `MigrationB` von `MigrationA` abhängt, sollte sie als zweites zu `app.migrations` hinzugefügt werden.

## Migrieren

Um deine Datenbank zu migrieren, führe den Befehl `migrate` aus.

```sh
swift run App migrate
```

Du kannst diesen [Befehl auch über Xcode](../advanced/commands.md#xcode) ausführen. Der `migrate`-Befehl prüft die Datenbank, um festzustellen, ob seit dem letzten Ausführen neue Migrationen registriert wurden. Falls es neue Migrationen gibt, wird vor deren Ausführung eine Bestätigung angefordert.

### Zurücksetzen

Um eine Migration deiner Datenbank rückgängig zu machen, führe `migrate` mit dem Flag `--revert` aus.

```sh
swift run App migrate --revert
```

Der Befehl prüft die Datenbank, um festzustellen, welcher Batch von Migrationen zuletzt ausgeführt wurde, und fordert vor dem Zurücksetzen eine Bestätigung an.

### Automatische Migration

Wenn Migrationen automatisch vor dem Ausführen anderer Befehle ausgeführt werden sollen, kannst du das Flag `--auto-migrate` übergeben.

```sh
swift run App serve --auto-migrate
```

Du kannst dies auch programmatisch tun.

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Beide Optionen existieren auch für das Zurücksetzen: `--auto-revert` und `app.autoRevert()`.

## Nächste Schritte

Wirf einen Blick auf die Anleitungen zum [Schema Builder](schema.md) und [Query Builder](query.md), um mehr darüber zu erfahren, was du in deine Migrationen einbauen kannst.
