# JWT

JSON Web Token (JWT) è uno standard aperto ([RFC 7519](https://tools.ietf.org/html/rfc7519)) che definisce un modo compatto e autonomo per trasmettere in modo sicuro informazioni tra attori come oggetto JSON. Queste informazioni possono essere verificate e considerate attendibili perché sono firmate digitalmente.

I JWT sono particolarmente utili nelle applicazioni web, dove sono comunemente usati per l'autenticazione/autorizzazione stateless e lo scambio di informazioni. Puoi leggere di più sulla teoria dietro i JWT nella specifica collegata sopra o su [jwt.io](https://jwt.io/introduction).

Vapor fornisce supporto di prima classe per i JWT tramite il modulo `JWT`. Questo modulo è costruito sulla libreria `JWTKit`, che è un'implementazione Swift dello standard JWT basata su [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit fornisce firmatari e verificatori per una varietà di algoritmi, tra cui HMAC, ECDSA, EdDSA e RSA.

## Iniziare

Il primo passo per usare i JWT nella tua applicazione Vapor è aggiungere la dipendenza `JWT` al file `Package.swift` del tuo progetto:

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Altre dipendenze...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Altre dipendenze...
            .product(name: "JWT", package: "jwt")
        ]),
        // Altri target...
    ]
)
```

### Configurazione

Dopo aver aggiunto la dipendenza, puoi iniziare a usare il modulo `JWT` nella tua applicazione. Il modulo JWT aggiunge una nuova proprietà `jwt` ad `Application` che viene usata per la configurazione, i cui dettagli interni sono forniti dalla libreria [JWTKit](https://github.com/vapor/jwt-kit).

#### Key Collection

L'oggetto `jwt` viene fornito con una proprietà `keys`, che è un'istanza di `JWTKeyCollection` di JWTKit. Questa collezione viene usata per memorizzare e gestire le chiavi usate per firmare e verificare i JWT. `JWTKeyCollection` è un `actor`, il che significa che tutte le operazioni sulla collezione sono serializzate e thread-safe.

Per firmare o verificare i JWT, dovrai aggiungere una chiave alla collezione. Questo viene solitamente fatto nel file `configure.swift`:

```swift
import JWT

// Aggiunta di una chiave HMAC con SHA-256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Questo aggiunge una chiave HMAC con SHA-256 come algoritmo di digest al keychain, o HS256 nella notazione JWA. Consulta la sezione [algoritmi](#algoritmi) di seguito per ulteriori informazioni sugli algoritmi disponibili.

!!! note "Nota"
    Assicurati di sostituire `"secret"` con una chiave segreta reale. Questa chiave dovrebbe essere mantenuta al sicuro, idealmente in un file di configurazione o in una variabile d'ambiente.

### Firma

La chiave aggiunta può poi essere usata per firmare i JWT. Per farlo, hai prima bisogno di _qualcosa_ da firmare, ovvero un 'payload'.
Questo payload è semplicemente un oggetto JSON contenente i dati che vuoi trasmettere. Puoi creare il tuo payload personalizzato conformando la tua struttura al protocollo `JWTPayload`:

```swift
// Struttura del payload JWT personalizzato.
struct TestPayload: JWTPayload {
    // Mappa i nomi delle proprietà Swift più lunghi alle
    // chiavi abbreviate usate nel payload JWT.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // Il claim "sub" (subject) identifica il soggetto del JWT.
    var subject: SubjectClaim

    // Il claim "exp" (expiration time) identifica il momento di scadenza
    // o successivo al quale il JWT NON DEVE essere accettato per l'elaborazione.
    var expiration: ExpirationClaim

    // Dati personalizzati.
    // Se true, l'utente è un amministratore.
    var isAdmin: Bool

    // Esegui qualsiasi logica di verifica aggiuntiva oltre
    // alla verifica della firma qui.
    // Poiché abbiamo un ExpirationClaim, chiameremo
    // il suo metodo verify.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

La firma del payload viene eseguita chiamando il metodo `sign` sul modulo `JWT`, per esempio all'interno di un handler di route:

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

Quando viene fatta una richiesta a questo endpoint, restituirà il JWT firmato come `String` nel corpo della risposta, e se tutto è andato secondo i piani, vedrai qualcosa di simile a questo:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Puoi decodificare e verificare questo token usando il [debugger di `jwt.io`](https://jwt.io/#debugger). Il debugger ti mostrerà il payload (che dovrebbe essere i dati che hai specificato in precedenza) e l'intestazione del JWT, e puoi verificare la firma usando la chiave segreta che hai usato per firmare il JWT.

### Verifica

Quando invece viene inviato un token _alla_ tua applicazione, puoi verificare l'autenticità del token chiamando il metodo `verify` sul modulo `JWT`:

```swift
// Ottieni e verifica il JWT dall'header Authorization.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

Il helper `req.jwt.verify` verificherà l'header `Authorization` per un token bearer. Se ne esiste uno, analizzerà il JWT e verificherà la sua firma e i claim. Se uno qualsiasi di questi passaggi fallisce, verrà lanciato un errore 401 Unauthorized.

Testa la route inviando la seguente richiesta HTTP:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Se tutto ha funzionato, verrà restituita una risposta `200 OK` e il payload verrà stampato:

```swift
TestPayload(
    subject: "vapor",
    expiration: 4001-01-01 00:00:00 +0000,
    isAdmin: true
)
```

L'intero flusso di autenticazione può essere trovato in [Autenticazione &rarr; JWT](authentication.it.md#jwt).

## Algoritmi

I JWT possono essere firmati usando una varietà di algoritmi.

Per aggiungere una chiave al keychain, è disponibile un overload del metodo `add` per ciascuno dei seguenti algoritmi:

### HMAC

HMAC (Hash-based Message Authentication Code) è un algoritmo simmetrico che usa una chiave segreta per firmare e verificare il JWT. Vapor supporta i seguenti algoritmi HMAC:

- `HS256`: HMAC con SHA-256
- `HS384`: HMAC con SHA-384
- `HS512`: HMAC con SHA-512

```swift
// Aggiunta di una chiave HMAC con SHA-256.\
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) è un algoritmo asimmetrico che usa una coppia di chiavi pubblica/privata per firmare e verificare il JWT. La sua affidabilità si basa sulla matematica delle curve ellittiche. Vapor supporta i seguenti algoritmi ECDSA:

- `ES256`: ECDSA con una curva P-256 e SHA-256
- `ES384`: ECDSA con una curva P-384 e SHA-384
- `ES512`: ECDSA con una curva P-521 e SHA-512

Tutti gli algoritmi forniscono sia una chiave pubblica che una chiave privata, come `ES256PublicKey` e `ES256PrivateKey`. Puoi aggiungere chiavi ECDSA usando il formato PEM:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Inizializza una chiave ECDSA con PEM pubblico.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

o generarne di casuali (utile per il testing):

```swift
let key = ES256PrivateKey()
```

Per aggiungere la chiave al keychain:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) è un algoritmo asimmetrico che usa una coppia di chiavi pubblica/privata per firmare e verificare il JWT. È simile a ECDSA in quanto entrambi si basano sull'algoritmo DSA, ma EdDSA è basato sulla curva di Edwards, una famiglia diversa di curve ellittiche, e presenta leggeri miglioramenti delle prestazioni. Tuttavia, è anche più recente e quindi meno ampiamente supportato. Vapor supporta solo l'algoritmo `EdDSA` che usa la curva `Ed25519`.

Puoi creare una chiave EdDSA usando la sua coordinata (stringa codificata in base-64), quindi `x` se è una chiave pubblica e `d` se è una chiave privata:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Puoi anche generarne di casuali:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Per aggiungere la chiave al keychain:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) è un algoritmo asimmetrico che usa una coppia di chiavi pubblica/privata per firmare e verificare il JWT.

!!! warning "Attenzione"
    Come vedrai, le chiavi RSA sono nascoste dietro un namespace `Insecure` per scoraggiare i nuovi utenti dall'usarle. Questo perché RSA è considerato meno sicuro di ECDSA e EdDSA, e dovrebbe essere usato solo per motivi di compatibilità.
    Se possibile, usa uno qualsiasi degli altri algoritmi.

Vapor supporta i seguenti algoritmi RSA:

- `RS256`: RSA con SHA-256
- `RS384`: RSA con SHA-384
- `RS512`: RSA con SHA-512

Puoi creare una chiave RSA usando il suo formato PEM:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Inizializza una chiave RSA con PEM pubblico.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

o usando i suoi componenti:

```swift
// Inizializza una chiave RSA privata con i componenti.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus,
    exponent: publicExponent,
    privateExponent: privateExponent
)
```

!!! warning "Attenzione"
    Il pacchetto non supporta chiavi RSA più piccole di 2048 bit.

Poi puoi aggiungere la chiave alla key collection:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Oltre all'algoritmo RSA-PKCS1v1.5, Vapor supporta anche l'algoritmo RSA-PSS. PSS (Probabilistic Signature Scheme) è uno schema di padding più sicuro per le firme RSA. Si raccomanda di usare PSS rispetto a PKCS1v1.5 quando possibile.

L'algoritmo differisce solo nella fase di firma, il che significa che le chiavi sono le stesse di RSA, tuttavia, devi specificare lo schema di padding quando le aggiungi alla key collection:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Key Identifier (kid)

Quando si aggiunge una chiave alla key collection, puoi anche specificare un key identifier (kid). Questo è un identificatore univoco per la chiave che può essere usato per cercare la chiave nella collezione.

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Se non specifichi un `kid`, la chiave verrà assegnata come chiave predefinita.

!!! note
    La chiave predefinita verrà sovrascritta se aggiungi un'altra chiave senza `kid`.

Quando si firma un JWT, puoi specificare il `kid` da usare:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Quando invece si verifica, il `kid` viene estratto automaticamente dall'intestazione del JWT e usato per cercare la chiave nella collezione. C'è anche un parametro `iteratingKeys` sul metodo verify che ti consente di specificare se iterare su tutte le chiavi nella collezione se il `kid` non viene trovato.

## Claim

Il pacchetto JWT di Vapor include diversi helper per implementare i [claim JWT](https://tools.ietf.org/html/rfc7519#section-4.1) comuni.

|Claim|Tipo|Metodo di Verifica|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Tutti i claim dovrebbero essere verificati nel metodo `JWTPayload.verify`. Se il claim ha un metodo di verifica speciale, puoi usarlo. Altrimenti, accedi al valore del claim usando `value` e verifica che sia valido.

## JWK

Un JSON Web Key (JWK) è una struttura dati JSON che rappresenta una chiave crittografica ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Sono comunemente usati per fornire ai client le chiavi per verificare i JWT.

Per esempio, Apple ospita i suoi JWKS di Sign in with Apple al seguente URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor fornisce utility per aggiungere JWK alla key collection:

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

Questo aggiungerà il JWK alla key collection, e puoi usarlo per firmare e verificare i JWT come faresti con qualsiasi altra chiave.

### JWKs

Se hai più JWK, puoi aggiungerli ugualmente:

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

## Vendor

Vapor fornisce API per la gestione dei JWT dai popolari emittenti di seguito.

### Apple

Prima, configura il tuo identificatore di applicazione Apple.

```swift
// Configura l'identificatore dell'app Apple.
app.jwt.apple.applicationIdentifier = "..."
```

Poi, usa il helper `req.jwt.apple` per recuperare e verificare un JWT Apple.

```swift
// Ottieni e verifica il JWT Apple dall'header Authorization.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Prima, configura il tuo identificatore di applicazione Google e il nome di dominio G Suite.

```swift
// Configura l'identificatore dell'app Google e il nome di dominio G Suite.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Poi, usa il helper `req.jwt.google` per recuperare e verificare un JWT Google.

```swift
// Ottieni e verifica il JWT Google dall'header Authorization.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Prima, configura il tuo identificatore di applicazione Microsoft.

```swift
// Configura l'identificatore dell'app Microsoft.
app.jwt.microsoft.applicationIdentifier = "..."
```

Poi, usa il helper `req.jwt.microsoft` per recuperare e verificare un JWT Microsoft.

```swift
// Ottieni e verifica il JWT Microsoft dall'header Authorization.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
