# Password

Vapor include un'API di hashing delle password per aiutarti a conservare e verificare le password in modo sicuro. Questa API è configurabile sulla base di un ambiente e supporta l'hashing asincrono.

## Configurazione

Per configurare la funzione di hash delle password dell'applicazione, usa `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Per utilizzare [l'API Bcrypt](crypto.it.md#bcrypt) di Vapor per l'hashing delle password, specifica `.bcrypt`. Questa è l'API di default.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt utilizzerà un costo di 12 se non diversamente specificato. Puoi configurarlo modificando il parametro `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor permette di salvare in modo insicuro le password come testo in chiaro. Normalmente non si dovrebbe fare, ma può essere utile per il testing.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

Per ottenere l'hash delle password, usa l'oggetto `password` disponibile in `Request`.

```swift
let digest = try req.password.hash("vapor")
```

I digest delle password possono essere verificati paragonandoli alle password in chiaro usando il metodo `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

La stessa API è disponibile in `Application` per usarla all'avvio.

```swift
let digest = try app.password.hash("vapor")
```

### Asincrono 

Gli algoritmi di hashing delle password sono progettati per essere lenti e con un uso intensivo della CPU. Per questo motivo, potresti voler evitare di bloccare il loop di eventi mentre viene calcolato l'hash delle password. Vapor fornisce un'API asincrona di hashing delle password che affida l'hashing a un pool di thread in background. Per usare l'API asincrona, usa la proprietà `async` su una funzione di hash delle password.

```swift
req.password.async.hash("vapor").map { digest in
    // Gestisci il digest.
}

// oppure

let digest = try await req.password.async.hash("vapor")
```

Verificare i digest funziona in modo simile:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Gestisci il risultato.
}

// oppure

let result = try await req.password.async.verify("vapor", created: digest)
```

Calcolare gli hash nei thread in background può liberare i loop di eventi dell'applicazione per gestire più richieste in arrivo.
