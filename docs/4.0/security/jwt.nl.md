# JWT

JSON Web Token (JWT) is een open standaard ([RFC 7519](https://tools.ietf.org/html/rfc7519)) die een compacte en op zichzelf staande manier definieert voor het veilig verzenden van informatie tussen partijen als een JSON-object. Deze informatie kan worden geverifieerd en vertrouwd omdat ze digitaal ondertekend is.

JWT's zijn bijzonder nuttig in webapplicaties, waar ze vaak worden gebruikt voor stateless authenticatie/autorisatie en het uitwisselen van informatie. U kunt meer lezen over de theorie achter JWT's in de hierboven gelinkte spec of op [jwt.io](https://jwt.io/introduction).

Vapor biedt eersteklas ondersteuning voor JWT's via de `JWT` module. Deze module is gebouwd bovenop de `JWTKit` bibliotheek, een Swift-implementatie van de JWT-standaard gebaseerd op [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit biedt ondertekenaars en verifiers voor verschillende algoritmen, waaronder HMAC, ECDSA, EdDSA en RSA.

## Getting Started

De eerste stap om JWT's in uw Vapor applicatie te gebruiken, is het toevoegen van de `JWT` dependency aan het `Package.swift` bestand van uw project: 

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

### Configuratie

Nadat u de dependency hebt toegevoegd, kunt u de `JWT` module in uw applicatie gaan gebruiken. De JWT module voegt een nieuwe `jwt` property toe aan `Application` die gebruikt wordt voor configuratie, waarvan de interne werking geleverd wordt door de [JWTKit](https://github.com/vapor/jwt-kit) bibliotheek.

#### Sleutelverzameling

Het `jwt` object heeft een `keys` property, een instantie van JWTKit's `JWTKeyCollection`. Deze collectie wordt gebruikt om de sleutels op te slaan en te beheren die gebruikt worden om JWT's te ondertekenen en te verifiëren. De `JWTKeyCollection` is een `actor`, wat betekent dat alle bewerkingen op de collectie geserialiseerd en thread-safe zijn.

Om JWT's te ondertekenen of te verifiëren, moet u een sleutel aan de collectie toevoegen. Dit gebeurt meestal in uw `configure.swift` bestand:

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Dit voegt een HMAC-sleutel met SHA-256 als digest-algoritme toe aan de sleutelbos, oftewel HS256 in JWA-notatie. Bekijk de [algoritmen](#algorithms) sectie hieronder voor meer informatie over de beschikbare algoritmen.

!!! note 
    Zorg ervoor dat u `"secret"` vervangt door een echte geheime sleutel. Deze sleutel moet veilig bewaard worden, idealiter in een configuratiebestand of omgevingsvariabele.

### Ondertekenen

De toegevoegde sleutel kan vervolgens gebruikt worden om JWT's te ondertekenen. Om dit te doen, hebt u eerst _iets_ nodig om te ondertekenen, namelijk een 'payload'. 
Deze payload is simpelweg een JSON-object dat de gegevens bevat die u wilt verzenden. U kunt uw eigen payload maken door uw structuur te laten voldoen aan het `JWTPayload` protocol:

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

Het ondertekenen van de payload gebeurt door de `sign` methode van de `JWT` module aan te roepen, bijvoorbeeld binnen een route handler:

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

Wanneer een request naar dit endpoint wordt gestuurd, retourneert het de ondertekende JWT als een `String` in de response body, en als alles volgens plan verliep, ziet u zoiets als dit:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

U kunt dit token decoderen en verifiëren met behulp van de [`jwt.io` debugger](https://jwt.io/#debugger). De debugger toont de payload (dit zou de gegevens moeten zijn die u eerder opgegeven hebt) en de header van de JWT, en u kunt de handtekening verifiëren met de geheime sleutel die u gebruikt hebt om de JWT te ondertekenen.

### Verifiëren

Wanneer er juist een token _naar_ uw applicatie gestuurd wordt, kunt u de authenticiteit van het token verifiëren door de `verify` methode van de `JWT` module aan te roepen:

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

De `req.jwt.verify` helper controleert de `Authorization` header op een bearer token. Als er een bestaat, zal het de JWT parsen en de handtekening en claims verifiëren. Als een van deze stappen mislukt, wordt een 401 Unauthorized fout gegenereerd.

Test de route door het volgende HTTP verzoek te versturen:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Als alles gelukt is, wordt een `200 OK` response teruggestuurd en wordt de payload afgedrukt:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

De volledige authenticatieflow is te vinden op [Authenticatie &rarr; JWT](authentication.md#jwt).

## Algoritmen

JWT's kunnen worden ondertekend met verschillende algoritmen. 

Om een sleutel aan de sleutelbos toe te voegen, is voor elk van de volgende algoritmen een overload van de `add` methode beschikbaar:

### HMAC

HMAC (Hash-based Message Authentication Code) is een symmetrisch algoritme dat een geheime sleutel gebruikt om de JWT te ondertekenen en te verifiëren. Vapor ondersteunt de volgende HMAC-algoritmen:

- `HS256`: HMAC met SHA-256
- `HS384`: HMAC met SHA-384
- `HS512`: HMAC met SHA-512

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) is een asymmetrisch algoritme dat een publiek/privé sleutelpaar gebruikt om de JWT te ondertekenen en te verifiëren. Het berust op de wiskunde rondom elliptische krommen. Vapor ondersteunt de volgende ECDSA-algoritmen:

- `ES256`: ECDSA met een P-256 curve en SHA-256
- `ES384`: ECDSA met een P-384 curve en SHA-384
- `ES512`: ECDSA met een P-521 curve en SHA-512

Alle algoritmen bieden zowel een publieke als een privésleutel, zoals `ES256PublicKey` en `ES256PrivateKey`. U kunt ECDSA-sleutels toevoegen met behulp van het PEM-formaat:

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

of genereer willekeurige (handig voor testen): 

```swift
let key = ES256PrivateKey()
```

Om de sleutel aan de sleutelbos toe te voegen:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) is een asymmetrisch algoritme dat een publiek/privé sleutelpaar gebruikt om de JWT te ondertekenen en te verifiëren. Het lijkt op ECDSA doordat beide berusten op het DSA-algoritme, maar EdDSA is gebaseerd op de Edwards-curve, een andere familie van elliptische krommen, en heeft daardoor een licht betere performance. Het is echter ook nieuwer en dus minder breed ondersteund. Vapor ondersteunt alleen het `EdDSA` algoritme, dat de `Ed25519` curve gebruikt.

U kunt een EdDSA-sleutel maken met behulp van zijn (base64-gecodeerde `String`) coördinaat, dus `x` als het een publieke sleutel is en `d` als het een privésleutel is:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

U kunt ook willekeurige genereren:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Om de sleutel aan de sleutelbos toe te voegen:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) is een asymmetrisch algoritme dat een publiek/privé sleutelpaar gebruikt om de JWT te ondertekenen en te verifiëren. 

!!! warning
    Zoals u zult zien, zijn RSA-sleutels afgeschermd achter een `Insecure` namespace om nieuwe gebruikers te ontmoedigen deze te gebruiken. Dit komt doordat RSA als minder veilig wordt beschouwd dan ECDSA en EdDSA, en enkel om compatibiliteitsredenen gebruikt zou moeten worden.
    Gebruik indien mogelijk een van de andere algoritmen.

Vapor ondersteunt de volgende RSA-algoritmen:

- `RS256`: RSA met SHA-256
- `RS384`: RSA met SHA-384
- `RS512`: RSA met SHA-512

U kunt een RSA-sleutel maken met het PEM-formaat:

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

of met behulp van de componenten:

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    Het package ondersteunt geen RSA-sleutels kleiner dan 2048 bits.

Vervolgens kunt u de sleutel toevoegen aan de sleutelverzameling:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Naast het RSA-PKCS1v1.5 algoritme ondersteunt Vapor ook het RSA-PSS algoritme. PSS (Probabilistic Signature Scheme) is een veiliger padding-schema voor RSA-handtekeningen. Het wordt aangeraden om waar mogelijk PSS te gebruiken in plaats van PKCS1v1.5.

Het algoritme verschilt alleen in de ondertekeningsfase, wat betekent dat de sleutels dezelfde zijn als bij RSA, maar u moet wel het padding-schema opgeven wanneer u ze aan de sleutelverzameling toevoegt:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Sleutelidentificator (kid)

Bij het toevoegen van een sleutel aan de sleutelverzameling kunt u ook een sleutelidentificator (kid) opgeven. Dit is een unieke identificator voor de sleutel die gebruikt kan worden om de sleutel in de collectie op te zoeken. 

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Als u geen `kid` opgeeft, wordt de sleutel toegewezen als de standaardsleutel.

!!! note
    De standaardsleutel wordt overschreven als u een andere sleutel toevoegt zonder `kid`.

Bij het ondertekenen van een JWT kunt u opgeven welke `kid` gebruikt moet worden:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Bij het verifiëren daarentegen wordt de `kid` automatisch uit de JWT header gehaald en gebruikt om de sleutel in de collectie op te zoeken. Er is ook een `iteratingKeys` parameter op de verify methode waarmee u kunt opgeven of over alle sleutels in de collectie geïtereerd moet worden als de `kid` niet gevonden wordt.

## Claims

Vapor's JWT package bevat verschillende helpers voor het implementeren van veelvoorkomende [JWT claims](https://tools.ietf.org/html/rfc7519#section-4.1). 

|Claim|Type|Verifieer Methode|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Alle claims moeten geverifieerd worden in de `JWTPayload.verify` methode. Als de claim een speciale verifieermethode heeft, kunt u die gebruiken. Anders kunt u de waarde van de claim opvragen met `value` en controleren of deze geldig is.

## JWK

Een JSON Web Key (JWK) is een JSON datastructuur die een cryptografische sleutel voorstelt ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Deze worden gewoonlijk gebruikt om clients sleutels te verstrekken voor het verifiëren van JWT's.

Apple host bijvoorbeeld hun Sign in with Apple JWKS op de volgende URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor biedt hulpprogramma's om JWK's aan de sleutelverzameling toe te voegen:

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

Dit voegt de JWK toe aan de sleutelverzameling, en u kunt deze gebruiken om JWT's te ondertekenen en te verifiëren zoals met elke andere sleutel.

### JWKs

Als u meerdere JWK's hebt, kunt u deze net zo goed toevoegen:

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

Vapor biedt API's voor het verwerken van JWT's van de populaire uitgevers hieronder.

### Apple

Configureer eerst uw Apple applicatie-identificator.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

Gebruik vervolgens de `req.jwt.apple` helper om een Apple JWT op te halen en te verifiëren. 

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Configureer eerst uw Google applicatie-identificator en G Suite domeinnaam.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Gebruik vervolgens de `req.jwt.google` helper om een Google JWT op te halen en te verifiëren. 

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Configureer eerst uw Microsoft applicatie-identificator.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

Gebruik vervolgens de `req.jwt.microsoft` helper om een Microsoft JWT op te halen en te verifiëren. 

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
