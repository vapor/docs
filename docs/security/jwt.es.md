# JWT

JSON Web Token (JWT) es un estándar abierto ([RFC 7519](https://tools.ietf.org/html/rfc7519)) que define una forma compacta y autónoma de transmitir información de forma segura entre partes como un objeto JSON. Esta información se puede verificar y es confiable porque está firmada digitalmente.

Los JWT son particularmente útiles en aplicaciones web, donde se usan comúnmente para la autenticación/autorización sin estado y el intercambio de información. Puedes leer más sobre la teoría detrás de los JWT en la especificación vinculada anteriormente o en [jwt.io](https://jwt.io/introduction).

Vapor proporciona soporte de primera clase para JWT a través del módulo `JWT`. Este módulo está construido sobre la librería `JWTKit`, que es una implementación Swift del estándar JWT basada en [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit proporciona firmantes y verificadores para una variedad de algoritmos, incluidos HMAC, ECDSA, EdDSA, y RSA.

## Primeros pasos

El primer paso para usar JWT en tu aplicación Vapor es agregar la dependencia `JWT` al archivo `Package.swift` de tu proyecto: 

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Otras dependencias...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Otras dependencias...
            .product(name: "JWT", package: "jwt")
        ]),
        // Otros targets...
    ]
)
```

### Configuración

Después de agregar la dependencia, puedes comenzar a usar el módulo `JWT` en tu aplicación. El módulo JWT agrega una nueva propiedad `jwt` a `Application` que se utiliza para la configuración, cuyas partes internas las proporciona la librería [JWTKit](https://github.com/vapor/jwt-kit).

#### Recogida de llaves

El objeto `jwt` viene con una propiedad `keys`, que es una instancia de `JWTKeyCollection` de JWTKit. Esta colección se usa para almacenar y administrar las claves utilizadas para firmar y verificar los JWT. `JWTKeyCollection` es un `actor`, lo que significa que todas las operaciones en la colección están serializadas y son seguras para subprocesos.

Para firmar o verificar JWT, deberás agregar una clave a la colección. Esto se hace generalmente en tu archivo `configure.swift`:

```swift
import JWT

// Agrega HMAC con firmante SHA-256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Esto agrega una clave HMAC con SHA-256 como algoritmo de resumen al llavero, o HS256 en notación JWA. Consulte la sección [algoritmos](#algoritmos) a continuación para obtener más información sobre los algoritmos disponibles.

!!! note "Nota"
    Asegúrese de reemplazar `"secret"` con una clave secreta real. Esta clave debe mantenerse segura, idealmente en un archivo de configuración o variable de entorno.

### Firma

La clave agregada luego se puede usar para firmar JWT. Para hacer esto, primero necesitas _algo_ para firmar, es decir, una "carga útil" (payload).
Esta carga útil es simplemente un objeto JSON que contiene los datos que deseas transmitir. Puedes crear tu carga útil personalizada adaptando tu estructura al protocolo `JWTPayload`:

```swift
// Estructura de carga útil JWT.
struct TestPayload: JWTPayload {
    // Asigna los nombres de propiedad Swift más largos a las
    // claves abreviadas utilizadas en la carga útil JWT.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // El reclamo "sub" (sujeto) identifica al principal que es el
    // sujeto del JWT.
    var subject: SubjectClaim

    // El reclamo "exp" (tiempo de vencimiento) identifica el tiempo de vencimiento en
    // o después del cual el JWT NO DEBE aceptarse para tu procesamiento.
    var expiration: ExpirationClaim

    // Datos personalizados.
    // Si es verdadero, el usuario es administrador.
    var isAdmin: Bool

    // Ejecuta aquí cualquier lógica de verificación adicional más allá
    // verificación de firma.
    // Como tenemos un ExpirationClaim, llamaremos
    // a su método de verificación.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

La firma de la carga útil se realiza llamando al método `sign` en el módulo `JWT`, por ejemplo dentro de un manejador de ruta:

```swift
app.post("login") { req async throws -> [String: String]
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    return try await ["token": req.jwt.sign(payload)]
}
```

Cuando se realiza una solicitud a este endpoint, devolverá el JWT firmado como un `String` en el cuerpo de la respuesta y, si todo salió según lo planeado, verá algo como esto:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Puedes decodificar y verificar este token usando el [depurador `jwt.io`](https://jwt.io/#debugger). El depurador te mostrará la carga útil (que deberían ser los datos que especificaste anteriormente) y el encabezado del JWT, y podrás verificar la firma utilizando la clave secreta que utilizaste para firmar el JWT.

### Verificando

Cuando se envía un token _a_ tu aplicación, puedes verificar la autenticidad del token llamando al método `verify` en el módulo `JWT`:

```swift
// Recupera y verifica JWT de la solicitud entrante.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

El asistente `req.jwt.verify` verificará el encabezado `Authorization` en busca del token del portador (bearer token). Si existe uno, analizará el JWT y verificará su firma y sus reclamos. Si alguno de estos pasos falla, se generará un error 401 no autorizado.

Prueba la ruta enviando la siguiente solicitud HTTP:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Si funcionó todo, se devolverá una respuesta `200 OK` y se imprimirá la carga útil:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

El flujo de autenticación completo se puede encontrar en [Autenticación &rarr; JWT](authentication.md#jwt).

## Algoritmos

Los JWT se pueden firmar utilizando una variedad de algoritmos.

Para agregar una clave al llavero, hay disponible una sobrecarga del método "add" para cada uno de los siguientes algoritmos:

### HMAC

HMAC (Hash-based Message Authentication Code o código de autenticación de mensajes basados en hash) es un algoritmo simétrico que utiliza una clave secreta para firmar y verificar el JWT. Vapor admite los siguientes algoritmos HMAC:

- `HS256`: HMAC con SHA-256
- `HS384`: HMAC con SHA-384
- `HS384`: HMAC con SHA-384

```swift
// Agrega una clave HS256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm o algoritmo de firma digital de curva elíptica) es un algoritmo asimétrico que utiliza un par de claves pública/privada para firmar y verificar el JWT. Su confianza se basa en las matemáticas relacionadas con curvas elípticas. Vapor admite los siguientes algoritmos ECDSA:

- `ES256`: ECDSA con curva P-256 y SHA-256
- `ES384`: ECDSA con curva P-384 y SHA-384
- `ES512`: ECDSA con curva P-521 y SHA-512

Todos los algoritmos proporcionan una clave pública y una clave privada, como `ES256PublicKey` y `ES256PrivateKey`. Puedes agregar claves ECDSA usando el formato PEM:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Inicializa una clave ECDSA con PEM público.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

o generar aleatorias (útiles para pruebas): 

```swift
let key = ES256PrivateKey()
```

Para agregar la clave al llavero:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm o algoritmo de firma digital de curva de Edwards) es un algoritmo asimétrico que utiliza un par de claves pública/privada para firmar y verificar el JWT. Es similar a ECDSA en que ambos se basan en el algoritmo DSA, pero EdDSA se basa en la curva de Edwards, una familia diferente de curvas elípticas, y tiene ligeras mejoras de rendimiento. Sin embargo, también es más nuevo y, por lo tanto, tiene menos soporte. Vapor solo admite el algoritmo `EdDSA` que utiliza la curva `Ed25519`.

Puedes crear una clave EdDSA usando su coordenada (`String` codificada en base 64), donde `x` es una clave pública y `d` una clave privada:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

También puedes generar aleatorias:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Para agregar la clave al llavero:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) es un algoritmo asimétrico que utiliza un par de claves pública/privada para firmar y verificar el JWT.

!!! warning "Advertencia"
    Como verás, las claves RSA están protegidas detrás de un espacio de nombres `Insecure` para disuadir a los nuevos usuarios de usarlas. Esto se debe a que RSA se considera menos seguro que ECDSA y EdDSA y solo debe usarse por razones de compatibilidad.
    Si es posible, utiliza cualquiera de los otros algoritmos.

Vapor admite los siguientes algoritmos RSA:

- `RS256`: RSA con SHA-256
- `RS384`: RSA con SHA-384
- `RS512`: RSA con SHA-512

Puedes crear una clave RSA utilizando su formato PEM:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Inicializa una clave RSA con pem público.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

o utilizar sus componentes:

```swift
// Inicializa una clave privada RSA con componentes.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning "Advertencia"
    El paquete no admite claves RSA de menos de 2048 bits.

Luego puedes agregar la clave a la colección de claves:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Además del algoritmo RSA-PKCS1v1.5, Vapor también admite el algoritmo RSA-PSS. PSS (Probabilistic Signature Scheme o esquema de firma probabilística) es un esquema de relleno más seguro para firmas RSA. Se recomienda utilizar PSS sobre PKCS1v1.5 cuando sea posible.

El algoritmo solo difiere en la fase de firma, lo que significa que las claves son las mismas que RSA; sin embargo, debe especificar el esquema de relleno al agregarlas a la colección de claves:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Identificador de clave (kid)

Al agregar una clave a la colección de claves, también puedes especificar un identificador de clave (kid). Este es un identificador único para la clave que se puede utilizar para buscar la clave en la colección.

```swift
// Agregue HMAC con la clave SHA-256 denominada "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Si no especifica un `kid`, la clave se asignará como la clave predeterminada.

!!! note "Nota"
    La clave predeterminada se anulará si agrega otra clave sin un `kid`.

Al firmar un JWT, puedes especificar el `kid` que se usará:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Por otro lado, al verificar, el `kid` se extrae automáticamente del encabezado JWT y se usa para buscar la clave en la colección. También hay un parámetro `iteratingKeys` en el método de verificación que le permite especificar si se deben iterar sobre todas las claves de la colección si no se encuentra el `kid`.

## Reclamos

El paquete JWT de Vapor incluye varios asistentes para implementar [reclamos JWT](https://tools.ietf.org/html/rfc7519#section-4.1) comunes.

|Reclamo|Tipo|Método de verificación|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(incluye:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Todos los reclamos deben verificarse con el método `JWTPayload.verify`. Si el reclamo tiene un método de verificación especial, puedes usarlo. De lo contrario, acceda al valor del reclamo usando `valor` y verifica que sea válido.

## JWK

Una clave web JSON (JWK) es una estructura de datos JSON que representa una clave criptográfica ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Se utilizan comúnmente para proporcionar a los clientes claves para verificar los JWT.

Por ejemplo, Apple aloja su Iniciar sesión con Apple JWKS en la siguiente URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor proporciona utilidades para agregar JWKs a la colección de claves:

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

Esto agregará el JWK a la colección de claves y podrás usarlo para firmar y verificar JWT como lo harías con cualquier otra clave.

### JWK

Si tienes varios JWK, también puedes agregarlos:

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

## Proveedores

Vapor proporciona APIs para manejar JWTs de los emisores más populares que se indican a continuación.

### Apple

Primero, configura el identificador de tu aplicación Apple.

```swift
// Configurar el identificador de la aplicación Apple.
app.jwt.apple.applicationIdentifier = "..."
```

Luego, usa el asistente `req.jwt.apple` para buscar y verificar un Apple JWT.

```swift
// Recupera y verifica el JWT de Apple desde el encabezado de Autorización.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Primero, configura el identificador de tu aplicación de Google y el nombre de dominio de G Suite.

```swift
// Configurar el identificador de la aplicación de Google y el nombre de dominio.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Luego, usa el asistente `req.jwt.google` para buscar y verificar un JWT de Google.

```swift
// Recupera y verifica el JWT de Google desde el encabezado de Autorización.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Primero, configura el identificador de tu aplicación de Microsoft.

```swift
// Configurar el identificador de la aplicación de Microsoft.
app.jwt.microsoft.applicationIdentifier = "..."
```

Luego, usa el asistente `req.jwt.microsoft` para buscar y verificar un JWT de Microsoft.

```swift
// Recupera y verifica el JWT de Microsoft desde el encabezado de Autorización.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
