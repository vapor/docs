# JWT

JSON Web Token (JWT) est un standard ouvert ([RFC 7519](https://tools.ietf.org/html/rfc7519)) qui définit une manière compacte et auto-suffisante pour transmettre des informations de façon sécurisée entre des acteurs via un objet JSON. Ces informations peuvent être vérifiées et dignes de confiances car elles sont numériquement signées.

Le standard JWT est particulièrement utile dans les applications web, où il sert souvent pour l'authentification/autorisation sans état ainsi que pour échanger des informations. Plus d'informations sur la théorie de JWT se trouve dans les spécifications mentionnées ci-dessus ou sur [jwt.io](https://jwt.io/introduction).

Vapor fournit un support de première classe pour JWT à travers son module `JWT`. Ce module est conçu sur la librairie `JWTKit`, qui est une implémentation Swift du standard JWT basée sur [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit fournit des signataires et contrôleurs d'authenticité pour différents algorithmes, comprenant HMAC, ECDSA, EdDSA, et RSA.

## Premiers pas

Pour utiliser JWT dans votre application Vapor, vous devrez commencer par ajouter la dépendance à `JWT` dans le fichier `Package.swift` de votre projet : 

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
        // Autres targets...
    ]
)
```

### Configuration

Une fois la dépendance ajoutée, vous pourrez commencer à utiliser le module `JWT` dans votre application. Ce module ajoute la propriété `jwt` à l'objet `Application`, propriété qui sera utilisée pour la configuration, dont l'objet est fourni par la librairie [JWTKit](https://github.com/vapor/jwt-kit).

#### Trousseau de clés

L'objet `jwt` expose une propriété `keys`, qui est une instance de l'objet JWTKit `JWTKeyCollection`. Cette liste sert à stoquer et gérer les clés utilisées pour signer et vérifier les JWTs. L'objet `JWTKeyCollection` est un type `actor`, ce qui signifie que toutes les opérations sur la liste sont sérialisées et thread-safe.

Pour signer ou vérifier des JWTs, vous devrez ajouter une clé à ce trousseau. Cela se fait généralement dans le fichier `configure.swift` :

```swift
import JWT

// Ajoute une clé HMAC avec un signataire SHA-256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Cela ajoute une clé HMAC avec SHA-256 comme algorithme de calcul d'empreinte au trousseau de clés, soit HS256 en notation JWA (JSON Web Algorithm). Lisez la section [algorithmes](#algorithmes) plus bas pour plus d'informations concercant les algorithmes disponibles.

!!! Note 
    Assurez-vous de remplacer `"secret"` par une vraie clé secrète. Cette clé devrait être conservée dans un endroit sécurisé, idéalement dans un fichier de configuration ou une variable d'environnement, non versionnée avec les sources.

### Signer

La clé ajoutée peut désormais servir à signer des JWTs. Pour cela, vous avez d'abord besoin de _quelque-chose_ à signer, appelé un 'payload'. 
Ce payload est un simple objet JSON qui contient les données que vous souhaitez envoyer. Vous pouvez créer votre payload en mettant une structure en conformité au protocole `JWTPayload` :

```swift
// Structure payload JWT.
struct TestPayload: JWTPayload {
    // Fait correspondre les noms de propriétés Swift
    // aux clés raccourcies du payload JWT.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // La déclaration "sub" (subject) identifie l'entité concernée par le JWT.
    // Si les données du JWT concernent un utilisateur, sub pourrait contenir son ID ou nom d'utilisateur.
    var subject: SubjectClaim

    // La déclaration "exp" (expiration time) indique le moment à partir duquel le JWT NE DOIT PLUS être accepté.
    var expiration: ExpirationClaim

    // Données personnalisées.
    // Ici, un booléen pour indiquer si l'utilisateur est un administrateur.
    var isAdmin: Bool

    // Exécutez vos logiques de vérification des données ici, autres que la vérification de signature.
    // Puisque nous avons la déclaration ExpirationClaim, nous allons appeler sa méthode de vérification.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

La signature du payload se fait par appel de la méthode `sign` du module `JWT`, voici un exemple depuis une route :

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

Quand une requête arrive sur cette route, elle renverra une chaîne de caractères JWT signée de type `String` dans le corps de la réponse, et si tout se passe bien, vous aurez un résultat semblable à celui-ci :

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Vous pouvez décoder et vérifier ce jeton grâce au [debugger `jwt.io`](https://jwt.io/#debugger). Le debugger vous affichera le contenu du payload (qui doit correspondre au payload défini précédemment) et l'entête JWT, et vous pouvez vérifier la signature en utilisant la clé secrète que vous avez utilisée pour signer le JWT.

### Vérifier

Quand à l'inverse un jeton est _envoyé à_ votre application, vous pouvez vérifier son authenticité par un appel à la méthode `verify` du module `JWT` :

```swift
// Récupère et vérifie le JWT de la requête entrante.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

La méthode `req.jwt.verify` cherchera dans l'entête `Authorization` un jeton de type Bearer. Si elle en trouve un, elle analysera le JWT et vérifiera sa signature et ses déclarations. Si une de ces étapes échoue, une erreur 401 Unauthorized sera levée.

Testez la route en envoyant la requête HTTP suivante :

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Si tout fonctionne, une réponse `200 OK` sera retournée avec ce payload :

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

La documentation complète du flux d'authentification se trouve dans la section [Authentification &rarr; JWT](authentication.md#jwt).

## Algorithmes

Les JWTs peuvent être signés par divers algorithmes. 

Pour ajouter une clé au trousseau, une surcharge de la méthode `add` est exposée pour chacun des algorithmes suivants :

### HMAC

HMAC (Hash-based Message Authentication Code) est un algorithme symétrique utilisant une clé secrète pour la signature et vérification de JWT. Vapor supporte les algorithmes HMAC suivants :

- `HS256`: HMAC avec SHA-256
- `HS384`: HMAC avec SHA-384
- `HS512`: HMAC avec SHA-512

```swift
// Ajoute une clé HS256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) est un algorithme asymétrique utilisant une paire de clés publique et privée pour la signature et vérification de JWT. Son fonctionnement se base sur les calculs de courbes elliptiques. Vapor supporte les algorithmes ECDSA suivants :

- `ES256`: ECDSA à courbe P-256 avec SHA-256
- `ES384`: ECDSA à courbe P-384 avec SHA-384
- `ES512`: ECDSA à courbe P-521 avec SHA-512

Chacun de ces algorithmes fournit une clé publique et une clé privée, comme les objets `ES256PublicKey` et `ES256PrivateKey` par exemple. Vous pouvez ajouter des clés ECDSA au format PEM :

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialise une clé ECDSA avec un PEM publique.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

Vous pouvez aussi en générer des aléatoires (pratique pour les tests) : 

```swift
let key = ES256PrivateKey()
```

Puis ajouter la clé au trousseau avec :

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) est un algorithme asymétrique utilisant une paire de clés publique et privée pour la signature et vérification de JWT. Il ressemble à l'ECDSA car tous deux dépendent de l'algorithme DSA, mais l'EdDSA s'appuie sur les courbes Edwards, une autre famille de courbes elliptiques, qui a des performances légèrement meilleures. Il est en revanche plus récent, et donc moins généralisé. Vapor ne supporte que l'algorithme `EdDSA` utilisant la courbe `Ed25519`.

Vous pouvez créer une clé EdDSA avec ses coordonnées (encodées en chaîne de caractère base-64), avec `x` pour la clé publique, et `d` pour la clé privée :

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Vous pouvez aussi en générer des aléatoires (pratique pour les tests) :

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Puis ajouter la clé au trousseau avec :

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) est un algorithme asymétrique utilisant une paire de clés publique et privée pour la signature et vérification de JWT. 

!!! Avertissement
    Comme vous le constaterez, les clés RSA sont rangées derrière le namespace `Insecure` pour dissuader de les utiliser. RSA étant considéré comme moins sécurisé que ECDSA ou EdDSA, cet algorithme ne devrait pas être utilisé pour d'autres raisons que d'assurer la compatibilité avec d'anciens systèmes qui les utiliseraient encore.
    Si possible, préférez l'un des autres algorithmes disponibles.

Vapor supporte les algorithmes RSA suivants :

- `RS256`: RSA avec SHA-256
- `RS384`: RSA avec SHA-384
- `RS512`: RSA avec SHA-512

Vous pouvez créer une clé RSA avec son format PEM :

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialise une clé RSA avec un PEM publique.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

Ou par ses composantes :

```swift
// Initialise une clé privée RSA par ses composantes.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! Avertissement
    Ce package ne supporte pas les clés RSA de moins de 2048 bits.

Puis ajouter la clé au trousseau avec :

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

En plus de l'algorithme RSA-PKCS1v1.5, Vapor supporte également l'algorithme RSA-PSS. PSS (Probabilistic Signature Scheme) est une fonction de génération plus sécurisée pour signatures RSA. Il faut préférer l'usage de PSS par rapport à PKCS1v1.5 lorsque c'est possible.

L'algorithme ne diffère que sur la phase de signature, ce qui veut dire que les clés sont les mêmes que celles de RSA, cependant, vous devrez préciser la fonction de génération quand vous ajouterez la clé au trousseau :

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Identifiant de clé kid (Key Identifier)

Quand vous ajoutez une clé au trousseau, vous pouvez lui associer un identifiant (kid). Cet identifiant devra être unique, et pourra servir à chercher une clé dans le trousseau. 

```swift
// Ajoute une clé HMAC avec SHA-256 nommée "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Si vous ne précisez pas de `kid`, la clé sera assignée comme clé par défaut.

!!! Note
    La clé par défaut sera écrasée si vous en ajoutez une autre sans `kid`.

Lors de la signature d'un JWT, vous pouvez indiquer quelle clé utiliser en indiquant son `kid` :

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Lors de la vérification en revanche, le `kid` est automatiquement extrait de l'entête JWT et utilisé pour récupérer la bonne clé du trousseau. Il existe également un paramètre `iteratingKeys` sur la méthode `verify` qui permet de tester chaque clé du trousseau si `kid` n'est pas trouvé.

## Déclarations

Le package JWT de Vapor contient différents objets pour aider à implémenter les [déclarations JWT](https://tools.ietf.org/html/rfc7519#section-4.1) courantes. 

| Déclaration | Type              | Méthode de validation.              |
|-------------|-------------------|-------------------------------------|
| `aud`       | `AudienceClaim`   | `verifyIntendedAudience(includes:)` |
| `exp`       | `ExpirationClaim` | `verifyNotExpired(currentDate:)`    |
| `jti`       | `IDClaim`         | n/a                                 |
| `iat`       | `IssuedAtClaim`   | n/a                                 |
| `iss`       | `IssuerClaim`     | n/a                                 |
| `locale`    | `LocaleClaim`     | n/a                                 |
| `nbf`       | `NotBeforeClaim`  | `verifyNotBefore(currentDate:)`     |
| `sub`       | `SubjectClaim`    | n/a                                 |

Chaque déclaration devrait être validée dans la méthode `JWTPayload.verify`. Si la déclaration possède sa propre méthode de validation, vous devriez l'utiliser. Autrement, vous pouvez accéder à la valeur de la déclaration via `value` et vérifier sa validité.

## JWK

Une JSON Web Key (JWK) est une structure de données JSON qui représente une clé cryptographique ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). On les utilise généralement pour fournir des clés publiques aux clients à des fins de vérification de JWTs.

Par exemple, Apple héberge ses JWKs publiques pour la fonctionnalité Sign in with Apple à l'adresse suivante :

```http
GET https://appleid.apple.com/auth/keys
```

Vapor fournit des outils pour ajouter des JWKs (publiques ou privées) au trousseau :

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

Cela ajoutera la clé JWK au trousseau, et vous pourrez l'utiliser pour signer et vérifier des JWTs comme vous le feriez avec n'importe quelle autre clé.

### JWKs

Si vous avez plusieurs JWKs, vous pouvez aussi les ajouter comme ceci :

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

## Services tiers

Vapor fournit des APIs pour gérer les JWTs des émetteurs populaires ci-dessous.

### Apple

Pour commencer, configurez votre identifiant d'application Apple application.

```swift
// Configure l'identifiant d'application Apple.
app.jwt.apple.applicationIdentifier = "..."
```

Ensuite, utilisez `req.jwt.apple` pour récupérer et vérifier un JWT Apple. 

```swift
// Récupère et vérifie un JWT Apple présent dans l'entête Authorization.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Pour commencer, configurez votre identifiant d'application Google et nom de domaine G-Suite.

```swift
// Configure l'identifiant d'application Google et le nom de domaine.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Ensuite, utilisez `req.jwt.google` pour récupérer et vérifier un JWT Google. 

```swift
// Récupère et vérifie un JWT Google présent dans l'entête Authorization.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Pour commencer, configurez votre identifiant d'application Microsoft.

```swift
// Configure l'identifiant d'application Microsoft.
app.jwt.microsoft.applicationIdentifier = "..."
```

Ensuite, utilisez `req.jwt.microsoft` pour récupérer et vérifier un JWT Microsoft.

```swift
// Récupère et vérifie un JWT Microsoft présent dans l'entête Authorization.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
