# JWT

JSON Web Token (JWT) は、JSON オブジェクトとして当事者間で情報を安全に送信するための、コンパクトで自己完結型の方法を定義するオープンスタンダード ([RFC 7519](https://tools.ietf.org/html/rfc7519)) です。この情報はデジタル署名されているため、検証可能で信頼できます。

JWT は Web アプリケーションで特に有用で、ステートレスな認証/認可や情報交換によく使用されます。JWT の背後にある理論については、上記のリンク先の仕様書または [jwt.io](https://jwt.io/introduction) で詳しく読むことができます。

Vapor は `JWT` モジュールを通じて JWT のファーストクラスサポートを提供しています。このモジュールは `JWTKit` ライブラリの上に構築されており、[SwiftCrypto](https://github.com/apple/swift-crypto) に基づく JWT 標準の Swift 実装です。JWTKit は、HMAC、ECDSA、EdDSA、RSA を含むさまざまなアルゴリズムの署名者と検証者を提供します。

## はじめに {#getting-started}

Vapor アプリケーションで JWT を使用する最初のステップは、プロジェクトの `Package.swift` ファイルに `JWT` 依存関係を追加することです：

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

### 設定 {#configuration}

依存関係を追加した後、アプリケーションで `JWT` モジュールを使い始めることができます。JWT モジュールは `Application` に新しい `jwt` プロパティを追加し、設定に使用されます。その内部は [JWTKit](https://github.com/vapor/jwt-kit) ライブラリによって提供されています。

#### キーコレクション {#key-collection}

`jwt` オブジェクトには `keys` プロパティが付属しており、これは JWTKit の `JWTKeyCollection` のインスタンスです。このコレクションは、JWT の署名と検証に使用されるキーの保存と管理に使用されます。`JWTKeyCollection` は `actor` であり、コレクションに対するすべての操作がシリアライズされ、スレッドセーフであることを意味します。

JWT を署名または検証するには、コレクションにキーを追加する必要があります。これは通常、`configure.swift` ファイルで行われます：

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

これにより、SHA-256 をダイジェストアルゴリズムとして使用する HMAC キーがキーチェーンに追加されます（JWA 記法では HS256）。利用可能なアルゴリズムの詳細については、下記の[アルゴリズム](#algorithms)セクションをご覧ください。

!!! note 
    `"secret"` を実際のシークレットキーに置き換えてください。このキーは安全に保管する必要があり、理想的には設定ファイルまたは環境変数に保存します。

### 署名 {#signing}

追加されたキーは JWT の署名に使用できます。これを行うには、まず署名する_もの_、つまり「ペイロード」が必要です。
このペイロードは、送信したいデータを含む単純な JSON オブジェクトです。`JWTPayload` プロトコルに準拠する構造体を作成することで、カスタムペイロードを作成できます：

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

ペイロードの署名は、例えばルートハンドラ内で `JWT` モジュールの `sign` メソッドを呼び出すことで行われます：

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

このエンドポイントにリクエストが送信されると、レスポンスボディに署名された JWT を `String` として返し、すべてが計画通りに進んだ場合、次のようなものが表示されます：

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

[`jwt.io` デバッガー](https://jwt.io/#debugger)を使用して、このトークンをデコードして検証できます。デバッガーは JWT のペイロード（先ほど指定したデータであるはずです）とヘッダーを表示し、JWT の署名に使用したシークレットキーを使用して署名を検証できます。

### 検証 {#verifying}

トークンがアプリケーションに_送信された_場合、`JWT` モジュールの `verify` メソッドを呼び出すことで、トークンの真正性を検証できます：

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

`req.jwt.verify` ヘルパーは、`Authorization` ヘッダーでベアラートークンをチェックします。存在する場合、JWT を解析し、その署名とクレームを検証します。これらのステップのいずれかが失敗した場合、401 Unauthorized エラーがスローされます。

次の HTTP リクエストを送信してルートをテストします：

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

すべてが正常に動作した場合、`200 OK` レスポンスが返され、ペイロードが出力されます：

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

完全な認証フローは [認証 &rarr; JWT](authentication.md#jwt) で確認できます。

## アルゴリズム {#algorithms}

JWT はさまざまなアルゴリズムを使用して署名できます。

キーチェーンにキーを追加するには、次の各アルゴリズムに対して `add` メソッドのオーバーロードが利用可能です：

### HMAC

HMAC（Hash-based Message Authentication Code）は、JWT の署名と検証にシークレットキーを使用する対称アルゴリズムです。Vapor は次の HMAC アルゴリズムをサポートしています：

- `HS256`：SHA-256 を使用した HMAC
- `HS384`：SHA-384 を使用した HMAC
- `HS512`：SHA-512 を使用した HMAC

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA（Elliptic Curve Digital Signature Algorithm）は、JWT の署名と検証に公開鍵/秘密鍵のペアを使用する非対称アルゴリズムです。楕円曲線に関する数学に基づいています。Vapor は次の ECDSA アルゴリズムをサポートしています：

- `ES256`：P-256 曲線と SHA-256 を使用した ECDSA
- `ES384`：P-384 曲線と SHA-384 を使用した ECDSA
- `ES512`：P-521 曲線と SHA-512 を使用した ECDSA

すべてのアルゴリズムは、`ES256PublicKey` と `ES256PrivateKey` のように、公開鍵と秘密鍵の両方を提供します。PEM 形式を使用して ECDSA キーを追加できます：

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

またはランダムなキーを生成できます（テストに便利です）：

```swift
let key = ES256PrivateKey()
```

キーチェーンにキーを追加するには：

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA（Edwards-curve Digital Signature Algorithm）は、JWT の署名と検証に公開鍵/秘密鍵のペアを使用する非対称アルゴリズムです。両方とも DSA アルゴリズムに依存している点で ECDSA に似ていますが、EdDSA は異なる楕円曲線ファミリーである Edwards 曲線に基づいており、わずかにパフォーマンスが向上しています。ただし、より新しいため、広くサポートされていません。Vapor は `Ed25519` 曲線を使用する `EdDSA` アルゴリズムのみをサポートしています。

EdDSA キーは、その（base-64 エンコードされた `String`）座標を使用して作成できます。公開鍵の場合は `x`、秘密鍵の場合は `d` です：

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

ランダムなキーを生成することもできます：

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

キーチェーンにキーを追加するには：

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA（Rivest-Shamir-Adleman）は、JWT の署名と検証に公開鍵/秘密鍵のペアを使用する非対称アルゴリズムです。

!!! warning
    ご覧のとおり、RSA キーは新しいユーザーがそれらを使用することを思いとどまらせるために `Insecure` 名前空間の後ろにゲートされています。これは、RSA が ECDSA および EdDSA よりも安全性が低いと見なされており、互換性の理由でのみ使用すべきだからです。
    可能であれば、他のアルゴリズムのいずれかを使用してください。

Vapor は次の RSA アルゴリズムをサポートしています：

- `RS256`：SHA-256 を使用した RSA
- `RS384`：SHA-384 を使用した RSA
- `RS512`：SHA-512 を使用した RSA

PEM 形式を使用して RSA キーを作成できます：

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

またはコンポーネントを使用して：

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    パッケージは 2048 ビット未満の RSA キーをサポートしていません。

その後、キーコレクションにキーを追加できます：

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

RSA-PKCS1v1.5 アルゴリズムに加えて、Vapor は RSA-PSS アルゴリズムもサポートしています。PSS（Probabilistic Signature Scheme）は、RSA 署名のためのより安全なパディングスキームです。可能な場合は、PKCS1v1.5 よりも PSS を使用することが推奨されます。

アルゴリズムは署名フェーズでのみ異なり、キーは RSA と同じですが、キーコレクションに追加する際にパディングスキームを指定する必要があります：

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## キー識別子（kid） {#key-identifier-kid}

キーコレクションにキーを追加する際に、キー識別子（kid）を指定することもできます。これは、コレクション内でキーを検索するために使用できるキーの一意の識別子です。

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

`kid` を指定しない場合、キーはデフォルトキーとして割り当てられます。

!!! note
    `kid` なしで別のキーを追加すると、デフォルトキーは上書きされます。

JWT に署名する際に、使用する `kid` を指定できます：

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

一方、検証時には、`kid` は JWT ヘッダーから自動的に抽出され、コレクション内のキーを検索するために使用されます。また、`kid` が見つからない場合にコレクション内のすべてのキーを反復処理するかどうかを指定できる `iteratingKeys` パラメータが verify メソッドにあります。

## クレーム {#claims}

Vapor の JWT パッケージには、一般的な [JWT クレーム](https://tools.ietf.org/html/rfc7519#section-4.1)を実装するためのいくつかのヘルパーが含まれています。

|クレーム|型|検証メソッド|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

すべてのクレームは `JWTPayload.verify` メソッドで検証する必要があります。クレームに特別な検証メソッドがある場合は、それを使用できます。それ以外の場合は、`value` を使用してクレームの値にアクセスし、それが有効であることを確認してください。

## JWK

JSON Web Key（JWK）は、暗号化キーを表す JSON データ構造です（[RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)）。これらは一般的に、JWT を検証するためのキーをクライアントに提供するために使用されます。

例えば、Apple は Sign in with Apple JWKS を次の URL でホストしています。

```http
GET https://appleid.apple.com/auth/keys
```

Vapor は JWK をキーコレクションに追加するためのユーティリティを提供します：

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

これにより、JWK がキーコレクションに追加され、他のキーと同様に JWT の署名と検証に使用できます。

### JWKs

複数の JWK がある場合は、同様に追加できます：

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

## ベンダー {#vendors}

Vapor は、以下の人気のある発行者からの JWT を処理するための API を提供します。

### Apple

まず、Apple アプリケーション識別子を設定します。

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

次に、`req.jwt.apple` ヘルパーを使用して Apple JWT を取得して検証します。

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

まず、Google アプリケーション識別子と G Suite ドメイン名を設定します。

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

次に、`req.jwt.google` ヘルパーを使用して Google JWT を取得して検証します。

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

まず、Microsoft アプリケーション識別子を設定します。

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

次に、`req.jwt.microsoft` ヘルパーを使用して Microsoft JWT を取得して検証します。

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```