# 认证

身份认证是验证用户身份的行为。这是通过验证用户名和密码或唯一令牌等凭据来完成的。身份认证（有时称为 auth/c）与授权 (auth/z) 是不同的，授权 (auth/z) 是验证先前经过身份认证的用户执行某些任务的权限的行为。

## 介绍

Vapor 的身份认证 API 支持使用 [Basic](https://tools.ietf.org/html/rfc7617) 和 [Bearer](https://tools.ietf.org/html/rfc6750) 通过 `Authorization` 的 header 来对用户进行身份验证。它还支持通过从 [Content](../basics/content.zh.md) API 解码的数据对用户进行身份验证。

身份认证是通过创建一个包含验证逻辑的 `Authenticator` 来实现的。身份认证器可用于保护单个路由组或整个应用程序。Vapor 提供了以下身份认证辅助工具：

|协议|描述|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|能够创建中间件的基本身份验证器。|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|验证 Basic 授权标头。|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|验证 Bearer 授权标头。|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|从请求体中验证凭据 payload。|

如果身份认证成功，则身份认证器将已验证的用户添加到 `req.auth` 中。 然后，可以在认证器保护的路由上使用 `req.auth.get(_:)` 方法访问此用户。如果身份认证失败，则不会添加用户到 `req.auth` 中，任何访问都会失败。

## Authenticatable

要使用认证 API，首先需要一个遵循 `Authenticatable` 协议的 User 类型。它可以是 `struct`、`class`，甚至可以是 Fluent 的 `Model` 类型。下面的示例假定这个简单的  `User` 结构有一个属性：`name`。

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

下面的每个示例将使用我们创建的身份认证器的一个实例。在这些示例中，我们将其称为 `UserAuthenticator`。

### 路由

身份认证器是一个中间件，可用于保护路由。

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` 方法用于获取经过身份认证的 `User`。如果身份验证失败，此方法将抛出错误，保护路由。

### 守卫中间件(Guard Middleware)

你还可以在路由组中使用 `GuardMiddleware` 中间件，以确保用户在到达路由处理之前已通过身份认证。

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

身份认证中间件不需要进行身份验证，从而不需要组合身份认证器。在下面阅读更多关于 [composition](#composition) 的内容。

## Basic

Basic 身份认证在 `Authorization` 头中发送用户名和密码。用户名和密码使用冒号连接（例如 `test：ici`），采用 base-64 编码，并以 `"Basic "` 为前缀。下面的请求示例对用户名 `test`，密码为 `secur` 进行编码。

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Basic 身份认证通常用于一次登录用户并生成令牌。这最大限度地减少了必须发送用户敏感密码的频率。你永远不应该通过明文或未经验证的 TLS 连接发送 Basic 授权。

要在你的应用中实现 Basic 身份认证，请创建一个遵循 `BasicAuthenticator` 协议的认证器。下面是一个硬编码的认证器示例，用于验证来自上面的请求。

```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

如果你正在使用 `async`/`await` 你可以改用 `AsyncBasicAuthenticator`：

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

该协议要求你实现 `authenticate(basic:for:)` 方法，当传入的请求包含 `Authorization: Basic ...` 头部时，会调用该方法。包含用户名和密码 `BasicAuthorization` 结构被传递给该方法。

此身份认证器测试用例，将对照硬编码值测试用户名和密码。在真正的身份认证器中，你可能会对照数据库或外部 API 进行检查。这就是 `authenticate` 方法允许你返回一个 future 对象的原因。

!!! tip "建议"
    密码永远不应以明文形式存储在数据库中。始终使用密码哈希进行比较。

如果身份认证参数正确，在本例中与硬编码值匹配，则会登录一个名为 Vapor 的 `User`。如果身份认证参数不匹配，则没有用户登录，这意味着身份验证失败。

如果你将此身份认证器添加到你的应用程序中，并测试上面定义的路由，你应该会看到登录成功并返回名为 `"Vapor"` 的用户。如果凭据不正确，你应该会看到 `401 未经授权` 的错误。

## Bearer

Bearer 身份认证在 `Authorization` 头部中发送令牌。令牌的前缀是 `"Bearer "`。下面的请求示例发送令牌 `foo`。

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 
Bearer 身份认证通常用于 API 端点的身份验证。用户通常通过向登录端点发送用户名和密码等凭据来请求 Bearer 令牌。此令牌可能持续数分钟或数天，具体取决于应用程序的需要。

只要令牌有效，用户就可以使用它来代替他或她的凭据来根据 API 进行身份验证。如果令牌无效，则可以使用登录端点生成新的令牌。

要在你的应用中实现 Bearer 身份验证，需要创建一个新的遵循 `BearerAuthenticator` 协议的认证器。下面是一个硬编码的认证器示例，用于验证来自上面的请求。

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

如果你正在使用 `async`/`await` 你可以改用 `AsyncBearerAuthenticator`：

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

该协议要求你实现 `authenticate(bearer:for:)`方法，当传入的请求包含 `Authorization: Bearer ...` 头部时，会调用该方法。包含令牌的 `BearerAuthorization` 结构被传递给该方法。

此身份认证器测试用例，将对照硬编码值测试令牌。在真正的身份认证器中，你可能会对照数据库或使用加密方法来验证令牌。就像对 JWT 所做的那样。这就是 `authenticate` 方法允许你返回一个 future 对象的原因。

!!! tip "建议"
    在实现令牌验证时，考虑横向可扩展性很重要。如果你的应用程序需要同时处理多个用户，身份认证可能是一个潜在的瓶颈。考虑一下你的设计将如何在一次运行的应用程序的多个实例中进行扩展。

如果身份认证参数正确，在本例中与硬编码值匹配，则会登录一个名为 Vapor 的 `User`。如果身份认证参数不匹配，则没有用户登录，这意味着身份验证失败。

如果你将此身份认证器添加到你的应用程序中，并测试上面定义的路由，你应该会看到登录成功并返回名为 `"Vapor"` 的用户。如果凭据不正确，你应该会看到 `401 未经授权` 的错误。

## 组合(Composition)

可以组合（组合在一起）多个身份认证器以创建更复杂的端点身份验证。由于身份认证器中间件不会在身份验证失败时拒绝请求，因此可以将多个中间件链接在一起。身份认证器可以通过两种关键方式组成。

### 组合方法

身份认证组合的第一种方法是为同一用户类型链接多个身份认证器。举个例子：

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // 处理用户的一些操作。
}
```

本例假设有两个身份认证器 `UserPasswordAuthenticator` 和 `UserTokenAuthenticator`，它们都对 `User` 进行身份验证。这两个认证器都会添加到路由组。最后，在认证器之后添加 `GuardMiddleware`，以要求 `User` 已成功通过身份认证。

身份验证器的这种组合导致可以通过密码或令牌访问的路由。这样的路由可以允许用户登录并生成令牌，然后继续使用该令牌来生成新令牌。

### 组合用户

身份认证组合的第二种方法是链接不同用户类型的身份认证器。举个例子：

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // 处理其它操作。
}
```

本例假设有两个认证器 `AdminAuthenticator` 和 `UserAuthenticator`，分别对 `Admin` 和 `User` 进行身份验证。这两个认证器都会添加到路由组中。没有使用`GuardMiddleware`，而是在路由处理中增加了一个检查，看看 `Admin` 或 `User` 是否通过了身份验证。如果不是，则抛出错误。

身份认证器的这种组合导致可以由两种不同类型的用户使用可能不同的身份验证方法访问的路由。这样的路由可以允许正常的用户身份验证，同时仍然允许超级用户访问。

## 手动处理

你还可以使用 `req.auth` 方法手动处理身份验证。这对于测试特别有用。

要手动登录用户，请使用 `req.auth.login(_:)` 方法。任何 `Authenticatable` 用户都可以传递给此方法。

```swift
req.auth.login(User(name: "Vapor"))
```

要获取经过身份验证的用户，请使用 `req.auth.require(_:)` 方法。

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

如果你不想在身份验证失败时自动抛出错误，也可以使用 `req.auth.get(_:)` 方法。

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

要取消对用户的身份验证，请将用户类型传递给 `req.auth.logout(_:)` 方法。

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.zh.md) 定义了两个协议 `ModelAuthenticatable` 和 `ModelTokenAuthenticatable` 可以添加到你已有的模型中。通过使你的模型遵循这些协议，可以创建用于保护终端的验证器。

`ModelTokenAuthenticatable` 使用 Bearer 令牌进行身份验证。这是你用来保护大多数终端的工具。`ModelAuthenticatable` 使用用户名和密码进行身份验证，并由单个端点用于生成令牌。

本指南假定你熟悉 Fluent，并已成功配置你的应用程序以使用数据库。如果你是 Fluent 新手，请从[概述](../fluent/overview.zh.md)开始。

### User

首先，你需要一个模型来表示将被验证的用户。对于本指南，我们将使用以下模型，但你可以自由使用现有模型。

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

该模型必须能够存储用户名，在本例中为电子邮件和密码哈希。我们还设置了 `email` 字段的唯一性约束，以避免重复用户。此示例模型的相应迁移在这里：

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

不要忘记将迁移添加到 `app.migrations` 中。

```swift
app.migrations.add(User.Migration())
``` 

首先需要一个端点来创建新用户。让我们使用 `POST /users`。创建一个 [Content](../basics/content.zh.md) 的结构体，表示这个端点期望的数据。

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

如果你愿意，可以将此结构遵循 [Validatable](../basics/validation.zh.md) 协议以添加验证要求。

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

现在你可以在端点通过 `POST /users` 创建用户。

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

该端点验证传入的请求，解码 `User.Create` 结构，并检查密码是否匹配。然后，它使用解码后的数据创建新的 `User`，并将其保存到数据库中。明文密码在保存到数据库之前使用 `Bcrypt` 进行哈希处理。

构建并运行项目，确保先迁移数据库，然后使用以下请求创建新用户。

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### 可认证的模型

现在你已经有了一个用户模型和一个端点来创建新用户，让我们将模型遵循 `ModelAuthenticatable` 协议。这将允许使用用户名和密码对模型进行身份验证。

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

该扩展在 `User` 基础上增加了 `ModelAuthenticatable` 协议。前两个属性分别指定使用哪些字段来存储用户名和密码散列。`\`表示法创建一个指向字段的键路径，Fluent 可以使用该路径访问字段。

最后一个要求是验证 Basic 身份认证头中发送的明文密码的方法。因为我们在注册期间使用 Bcrypt 对密码进行哈希处理，所以我们将使用 Bcrypt 来验证提供的密码是否与存储的密码散列匹配。

现在 `User` 遵循 `ModelAuthenticatable` 协议，我们可以创建一个认证器来保护登录路由。

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` 添加了一个静态方法 `authenticator` 来创建一个认证器。

通过发送以下请求来测试此路由是否有效。

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

该请求通过 Basic 认证头传递用户名 `test@volor.codes` 和密码 `ici42`。你应该会看到返回了之前创建的用户。

虽然理论上可以使用基本身份验证来保护所有端点，但建议使用单独的令牌。这可以最大限度地减少你必须通过 Internet 发送用户敏感密码的频率。它还使身份验证速度更快，因为在登录期间只需要执行密码散列。

### 用户令牌

创建一个新模型来表示用户令牌。

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

这个模型必须有一个 `value` 字段来存储令牌的唯一字符串。它还必须与用户模型具有 [parent-relation](../fluent/overview.zh.md#parent)，你可以根据需要向此令牌添加其他属性，例如过期日期。

接下来，为此模型创建迁移。

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

注意，这种迁移使 `value` 字段唯一。它还在 `user_id` 字段和 users 表之间创建一个外键引用。

不要忘记将迁移添加到 `app.migrations` 中。

```swift
app.migrations.add(UserToken.Migration())
``` 

最后，为 `User` 添加一个用于生成新令牌的方法。此方法将在登录时使用。

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

这里我们使用 `[UInt8].random(count:)` 来生成一个随机的令牌值。对于本例，将使用16字节（或128位）的随机数据。你可以根据自己的需要调整这个数字。然后对随机数据进行 base-64 编码，以便于在 HTTP 报头中传输。

现在你可以生成用户令牌，更新 `POST /login` 路由以创建和返回令牌。

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

使用上面的相同登录请求测试此路由是否有效。你现在应该在登录时获得一个类似于以下内容的令牌：

```
8gtg300Jwdhc/Ffw784EXA==
```

保留你获得的令牌，因为我们很快就会使用它。

#### 可认证的模型令牌

使 `UserToken` 遵循 `ModelTokenAuthenticatable` 协议。这将允许令牌验证你的 `User` 模型。

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        true
    }
}
```

第一个协议要求指定哪个字段存储令牌的唯一值。这是将在 Bearer 身份认证报头中发送的值。第二个要求指定了 `User` 模型的父级关系。这就是 Fluent 查找经过身份验证的用户的方式。

最后一个要求是一个 `isValid` 布尔值。如果这是 `false`，令牌将从数据库中删除，用户将不被验证。为了简单起见，我们将把这个硬编码为 `true`，使这些标记永远存在。

现在令牌遵循 `ModelTokenAuthenticatable` 协议，你可以创建一个身份认证器来保护路由。

创建一个新的端点通过 `Get /me` 来获取当前认证的用户。

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

与 `User`类似，`UserToken` 现在有一个静态的 `authenticator()` 方法，可以生成一个认证器。认证器将尝试使用在 Bearer 认证头中提供的值来找到匹配的 `UserToken`。如果找到匹配，它将获取相关的 `User` 并验证它。

通过发送以下 HTTP 请求来测试此路由是否有效，其中令牌是你从 `POST /login` 请求中保存的值。

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

你应该看到返回经过身份认证的 `User`。

## 会话

Vapor 的 [Session API](../advanced/sessions.zh.md) 可用于在请求之间自动持久化用户身份验证。这通过在成功登录后将用户的唯一标识符存储在请求的会话数据中来实现。在后续请求中，将从会话中获取用户标识符，并在调用路由处理之前用于验证用户。

会话非常适合内置在 Vapor 中的前端 Web 应用程序，这些应用程序直接向 Web 浏览器提供 HTML。对于 API，我们建议使用无状态、基于令牌的身份验证在请求之间保留用户数据。

### 可认证的会话

要使用基于会话的身份验证，你需要一个遵循 `SessionAuthenticatable` 协议的类型。对于本例，我们将使用一个简单的结构。

```swift
import Vapor

struct User {
    var email: String
}
```

要遵循 `SessionAuthenticatable`，你需要指定 `sessionID`。该值将存储在会话数据中，并且必须唯一标识用户。

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

对于我们的简单 `User` 类型，我们将使用电子邮件地址作为唯一会话标识符。

### 会话认证器

接下来，我们需要一个 `SessionAuthenticator` 来处理从持久会话标识符中解析用户实例。

```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

如果你使用 `async`/`await`，你可以使用 `AsyncSessionAuthenticator`：

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

由于初始化示例 `User` 所需的所有信息都包含在会话标识符中，因此我们可以同步创建和登录用户。在实际应用程序中，你可能会使用会话标识符执行数据库查找或 API 请求，以便在身份验证之前获取其它的用户数据

接下来，让我们创建一个简单的 Bearer 认证器来执行初始认证。

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

此认证器将在发送 bearer 令牌 `test` 时，使用电子邮件 `hello@vapor.codes` 对用户进行身份验证。

最后，让我们在应用程序中将这部分认证方法组合在一起。

```swift
// 创建需要用户认证的保护路由组。
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// 添加 GET /me 路由读取用户邮箱信息
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

要添加 `SessionsMiddleware` 中间件，首先在应用程序上启用会话支持。有关配置会话的更多信息，请参阅[会话 API](../advanced/sessions.zh.md) 部分。

接下来，添加了 `SessionAuthenticator` 后。如果会话处于活动状态，将处理对用户的身份验证。

如果身份验证还没有持久化到会话中，那么请求将被转发到下一个身份验证器。`UserBearerAuthenticator` 将检查 bearer 令牌，并验证用户是否等于 `"test"`。

最后，`User.guardMiddleware()` 将确保 `User` 已通过前一个中间件的身份验证。如果用户没有经过身份验证，就会抛出一个错误。

要测试此路由，首先发送以下请求：

```http
GET /me HTTP/1.1
authorization: Bearer test
```

这将导致 `UserBearerAuthenticator` 对用户进行身份验证。一旦通过身份验证，`UserSessionAuthenticator` 将在会话存储中持久化用户标识符并生成 cookie。再次对路由请求时将使用响应中的 cookie。

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

这一次，`UserSessionAuthenticator` 将验证用户，你应该再次看到返回的用户电子邮件。

### 可认证的模型会话

Fluent 模型可以通过遵循 `ModelSessionAuthenticatable` 协议来生成 `SessionAuthenticator`。这将使用模型的唯一标识符作为会话标识符，并自动执行数据库查找以从会话中恢复模型。

```swift
import Fluent

final class User: Model { ... }

// 允许在会话中持久化此模型。
extension User: ModelSessionAuthenticatable { }
```

你可以将 `ModelSessionAuthatable` 作为空一致性添加到任何已有的模型中。添加后，将有一个新的静态方法可用于为该模型创建 `SessionAuthenticator`。

```swift
User.sessionAuthenticator()
```

这将使用应用程序的默认数据库来解析用户。要指定数据库，请传递标识符。

```swift
User.sessionAuthenticator(.sqlite)
```

## 网站认证

网站的身份认证是一种特例，因为浏览器的使用限制了你如何将凭据附加到浏览器。这会导致两种不同的身份验证方案：

* 通过表单进行初始登录
* 后续调用使用会话 cookie 进行身份验证

Vapor 和 Fluent 提供了几个辅助函数来实现这一点。

### 会话身份认证

会话身份验证的工作方式如上所述。你需要将会话中间件和会话身份认证器用于你的用户将访问的所有路由。这些包括任何受保护的路由，任何公开的路由，但如果用户已登录（例如显示帐户按钮），你可能仍然想要访问该用户**和**登录路由。

你可以在你的应用程序中的 **configure.swift** 文件中全局启用此功能，如下所示：

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

这些中间件执行以下操作：

* 会话中间件获取请求中提供的会话 cookie 并将其转换为会话
* 会话身份认证器获取会话，并查看该会话是否有经过身份验证的用户。如果是，中间件对请求进行身份验证。在响应中，会话身份认证器查看请求是否具有经过身份验证的用户，并将其保存在会话中，以便在下一个请求中对其进行身份验证。

!!! note "注意"
    默认情况下会话 cookie 不会设置为 `secure` 和 `httpOnly`。查看 [Session API](../advanced/sessions.zh.md#configuration) 获取更多关于配置 cookie 的信息。


### 保护路由

当保护 API 的路由时，如果请求没有经过身份验证，通常会返回一个包含状态码（比如 **401 未经授权**）的 HTTP 响应。然而，对于使用浏览器的用户来说，这并不是一个很好的用户体验。Vapor 提供了一个 `RedirectMiddleware` 中间件，用于该场景中的任何 `Authenticatable` 类型：

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

`RedirectMiddleware` 对象还支持在创建过程中传递一个闭包，该闭包将重定向路径作为 `String` 返回，用于高级 url 处理。例如，包括作为查询参数重定向到状态管理重定向目标的路径。

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

它的工作原理类似于 `GuardMiddleware`。任何对注册到 `protectedRoutes` 的未认证路由的请求都将被重定向到提供的路径。这允许你告诉你的用户登录，而不是仅仅提供一个**401 未经授权**的提示。

确保在 `RedirectMiddleware` 之前包含一个会话认证器，以确保在运行 `RedirectMiddleware` 中间件之前加载经过身份验证的用户。

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### 表单登录

要用会话对用户和未来的请求进行身份认证，需要让用户登录。Vapor 提供了一个 `ModelCredentialsAuthenticatable` 协议。它处理通过表单登录的身份验证。首先让你的 `User ` 遵循该协议:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

这与 `ModelAuthenticatable` 协议是相同的，如果你已经遵循该协议，那么你不需要做任何事情。接下来，将这个 `ModelCredentialsAuthenticator` 中间件应用到你的表单 POST 请求中:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

这将使用默认凭证认证器来保护登录路由。你必须在 POST 请求中发送 `username` 和 `password`。你可以这样设置你的表单:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

`CredentialsAuthenticator` 从请求体中提取 `username` 和 `password`，从用户名中找到用户并验证密码。如果密码有效，中间件将对请求进行身份验证。然后，`SessionAuthenticator` 为后续请求验证会话。

## JWT

[JWT](jwt.zh.md) 提供了一个 `JWTAuthenticator` 可用于对传入请求中的 JSON Web 令牌进行身份验证。如果你是 JWT 的新手，请查看[概述](jwt.zh.md)。

首先，创建一个表示 JWT payload 的类型。

```swift
// JWT payload 示例。
struct SessionToken: Content, Authenticatable, JWTPayload {

    // 常量
    let expirationTime: TimeInterval = 60 * 15
    
    // Token 数据
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}
```

接下来，我们可以定义成功登录响应中包含的数据的表示形式。目前，响应将只有一个属性，即表示已签名的 JWT 的字符串。

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

使用我们的 JWT 令牌和响应模型，我们可以使用受密码保护的登录路由，该路由返回一个 `ClientTokenReponse` 并包含一个已签名的 `SessionToken`。

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

或者，如果你不想使用身份认证器，则可以使用如下所示的内容。

```swift
app.post("login") { req -> ClientTokenReponse in
    // 验证为用户提供的凭据
    // 获取提供的用户的 userId
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

通过使 payload 遵循 `Authenticatable` 协议和 `JWTPayload` 协议，你可以使用 `authator()` 方法生成一个路由认证器。将其添加到路由组，以便在调用你的路由之前自动获取和验证 JWT。

```swift
// 创建需要 SessionToken JWT 的路由组。
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

添加可选的 [guard 中间件](#guard-middleware)需要授权成功。

在受保护的路由中，你可以使用 `req.auth` 方法访问经过身份验证的 JWT payload。

```swift
// 如果用户提供的令牌有效，则返回响应 ok 。
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
