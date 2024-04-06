# Transazioni

Le transazioni garantiscono che varie operazioni vengano eseguite con successo prima di effettuare l'aggiornamento dei dati sul tuo database. 
Una volta avviata una transazione, puoi procedere con le query Fluent come al solito, tuttavia i dati non verranno effettivamente salvati sul database fino al completamento della transazione. 
In caso di errore durante la transazione, che sia scaturito da te o dal sistema di gestione del database, le modifiche proposte non saranno applicate.

Per eseguire una transazione, devi accedere a qualcosa che si può connettere al database. Questo solitamente è una richiesta HTTP. In questo caso, usa `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // usa il database
}
```
Una volta dentro la chiusura della transazione, devi usare il database fornito nel parametro della chiusura (chiamato `database` nell'esempio) per eseguire query.

Quando questa chiusura ritorna con successo, la transazione sarà confermata.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
L'esempio qui sopra salverà `sun` e *dopo* `sirius` prima di completare la transazione. Se il salvataggio di una delle due `Star` fallisce, nessuna delle due verrà salvata.

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
    try await sun.save(on: database)
    try await sirius.save(on: database)
}
return .ok
```
