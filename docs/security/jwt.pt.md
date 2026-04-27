# JWT

JSON Web Token (JWT) é um padrão aberto ([RFC 7519](https://tools.ietf.org/html/rfc7519)) que define uma forma compacta e autocontida para transmitir informações de forma segura entre partes como um objeto JSON. Essas informações podem ser verificadas e confiáveis porque são assinadas digitalmente.

JWTs são particularmente úteis em aplicações web, onde são comumente usados para autenticação/autorização stateless e troca de informações. Você pode ler mais sobre a teoria por trás dos JWTs na especificação acima ou em [jwt.io](https://jwt.io/introduction).

O Vapor fornece suporte de primeira classe para JWTs através do módulo `JWT`. Este módulo é construído sobre a biblioteca `JWTKit`, que é uma implementação Swift do padrão JWT baseada no [SwiftCrypto](https://github.com/apple/swift-crypto). O JWTKit fornece signers e verifiers para uma variedade de algoritmos, incluindo HMAC, ECDSA, EdDSA e RSA.

## Primeiros Passos

O primeiro passo para usar JWTs na sua aplicação Vapor é adicionar a dependência `JWT` ao arquivo `Package.swift` do seu projeto:

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Outras dependências...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Outras dependências...
            .product(name: "JWT", package: "jwt")
        ]),
        // Outros targets...
    ]
)
```

### Configuração

Após adicionar a dependência, você pode começar a usar o módulo `JWT` na sua aplicação. O módulo JWT adiciona uma nova propriedade `jwt` à `Application` que é usada para configuração, cujos internos são fornecidos pela biblioteca [JWTKit](https://github.com/vapor/jwt-kit).

#### Key Collection

O objeto `jwt` possui uma propriedade `keys`, que é uma instância de `JWTKeyCollection` do JWTKit. Esta coleção é usada para armazenar e gerenciar as chaves usadas para assinar e verificar JWTs. A `JWTKeyCollection` é um `actor`, o que significa que todas as operações na coleção são serializadas e thread-safe.

Para assinar ou verificar JWTs, você precisará adicionar uma chave à coleção. Isso geralmente é feito no seu arquivo `configure.swift`:

```swift
import JWT

// Adicionar signer HMAC com SHA-256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

Isso adiciona uma chave HMAC com SHA-256 como algoritmo de digest ao keychain, ou HS256 na notação JWA. Confira a seção de [algoritmos](#algoritmos) abaixo para mais informações sobre os algoritmos disponíveis.

!!! note "Nota"
    Certifique-se de substituir `"secret"` por uma chave secreta real. Esta chave deve ser mantida segura, idealmente em um arquivo de configuração ou variável de ambiente.

### Assinatura

A chave adicionada pode então ser usada para assinar JWTs. Para fazer isso, você primeiro precisa de _algo_ para assinar, ou seja, um 'payload'.
Este payload é simplesmente um objeto JSON contendo os dados que você quer transmitir. Você pode criar seu payload personalizado conformando sua estrutura ao protocolo `JWTPayload`:

```swift
// Estrutura do payload JWT.
struct TestPayload: JWTPayload {
    // Mapeia os nomes de propriedade Swift mais longos para as
    // chaves abreviadas usadas no payload JWT.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // A claim "sub" (subject) identifica o principal que é o
    // sujeito do JWT.
    var subject: SubjectClaim

    // A claim "exp" (expiration time) identifica o tempo de expiração
    // após o qual o JWT NÃO DEVE ser aceito para processamento.
    var expiration: ExpirationClaim

    // Dados personalizados.
    // Se verdadeiro, o usuário é um admin.
    var isAdmin: Bool

    // Execute qualquer lógica de verificação adicional além
    // da verificação de assinatura aqui.
    // Como temos uma ExpirationClaim, vamos
    // chamar seu método verify.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

A assinatura do payload é feita chamando o método `sign` no módulo `JWT`, por exemplo dentro de um route handler:

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

Quando uma requisição é feita a este endpoint, ele retornará o JWT assinado como uma `String` no corpo da resposta, e se tudo correu conforme o planejado, você verá algo assim:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

Você pode decodificar e verificar este token usando o [debugger do `jwt.io`](https://jwt.io/#debugger). O debugger mostrará o payload (que deve ser os dados que você especificou anteriormente) e o header do JWT, e você pode verificar a assinatura usando a chave secreta que usou para assinar o JWT.

### Verificação

Quando um token é enviado _para_ a sua aplicação, você pode verificar a autenticidade do token chamando o método `verify` no módulo `JWT`:

```swift
// Buscar e verificar JWT da requisição recebida.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

O helper `req.jwt.verify` verificará o header `Authorization` em busca de um bearer token. Se existir, ele fará o parse do JWT e verificará sua assinatura e claims. Se qualquer uma dessas etapas falhar, um erro 401 Unauthorized será lançado.

Teste a rota enviando a seguinte requisição HTTP:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

Se tudo funcionou, uma resposta `200 OK` será retornada e o payload será impresso:

```swift
TestPayload(
    subject: "vapor",
    expiration: 4001-01-01 00:00:00 +0000,
    isAdmin: true
)
```

O fluxo completo de autenticação pode ser encontrado em [Autenticação &rarr; JWT](authentication.md#jwt).

## Algoritmos

JWTs podem ser assinados usando uma variedade de algoritmos.

Para adicionar uma chave ao keychain, uma sobrecarga do método `add` está disponível para cada um dos seguintes algoritmos:

### HMAC

HMAC (Hash-based Message Authentication Code) é um algoritmo simétrico que usa uma chave secreta para assinar e verificar o JWT. O Vapor suporta os seguintes algoritmos HMAC:

- `HS256`: HMAC com SHA-256
- `HS384`: HMAC com SHA-384
- `HS512`: HMAC com SHA-512

```swift
// Adicionar uma chave HS256.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) é um algoritmo assimétrico que usa um par de chaves pública/privada para assinar e verificar o JWT. Sua confiabilidade é baseada na matemática em torno de curvas elípticas. O Vapor suporta os seguintes algoritmos ECDSA:

- `ES256`: ECDSA com curva P-256 e SHA-256
- `ES384`: ECDSA com curva P-384 e SHA-384
- `ES512`: ECDSA com curva P-521 e SHA-512

Todos os algoritmos fornecem tanto uma chave pública quanto uma chave privada, como `ES256PublicKey` e `ES256PrivateKey`. Você pode adicionar chaves ECDSA usando o formato PEM:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Inicializar uma chave ECDSA com PEM público.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

ou gerar aleatórias (útil para testes):

```swift
let key = ES256PrivateKey()
```

Para adicionar a chave ao keychain:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) é um algoritmo assimétrico que usa um par de chaves pública/privada para assinar e verificar o JWT. É similar ao ECDSA na medida em que ambos dependem do algoritmo DSA, mas o EdDSA é baseado na curva de Edwards, uma família diferente de curvas elípticas, e tem leves melhorias de desempenho. No entanto, também é mais novo e, portanto, menos amplamente suportado. O Vapor suporta apenas o algoritmo `EdDSA` que usa a curva `Ed25519`.

Você pode criar uma chave EdDSA usando sua coordenada (uma `String` codificada em base-64), então `x` se for uma chave pública e `d` se for uma chave privada:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

Você também pode gerar aleatórias:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

Para adicionar a chave ao keychain:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) é um algoritmo assimétrico que usa um par de chaves pública/privada para assinar e verificar o JWT.

!!! warning "Aviso"
    Como você verá, as chaves RSA estão protegidas por um namespace `Insecure` para desencorajar novos usuários de utilizá-las. Isso porque o RSA é considerado menos seguro que ECDSA e EdDSA, e deve ser usado apenas por razões de compatibilidade.
    Se possível, use qualquer um dos outros algoritmos.

O Vapor suporta os seguintes algoritmos RSA:

- `RS256`: RSA com SHA-256
- `RS384`: RSA com SHA-384
- `RS512`: RSA com SHA-512

Você pode criar uma chave RSA usando o formato PEM:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Inicializar uma chave RSA com PEM público.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

ou usando seus componentes:

```swift
// Inicializar uma chave RSA privada com componentes.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus,
    exponent: publicExponent,
    privateExponent: privateExponent
)
```

!!! warning "Aviso"
    O pacote não suporta chaves RSA menores que 2048 bits.

Então você pode adicionar a chave à coleção de chaves:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Além do algoritmo RSA-PKCS1v1.5, o Vapor também suporta o algoritmo RSA-PSS. PSS (Probabilistic Signature Scheme) é um esquema de preenchimento mais seguro para assinaturas RSA. É recomendado usar PSS em vez de PKCS1v1.5 quando possível.

O algoritmo difere apenas na fase de assinatura, o que significa que as chaves são as mesmas que RSA, porém, você precisa especificar o esquema de preenchimento ao adicioná-las à coleção de chaves:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Identificador de Chave (kid)

Ao adicionar uma chave à coleção de chaves, você também pode especificar um identificador de chave (kid). Este é um identificador único para a chave que pode ser usado para buscar a chave na coleção.

```swift
// Adicionar chave HMAC com SHA-256 chamada "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

Se você não especificar um `kid`, a chave será atribuída como a chave padrão.

!!! note "Nota"
    A chave padrão será substituída se você adicionar outra chave sem um `kid`.

Ao assinar um JWT, você pode especificar o `kid` a ser usado:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

Ao verificar, por outro lado, o `kid` é automaticamente extraído do header do JWT e usado para buscar a chave na coleção. Há também um parâmetro `iteratingKeys` no método verify que permite especificar se deve iterar sobre todas as chaves na coleção caso o `kid` não seja encontrado.

## Claims

O pacote JWT do Vapor inclui vários helpers para implementar [claims JWT](https://tools.ietf.org/html/rfc7519#section-4.1) comuns.

|Claim|Tipo|Método de Verificação|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

Todas as claims devem ser verificadas no método `JWTPayload.verify`. Se a claim tiver um método de verificação especial, você pode usá-lo. Caso contrário, acesse o valor da claim usando `value` e verifique se ele é válido.

## JWK

Um JSON Web Key (JWK) é uma estrutura de dados JSON que representa uma chave criptográfica ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). Estes são comumente usados para fornecer chaves aos clientes para verificação de JWTs.

Por exemplo, a Apple hospeda seus JWKS do Sign in with Apple na seguinte URL.

```http
GET https://appleid.apple.com/auth/keys
```

O Vapor fornece utilitários para adicionar JWKs à coleção de chaves:

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

Isso adicionará o JWK à coleção de chaves, e você pode usá-lo para assinar e verificar JWTs como faria com qualquer outra chave.

### JWKs

Se você tem múltiplos JWKs, pode adicioná-los da mesma forma:

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

O Vapor fornece APIs para lidar com JWTs dos emissores populares abaixo.

### Apple

Primeiro, configure o identificador da sua aplicação Apple.

```swift
// Configurar identificador do app Apple.
app.jwt.apple.applicationIdentifier = "..."
```

Então, use o helper `req.jwt.apple` para buscar e verificar um JWT da Apple.

```swift
// Buscar e verificar JWT da Apple do header Authorization.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

Primeiro, configure o identificador da sua aplicação Google e o nome de domínio G Suite.

```swift
// Configurar identificador do app Google e nome de domínio.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Então, use o helper `req.jwt.google` para buscar e verificar um JWT do Google.

```swift
// Buscar e verificar JWT do Google do header Authorization.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

Primeiro, configure o identificador da sua aplicação Microsoft.

```swift
// Configurar identificador do app Microsoft.
app.jwt.microsoft.applicationIdentifier = "..."
```

Então, use o helper `req.jwt.microsoft` para buscar e verificar um JWT da Microsoft.

```swift
// Buscar e verificar JWT da Microsoft do header Authorization.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
