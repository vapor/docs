# JWT

JSON Web Token (JWT) ist ein offener Standard ([RFC 7519](https://tools.ietf.org/html/rfc7519)), der eine kompakte und in sich geschlossene Methode zur sicheren Übertragung von Informationen zwischen Parteien als JSON-Objekt definiert. Diese Informationen können überprüft und als vertrauenswürdig angesehen werden, da sie digital signiert sind.

JWTs sind besonders nützlich in Webanwendungen, wo sie üblicherweise für zustandslose Authentifizierung/Autorisierung und den Austausch von Informationen verwendet werden. Mehr über die Theorie hinter JWTs erfährst du in der oben verlinkten Spezifikation oder auf [jwt.io](https://jwt.io/introduction).

Vapor bietet erstklassige Unterstützung für JWTs durch das `JWT`-Modul. Dieses Modul baut auf der `JWTKit`-Bibliothek auf, einer Swift-Implementierung des JWT-Standards, die auf [SwiftCrypto](https://github.com/apple/swift-crypto) basiert. JWTKit stellt Unterzeichner und Prüfer für eine Vielzahl von Algorithmen bereit, darunter HMAC, ECDSA, EdDSA und RSA.

## Erste Schritte

Der erste Schritt zur Verwendung von JWTs in deiner Vapor-Anwendung besteht darin, die Abhängigkeit `JWT` zur `Package.swift`-Datei deines Projekts hinzuzufügen:

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "JWT", package: "jwt")
        ]),
        // Other targets...
    ]
)
```

### Konfiguration

Nachdem du die Abhängigkeit hinzugefügt hast, kannst du das `JWT`-Modul in deiner Anwendung verwenden. Das JWT-Modul fügt `Application` eine neue Eigenschaft `jwt` hinzu, die für die Konfiguration verwendet wird und deren Interna von der [JWTKit](https://github.com/vapor/jwt-kit)-Bibliothek bereitgestellt werden.

#### Schlüsselsammlung

Das `jwt`-Objekt verfügt über eine Eigenschaft `keys`, eine Instanz von JWTKits `JWTKeyCollection`. Diese Sammlung wird verwendet, um die Schlüssel zu speichern und zu verwalten, mit denen JWTs signiert und verifiziert werden. Die `JWTKeyCollection` ist ein `actor`, was bedeutet, dass alle Operationen auf der Sammlung serialisiert und thread-sicher sind.

Um JWTs zu signieren oder zu verifizieren, musst du einen Schlüssel zur Sammlung hinzufügen. Dies geschieht üblicherweise in deiner Datei `configure.swift`:

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Dies fügt der Schlüsselsammlung einen HMAC-Schlüssel mit SHA-256 als Digest-Algorithmus hinzu, in JWA-Notation auch HS256 genannt. Weitere Informationen zu den verfügbaren Algorithmen findest du im Abschnitt [Algorithmen](#algorithmen) unten.

!!! note 
    Achte darauf, `"secret"` durch einen echten geheimen Schlüssel zu ersetzen. Dieser Schlüssel sollte sicher aufbewahrt werden, idealerweise in einer Konfigurationsdatei oder Umgebungsvariable.

### Signierung

Der hinzugefügte Schlüssel kann anschließend verwendet werden, um JWTs zu signieren. Dazu benötigst du zunächst _etwas_ zum Signieren, nämlich eine „Payload“.
Diese Payload ist einfach ein JSON-Objekt, das die zu übertragenden Daten enthält. Du kannst deine eigene Payload erstellen, indem du deine Struktur dem Protokoll `JWTPayload` anpasst:

```swift
// JWT payload structure.
struct TestPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim

    // Custom data.
    // If true, the user is an admin.
    var isAdmin: Bool

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

Um die Payload zu signieren, rufst du die Methode `sign` des `JWT`-Moduls auf, zum Beispiel innerhalb eines Routen-Handlers:

```swift
app.post("login") { req async throws -> [String: String] in
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    return try await ["token": req.jwt.sign(payload)]
}
```

Wenn eine Anfrage an diesen Endpunkt gestellt wird, gibt dieser das signierte JWT als `String` im Antwortkörper zurück, und wenn alles wie geplant funktioniert hat, siehst du etwas wie das Folgende:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Du kannst dieses Token mit dem [Debugger von `jwt.io`](https://jwt.io/#debugger) dekodieren und überprüfen. Der Debugger zeigt dir die Payload (die den zuvor angegebenen Daten entsprechen sollte) und den Header des JWT, und du kannst die Signatur mit dem geheimen Schlüssel überprüfen, mit dem du das JWT signiert hast.

### Verifizierung

Wenn stattdessen ein Token _an_ deine Anwendung gesendet wird, kannst du die Authentizität des Tokens überprüfen, indem du die Methode `verify` des `JWT`-Moduls aufrufst:

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

Der Helfer `req.jwt.verify` prüft den `Authorization`-Header auf ein Bearer-Token. Wenn eines vorhanden ist, wird das JWT geparst und dessen Signatur sowie die Claims werden verifiziert. Schlägt einer dieser Schritte fehl, wird ein 401-Unauthorized-Fehler ausgelöst.

Teste die Route, indem du die folgende HTTP-Anfrage sendest:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Wenn alles funktioniert hat, wird eine `200 OK`-Antwort zurückgegeben und die Payload ausgegeben:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

Der gesamte Authentifizierungsablauf findet sich unter [Authentifizierung &rarr; JWT](authentication.md#jwt).

## Algorithmen

JWTs können mit einer Vielzahl von Algorithmen signiert werden.

Um einen Schlüssel zur Schlüsselsammlung hinzuzufügen, steht für jeden der folgenden Algorithmen eine Überladung der Methode `add` zur Verfügung:

### HMAC

HMAC (Hash-based Message Authentication Code) ist ein symmetrischer Algorithmus, der einen geheimen Schlüssel verwendet, um das JWT zu signieren und zu verifizieren. Vapor unterstützt die folgenden HMAC-Algorithmen:

- `HS256`: HMAC mit SHA-256
- `HS384`: HMAC mit SHA-384
- `HS512`: HMAC mit SHA-512

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) ist ein asymmetrischer Algorithmus, der ein Paar aus öffentlichem und privatem Schlüssel verwendet, um das JWT zu signieren und zu verifizieren. Er beruht auf der Mathematik der elliptischen Kurven. Vapor unterstützt die folgenden ECDSA-Algorithmen:

- `ES256`: ECDSA mit einer P-256-Kurve und SHA-256
- `ES384`: ECDSA mit einer P-384-Kurve und SHA-384
- `ES512`: ECDSA mit einer P-521-Kurve und SHA-512

Alle Algorithmen stellen sowohl einen öffentlichen als auch einen privaten Schlüssel bereit, wie z. B. `ES256PublicKey` und `ES256PrivateKey`. Du kannst ECDSA-Schlüssel im PEM-Format hinzufügen:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialize an ECDSA key with public PEM.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

oder zufällige generieren (nützlich zum Testen):

```swift
let key = ES256PrivateKey()
```

Um den Schlüssel zur Schlüsselsammlung hinzuzufügen:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) ist ein asymmetrischer Algorithmus, der ein Paar aus öffentlichem und privatem Schlüssel verwendet, um das JWT zu signieren und zu verifizieren. Er ähnelt ECDSA insofern, als beide auf dem DSA-Algorithmus beruhen, aber EdDSA basiert auf der Edwards-Kurve, einer anderen Familie elliptischer Kurven, und bietet leichte Performance-Vorteile. Er ist jedoch auch neuer und daher weniger weit verbreitet. Vapor unterstützt ausschließlich den Algorithmus `EdDSA`, der die Kurve `Ed25519` verwendet.

Du kannst einen EdDSA-Schlüssel über seine (base-64-kodierte `String`-)Koordinate erstellen, also `x`, wenn es sich um einen öffentlichen Schlüssel handelt, und `d`, wenn es sich um einen privaten Schlüssel handelt:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Du kannst auch zufällige Schlüssel generieren:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Um den Schlüssel zur Schlüsselsammlung hinzuzufügen:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) ist ein asymmetrischer Algorithmus, der ein Paar aus öffentlichem und privatem Schlüssel verwendet, um das JWT zu signieren und zu verifizieren.

!!! warning
    Wie du sehen wirst, sind RSA-Schlüssel hinter einem `Insecure`-Namensraum verborgen, um neue Nutzer von ihrer Verwendung abzuschrecken. Der Grund dafür ist, dass RSA als weniger sicher gilt als ECDSA und EdDSA und nur aus Kompatibilitätsgründen verwendet werden sollte.
    Verwende nach Möglichkeit einen der anderen Algorithmen.

Vapor unterstützt die folgenden RSA-Algorithmen:

- `RS256`: RSA mit SHA-256
- `RS384`: RSA mit SHA-384
- `RS512`: RSA mit SHA-512

Du kannst einen RSA-Schlüssel über sein PEM-Format erstellen:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialize an RSA key with public pem.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

oder über seine Komponenten:

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    Das Paket unterstützt keine RSA-Schlüssel, die kleiner als 2048 Bit sind.

Anschließend kannst du den Schlüssel zur Schlüsselsammlung hinzufügen:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Zusätzlich zum RSA-PKCS1v1.5-Algorithmus unterstützt Vapor auch den RSA-PSS-Algorithmus. PSS (Probabilistic Signature Scheme) ist ein sichereres Padding-Schema für RSA-Signaturen. Es wird empfohlen, PSS gegenüber PKCS1v1.5 zu bevorzugen, wo dies möglich ist.

Der Algorithmus unterscheidet sich nur in der Signaturphase, was bedeutet, dass die Schlüssel dieselben sind wie bei RSA. Beim Hinzufügen zur Schlüsselsammlung musst du jedoch das Padding-Schema angeben:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Schlüsselidentifikator (kid)

Beim Hinzufügen eines Schlüssels zur Schlüsselsammlung kannst du auch einen Schlüsselidentifikator (kid) angeben. Dies ist eine eindeutige Kennung für den Schlüssel, mit der der Schlüssel in der Sammlung nachgeschlagen werden kann.

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Wenn du keinen `kid` angibst, wird der Schlüssel als Standardschlüssel zugewiesen.

!!! note
    Der Standardschlüssel wird überschrieben, wenn du einen weiteren Schlüssel ohne `kid` hinzufügst.

Beim Signieren eines JWT kannst du den zu verwendenden `kid` angeben:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Bei der Verifizierung hingegen wird der `kid` automatisch aus dem JWT-Header extrahiert und verwendet, um den Schlüssel in der Sammlung nachzuschlagen. Es gibt außerdem einen Parameter `iteratingKeys` bei der Methode `verify`, mit dem du festlegen kannst, ob alle Schlüssel in der Sammlung durchlaufen werden sollen, falls der `kid` nicht gefunden wird.

## Claims

Vapors JWT-Paket enthält mehrere Hilfsmittel zur Implementierung gängiger [JWT-Ansprüche](https://tools.ietf.org/html/rfc7519#section-4.1).

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

Alle Claims sollten in der Methode `JWTPayload.verify` überprüft werden. Wenn der Claim eine spezielle Verify-Methode besitzt, kannst du diese verwenden. Andernfalls greife über `value` auf den Wert des Claims zu und prüfe, ob er gültig ist.

## JWK

Ein JSON Web Key (JWK) ist eine JSON-Datenstruktur, die einen kryptografischen Schlüssel darstellt ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Diese werden üblicherweise verwendet, um Clients mit Schlüsseln zur Verifizierung von JWTs zu versorgen.

Apple hostet zum Beispiel sein Sign-in-with-Apple-JWKS unter der folgenden URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor stellt Hilfsmittel bereit, um JWKs zur Schlüsselsammlung hinzuzufügen:

```swift
let privateKey = """
{
    "kty": "RSA",
    "d": "\(rsaPrivateExponent)",
    "e": "AQAB",
    "use": "sig",
    "kid": "1234",
    "alg": "RS256",
    "n": "\(rsaModulus)"
}
"""

let jwk = try JWK(json: privateKey)
try await app.jwt.keys.use(jwk: jwk)
```

Dies fügt das JWK zur Schlüsselsammlung hinzu, und du kannst es verwenden, um JWTs zu signieren und zu verifizieren wie mit jedem anderen Schlüssel.

### JWKs

Wenn du mehrere JWKs hast, kannst du diese ebenso hinzufügen:

```swift
let json = """
{
    "keys": [
        {"kty": "RSA", "alg": "RS256", "kid": "a", "n": "\(rsaModulus)", "e": "AQAB"},
        {"kty": "RSA", "alg": "RS512", "kid": "b", "n": "\(rsaModulus)", "e": "AQAB"},
    ]
}
"""

try await app.jwt.keys.use(jwksJSON: json)
```

## Vendors

Vapor bietet APIs für die Verarbeitung von JWTs von den unten aufgeführten populären Ausstellern.

### Apple

Konfiguriere zunächst die Kennung deiner Apple-Anwendung.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

Verwende dann den Helfer `req.jwt.apple`, um ein Apple-JWT abzurufen und zu verifizieren.

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Konfiguriere zunächst die Kennung deiner Google-Anwendung sowie den G-Suite-Domänennamen.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Verwende dann den Helfer `req.jwt.google`, um ein Google-JWT abzurufen und zu verifizieren.

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Konfiguriere zunächst die Kennung deiner Microsoft-Anwendung.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

Verwende dann den Helfer `req.jwt.microsoft`, um ein Microsoft-JWT abzurufen und zu verifizieren.

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
