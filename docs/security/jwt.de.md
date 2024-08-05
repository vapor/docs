# JWT

JSON Web Token (JWT) ist ein offener Standard (RFC 7519), der eine kompakte und in sich geschlossene Methode zur sicheren Übertragung von Informationen zwischen Parteien als JSON-Objekt definiert. Diese Informationen können überprüft und als vertrauenswürdig angesehen werden, da sie digital signiert sind. JWTs können entweder mit einem Geheimnis (unter Verwendung des HMAC-Algorithmus) oder einem öffentlichen/privaten Schlüsselpaar mithilfe von RSA oder ECDSA signiert werden.
## Erste Schritte
Der erste Schritt zur Verwendung von JWT besteht darin, die Abhängigkeit in deiner Package.swift hinzuzufügen.
```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Andere Abhängigkeiten...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0-beta"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Andere Abhängigkeiten...
            .product(name: "JWT", package: "jwt")
        ]),
        // Weitere Ziele...
    ]
)
```

Wenn du das Manifest direkt in Xcode bearbeitest, werden die Änderungen automatisch übernommen und die neue Abhängigkeit wird beim Speichern der Datei abgerufen. Andernfalls führe `swift package resolve` aus, um die neue Abhängigkeit abzurufen.
### Konfiguration

Das JWT-Modul fügt `Application` eine neue Eigenschaft `jwt` hinzu, die für die Konfiguration verwendet wird. Um JWTs zu signieren oder zu verifizieren, musst du einen Schlüssel hinzufügen. Der einfachste Signieralgorithmus ist HS256 oder HMAC mit SHA-256.

```swift
import JWT

// HMAC mit SHA-256 Unterzeichner hinzufügen.
await app.jwt.keys.addHMAC(key: "secret", digestAlgorithm: .sha256)
```

!!! tip "Hinweis": 
    Das `await` Schlüsselwort ist erforderlich, da die Schlüsselsammlung ein `actor` ist.


Der `HS256` Unterzeichner benötigt einen Schlüssel zur Initialisierung. Im Gegensatz zu anderen Unterzeichnern wird dieser eine Schlüssel sowohl zum Signieren _als auch_ zum Verifizieren von Tokens verwendet. Erfahre mehr über die verfügbaren [Algorithmen](#Algorithmen) unten.
### Payload

Versuchen wir, das folgende JWT-Beispiel zu überprüfen.

```swift
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```
Du kannst den Inhalt dieses Tokens überprüfen, indem du [jwt.io](https://jwt.io) besuchst und das Token in den Debugger einfügst. Setz den Schlüssel im Abschnitt "Verify Signature" auf `secret`.

Wir müssen eine Struktur erstellen, die mit `JWTPayload` konform ist und die Struktur des JWT darstellt. Wir werden die in JWT enthaltenen [claims](#claims) verwenden, um gängige Felder wie `sub` und `exp` zu behandeln.

```swift
// JWT payload structure.
struct TestPayload: JWTPayload {
    // Weist die längeren Swift-Eigenschaftsnamen den
    // kürzeren Schlüsseln im JWT-Payload zu.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // Das "sub" (Subject) Claim identifiziert die Entität, die
    // Gegenstand des JWT ist.
    var subject: SubjectClaim

    // Das "exp" (Ablaufzeit) Claim identifiziert den Zeitpunkt, nach dem
    // das JWT nicht mehr akzeptiert werden darf.
    var expiration: ExpirationClaim

    // Benutzerdefinierte Daten.
    // Wenn wahr, ist der Benutzer ein Admin.
    var isAdmin: Bool

    // Führe hier zusätzliche Überprüfungslogik aus,
    // die über die Signaturüberprüfung hinausgeht.
    // Da wir ein ExpirationClaim haben, werden wir
    // die verify-Methode aufrufen.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

### Verifizierung

Nun, da wir ein `JWTPayload` haben, können wir das obige JWT an eine Anfrage anhängen und `req.jwt` verwenden, um es abzurufen und zu verifizieren. Füge deinem Projekt die folgende Route hinzu.

```swift
// JWT aus eingehender Anfrage abrufen und verifizieren.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```
Der Helfer `req.jwt.verify` prüft den `Authorization` Header auf ein Inhaber-Token. Wenn eines vorhanden ist, wird das JWT analysiert und seine Signatur und Claims werden überprüft. Wenn einer dieser Schritte fehlschlägt, wird ein _401 Unauthorized_ Fehler ausgelöst.

Teste die Route, indem du die folgende HTTP-Anfrage sendest.

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```
Wenn alles funktioniert hat, wird eine _200 OK_ Antwort zurückgegeben und der Payload wird ausgegeben:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

### Signierung

Dieses Paket kann auch JWTs _generieren_, auch bekannt als Signatur. Um dies zu demonstrieren, verwenden wir das `TestPayload` aus dem vorherigen Abschnitt. Füge deinem Projekt die folgende Route hinzu.

```swift
// Erstellen und Zurückgeben eines neuen JWT.
app.post("login") { req async throws -> [String: String] in
    // Erzeuge eine neue Instanz unseres JWTPayload
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    // Gib das signierte JWT zurück
    return try await [
        "token": req.jwt.sign(payload, kid: "a"),
    ]
}
```

Die `req.jwt.sign` Hilfe verwendet den standardmäßig konfigurierten Signierer, um die `JWTPayload` zu serialisieren und zu signieren. Das kodierte JWT wird als `String` zurückgegeben.

Teste die Route, indem du die folgende HTTP-Anfrage sendest.

```http
POST /login HTTP/1.1
```

Du solltest das neu erzeugte Token in einer _200 OK_ Antwort zurückerhalten.

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

## Authentifizierung

Weitere Informationen zur Verwendung von JWT mit Vapors Authentifizierungs-API findest du unter [Authentifizierung &rarr; JWT](authentication.md#jwt).

## Algorithmen

Vapor's JWT API unterstützt die Verifizierung und Signierung von Token mit den folgenden Algorithmen.

### HMAC

HMAC ist der einfachste JWT-Signieralgorithmus. Er verwendet einen einzigen Schlüssel, der sowohl signieren als auch Token verifizieren kann. Der Schlüssel kann beliebig lang sein.

- `HS256`: HMAC mit SHA-256
- `HS384`: HMAC mit SHA-384
- `HS512`: HMAC mit SHA-512

```swift
// HMAC mit SHA-256 Unterzeichner hinzufügen.
await app.jwt.keys.addHMAC(key: "secret", digestAlgorithm: .sha256)
```

### RSA

RSA ist der am häufigsten verwendete JWT-Signieralgorithmus. Er unterstützt unterschiedliche öffentliche und private Schlüssel. Das bedeutet, dass ein öffentlicher Schlüssel verteilt werden kann, um die Authentizität der JWTs zu überprüfen, während der private Schlüssel, der sie erzeugt, geheim gehalten wird.

!!! warning "Warnung"
    Das JWT-Paket von Vapor unterstützt keine RSA-Schlüssel mit einer Größe von weniger als 2048 Bit. Da RSA aus Sicherheitsgründen von der NIST nicht mehr empfohlen wird, sind RSA-Schlüssel hinter einem `Insecure`-Namensraum eingeschlossen, um von ihrer Verwendung abzuschrecken.

Um einen RSA-Signierer zu erstellen, muss zunächst ein `RSAKey` initialisiert werden. Dies kann durch Übergabe der Komponenten geschehen.
```swift
// Initialisiere einen privaten RSA-Schlüssel mit Komponenten.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```
Der Initialisierer für den öffentlichen Schlüssel ist ähnlich.

```swift
// Initialisiere einen öffentlichen RSA-Schlüssel mit Komponenten.
let key = try Insecure.RSA.PublicKey(
    modulus: modulus, 
    exponent: publicExponent
)
```

Du kannst auch eine PEM-Datei laden:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialisieren Sie einen RSA-Schlüssel mit public pem.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

Verwende `Insecure.RSA.PrivateKey`, um private RSA-PEM-Schlüssel zu laden. Diese beginnen mit:
```
-----BEGIN RSA PRIVATE KEY-----
```

Sobald du den RSA-Schlüssel hast, kannst du ihn mit der Methode `addRSA` hinzufügen.

```swift
// RSA mit SHA-256 Signierer hinzufügen.
try await app.jwt.keys.addRSA(
    key: Insecure.RSA.PublicKey(pem: rsaPublicKey),
    digestAlgorithm: .sha256
)
```

### PSS

Zusätzlich zum Standard-RSA unterstützt das JWT-Paket von Vapor auch RSA mit PSS-Padding.
Dies wird als sicherer als Standard-RSA, wird aber immer noch zugunsten anderer asymmetrischer Algorithmen wie ECDSA abgelehnt.
Während PSS lediglich ein anderes Auffüllungsschema als Standard-RSA verwendet, ist die Schlüsselerzeugung und -verwendung die gleiche wie bei RSA.

```swift
let key = Insecure.RSA.PublicKey(pem: publicKey)
try app.jwt.keys.addPSS(key: key, digestAlgorithm: .sha256)
```

### ECDSA

ECDSA ist ein modernerer Algorithmus, der mit RSA vergleichbar ist. Er gilt bei einer bestimmten Schlüssellänge als sicherer als RSA[^1]. Sie sollten jedoch eigene Nachforschungen anstellen, bevor Sie sich entscheiden.
[^1]: https://www.ssl.com/article/comparing-ecdsa-vs-rsa/

Wie bei RSA kannst du ECDSA-Schlüssel über PEM-Dateien laden:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialisiere einen ECDSA-Schlüssel mit öffentlichem PEM.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

Es gibt drei ECDSA-Algorithmen, je nach verwendeter Kurve:
- `ES256`: ECDSA mit einer P-256 Kurve und SHA-256
- `ES384`: ECDSA mit einer P-384 Kurve und SHA-384
- `ES512`: ECDSA mit einer P-521 Kurve und SHA-512

Alle Algorithmen bieten sowohl einen öffentlichen Schlüssel als auch einen privaten Schlüssel,
wie z. B. `ES256PublicKey` und `ES256PrivateKey`.

Du kannst auch einen zufälligen ECDSA-Schlüssel erzeugen, indem du den leeren Initialisierer verwendest. Dies ist für Tests nützlich.

```swift
let key = ES256PrivateKey()
```

Sobald du den ECDSAKey hast, kannst du ihn mit der Methode `addECDSA` zur Schlüsselsammlung hinzufügen.

```swift
// ECDSA mit SHA-256 Unterzeichner hinzufügen.
try await app.jwt.keys.addECDSA(key: ES256PublicKey(pem: ecdsaPublicKey))
```

### Schlüsselidentifikator (kid)

Wenn du mehrere Algorithmen verwendest, kannst du Schlüsselbezeichner (`kid`) verwenden, um sie zu unterscheiden. Wenn du einen Algorithmus konfigurierst, übergebe den `kid` Parameter.

```swift
// HMAC mit SHA-256 Unterzeichner namens "a" hinzufügen.
await app.jwt.keys.addHMAC(key: "foo", digestAlgorithm: .sha256, kid: "a")
// HMAC mit SHA-256 Unterzeichner namens "b" hinzufügen.
await app.jwt.keys.addHMAC(key: "bar", digestAlgorithm: .sha256, kid: "b")
```

Wenn du JWTs signierst, übergebe den `kid` Parameter für den gewünschten Unterzeichner.

```swift
// Unterschreiben mit Unterzeichner "a"
try await req.jwt.sign(payload, kid: "a")
```
Dadurch wird der Name des Unterzeichners automatisch in das Feld `"kid"` des JWT-Headers aufgenommen. Bei der Verifizierung des JWT wird dieses Feld verwendet, um den entsprechenden Unterzeichner zu finden.

```swift
// Überprüfung mit dem im "kid"-Kopf angegebenen Unterzeichner.
// Wenn kein "kid"-Header vorhanden ist, wird der Standardunterzeichner verwendet.
let payload = try await req.jwt.verify(as: TestPayload.self)
```

Da [JWKs](#jwk) bereits `kid` Werte enthalten, musst du diese bei der Konfiguration nicht angeben.

```swift
// JWKs enthalten bereits das "kid"-Feld.
let jwk: JWK = ...
try await app.jwt.keys.use(jwk: jwk)
```

## Claims

Das JWT-Paket von Vapor enthält mehrere Hilfsprogramme für die Implementierung gängiger [JWT-Ansprüche](https://tools.ietf.org/html/rfc7519#section-4.1).

|Claim|Type|Verify Method|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Alle Ansprüche sollten mit der Methode `JWTPayload.verify` überprüft werden. Wenn der Anspruch eine spezielle verify-Methode hat, kannst du diese verwenden. Andernfalls greife mit `value` auf den Wert des Anspruchs zu und prüfen, ob er gültig ist.

## JWK

Ein JSON Web Key (JWK) ist eine JavaScript Object Notation (JSON) Datenstruktur, die einen kryptografischen Schlüssel darstellt ([RFC7517](https://tools.ietf.org/html/rfc7517)). Diese werden üblicherweise verwendet, um Clients mit Schlüsseln zur Verifizierung von JWTs zu versorgen.

Zum Beispiel hostet Apple sein _Sign in with Apple_ JWKS unter der folgenden URL.

```http
GET https://appleid.apple.com/auth/keys
```

Du kannst dieses JSON Web Key Set (JWKS) zu `JWTKeyCollection` hinzufügen.
Du kannst dann JWTs von Apple an die Methode `verify` übergeben. Der Schlüsselbezeichner (`kid`) im JWT-Header wird verwendet, um automatisch den richtigen Schlüssel für die Verifizierung auszuwählen.

JWT-Herausgeber können deine JWKS rotieren, was bedeutet, dass du gelegentlich einen neuen Download durchführen musst. Siehe Vapor's unterstützte JWT [Vendors](#vendors) Liste unten für APIs, die dies automatisch tun.

## Vendors

Vapor bietet APIs für die Verarbeitung von JWTs von den unten aufgeführten populären Emittenten.

### Apple

Konfiguriere zunächst die Kennung deiner Apple-Anwendung.

```swift
// Konfiguriere die Apple-App-Kennung.
app.jwt.apple.applicationIdentifier = "..."
```

Verwende dann die Hilfsfunktion `req.jwt.apple`, um ein Apple JWT abzurufen und zu überprüfen.

```swift
// Apple JWT aus dem Autorisierungs-Header abrufen und überprüfen.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Konfiguriere zunächst die Google-Anwendungskennung und den G Suite-Domänennamen.

```swift
// Konfiguriere den Bezeichner der Google-App und den Domänennamen.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Verwende dann die Hilfe `req.jwt.google`, um ein Google JWT zu holen und zu überprüfen.

```swift
// Google JWT aus der Autorisierungskopfzeile abrufen und überprüfen.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Konfiguriere zunächst die Kennung deiner Microsoft-Anwendung.

```swift
// Konfiguriere die Kennung der Microsoft-App.
app.jwt.microsoft.applicationIdentifier = "..."
```

Verwende dann die Hilfsfunktion `req.jwt.microsoft`, um ein Microsoft JWT abzurufen und zu überprüfen.

```swift
// Microsoft JWT aus dem Autorisierungs-Header abrufen und überprüfen.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
