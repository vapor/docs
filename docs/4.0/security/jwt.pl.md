# JWT

JSON Web Token (JWT) to otwarty standard ([RFC 7519](https://tools.ietf.org/html/rfc7519)), który definiuje zwarty i samodzielny sposób bezpiecznego przesyłania informacji pomiędzy stronami jako obiekt JSON. Informacje te mogą być zweryfikowane i są godne zaufania, ponieważ są podpisane cyfrowo.

JWT są szczególnie przydatne w aplikacjach webowych, gdzie są powszechnie wykorzystywane do bezstanowego uwierzytelniania/autoryzacji oraz wymiany informacji. Więcej na temat teorii stojącej za JWT możesz przeczytać w powyższej specyfikacji lub na stronie [jwt.io](https://jwt.io/introduction).

Vapor zapewnia pełnowartościowe wsparcie dla JWT poprzez moduł `JWT`. Moduł ten jest zbudowany na bibliotece `JWTKit`, która jest implementacją standardu JWT w Swift, opartą na [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit dostarcza podpisujących i weryfikujących dla wielu algorytmów, w tym HMAC, ECDSA, EdDSA i RSA.

## Rozpoczęcie pracy

Pierwszym krokiem do używania JWT w twojej aplikacji Vapor jest dodanie zależności `JWT` do pliku `Package.swift` twojego projektu:

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

### Konfiguracja

Po dodaniu zależności możesz zacząć korzystać z modułu `JWT` w swojej aplikacji. Moduł JWT dodaje nową właściwość `jwt` do `Application`, która jest używana do konfiguracji, a której wewnętrzna implementacja jest dostarczana przez bibliotekę [JWTKit](https://github.com/vapor/jwt-kit).

#### Kolekcja kluczy

Obiekt `jwt` posiada właściwość `keys`, będącą instancją `JWTKeyCollection` z JWTKit. Ta kolekcja służy do przechowywania i zarządzania kluczami używanymi do podpisywania i weryfikowania JWT. `JWTKeyCollection` jest `actor`em, co oznacza, że wszystkie operacje na kolekcji są serializowane i bezpieczne wątkowo.

Aby podpisywać lub weryfikować JWT, musisz dodać klucz do kolekcji. Zazwyczaj robi się to w pliku `configure.swift`:

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Dodaje to klucz HMAC z SHA-256 jako algorytmem skrótu do zbioru kluczy, czyli HS256 w notacji JWA. Zajrzyj do sekcji [algorytmy](#algorithms) poniżej, aby uzyskać więcej informacji o dostępnych algorytmach.

!!! note 
    Pamiętaj, aby zastąpić `"secret"` rzeczywistym kluczem sekretnym. Ten klucz powinien być przechowywany w bezpieczny sposób, najlepiej w pliku konfiguracyjnym lub zmiennej środowiskowej.

### Podpisywanie

Dodany klucz może być następnie użyty do podpisywania JWT. Aby to zrobić, najpierw potrzebujesz _czegoś_ do podpisania, czyli „payloadu”.
Ten payload to po prostu obiekt JSON zawierający dane, które chcesz przesłać. Możesz stworzyć własny payload, dostosowując swoją strukturę do protokołu `JWTPayload`:

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

Podpisanie payloadu odbywa się przez wywołanie metody `sign` na module `JWT`, na przykład wewnątrz handlera trasy:

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

Gdy zostanie wykonane żądanie do tego endpointu, zwróci ono podpisany JWT jako `String` w ciele odpowiedzi, a jeśli wszystko poszło zgodnie z planem, zobaczysz coś takiego:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Możesz zdekodować i zweryfikować ten token za pomocą [debugera `jwt.io`](https://jwt.io/#debugger). Debuger pokaże ci payload (który powinien zawierać dane podane wcześniej) oraz nagłówek JWT, a także pozwoli zweryfikować podpis za pomocą klucza sekretnego, którym podpisano JWT.

### Weryfikowanie

Kiedy token jest zamiast tego wysyłany _do_ twojej aplikacji, możesz zweryfikować autentyczność tokenu, wywołując metodę `verify` na module `JWT`:

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

Pomocnik `req.jwt.verify` sprawdzi nagłówek `Authorization` w poszukiwaniu tokenu typu bearer. Jeśli taki istnieje, sparsuje JWT i zweryfikuje jego podpis oraz roszczenia (claims). Jeśli którykolwiek z tych kroków się nie powiedzie, zostanie rzucony błąd 401 Unauthorized.

Przetestuj trasę, wysyłając następujące żądanie HTTP:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Jeśli wszystko zadziałało, zostanie zwrócona odpowiedź `200 OK`, a payload zostanie wydrukowany:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

Cały przepływ uwierzytelniania można znaleźć w [Uwierzytelnianie &rarr; JWT](authentication.md#jwt).

## Algorytmy

JWT mogą być podpisywane za pomocą wielu różnych algorytmów.

Aby dodać klucz do zbioru kluczy, dla każdego z poniższych algorytmów dostępne jest przeciążenie metody `add`:

### HMAC

HMAC (Hash-based Message Authentication Code) to algorytm symetryczny, który używa klucza sekretnego do podpisywania i weryfikowania JWT. Vapor wspiera następujące algorytmy HMAC:

- `HS256`: HMAC z SHA-256
- `HS384`: HMAC z SHA-384
- `HS512`: HMAC z SHA-512

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) to algorytm asymetryczny, który używa pary kluczy publiczny/prywatny do podpisywania i weryfikowania JWT. Jego działanie opiera się na matematyce krzywych eliptycznych. Vapor wspiera następujące algorytmy ECDSA:

- `ES256`: ECDSA z krzywą P-256 i SHA-256
- `ES384`: ECDSA z krzywą P-384 i SHA-384
- `ES512`: ECDSA z krzywą P-521 i SHA-512

Wszystkie algorytmy udostępniają zarówno klucz publiczny, jak i prywatny, na przykład `ES256PublicKey` i `ES256PrivateKey`. Klucze ECDSA możesz dodać w formacie PEM:

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

lub wygenerować losowe (przydatne do testów):

```swift
let key = ES256PrivateKey()
```

Aby dodać klucz do zbioru kluczy:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) to algorytm asymetryczny, który używa pary kluczy publiczny/prywatny do podpisywania i weryfikowania JWT. Jest podobny do ECDSA w tym sensie, że oba opierają się na algorytmie DSA, ale EdDSA bazuje na krzywej Edwardsa, innej rodzinie krzywych eliptycznych, i ma nieco lepszą wydajność. Jest jednak również nowszy, a przez to mniej powszechnie wspierany. Vapor wspiera wyłącznie algorytm `EdDSA` wykorzystujący krzywą `Ed25519`.

Klucz EdDSA możesz utworzyć na podstawie jego współrzędnej (zakodowanego w base-64 `String`), czyli `x` w przypadku klucza publicznego i `d` w przypadku klucza prywatnego:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Możesz też wygenerować losowe:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Aby dodać klucz do zbioru kluczy:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) to algorytm asymetryczny, który używa pary kluczy publiczny/prywatny do podpisywania i weryfikowania JWT.

!!! warning
    Jak zauważysz, klucze RSA są ukryte za przestrzenią nazw `Insecure`, aby zniechęcić nowych użytkowników do ich stosowania. Wynika to z faktu, że RSA jest uważane za mniej bezpieczne niż ECDSA i EdDSA i powinno być używane wyłącznie ze względów kompatybilności.
    Jeśli to możliwe, użyj zamiast tego jednego z pozostałych algorytmów.

Vapor wspiera następujące algorytmy RSA:

- `RS256`: RSA z SHA-256
- `RS384`: RSA z SHA-384
- `RS512`: RSA z SHA-512

Klucz RSA możesz utworzyć w formacie PEM:

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

lub wykorzystując jego komponenty:

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    Pakiet nie wspiera kluczy RSA mniejszych niż 2048 bitów.

Następnie możesz dodać klucz do kolekcji kluczy:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Oprócz algorytmu RSA-PKCS1v1.5, Vapor wspiera również algorytm RSA-PSS. PSS (Probabilistic Signature Scheme) to bezpieczniejszy schemat wypełnienia (padding) dla podpisów RSA. Zaleca się używanie PSS zamiast PKCS1v1.5, kiedy to możliwe.

Algorytm różni się jedynie w fazie podpisywania, co oznacza, że klucze są takie same jak w RSA, jednak podczas dodawania ich do kolekcji kluczy musisz określić schemat wypełnienia:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Identyfikator klucza (kid)

Podczas dodawania klucza do kolekcji kluczy możesz również określić identyfikator klucza (kid). Jest to unikalny identyfikator klucza, który może być użyty do wyszukania go w kolekcji.

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Jeśli nie określisz `kid`, klucz zostanie przypisany jako klucz domyślny.

!!! note
    Klucz domyślny zostanie nadpisany, jeśli dodasz kolejny klucz bez `kid`.

Podczas podpisywania JWT możesz określić, który `kid` ma zostać użyty:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Podczas weryfikacji z kolei `kid` jest automatycznie wyodrębniany z nagłówka JWT i używany do wyszukania klucza w kolekcji. Metoda weryfikacji posiada również parametr `iteratingKeys`, który pozwala określić, czy przeszukiwać wszystkie klucze w kolekcji, jeśli `kid` nie zostanie znaleziony.

## Roszczenia (Claims)

Pakiet JWT dla Vapora zawiera kilka pomocników do implementacji popularnych [roszczeń JWT](https://tools.ietf.org/html/rfc7519#section-4.1).

|Roszczenie|Typ|Metoda weryfikacji|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/d|
|`iat`|`IssuedAtClaim`|n/d|
|`iss`|`IssuerClaim`|n/d|
|`locale`|`LocaleClaim`|n/d|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/d|

Wszystkie roszczenia powinny być weryfikowane w metodzie `JWTPayload.verify`. Jeśli dane roszczenie posiada specjalną metodę weryfikacji, możesz jej użyć. W przeciwnym razie odczytaj wartość roszczenia za pomocą `value` i sprawdź, czy jest ona prawidłowa.

## JWK

JSON Web Key (JWK) to struktura danych JSON reprezentująca klucz kryptograficzny ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Są one powszechnie używane do dostarczania klientom kluczy do weryfikacji JWT.

Na przykład Apple udostępnia swoje JWKS Sign in with Apple pod następującym adresem URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor dostarcza narzędzia do dodawania JWK do kolekcji kluczy:

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

Spowoduje to dodanie JWK do kolekcji kluczy, dzięki czemu będziesz mógł go używać do podpisywania i weryfikowania JWT tak samo, jak w przypadku każdego innego klucza.

### JWKs

Jeśli posiadasz wiele JWK, możesz je dodać w podobny sposób:

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

## Dostawcy

Vapor dostarcza API do obsługi JWT od poniższych popularnych wystawców.

### Apple

Najpierw skonfiguruj identyfikator aplikacji Apple.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

Następnie użyj pomocnika `req.jwt.apple` do pobrania i zweryfikowania JWT od Apple.

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Najpierw skonfiguruj identyfikator aplikacji Google oraz nazwę domeny G Suite.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Następnie użyj pomocnika `req.jwt.google` do pobrania i zweryfikowania JWT od Google.

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Najpierw skonfiguruj identyfikator aplikacji Microsoft.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

Następnie użyj pomocnika `req.jwt.microsoft` do pobrania i zweryfikowania JWT od Microsoft.

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
