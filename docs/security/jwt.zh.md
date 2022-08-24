# JWT

JSON Web Token (JWT) 是一种开放标准 ([RFC 7519](https://tools.ietf.org/html/rfc7519))，它定义了一种紧凑而独立的方式，用于在各方之间作为 JSON 对象安全地传输信息。此信息可以被验证和信任，因为它经过数字签名。JWT 可以使用密钥(使用 HMAC 算法)或使用 RSA 或 ECDSA 的公钥/私钥对进行签名。

## 入门

使用 JWT 的第一步是将依赖项添加到你的 [Package.swift](../getting-started/spm.zh.md#package-manifest) 文件中。

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
		 // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
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

如果你直接在 Xcode 中编辑清单，它会在文件保存时自动获取更改并获取新的依赖项。否则，在终端运行 `swift package resolve` 命令以获取新的依赖项。

### 配置

JWT 模块在 `Application` 中增加了一个新的属性 `jwt`，用于配置。要签名或验证 JWT，你需要添加一个签名者。最简单的签名算法是 `HS256` 或带有 SHA-256 的 HMAC。

```swift
import JWT

// 添加具有 SHA-256 的 HMAC 算法的签名者。
app.jwt.signers.use(.hs256(key: "secret"))
```

`HS256` 签名者需要一个密钥来初始化。与其他签名者不同，这个单一密钥用于签名 _和_ 验证令牌。在下面了解[算法](#algorithms)的更多信息。

### Payload

让我们尝试验证以下 JWT 示例。

```swift
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

你可以访问 [jwt.io](https://jwt.io) 网站并将该令牌粘贴到调试器中来检查该令牌的内容。将 “Verify Signature” 部分中的密钥设置为 `secret`。

我们需要创建一个符合 `JWTPayload` 的结构来表示 JWT 的结构。我们将使用 JWT 包含的 [声明](#claims) 来处理常见的字段，如 `sub`和 `exp`。

```swift
// JWT payload 结构。
struct TestPayload: JWTPayload {
    // 将较长的 Swift 属性名称映射到 JWT payload 中使用的缩写密钥。
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // "sub" (主题) 声明标识了作为 JWT 主题的主体。
    var subject: SubjectClaim

    // “exp” (过期时间) 声明标识了过期时间，过期后 JWT 绝对不能被接受处理。
    var expiration: ExpirationClaim

    // 自定义数据。
    // 如果为真，则该用户为管理员。
    var isAdmin: Bool

    // 在这里运行额外的签名验证逻辑。
    // 因为我们有 ExpirationClaim，我们将调用其 verify 方法。
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
```

### 验证

现在我们有了一个 `JWTPayload`，我们可以将上面的 JWT 附加到一个请求中，并使用 `req.jwt` 来获取和验证它。将以下路由添加到你的项目中。

```swift
// 从请求中获取并验证 JWT。
app.get("me") { req -> HTTPStatus in
    let payload = try req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

`req.jwt.verify` 辅助函数将检查 `Authorization` 请求头中的不记名令牌。如果存在，它将解析 JWT 并验证其签名和声明。如果这些步骤中的任何一个失败，则将抛出 _401未经授权_ 的错误。

通过发送以下 HTTP 请求来测试路由。

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

如果一切正常，将返回 *200 OK* 响应并打印 payload：

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

### 签名

此包还可以 _生成_ JWT，也称为签名。为了演示这一点，让我们使用上一节中的 `TestPayload`。将以下路由添加到你的项目中。

```swift
// 生成并返回一个新的 JWT。
app.post("login") { req -> [String: String] in
    // 创建一个 JWTPayload 实例
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    // 返回签名的 JWT。
    return try [
        "token": req.jwt.sign(payload)
    ]
}
```

`req.jwt.sign` 辅助函数将使用默认配置的签名器来序列化和签名 `JWTPayLoad`。编码后的 JWT 以 `String` 形式返回。

通过发送以下 HTTP 请求来测试路由。

```http
POST /login HTTP/1.1
```

你应该会看到在 _200 OK_ 响应中返回的新生成的令牌。

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

## 认证

了解 JWT 与 Vapor 的身份验证 API 结合使用的更多信息，请访问 [认证 → JWT](authentication.md#jwt)。

## 算法(Algorithms)

Vapor 的 JWT API 支持使用以下算法验证和签名令牌。

### HMAC

HMAC 是最简单的 JWT 签名算法。它使用一个既可以签名又可以验证令牌的密钥。密钥可以是任意长度。

- `hs256`：带有 SHA-256 的 HMAC
- `hs384`：带有 SHA-384 的 HMAC
- `hs512`：带有 SHA-512 的 HMAC

```swift
// 添加带有 SHA-256 的 HMAC 算法的签名者。
app.jwt.signers.use(.hs256(key: "secret"))
```

### RSA

RSA 是最常用的 JWT 签名算法。它支持不同的公钥和私钥。这意味着可以分发公钥来验证 JWT 的真实性，而生成它们的私钥是保密的。

要创建 RSA 签名者，首先初始化一个 `RSAKey`。这可以通过传入组件来完成。

```swift
// 使用组件初始化 RSA 密钥。
let key = RSAKey(
    modulus: "...",
    exponent: "...",
    // 仅包含在私钥中。
    privateExponent: "..."
)
```

你还可以选择加载 PEM 文件：

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// 使用公共 pem 初始化 RSA 密钥。
let key = RSAKey.public(pem: rsaPublicKey)
```

使用 `.private` 加载 RSA PEM 私钥。它们以以下内容开头：

```
-----BEGIN RSA PRIVATE KEY-----
```

获得 RSAKey 后，你可以使用它来创建 RSA 签名者。

- `rs256`：带有 SHA-256 的 RSA
- `rs384`：带有 SHA-384 的 RSA  
- `rs512`：带有 SHA-512 的 RSA

```swift
// 添加带有 SHA-256 的 RSA 算法的签名者。
try app.jwt.signers.use(.rs256(key: .public(pem: rsaPublicKey)))
```

### ECDSA

ECDSA 是一种更现代的算法，类似于 RSA。对于给定的密钥长度，它被认为比 RSA[^1] 更安全。然而，在做出决定之前，你应该自己研究一下。

[^1]: https://www.ssl.com/article/comparing-ecdsa-vs-rsa/

与 RSA 一样，你可以使用 PEM 文件加载 ECDSA 密钥：

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// 使用公共 PEM 初始化 ECDSA 密钥。
let key = ECDSAKey.public(pem: ecdsaPublicKey)
```

使用 `.private` 加载私有 ECDSA PEM 密钥。它们以以下内容开头：

```
-----BEGIN PRIVATE KEY-----
```

你还可以使用 `generate()` 方法随机生成 ECDSA。这对测试很有用。

```swift
let key = try ECDSAKey.generate()
```

拥有 ECDSAKey 后，你可以使用它来创建 ECDSA 签名者。

- `es256`：带有 SHA-256 的 ECDSA
- `es384`：带有 SHA-384 的 ECDSA
- `es512`：带有 SHA-512 的 ECDSA

```swift
// 添加带有 SHA-256 的 ECDSA 算法的签名者
try app.jwt.signers.use(.es256(key: .public(pem: ecdsaPublicKey)))
```

### 密钥标识符 (kid)

如果你使用多个算法，则可以使用密钥标识符（`kid`s）来区分它们。配置算法时，请传递 kid 参数。

```swift
// 添加名为 ”a“ 带有 SHA-256 的 HMAC 算法的签名者
app.jwt.signers.use(.hs256(key: "foo"), kid: "a")
// 添加名为 ”b“ 带有 SHA-256 的 HMAC 算法的签名者
app.jwt.signers.use(.hs256(key: "bar"), kid: "b")
```

在对 JWT 签名时，传递所需签名者的 `kid` 参数。

```swift
// 使用签名者 ”a“ 进行签名
req.jwt.sign(payload, kid: "a")
```

这将自动将签名者的名字包括在 JWT 头的 `kid` 字段中。在验证 JWT 时，此字段将用于查找适当的签名者。

```swift
// 使用 ”kid“ 头部指定的签名者进行验证。
// 如果没有 ”kid“ 头部，则使用默认的签名者
let payload = try req.jwt.verify(as: TestPayload.self)
```

由于 [JWKs](#jwk) 已包含 `kid` 值，因此你无需在配置期间指定它们。

```swift
// JWKs 已经包含 ”kid“ 字段。
let jwk: JWK = ...
app.jwt.signers.use(jwk: jwk)
```

## 声明(Claims)

Vapor 的 JWT 包包括几个用于实现常见 [JWT 声明](https://tools.ietf.org/html/rfc7519#section-4.1)的辅助函数。

|声明|类型|验证方法|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

所有声明都应该在 `JWTPayload.verify` 方法中进行验证。如果声明有特殊的验证方法，你可以使用它。否则，使用 `value` 访问声明的值并检查它是否有效。

## JWK


JSON Web Key (JWK) 是一种表示密钥 ([RFC7517](https://tools.ietf.org/html/rfc7517)) 的 JavaScript 对象表示法 (JSON) 数据结构，它们通常用于向客户端提供用于验证 JWT 的密钥。

例如，Apple 将他们的 _Sign in with Apple_ JWKS 托管在以下 URL 中。

```http
GET https://appleid.apple.com/auth/keys
```

你可以将此 JSON Web 密钥集 (JWKS) 添加到你的 `JWTSigners` 中。 

```swift
import JWT
import Vapor

// 下载 JWKS.
// 如果需要，这可以异步完成。
let jwksData = try Data(
    contentsOf: URL(string: "https://appleid.apple.com/auth/keys")!
)

// 对下载的 JSON 进行解码。
let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)

// 创建签名者并添加 JWKS。
try app.jwt.signers.use(jwks: jwks)
```

现在可以将 JWT 从 Apple 传递给 `verify` 方法。JWT 报头中的密钥标识符 (`kid`) 会自动选择正确的密钥进行验证。

在撰写本文时，JWK 只支持 RSA 密钥。此外，JWT 发行商可能会轮换他们的 JWK，这意味着你偶尔需要重新下载。有关自动执行此操作的 API，请参阅下面的 Vapor 支持的 JWT [供应商](#vendors)列表。

## 发行商(Vendors)

Vapor 提供了用于处理来自以下热门发行商的 JWT 的 API。

### Apple

首先，配置你的 Apple 应用程序标识符。

```swift
// 配置 Apple 应用标识符。
app.jwt.apple.applicationIdentifier = "..."
```

然后，使用 `req.jwt.apple` 辅助函数获取并验证 Apple JWT。

```swift
// 从 Authorization 头获取并验证 Apple JWT。
app.get("apple") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.apple.verify().map { token in
        print(token) // Apple 身份令牌
        return .ok
    }
}

// Or

app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // Apple 身份令牌
    return .ok
}
```

### Google

首先，配置你的 Google 应用标识符和 G Suite 域名。

```swift
// 配置 Google 应用标识符和域名。
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

然后，使用 `req.jwt.google` 辅助函数获取并验证 Google JWT。

```swift
// 从 Authorization 头获取并验证 Google JWT。
app.get("google") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.google.verify().map { token in
        print(token) // Google 身份令牌
        return .ok
    }
}

// 或

app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // Google 身份令牌
    return .ok
}
```

### Microsoft

首先，配置你的 Microsoft 应用程序标识符。

```swift
// 配置 Microsoft 应用标识符.
app.jwt.microsoft.applicationIdentifier = "..."
```

然后，使用 `req.jwt.microsoft` 辅助函数获取并验证 Microsoft JWT。

```swift
// 从 Authorization 头获取并验证 Microsoft JWT。
app.get("microsoft") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.microsoft.verify().map { token in
        print(token) // Microsoft 身份令牌
        return .ok
    }
}

// 或

app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // Microsoft 身份令牌
    return .ok
}
```
