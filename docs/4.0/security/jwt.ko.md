# JWT

JSON Web Token(JWT)은 JSON 객체 형태로 당사자 간에 정보를 안전하게 전송하기 위한, 간결하고 자체적으로 완결된 방법을 정의하는 공개 표준([RFC 7519](https://tools.ietf.org/html/rfc7519))입니다. 이 정보는 디지털 서명이 되어 있기 때문에 검증하고 신뢰할 수 있습니다.

JWT는 웹 애플리케이션에서 특히 유용하며, 상태를 갖지 않는(stateless) 인증(authentication)/인가(authorization) 및 정보 교환에 흔히 사용됩니다. JWT 이면의 이론에 대해서는 위에 링크된 명세나 [jwt.io](https://jwt.io/introduction)에서 더 자세히 알아볼 수 있습니다.

Vapor는 `JWT` 모듈을 통해 JWT에 대한 완전한 지원을 제공합니다. 이 모듈은 [SwiftCrypto](https://github.com/apple/swift-crypto)를 기반으로 한 JWT 표준의 Swift 구현체인 `JWTKit` 라이브러리 위에 구축되었습니다. JWTKit은 HMAC, ECDSA, EdDSA, RSA 등 다양한 알고리즘에 대한 서명자(signer)와 검증자(verifier)를 제공합니다.

## 시작하기

Vapor 애플리케이션에서 JWT를 사용하기 위한 첫 번째 단계는 프로젝트의 `Package.swift` 파일에 `JWT` 종속성을 추가하는 것입니다.

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

### 설정

종속성을 추가한 뒤에는 애플리케이션에서 `JWT` 모듈을 사용할 수 있습니다. JWT 모듈은 `Application`에 설정을 위한 새로운 `jwt` 프로퍼티를 추가하며, 그 내부는 [JWTKit](https://github.com/vapor/jwt-kit) 라이브러리에 의해 제공됩니다.

#### 키 컬렉션(Key Collection)

`jwt` 객체에는 JWTKit의 `JWTKeyCollection` 인스턴스인 `keys` 프로퍼티가 있습니다. 이 컬렉션은 JWT를 서명하고 검증하는 데 사용되는 키를 저장하고 관리하는 데 사용됩니다. `JWTKeyCollection`은 `actor`이므로 컬렉션에 대한 모든 작업이 직렬화되어 스레드 안전(thread-safe)합니다.

JWT를 서명하거나 검증하려면 컬렉션에 키를 추가해야 합니다. 이는 보통 `configure.swift` 파일에서 이루어집니다.

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

이렇게 하면 다이제스트 알고리즘으로 SHA-256을 사용하는 HMAC 키(JWA 표기법으로는 HS256)가 키체인에 추가됩니다. 사용 가능한 알고리즘에 대한 자세한 내용은 아래의 [알고리즘](#algorithms) 섹션을 확인하세요.

!!! note 
    `"secret"`을 실제 비밀 키로 반드시 교체하세요. 이 키는 이상적으로는 설정 파일이나 환경 변수에 안전하게 보관해야 합니다.

### 서명하기

추가한 키는 JWT에 서명하는 데 사용할 수 있습니다. 이를 위해서는 먼저 서명할 대상, 즉 '페이로드(payload)'가 필요합니다.
이 페이로드는 여러분이 전송하고자 하는 데이터를 담고 있는 단순한 JSON 객체입니다. 구조체를 `JWTPayload` 프로토콜에 준수시켜 사용자 정의 페이로드를 만들 수 있습니다.

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

페이로드에 서명하려면 라우트 핸들러 내부 등에서 `JWT` 모듈의 `sign` 메서드를 호출하면 됩니다.

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

이 엔드포인트로 요청을 보내면 서명된 JWT가 응답 본문에 `String`으로 반환되며, 모든 것이 계획대로 진행되었다면 다음과 같은 결과를 보게 됩니다.

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

이 토큰은 [`jwt.io` 디버거](https://jwt.io/#debugger)를 사용하여 디코딩하고 검증할 수 있습니다. 이 디버거는 JWT의 페이로드(앞서 지정한 데이터가 보여야 합니다)와 헤더를 보여주며, JWT 서명에 사용한 비밀 키를 이용해 서명을 검증할 수 있습니다.

### 검증하기

반대로 애플리케이션에 토큰이 전송되었을 때는, `JWT` 모듈의 `verify` 메서드를 호출하여 토큰의 진위를 검증할 수 있습니다.

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

`req.jwt.verify` 헬퍼는 `Authorization` 헤더에서 bearer 토큰을 확인합니다. 토큰이 존재하면 JWT를 파싱하고 서명과 클레임을 검증합니다. 이 단계 중 어느 하나라도 실패하면 401 Unauthorized 에러가 발생합니다.

다음 HTTP 요청을 보내서 라우트를 테스트해보세요.

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

모든 것이 잘 작동했다면 `200 OK` 응답이 반환되고 페이로드가 출력됩니다.

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

전체 인증 흐름은 [인증 &rarr; JWT](authentication.md#jwt)에서 확인할 수 있습니다.

## 알고리즘

JWT는 다양한 알고리즘을 사용하여 서명할 수 있습니다.

키체인에 키를 추가하려면 다음 각 알고리즘에 대한 `add` 메서드의 오버로드를 사용할 수 있습니다.

### HMAC

HMAC(Hash-based Message Authentication Code)는 JWT를 서명하고 검증하는 데 비밀 키를 사용하는 대칭 알고리즘입니다. Vapor는 다음 HMAC 알고리즘을 지원합니다.

- `HS256`: SHA-256을 사용하는 HMAC
- `HS384`: SHA-384를 사용하는 HMAC
- `HS512`: SHA-512를 사용하는 HMAC

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA(Elliptic Curve Digital Signature Algorithm)는 JWT를 서명하고 검증하는 데 공개/개인 키 쌍을 사용하는 비대칭 알고리즘입니다. 이는 타원 곡선에 관한 수학을 기반으로 합니다. Vapor는 다음 ECDSA 알고리즘을 지원합니다.

- `ES256`: P-256 곡선과 SHA-256을 사용하는 ECDSA
- `ES384`: P-384 곡선과 SHA-384를 사용하는 ECDSA
- `ES512`: P-521 곡선과 SHA-512를 사용하는 ECDSA

모든 알고리즘은 `ES256PublicKey`, `ES256PrivateKey`와 같이 공개 키와 개인 키를 모두 제공합니다. PEM 형식을 사용하여 ECDSA 키를 추가할 수 있습니다.

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

또는 (테스트에 유용한) 임의의 키를 생성할 수 있습니다.

```swift
let key = ES256PrivateKey()
```

키체인에 키를 추가하려면 다음과 같이 합니다.

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA(Edwards-curve Digital Signature Algorithm)는 JWT를 서명하고 검증하는 데 공개/개인 키 쌍을 사용하는 비대칭 알고리즘입니다. 둘 다 DSA 알고리즘에 기반한다는 점에서 ECDSA와 비슷하지만, EdDSA는 타원 곡선의 또 다른 계열인 Edwards 곡선을 기반으로 하며 성능이 약간 더 좋습니다. 다만 더 새로운 알고리즘이기 때문에 지원 범위가 상대적으로 좁습니다. Vapor는 `Ed25519` 곡선을 사용하는 `EdDSA` 알고리즘만 지원합니다.

EdDSA 키는 (base-64로 인코딩된 `String`) 좌표를 사용하여 만들 수 있는데, 공개 키라면 `x`를, 개인 키라면 `d`를 사용합니다.

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

또한 임의의 키를 생성할 수도 있습니다.

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

키체인에 키를 추가하려면 다음과 같이 합니다.

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA(Rivest-Shamir-Adleman)는 JWT를 서명하고 검증하는 데 공개/개인 키 쌍을 사용하는 비대칭 알고리즘입니다.

!!! warning
    보시다시피 RSA 키는 새로운 사용자가 사용하지 않도록 유도하기 위해 `Insecure` 네임스페이스 뒤에 배치되어 있습니다. 이는 RSA가 ECDSA 및 EdDSA보다 덜 안전하다고 여겨지기 때문이며, 호환성을 위한 이유가 있을 때만 사용해야 합니다.
    가능하다면 다른 알고리즘 중 하나를 대신 사용하세요.

Vapor는 다음 RSA 알고리즘을 지원합니다.

- `RS256`: SHA-256을 사용하는 RSA
- `RS384`: SHA-384를 사용하는 RSA
- `RS512`: SHA-512를 사용하는 RSA

PEM 형식을 사용하여 RSA 키를 만들 수 있습니다.

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

또는 구성 요소를 사용해서 만들 수도 있습니다.

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    이 패키지는 2048비트보다 작은 RSA 키를 지원하지 않습니다.

그런 다음 키 컬렉션에 키를 추가할 수 있습니다.

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

Vapor는 RSA-PKCS1v1.5 알고리즘 외에도 RSA-PSS 알고리즘을 지원합니다. PSS(Probabilistic Signature Scheme)는 RSA 서명을 위한 더 안전한 패딩 방식입니다. 가능하다면 PKCS1v1.5보다 PSS를 사용하는 것이 권장됩니다.

이 알고리즘은 서명 단계에서만 차이가 있으므로 키는 RSA와 동일하지만, 키 컬렉션에 추가할 때 패딩 방식을 지정해야 합니다.

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## 키 식별자(kid)

키 컬렉션에 키를 추가할 때 키 식별자(kid)를 지정할 수도 있습니다. 이는 컬렉션에서 키를 조회하는 데 사용할 수 있는, 해당 키에 대한 고유 식별자입니다.

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

`kid`를 지정하지 않으면 해당 키는 기본 키로 지정됩니다.

!!! note
    `kid` 없이 다른 키를 추가하면 기본 키가 재정의(override)됩니다.

JWT에 서명할 때 사용할 `kid`를 지정할 수 있습니다.

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

반면 검증할 때는 `kid`가 JWT 헤더에서 자동으로 추출되어 컬렉션에서 키를 조회하는 데 사용됩니다. verify 메서드에는 `kid`를 찾지 못했을 때 컬렉션의 모든 키를 순회할지 여부를 지정할 수 있는 `iteratingKeys` 매개변수도 있습니다.

## 클레임(Claims)

Vapor의 JWT 패키지는 일반적인 [JWT 클레임](https://tools.ietf.org/html/rfc7519#section-4.1)을 구현하기 위한 여러 헬퍼를 포함하고 있습니다.

|클레임|타입|검증 메서드|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

모든 클레임은 `JWTPayload.verify` 메서드에서 검증해야 합니다. 클레임에 전용 검증 메서드가 있다면 그것을 사용하면 됩니다. 그렇지 않다면 `value`를 사용하여 클레임의 값에 접근하고 유효한지 확인하세요.

## JWK

JSON Web Key(JWK)는 암호화 키를 나타내는 JSON 데이터 구조([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517))입니다. 이는 JWT를 검증하기 위한 키를 클라이언트에 제공하는 데 흔히 사용됩니다.

예를 들어 Apple은 다음 URL에서 Sign in with Apple JWKS를 호스팅합니다.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor는 키 컬렉션에 JWK를 추가하는 유틸리티를 제공합니다.

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

이렇게 하면 JWK가 키 컬렉션에 추가되며, 다른 키와 마찬가지로 이를 사용해 JWT를 서명하고 검증할 수 있습니다.

### JWK 목록

여러 개의 JWK가 있다면 마찬가지로 추가할 수 있습니다.

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

## 발급 기관(Vendors)

Vapor는 아래의 인기 있는 발급 기관(issuer)으로부터의 JWT를 처리하기 위한 API를 제공합니다.

### Apple

먼저 Apple 애플리케이션 식별자를 설정하세요.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

그런 다음 `req.jwt.apple` 헬퍼를 사용하여 Apple JWT를 가져와 검증합니다.

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

먼저 Google 애플리케이션 식별자와 G Suite 도메인 이름을 설정하세요.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

그런 다음 `req.jwt.google` 헬퍼를 사용하여 Google JWT를 가져와 검증합니다.

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

먼저 Microsoft 애플리케이션 식별자를 설정하세요.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

그런 다음 `req.jwt.microsoft` 헬퍼를 사용하여 Microsoft JWT를 가져와 검증합니다.

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
