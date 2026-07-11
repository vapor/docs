# Hasła

Vapor zawiera API do hashowania haseł, które pomaga bezpiecznie przechowywać i weryfikować hasła. To API jest konfigurowalne w zależności od środowiska i wspiera asynchroniczne hashowanie.

## Konfiguracja

Aby skonfigurować hasher haseł Application, użyj `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Aby użyć [API Bcrypt](crypto.md#bcrypt) Vapora do hashowania haseł, określ `.bcrypt`. Jest to opcja domyślna.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt użyje kosztu 12, chyba że określono inaczej. Możesz to skonfigurować, przekazując parametr `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor zawiera niebezpieczny hasher haseł, który przechowuje i weryfikuje hasła jako zwykły tekst (plaintext). Nie powinien być używany w produkcji, ale może być przydatny do testowania.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashowanie

Aby zahashować hasła, użyj pomocnika `password` dostępnego na `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Skróty haseł (digest) można zweryfikować względem hasła w postaci zwykłego tekstu za pomocą metody `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

To samo API jest dostępne na `Application` do użycia podczas uruchamiania (boot).

```swift
let digest = try app.password.hash("vapor")
```

### Async 

Algorytmy hashowania haseł są zaprojektowane tak, aby być wolne i intensywnie obciążać CPU. Z tego powodu możesz chcieć uniknąć blokowania event loopa podczas hashowania haseł. Vapor udostępnia asynchroniczne API do hashowania haseł, które przekazuje hashowanie do puli wątków w tle. Aby użyć asynchronicznego API, użyj właściwości `async` na hasherze haseł.

```swift
req.password.async.hash("vapor").map { digest in
    // Handle digest.
}

// or

let digest = try await req.password.async.hash("vapor")
```

Weryfikacja skrótów działa podobnie:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Handle result.
}

// or

let result = try await req.password.async.verify("vapor", created: digest)
```

Obliczanie hashy w wątkach w tle może odciążyć event loopy Twojej aplikacji, aby mogły obsługiwać więcej przychodzących żądań.
