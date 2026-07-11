# JWT

JSON Web Token (JWT) est un standard ouvert ([RFC 7519](https://tools.ietf.org/html/rfc7519)) qui définit une manière compacte et autonome de transmettre des informations de façon sécurisée entre plusieurs parties sous forme d'objet JSON. Ces informations peuvent être vérifiées et sont fiables car elles sont signées numériquement.

Les JWT sont particulièrement utiles dans les applications web, où ils sont couramment utilisés pour l'authentification/autorisation sans état (stateless) et l'échange d'informations. Vous pouvez en apprendre plus sur la théorie derrière les JWT dans la spécification liée ci-dessus ou sur [jwt.io](https://jwt.io/introduction).

Vapor fournit un support de premier ordre pour les JWT à travers le module `JWT`. Ce module est construit par-dessus la librairie `JWTKit`, qui est une implémentation Swift du standard JWT basée sur [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit fournit des signataires et des vérificateurs pour une variété d'algorithmes, dont HMAC, ECDSA, EdDSA, et RSA.

## Bien démarrer

La première étape pour utiliser les JWT dans votre application Vapor est d'ajouter la dépendance `JWT` au fichier `Package.swift` de votre projet : 

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Autres dépendances...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Autres dépendances...
            .product(name: "JWT", package: "jwt")
        ]),
        // Autres cibles...
    ]
)
```

### Configuration

Après avoir ajouté la dépendance, vous pouvez commencer à utiliser le module `JWT` dans votre application. Le module JWT ajoute une nouvelle propriété `jwt` à `Application`, utilisée pour la configuration, dont les mécanismes internes sont fournis par la librairie [JWTKit](https://github.com/vapor/jwt-kit).

#### Collection de clés

L'objet `jwt` est fourni avec une propriété `keys`, qui est une instance de `JWTKeyCollection` de JWTKit. Cette collection est utilisée pour stocker et gérer les clés utilisées pour signer et vérifier les JWT. `JWTKeyCollection` est un `actor`, ce qui signifie que toutes les opérations sur la collection sont sérialisées et thread-safe.

Pour signer ou vérifier des JWT, vous devrez ajouter une clé à la collection. Cela se fait généralement dans votre fichier `configure.swift` :

```swift
import JWT

// Ajoute un signataire HMAC avec SHA-256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Ceci ajoute une clé HMAC avec SHA-256 comme algorithme de hachage au trousseau, soit HS256 en notation JWA. Consultez la section [algorithmes](#algorithmes) ci-dessous pour plus d'informations sur les algorithmes disponibles.

!!! note 
    Assurez-vous de remplacer `"secret"` par une véritable clé secrète. Cette clé devrait être conservée de manière sécurisée, idéalement dans un fichier de configuration ou une variable d'environnement.

### Signature

La clé ajoutée peut ensuite être utilisée pour signer des JWT. Pour cela, vous avez d'abord besoin de _quelque chose_ à signer, à savoir un « payload ». 
Ce payload est simplement un objet JSON contenant les données que vous souhaitez transmettre. Vous pouvez créer votre propre payload personnalisé en conformant votre structure au protocole `JWTPayload` :

```swift
// Structure du payload JWT.
struct TestPayload: JWTPayload {
    // Fait correspondre les noms de propriétés Swift plus longs aux
    // clés raccourcies utilisées dans le payload JWT.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // Le claim "sub" (subject) identifie le principal qui est le
    // sujet du JWT.
    var subject: SubjectClaim

    // Le claim "exp" (expiration time) identifie la date d'expiration à
    // partir de laquelle le JWT NE DOIT PLUS être accepté pour traitement.
    var expiration: ExpirationClaim

    // Données personnalisées.
    // Si true, l'utilisateur est un administrateur.
    var isAdmin: Bool

    // Exécutez ici toute logique de vérification supplémentaire au-delà
    // de la vérification de la signature.
    // Puisque nous avons un ExpirationClaim, nous allons
    // appeler sa méthode verify.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

Signer le payload se fait en appelant la méthode `sign` sur le module `JWT`, par exemple à l'intérieur d'un gestionnaire de route :

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

Lorsqu'une requête est effectuée vers ce endpoint, elle retournera le JWT signé sous forme de `String` dans le corps de la réponse, et si tout s'est déroulé comme prévu, vous verrez quelque chose comme ceci :

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Vous pouvez décoder et vérifier ce token en utilisant le [débogueur `jwt.io`](https://jwt.io/#debugger). Le débogueur vous montrera le payload (qui devrait correspondre aux données que vous avez spécifiées plus tôt) ainsi que l'en-tête du JWT, et vous pourrez vérifier la signature en utilisant la clé secrète que vous avez utilisée pour signer le JWT.

### Vérification

Lorsqu'un token est au contraire envoyé _à_ votre application, vous pouvez vérifier l'authenticité du token en appelant la méthode `verify` sur le module `JWT` :

```swift
// Récupère et vérifie le JWT depuis la requête entrante.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

L'assistant `req.jwt.verify` vérifiera l'en-tête `Authorization` à la recherche d'un bearer token. S'il en existe un, il analysera le JWT et vérifiera sa signature ainsi que ses claims. Si l'une de ces étapes échoue, une erreur 401 Unauthorized sera levée.

Testez la route en envoyant la requête HTTP suivante :

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Si tout a fonctionné, une réponse `200 OK` sera retournée et le payload sera affiché :

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

Le flux d'authentification complet peut être trouvé dans [Authentification &rarr; JWT](authentication.md#jwt).

## Algorithmes

Les JWT peuvent être signés en utilisant une variété d'algorithmes. 

Pour ajouter une clé au trousseau, une surcharge de la méthode `add` est disponible pour chacun des algorithmes suivants :

### HMAC

HMAC (Hash-based Message Authentication Code) est un algorithme symétrique qui utilise une clé secrète pour signer et vérifier le JWT. Vapor prend en charge les algorithmes HMAC suivants :

- `HS256` : HMAC avec SHA-256
- `HS384` : HMAC avec SHA-384
- `HS512` : HMAC avec SHA-512

```swift
// Ajoute une clé HS256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) est un algorithme asymétrique qui utilise une paire de clés publique/privée pour signer et vérifier le JWT. Sa fiabilité repose sur les mathématiques des courbes elliptiques. Vapor prend en charge les algorithmes ECDSA suivants :

- `ES256` : ECDSA avec une courbe P-256 et SHA-256
- `ES384` : ECDSA avec une courbe P-384 et SHA-384
- `ES512` : ECDSA avec une courbe P-521 et SHA-512

Tous les algorithmes fournissent à la fois une clé publique et une clé privée, comme `ES256PublicKey` et `ES256PrivateKey`. Vous pouvez ajouter des clés ECDSA en utilisant le format PEM :

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialise une clé ECDSA avec un PEM public.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

ou en générer des aléatoires (utile pour les tests) : 

```swift
let key = ES256PrivateKey()
```

Pour ajouter la clé au trousseau :

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) est un algorithme asymétrique qui utilise une paire de clés publique/privée pour signer et vérifier le JWT. Il est similaire à ECDSA dans le sens où les deux reposent sur l'algorithme DSA, mais EdDSA est basé sur la courbe d'Edwards, une famille différente de courbes elliptiques, et offre de légères améliorations de performance. Il est cependant plus récent et donc moins largement supporté. Vapor ne prend en charge que l'algorithme `EdDSA` qui utilise la courbe `Ed25519`.

Vous pouvez créer une clé EdDSA en utilisant sa coordonnée (une `String` encodée en base 64), donc `x` s'il s'agit d'une clé publique et `d` s'il s'agit d'une clé privée :

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Vous pouvez également en générer des aléatoires :

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Pour ajouter la clé au trousseau :

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) est un algorithme asymétrique qui utilise une paire de clés publique/privée pour signer et vérifier le JWT. 

!!! warning
    Comme vous le verrez, les clés RSA sont protégées derrière un espace de noms `Insecure` afin de décourager les nouveaux utilisateurs de les utiliser. Ceci est dû au fait que RSA est considéré comme moins sécurisé qu'ECDSA et EdDSA, et ne devrait être utilisé que pour des raisons de compatibilité.
    Si possible, utilisez plutôt l'un des autres algorithmes.

Vapor prend en charge les algorithmes RSA suivants :

- `RS256` : RSA avec SHA-256
- `RS384` : RSA avec SHA-384
- `RS512` : RSA avec SHA-512

Vous pouvez créer une clé RSA en utilisant son format PEM :

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialise une clé RSA avec un PEM public.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

ou en utilisant ses composants :

```swift
// Initialise une clé privée RSA avec des composants.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    Le package ne prend pas en charge les clés RSA plus petites que 2048 bits.

Ensuite, vous pouvez ajouter la clé à la collection de clés :

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

En plus de l'algorithme RSA-PKCS1v1.5, Vapor prend également en charge l'algorithme RSA-PSS. PSS (Probabilistic Signature Scheme) est un schéma de remplissage (padding) plus sécurisé pour les signatures RSA. Il est recommandé d'utiliser PSS plutôt que PKCS1v1.5 lorsque cela est possible.

L'algorithme ne diffère que dans la phase de signature, ce qui signifie que les clés sont les mêmes que pour RSA, cependant, vous devez spécifier le schéma de remplissage lors de leur ajout à la collection de clés :

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Identifiant de clé (kid)

Lors de l'ajout d'une clé à la collection de clés, vous pouvez également spécifier un identifiant de clé (kid). Il s'agit d'un identifiant unique pour la clé qui peut être utilisé pour rechercher la clé dans la collection. 

```swift
// Ajoute une clé HMAC avec SHA-256 nommée "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Si vous ne spécifiez pas de `kid`, la clé sera assignée en tant que clé par défaut.

!!! note
    La clé par défaut sera remplacée si vous ajoutez une autre clé sans `kid`.

Lors de la signature d'un JWT, vous pouvez spécifier le `kid` à utiliser :

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Lors de la vérification en revanche, le `kid` est automatiquement extrait de l'en-tête du JWT et utilisé pour rechercher la clé dans la collection. Il existe également un paramètre `iteratingKeys` sur la méthode verify qui vous permet de spécifier s'il faut itérer sur toutes les clés de la collection lorsque le `kid` n'est pas trouvé.

## Claims

Le package JWT de Vapor inclut plusieurs assistants pour implémenter les [claims JWT](https://tools.ietf.org/html/rfc7519#section-4.1) courants. 

|Claim|Type|Méthode de vérification|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Tous les claims devraient être vérifiés dans la méthode `JWTPayload.verify`. Si le claim possède une méthode de vérification spéciale, vous pouvez l'utiliser. Sinon, accédez à la valeur du claim en utilisant `value` et vérifiez qu'elle est valide.

## JWK

Une JSON Web Key (JWK) est une structure de données JSON qui représente une clé cryptographique ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Elles sont couramment utilisées pour fournir aux clients des clés permettant de vérifier les JWT.

Par exemple, Apple héberge son JWKS de connexion Sign in with Apple à l'URL suivante.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor fournit des utilitaires pour ajouter des JWK à la collection de clés :

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

Ceci ajoutera le JWK à la collection de clés, et vous pourrez l'utiliser pour signer et vérifier des JWT comme vous le feriez avec n'importe quelle autre clé.

### JWKs

Si vous avez plusieurs JWK, vous pouvez les ajouter tout aussi bien :

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

## Fournisseurs

Vapor fournit des API pour gérer les JWT provenant des émetteurs populaires ci-dessous.

### Apple

Tout d'abord, configurez l'identifiant d'application Apple.

```swift
// Configure l'identifiant d'application Apple.
app.jwt.apple.applicationIdentifier = "..."
```

Ensuite, utilisez l'assistant `req.jwt.apple` pour récupérer et vérifier un JWT Apple. 

```swift
// Récupère et vérifie le JWT Apple depuis l'en-tête Authorization.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Tout d'abord, configurez l'identifiant d'application Google et le nom de domaine G Suite.

```swift
// Configure l'identifiant d'application Google et le nom de domaine.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Ensuite, utilisez l'assistant `req.jwt.google` pour récupérer et vérifier un JWT Google. 

```swift
// Récupère et vérifie le JWT Google depuis l'en-tête Authorization.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Tout d'abord, configurez l'identifiant d'application Microsoft.

```swift
// Configure l'identifiant d'application Microsoft.
app.jwt.microsoft.applicationIdentifier = "..."
```

Ensuite, utilisez l'assistant `req.jwt.microsoft` pour récupérer et vérifier un JWT Microsoft. 

```swift
// Récupère et vérifie le JWT Microsoft depuis l'en-tête Authorization.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
