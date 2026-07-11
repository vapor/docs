# Passwörter

Vapor enthält eine Passwort-Hashing-API, die dir dabei hilft, Passwörter sicher zu speichern und zu überprüfen. Diese API ist je nach Umgebung konfigurierbar und unterstützt asynchrones Hashing.

## Konfiguration

Um den Passwort-Hasher der Anwendung zu konfigurieren, verwende `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Um Vapors [Bcrypt-API](crypto.md#bcrypt) für das Passwort-Hashing zu verwenden, gib `.bcrypt` an. Dies ist die Standardeinstellung.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt verwendet standardmäßig einen Kostenfaktor von 12, sofern nicht anders angegeben. Du kannst dies konfigurieren, indem du den Parameter `cost` übergibst.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Klartext

Vapor enthält einen unsicheren Passwort-Hasher, der Passwörter im Klartext speichert und überprüft. Dieser sollte nicht in der Produktion verwendet werden, kann aber für Tests nützlich sein.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

Um Passwörter zu hashen, verwende den `password`-Helfer, der auf `Request` verfügbar ist.

```swift
let digest = try req.password.hash("vapor")
```

Passwort-Digests können mithilfe der `verify`-Methode gegen das Klartext-Passwort überprüft werden.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

Die gleiche API steht auch auf `Application` zur Verwendung während des Boot-Vorgangs zur Verfügung.

```swift
let digest = try app.password.hash("vapor")
```

### Async 

Passwort-Hashing-Algorithmen sind darauf ausgelegt, langsam und CPU-intensiv zu sein. Aus diesem Grund möchtest du eventuell vermeiden, den Event-Loop beim Hashing von Passwörtern zu blockieren. Vapor bietet eine asynchrone Passwort-Hashing-API, die das Hashing an einen Hintergrund-Thread-Pool weiterleitet. Um die asynchrone API zu verwenden, nutze die Eigenschaft `async` auf einem Passwort-Hasher.

```swift
req.password.async.hash("vapor").map { digest in
    // Digest verarbeiten.
}

// oder

let digest = try await req.password.async.hash("vapor")
```

Das Überprüfen von Digests funktioniert ähnlich.

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Ergebnis verarbeiten.
}

// oder

let result = try await req.password.async.verify("vapor", created: digest)
```

Das Berechnen von Hashes in Hintergrund-Threads kann die Event-Loops deiner Anwendung entlasten, damit sie mehr eingehende Anfragen bearbeiten können.
