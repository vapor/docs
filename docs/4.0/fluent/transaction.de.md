# Transaktionen

Transaktionen erlauben es dir, sicherzustellen, dass mehrere Operationen erfolgreich abgeschlossen werden, bevor Daten in deiner Datenbank gespeichert werden.
Sobald eine Transaktion gestartet wurde, kannst du Fluent-Queries wie gewohnt ausführen. Es werden jedoch keine Daten in der Datenbank gespeichert, bis die Transaktion abgeschlossen ist.
Wird an irgendeiner Stelle während der Transaktion ein Fehler ausgelöst (von dir oder von der Datenbank), werden keine der Änderungen wirksam.

Um eine Transaktion durchzuführen, benötigst du Zugriff auf etwas, das eine Verbindung zur Datenbank herstellen kann. Dies ist normalerweise ein eingehender HTTP-Request. Verwende dafür `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // use database
}
```
Innerhalb des Transaktions-Closures musst du die im Closure-Parameter übergebene Datenbank (im Beispiel `database` genannt) verwenden, um Queries auszuführen.

Sobald dieser Closure erfolgreich zurückkehrt, wird die Transaktion committet.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
Das obige Beispiel speichert `sun` und *anschließend* `sirius`, bevor die Transaktion abgeschlossen wird. Schlägt das Speichern eines der beiden Sterne fehl, wird keiner von beiden gespeichert.

Sobald die Transaktion abgeschlossen ist, kann das Ergebnis in ein anderes Future umgewandelt werden, zum Beispiel in einen HTTP-Status, um den Abschluss anzuzeigen, wie unten gezeigt:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Wenn du `async`/`await` verwendest, kannst du den Code wie folgt umschreiben:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
