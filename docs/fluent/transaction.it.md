# Transazioni

Le transazioni ti permettono di assicurare che diverse operazioni sono completate con successo prima di salvare dati sul tuo database. 
Non appena una transazione inizia, puoi eseguire query di Fluent normalmente. Però, nessun dato verrà salvato sul database finché la transazione non è completata. 
Se viene lanciato un errore in qualsiasi momento durante la transazione (da te o dal database), nessuna modifica avrà effetto.

Per eseguire una transazione, devi accedere a qualcosa che si può connettere al database. Questo solitamente è una richiesta HTTP. In questo caso, usa `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // usa il database
}
```
Una volta dentro la chiusura della transazione, devi usare il database fornito nel parametro della chiusura (chiamato `database` nell'esempio) per eseguire query.

Quando questa chiusura ritorna con successo, la transazione sarà confermata.
```swift
var sole: Stella = ...
var sirio: Stella = ...

return req.db.transaction { database in
    return sole.save(on: database).flatMap { _ in
        return sirio.save(on: database)
    }
}
```
L'esempio qui sopra salverà `sole` e *dopo* `sirio` prima di completare la transazione. Se il salvataggio di una delle due stelle fallisce, nessuna delle due verrà salvata.

Quando la transazione è completa, il risultato può essere trasformato in una future diversa, per esempio in uno status HTTP per indicare il completamento come mostrato qui sotto:
```swift
return req.db.transaction { database in
    // usa il database e esegui la transazione
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Se usi `async`/`await` puoi ristrutturare il codice come segue:

```swift
try await req.db.transaction { database in
    try await sole.save(on: database)
    try await sirio.save(on: database)
}
return .ok
```
