# Wachtwoorden

Vapor bevat een wachtwoord hashing API om u te helpen wachtwoorden veilig op te slaan en te verifiëren. Deze API kan op basis van de omgeving worden geconfigureerd en ondersteunt asynchroon hashen.

## Configuratie

Om de wachtwoord hasher van de Applicatie in te stellen, gebruik `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Om Vapor's [Bcrypt API](crypto.md#bcrypt) te gebruiken voor het hashen van wachtwoorden, geef `.bcrypt` op. Dit is de standaardinstelling.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt zal een waarde van 12 gebruiken, tenzij anders aangegeven. U kunt dit instellen door de `cost` parameter mee te geven.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor bevat een onveilige wachtwoord hasher die wachtwoorden als plaintext opslaat en verifieert. Dit zou niet in productie gebruikt moeten worden, maar het kan nuttig zijn om te testen.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashen

Om wachtwoorden te hashen, gebruik de `password` helper die beschikbaar is op `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Wachtwoord digests kunnen geverifieerd worden met het plaintext wachtwoord via de `verify` methode.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

Dezelfde API is beschikbaar op `Application` voor gebruik tijdens het opstarten.

```swift
let digest = try app.password.hash("vapor")
```

### Async 

Hash-algoritmen voor wachtwoorden zijn ontworpen om traag en CPU-intensief te zijn. Daarom wilt u misschien de event loop niet blokkeren tijdens het hashen van wachtwoorden. Vapor biedt een asynchrone wachtwoord hashing API die het hashen naar een achtergrond thread pool stuurt. Om de asynchrone API te gebruiken, gebruik de `async` eigenschap op een wachtwoord hasher.

```swift
req.password.async.hash("vapor").map { digest in
    // Verwerking afhandelen.
}

// of

let digest = try await req.password.async.hash("vapor")
```

Het verifiëren van digests werkt op dezelfde manier:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Resultaat afhandelen.
}

// of

let result = try await req.password.async.verify("vapor", created: digest)
```

Het berekenen van hashes op achtergrond threads kan de event loops van je applicatie vrijmaken om meer inkomende verzoeken af te handelen.
