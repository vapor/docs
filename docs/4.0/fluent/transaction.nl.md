# Transacties

Met transacties kunt u ervoor zorgen dat meerdere bewerkingen met succes worden voltooid voordat u gegevens in uw database opslaat. 
Zodra een transactie is gestart, kunt u Fluent queries normaal uitvoeren. Er worden echter geen gegevens in de database opgeslagen totdat de transactie is voltooid. 
Als er op enig moment tijdens de transactie een fout wordt gegooid (door u of door de database), zal geen van de wijzigingen effect hebben.

Om een transactie uit te voeren, heb je toegang nodig tot iets dat verbinding kan maken met de database. Dit is meestal een inkomend HTTP verzoek. Gebruik hiervoor `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // database gebruiken
}
```
Eenmaal in de transactie closure, moet je de database die in de closure parameter is meegegeven (in het voorbeeld `database` genoemd) gebruiken om queries uit te voeren.

Zodra deze afsluiting succesvol is, wordt de transactie vastgelegd.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
Het bovenstaande voorbeeld zal `sun` opslaan en *daarna* `sirius` alvorens de transactie te voltooien. Als een van de sterren niet opslaat, slaat geen van beide sterren op.

Zodra de transactie is voltooid, kan het resultaat worden omgezet in een andere future, bijvoorbeeld in een HTTP-status om de voltooiing aan te geven, zoals hieronder afgebeeld:
```swift
return req.db.transaction { database in
    // database gebruiken en transactie uitvoeren
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Als je `async`/`await` gebruikt kun je de code als volgt herformuleren:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
