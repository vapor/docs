# JWT


JSON Web Token (JWT) is een open standaard ([RFC 7519](https://tools.ietf.org/html/rfc7519)) die een compacte en op zichzelf staande manier definieert voor het veilig verzenden van informatie tussen partijen als een JSON-object. Deze informatie kan worden geverifieerd en vertrouwd omdat ze digitaal ondertekend is. JWT's kunnen worden ondertekend met een geheim (met het HMAC-algoritme) of een openbaar/particulier sleutelpaar met RSA of ECDSA.

## Getting Started

De eerste stap om JWT te gebruiken is het toevoegen van de afhankelijkheid aan uw [Package.swift](../getting-started/spm.md#package-manifest).

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
		 // Andere afhankelijkheden...
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Andere afhankelijkheden...
            .product(name: "JWT", package: "jwt")
        ]),
        // Andere targets...
    ]
)
```

Als u het manifest direct in Xcode bewerkt, zal het automatisch de wijzigingen oppikken en de nieuwe afhankelijkheid ophalen wanneer het bestand wordt opgeslagen. Anders, voer `swift package resolve` uit om de nieuwe dependency op te halen.

### Configuratie

De JWT module voegt een nieuwe property `jwt` toe aan `Application` die wordt gebruikt voor configuratie. Om JWTs te ondertekenen of verifiëren, moet je een ondertekenaar toevoegen. Het eenvoudigste onderteken algoritme is `HS256` of HMAC met SHA-256. 

```swift
import JWT

// Voeg HMAC toe met SHA-256 ondertekenaar.
app.jwt.signers.use(.hs256(key: "secret"))
```

De `HS256` ondertekenaar heeft een sleutel nodig om te initialiseren. In tegenstelling tot andere ondertekenaars, wordt deze sleutel gebruikt voor zowel het ondertekenen _als_ het verifiëren van tokens. Hieronder vindt u meer informatie over de beschikbare [algoritmen](#algoritmen).

### Payload

Laten we proberen het volgende voorbeeld JWT te verifiëren.

```swift
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

U kunt de inhoud van dit token inspecteren door [jwt.io](https://jwt.io) te bezoeken en het token in de debugger te plakken. Zet de sleutel in de "Verify Signature" sectie op `secret`. 

We moeten een struct maken die voldoet aan `JWTPayload` die de structuur van de JWT weergeeft. We zullen JWT's meegeleverde [claims](#claims) gebruiken om veel voorkomende velden zoals `sub` en `exp` te behandelen. 

```swift
// JWT payload structuur.
struct TestPayload: JWTPayload {
    // Zet de langere Swift-eigenschapnamen om in de
    // verkorte sleutels die gebruikt worden in de JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // De "sub" (onderwerp) claim identificeert de principal die het
    // onderwerp van de JWT is.
    var subject: SubjectClaim

    // De "exp" (vervaltijd) claim identificeert de vervaltijd op
    // of waarna de JWT NIET voor verwerking MOET worden geaccepteerd.
    var expiration: ExpirationClaim

    // Aangepaste gegevens.
    // Indien waar, de gebruiker is een admin.
    var isAdmin: Bool

    // Voer eventuele extra verificatielogica uit
    // handtekening verificatie hier.
    // Omdat we een ExpirationClaim hebben, zullen we
    // zijn verificatiemethode aanroepen.
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
```

### Verifiëren

Nu we een `JWTPayload` hebben, kunnen we de bovenstaande JWT aan een request koppelen en `req.jwt` gebruiken om het op te halen en te verifiëren. Voeg de volgende route toe aan je project. 

```swift
// Haal en verifieer JWT van inkomend verzoek.
app.get("me") { req -> HTTPStatus in
    let payload = try req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

De `req.jwt.verify` helper controleert de `Authorization` header voor een bearer token. Als er een bestaat, zal het de JWT parsen en de handtekening en claims verifiëren. Als een van deze stappen mislukt, zal een _401 Unauthorized_ foutmelding worden gegeven.

Test de route door het volgende HTTP verzoek te versturen. 

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Als alles gelukt is, wordt een _200 OK_ antwoord teruggestuurd en wordt de payload afgedrukt:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

### Ondertekenen

Dit pakket kan ook JWTs _genereren_, ook bekend als ondertekenen. Om dit te demonstreren, laten we de `TestPayload` uit de vorige sectie gebruiken. Voeg de volgende route toe aan je project.

```swift
// Genereer en stuur een nieuwe JWT terug.
app.post("login") { req -> [String: String] in
    // Maak een nieuwe instantie van onze JWTPayload
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    // Geef de ondertekende JWT terug
    return try [
        "token": req.jwt.sign(payload)
    ]
}
```

De `req.jwt.sign` helper zal de standaard geconfigureerde signer gebruiken om de `JWTPayload` te serialiseren en te ondertekenen. De ge-encodeerde JWT wordt geretourneerd als een `String`. 

Test de route door het volgende HTTP verzoek te versturen. 

```http
POST /login HTTP/1.1
```

U zou het nieuw gegenereerde token moeten zien terugkomen in een _200 OK_ antwoord.

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

## Authenticatie

Ga voor meer informatie over het gebruik van JWT met de authenticatie-API van Vapor naar [Authenticatie &rarr; JWT](authentication.md#jwt).

## Algoritmes

Vapor's JWT API ondersteunt het verifiëren en ondertekenen van tokens met de volgende algoritmen.

### HMAC

HMAC is het eenvoudigste JWT-signaleringsalgoritme. Het gebruikt een enkele sleutel die zowel tokens kan ondertekenen als verifiëren. De sleutel kan elke lengte hebben.

- `hs256`: HMAC met SHA-256
- `hs384`: HMAC met SHA-384
- `hs512`: HMAC met SHA-512

```swift
// Voeg HMAC toe met SHA-256 signer.
app.jwt.signers.use(.hs256(key: "secret"))
```

### RSA

RSA is het meest gebruikte JWT-signaleringsalgoritme. Het ondersteunt verschillende publieke en private sleutels. Dit betekent dat een publieke sleutel kan worden verspreid om te verifiëren of JWT's authentiek zijn, terwijl de private sleutel die ze genereert, geheim wordt gehouden.

Om een RSA signer te maken, moet eerst een `RSAKey` geïnitialiseerd worden. Dit kan gedaan worden door de componenten in te voeren.

```swift
// Initialiseer een RSA sleutel met componenten.
let key = RSAKey(
    modulus: "...",
    exponent: "...",
    // Alleen opgenomen in private sleutels.
    privateExponent: "..."
)
```

U kunt er ook voor kiezen een PEM-bestand in te laden:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialiseer een RSA sleutel met publieke pem.
let key = RSAKey.public(pem: rsaPublicKey)
```

Gebruik `.private` voor het laden van private RSA PEM sleutels. Deze beginnen met:

```
-----BEGIN RSA PRIVATE KEY-----
```

Zodra u de RSAKey hebt, kunt u die gebruiken om een RSA-signer aan te maken.

- `rs256`: RSA met SHA-256
- `rs384`: RSA met SHA-384
- `rs512`: RSA met SHA-512

```swift
// RSA toevoegen met SHA-256 ondertekenaar.
try app.jwt.signers.use(.rs256(key: .public(pem: rsaPublicKey)))
```

### ECDSA

ECDSA is een moderner algoritme dat lijkt op RSA. Het wordt geacht veiliger te zijn voor een gegeven sleutellengte dan RSA[^1]. U moet echter uw eigen onderzoek doen voordat u een beslissing neemt. 

[^1]: [https://sectigostore.com/blog/ecdsa-vs-rsa-everything-you-need-to-know/](https://sectigostore.com/blog/ecdsa-vs-rsa-everything-you-need-to-know/)

Net als RSA kunt u ECDSA-sleutels inladen met PEM-bestanden: 

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialiseer een ECDSA sleutel met publieke PEM.
let key = ECDSAKey.public(pem: ecdsaPublicKey)
```

Gebruik `.private` voor het laden van private ECDSA PEM sleutels. Deze beginnen met:

```
-----BEGIN PRIVATE KEY-----
```

U kunt ook willekeurige ECDSA genereren met de `generate()` methode. Dit is handig voor testen.

```swift
let key = try ECDSAKey.generate()
```

Als u de ECDSAKey heeft, kunt u die gebruiken om een ECDSA-signer aan te maken.

- `es256`: ECDSA met SHA-256
- `es384`: ECDSA met SHA-384
- `es512`: ECDSA met SHA-512

```swift
// ECDSA toevoegen met SHA-256 ondertekenaar.
try app.jwt.signers.use(.es256(key: .public(pem: ecdsaPublicKey)))
```

### Key Identifier (kid)

Als je meerdere algoritmes gebruikt, kun je sleutel-identifiers (`kid`s) gebruiken om ze te onderscheiden. Wanneer je een algoritme configureert, geef je de `kid` parameter door. 

```swift
// Voeg HMAC toe met SHA-256 ondertekenaar genaamd "a".
app.jwt.signers.use(.hs256(key: "foo"), kid: "a")
// Voeg HMAC toe met SHA-256 ondertekenaar genaamd "b".
app.jwt.signers.use(.hs256(key: "bar"), kid: "b")
```

Bij het ondertekenen van JWTs, geef de `kid` parameter door voor de gewenste ondertekenaar.

```swift
// Onderteken met ondertekenaar "a"
req.jwt.sign(payload, kid: "a")
```

Hierdoor wordt de naam van de ondertekenaar automatisch opgenomen in het `"kid"` veld van de JWT header. Bij het verifiëren van de JWT, zal dit veld gebruikt worden om de juiste ondertekenaar op te zoeken. 

```swift
// Verifieer met de ondertekenaar gespecificeerd door de "kid" header.
// Als er geen "kid" header aanwezig is, zal de standaard ondertekenaar gebruikt worden.
let payload = try req.jwt.verify(as: TestPayload.self)
```

Omdat [JWKs](#jwk) al `kid` waarden bevatten, hoeft u deze niet te specificeren tijdens de configuratie.

```swift
// JWK's bevatten al het "kid" veld.
let jwk: JWK = ...
app.jwt.signers.use(jwk: jwk)
```

## Claims

Het JWT-pakket van Vapor bevat verschillende helpers voor de implementatie van veelvoorkomende [JWT-claims](https://tools.ietf.org/html/rfc7519#section-4.1). 

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

Alle claims moeten geverifieerd worden in de `JWTPayload.verify` methode. Als de claim een speciale `verifieer` methode heeft, kun je die gebruiken. Anders kun je met `value` de waarde van de claim opvragen en controleren of deze geldig is.

## JWK

Een JSON Web Key (JWK) is een JavaScript Object Notation (JSON) datastructuur die een cryptografische sleutel voorstelt ([RFC7517](https://tools.ietf.org/html/rfc7517)). Deze worden gewoonlijk gebruikt om cliënten sleutels te verstrekken voor het verifiëren van JWT's.

Bijvoorbeeld, Apple host zijn _Sign in with Apple_ JWKS op de volgende URL.

```http
GET https://appleid.apple.com/auth/keys
```

U kunt deze JSON Web Key Set (JWKS) toevoegen aan uw `JWTSigners`. 

```swift
import JWT
import Vapor

// Download de JWKS.
// Dit kan asynchroon gedaan worden indien nodig.
let jwksData = try Data(
    contentsOf: URL(string: "https://appleid.apple.com/auth/keys")!
)

// Decodeer de gedownloade JSON.
let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)

// Creëer ondertekenaars en voeg JWKS toe.
try app.jwt.signers.use(jwks: jwks)
```

U kunt nu JWTs van Apple doorgeven aan de `verify` methode. De key identifier (`kid`) in de JWT header zal worden gebruikt om automatisch de juiste key te selecteren voor verificatie.

Op het moment van schrijven ondersteunt JWK alleen RSA-sleutels. Bovendien kunnen JWT-emittenten hun JWKS roteren, wat betekent dat u deze af en toe opnieuw moet downloaden. Zie Vapor's ondersteunde JWT [Vendors](#vendors) lijst hieronder voor API's die dit automatisch doen.

## Vendors

Vapor biedt API's voor het verwerken van JWT's van de populaire uitgevers hieronder.

### Apple

Configureer eerst uw Apple applicatie-id.

```swift
// Configureer Apple app identificatie.
app.jwt.apple.applicationIdentifier = "..."
```

Gebruik dan de `req.jwt.apple` helper om een Apple JWT op te halen en te verifiëren. 

```swift
// Haal en verifieer Apple JWT van de autorisatie header.
app.get("apple") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.apple.verify().map { token in
        print(token) // AppleIdentityToken
        return .ok
    }
}

// Of

app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Configureer eerst uw Google applicatie-id en G Suite domeinnaam.

```swift
// Configureer Google app identifier en domeinnaam.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Gebruik dan de `req.jwt.google` helper om een Google JWT op te halen en te verifiëren. 

```swift
// Haal en verifieer Google JWT uit de autorisatie header.
app.get("google") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.google.verify().map { token in
        print(token) // GoogleIdentityToken
        return .ok
    }
}

// of

app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Configureer eerst uw Microsoft applicatie-id.

```swift
// Configureer Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

Gebruik dan de `req.jwt.microsoft` helper om een Microsoft JWT op te halen en te verifiëren. 

```swift
// Haal en verifieer Microsoft JWT van de autorisatie header.
app.get("microsoft") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.microsoft.verify().map { token in
        print(token) // MicrosoftIdentityToken
        return .ok
    }
}

// Of

app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
