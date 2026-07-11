# 인증(Authentication)

인증(Authentication)이란 사용자의 신원을 확인하는 행위입니다. 이는 사용자 이름과 비밀번호, 또는 고유한 토큰과 같은 자격 증명(credentials)을 검증함으로써 이루어집니다. 인증(때로는 auth/c라고도 불립니다)은 이미 인증된 사용자가 특정 작업을 수행할 권한이 있는지 확인하는 인가(authorization, auth/z)와는 구분되는 개념입니다.

## 소개

Vapor의 인증 API는 [Basic](https://tools.ietf.org/html/rfc7617)과 [Bearer](https://tools.ietf.org/html/rfc6750)를 사용하여 `Authorization` 헤더를 통해 사용자를 인증하는 기능을 제공합니다. 또한 [Content](../basics/content.md) API를 통해 디코딩된 데이터로 사용자를 인증하는 것도 지원합니다.

인증은 검증 로직을 포함하는 `Authenticator`를 생성함으로써 구현됩니다. Authenticator는 개별 라우트 그룹이나 앱 전체를 보호하는 데 사용할 수 있습니다. Vapor에는 다음과 같은 Authenticator 헬퍼가 기본으로 제공됩니다.

|프로토콜|설명|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|미들웨어를 생성할 수 있는 기본 Authenticator입니다.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Basic 인증 헤더를 인증합니다.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Bearer 인증 헤더를 인증합니다.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|요청 본문에 담긴 자격 증명 페이로드를 인증합니다.|

인증에 성공하면, Authenticator는 검증된 사용자를 `req.auth`에 추가합니다. 이렇게 추가된 사용자는 해당 Authenticator로 보호되는 라우트에서 `req.auth.get(_:)`을 사용해 접근할 수 있습니다. 인증에 실패하면 사용자는 `req.auth`에 추가되지 않으며, 이를 접근하려는 모든 시도는 실패하게 됩니다.

## Authenticatable

인증 API를 사용하려면, 먼저 `Authenticatable`을 준수하는 사용자 타입이 필요합니다. 이는 `struct`, `class`, 심지어 Fluent `Model`일 수도 있습니다. 아래의 예제들은 `name`이라는 하나의 프로퍼티를 가진 다음의 간단한 `User` 구조체를 사용한다고 가정합니다.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

아래의 각 예제는 우리가 만든 Authenticator의 인스턴스를 사용합니다. 이 예제들에서는 이를 `UserAuthenticator`라고 부르겠습니다.

### 라우트

Authenticator는 미들웨어이며 라우트를 보호하는 데 사용될 수 있습니다.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require`는 인증된 `User`를 가져오는 데 사용됩니다. 인증에 실패하면, 이 메서드는 에러를 던져 라우트를 보호합니다.

### Guard 미들웨어

라우트 그룹에 `GuardMiddleware`를 사용하여, 라우트 핸들러에 도달하기 전에 사용자가 인증되었는지 확인할 수도 있습니다.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Authenticator를 조합(compose)할 수 있도록, 인증을 요구하는 작업은 Authenticator 미들웨어에서 수행하지 않습니다. 아래의 [조합(composition)](#composition) 항목에서 더 자세히 알아보세요.

## Basic

Basic 인증은 사용자 이름과 비밀번호를 `Authorization` 헤더에 담아 전송합니다. 사용자 이름과 비밀번호는 콜론으로 연결되고(예: `test:secret`), base-64로 인코딩된 후 `"Basic "`이 접두사로 붙습니다. 아래 예제 요청은 사용자 이름 `test`와 비밀번호 `secret`을 인코딩합니다.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Basic 인증은 일반적으로 사용자를 한 번 로그인시키고 토큰을 생성하는 데 사용됩니다. 이렇게 하면 사용자의 민감한 비밀번호가 전송되는 빈도를 최소화할 수 있습니다. Basic 인증 정보는 평문(plaintext) 연결이나 검증되지 않은 TLS 연결을 통해 절대로 전송해서는 안 됩니다.

앱에 Basic 인증을 구현하려면, `BasicAuthenticator`를 준수하는 새로운 Authenticator를 만드세요. 아래는 위의 요청을 검증하도록 하드코딩된 예제 Authenticator입니다.


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

`async`/`await`를 사용하고 있다면, 대신 `AsyncBasicAuthenticator`를 사용할 수 있습니다.

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

이 프로토콜은 `authenticate(basic:for:)`를 구현하도록 요구하며, 이 메서드는 들어오는 요청에 `Authorization: Basic ...` 헤더가 포함되어 있을 때 호출됩니다. 사용자 이름과 비밀번호를 담은 `BasicAuthorization` 구조체가 이 메서드로 전달됩니다.

이 테스트용 Authenticator에서는 사용자 이름과 비밀번호를 하드코딩된 값과 비교하여 검사합니다. 실제 Authenticator에서는 데이터베이스나 외부 API와 대조하여 확인할 수도 있습니다. 이것이 `authenticate` 메서드가 future를 반환할 수 있도록 되어 있는 이유입니다.

!!! tip
    비밀번호는 절대로 평문 상태로 데이터베이스에 저장해서는 안 됩니다. 비교에는 항상 비밀번호 해시를 사용하세요.

인증 매개변수가 올바르면, 즉 이 경우에는 하드코딩된 값과 일치하면, Vapor라는 이름의 `User`가 로그인됩니다. 인증 매개변수가 일치하지 않으면 어떤 사용자도 로그인되지 않으며, 이는 인증 실패를 의미합니다.

앱에 이 Authenticator를 추가하고 위에서 정의한 라우트를 테스트해 보면, 로그인에 성공했을 때 이름 `"Vapor"`가 반환되는 것을 볼 수 있습니다. 자격 증명이 올바르지 않으면 `401 Unauthorized` 에러가 나타날 것입니다.

## Bearer

Bearer 인증은 토큰을 `Authorization` 헤더에 담아 전송합니다. 토큰에는 `"Bearer "`가 접두사로 붙습니다. 아래 예제 요청은 토큰 `foo`를 전송합니다.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Bearer 인증은 흔히 API 엔드포인트를 인증하는 데 사용됩니다. 사용자는 일반적으로 사용자 이름과 비밀번호 같은 자격 증명을 로그인 엔드포인트로 전송하여 Bearer 토큰을 요청합니다. 이 토큰은 애플리케이션의 필요에 따라 몇 분에서 며칠까지 유효할 수 있습니다.

토큰이 유효한 동안에는, 사용자는 API에 인증할 때 자신의 자격 증명 대신 이 토큰을 사용할 수 있습니다. 토큰이 무효화되면, 로그인 엔드포인트를 사용하여 새 토큰을 생성할 수 있습니다.

앱에 Bearer 인증을 구현하려면, `BearerAuthenticator`를 준수하는 새로운 Authenticator를 만드세요. 아래는 위의 요청을 검증하도록 하드코딩된 예제 Authenticator입니다.

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

`async`/`await`를 사용하고 있다면, 대신 `AsyncBearerAuthenticator`를 사용할 수 있습니다.

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

이 프로토콜은 `authenticate(bearer:for:)`를 구현하도록 요구하며, 이 메서드는 들어오는 요청에 `Authorization: Bearer ...` 헤더가 포함되어 있을 때 호출됩니다. 토큰을 담은 `BearerAuthorization` 구조체가 이 메서드로 전달됩니다.

이 테스트용 Authenticator에서는 토큰을 하드코딩된 값과 비교하여 검사합니다. 실제 Authenticator에서는 데이터베이스와 대조하거나, JWT에서처럼 암호화 기법을 사용하여 토큰을 검증할 수도 있습니다. 이것이 `authenticate` 메서드가 future를 반환할 수 있도록 되어 있는 이유입니다.

!!! tip
    토큰 검증을 구현할 때는 수평적 확장성(horizontal scalability)을 고려하는 것이 중요합니다. 애플리케이션이 많은 사용자를 동시에 처리해야 한다면, 인증이 잠재적인 병목 지점이 될 수 있습니다. 애플리케이션의 여러 인스턴스가 동시에 실행될 때 여러분의 설계가 어떻게 확장될지 고려하세요.

인증 매개변수가 올바르면, 즉 이 경우에는 하드코딩된 값과 일치하면, Vapor라는 이름의 `User`가 로그인됩니다. 인증 매개변수가 일치하지 않으면 어떤 사용자도 로그인되지 않으며, 이는 인증 실패를 의미합니다.

앱에 이 Authenticator를 추가하고 위에서 정의한 라우트를 테스트해 보면, 로그인에 성공했을 때 이름 `"Vapor"`가 반환되는 것을 볼 수 있습니다. 자격 증명이 올바르지 않으면 `401 Unauthorized` 에러가 나타날 것입니다.

## 조합(Composition)

여러 개의 Authenticator를 조합(compose)하여, 즉 함께 결합하여 더 복잡한 엔드포인트 인증을 만들 수 있습니다. Authenticator 미들웨어는 인증에 실패하더라도 요청을 거부하지 않기 때문에, 이러한 미들웨어를 두 개 이상 연결(chain)할 수 있습니다. Authenticator는 두 가지 주요 방식으로 조합할 수 있습니다.

### 메서드 조합

인증을 조합하는 첫 번째 방법은 동일한 사용자 타입에 대해 둘 이상의 Authenticator를 연결하는 것입니다. 다음 예제를 살펴보세요.

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // user로 무언가를 수행합니다.
}
```

이 예제는 둘 다 `User`를 인증하는 `UserPasswordAuthenticator`와 `UserTokenAuthenticator`라는 두 개의 Authenticator가 있다고 가정합니다. 이 두 Authenticator는 모두 라우트 그룹에 추가됩니다. 마지막으로, `User`가 성공적으로 인증되었음을 요구하기 위해 Authenticator들 뒤에 `GuardMiddleware`가 추가됩니다.

이렇게 Authenticator를 조합하면 비밀번호나 토큰 중 어느 쪽으로든 접근할 수 있는 라우트가 만들어집니다. 이러한 라우트를 사용하면 사용자가 로그인하여 토큰을 생성한 다음, 계속해서 그 토큰으로 새로운 토큰을 생성하도록 할 수 있습니다.

### 사용자 조합

인증을 조합하는 두 번째 방법은 서로 다른 사용자 타입에 대한 Authenticator를 연결하는 것입니다. 다음 예제를 살펴보세요.

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // 작업을 수행합니다.
}
```

이 예제는 각각 `Admin`과 `User`를 인증하는 `AdminAuthenticator`와 `UserAuthenticator`라는 두 개의 Authenticator가 있다고 가정합니다. 이 두 Authenticator는 모두 라우트 그룹에 추가됩니다. `GuardMiddleware`를 사용하는 대신, `Admin` 또는 `User` 중 하나라도 인증되었는지 확인하는 검사가 라우트 핸들러에 추가됩니다. 인증되지 않았다면 에러가 던져집니다.

이렇게 Authenticator를 조합하면, 서로 다른 인증 방식을 가질 수 있는 두 가지 다른 유형의 사용자가 접근할 수 있는 라우트가 만들어집니다. 이러한 라우트를 사용하면 일반 사용자 인증을 유지하면서도 슈퍼 유저에게 접근 권한을 부여할 수 있습니다.

## 수동(Manual)

`req.auth`를 사용하여 인증을 수동으로 처리할 수도 있습니다. 이는 특히 테스트에 유용합니다.

사용자를 수동으로 로그인시키려면 `req.auth.login(_:)`을 사용하세요. `Authenticatable`한 사용자라면 무엇이든 이 메서드에 전달할 수 있습니다.

```swift
req.auth.login(User(name: "Vapor"))
```

인증된 사용자를 가져오려면 `req.auth.require(_:)`를 사용하세요.

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

인증이 실패했을 때 자동으로 에러를 던지지 않길 원한다면, `req.auth.get(_:)`을 사용할 수도 있습니다.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

사용자의 인증을 해제하려면, `req.auth.logout(_:)`에 사용자 타입을 전달하세요.

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md)는 기존 모델에 추가할 수 있는 두 개의 프로토콜 `ModelAuthenticatable`과 `ModelTokenAuthenticatable`을 정의합니다. 모델을 이 프로토콜에 준수시키면 엔드포인트를 보호하는 Authenticator를 생성할 수 있습니다.

`ModelTokenAuthenticatable`은 Bearer 토큰으로 인증합니다. 이것이 대부분의 엔드포인트를 보호하는 데 사용하는 방법입니다. `ModelAuthenticatable`은 사용자 이름과 비밀번호로 인증하며, 토큰을 생성하는 단일 엔드포인트에서 사용됩니다.

이 가이드는 여러분이 Fluent에 익숙하며 데이터베이스를 사용하도록 앱을 성공적으로 설정했다고 가정합니다. Fluent를 처음 사용한다면, [개요](../fluent/overview.md)부터 시작하세요.

### User

시작하려면, 인증될 사용자를 나타내는 모델이 필요합니다. 이 가이드에서는 다음 모델을 사용하겠지만, 이미 있는 모델을 자유롭게 사용해도 됩니다.

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

이 모델은 사용자 이름(여기서는 이메일)과 비밀번호 해시를 저장할 수 있어야 합니다. 또한 중복 사용자를 방지하기 위해 `email`을 고유 필드로 설정합니다. 이 예제 모델에 대응하는 마이그레이션은 다음과 같습니다.

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

`app.migrations`에 마이그레이션을 추가하는 것을 잊지 마세요.

```swift
app.migrations.add(User.Migration())
``` 

!!! tip
     이메일 주소는 대소문자를 구분하지 않으므로, 데이터베이스에 저장하기 전에 이메일 주소를 소문자로 변환하는 [`Middleware`](../fluent/model.md#lifecycle)를 추가하고 싶을 수 있습니다. 다만, `ModelAuthenticatable`은 대소문자를 구분하는 비교를 사용하므로, 이렇게 한다면 클라이언트 측에서 대소문자를 변환하거나 사용자 정의 Authenticator를 사용하는 등의 방법으로 사용자의 입력이 모두 소문자인지 확인해야 합니다.

가장 먼저 필요한 것은 새로운 사용자를 생성하는 엔드포인트입니다. `POST /users`를 사용하겠습니다. 이 엔드포인트가 기대하는 데이터를 나타내는 [Content](../basics/content.md) 구조체를 만드세요.

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

원한다면, 이 구조체를 [Validatable](../basics/validation.md)에 준수시켜 검증 요구사항을 추가할 수 있습니다.

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

이제 `POST /users` 엔드포인트를 만들 수 있습니다.

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

이 엔드포인트는 들어오는 요청을 검증하고, `User.Create` 구조체를 디코딩한 다음, 비밀번호가 일치하는지 확인합니다. 그런 다음 디코딩된 데이터를 사용하여 새로운 `User`를 생성하고 데이터베이스에 저장합니다. 평문 비밀번호는 데이터베이스에 저장되기 전에 `Bcrypt`로 해시됩니다.

프로젝트를 빌드하고 실행하세요. 이때 먼저 데이터베이스 마이그레이션을 반드시 실행해야 하며, 그런 다음 다음 요청을 사용하여 새로운 사용자를 생성하세요.

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

#### Model Authenticatable

이제 사용자 모델과 새로운 사용자를 생성하는 엔드포인트가 있으니, 모델을 `ModelAuthenticatable`에 준수시켜 봅시다. 이렇게 하면 사용자 이름과 비밀번호로 모델을 인증할 수 있게 됩니다.

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

이 익스텐션은 `User`에 `ModelAuthenticatable` 준수성을 추가합니다. 처음 두 프로퍼티는 각각 사용자 이름과 비밀번호 해시를 저장하는 데 사용할 필드를 지정합니다. `\` 표기법은 Fluent가 해당 필드에 접근하는 데 사용할 수 있는 키 경로(key path)를 생성합니다.

마지막 요구사항은 Basic 인증 헤더로 전송된 평문 비밀번호를 검증하는 메서드입니다. 회원가입 시 비밀번호를 해시하는 데 Bcrypt를 사용했으므로, 전달받은 비밀번호가 저장된 비밀번호 해시와 일치하는지 검증하는 데도 Bcrypt를 사용하겠습니다.

이제 `User`가 `ModelAuthenticatable`을 준수하므로, 로그인 라우트를 보호하는 Authenticator를 만들 수 있습니다.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable`은 Authenticator를 생성하는 정적(static) 메서드 `authenticator`를 추가합니다.

다음 요청을 전송하여 이 라우트가 동작하는지 테스트해 보세요.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

이 요청은 Basic 인증 헤더를 통해 사용자 이름 `test@vapor.codes`와 비밀번호 `secret42`를 전달합니다. 앞서 생성한 사용자가 반환되는 것을 볼 수 있을 것입니다.

이론적으로는 Basic 인증을 사용하여 모든 엔드포인트를 보호할 수도 있지만, 대신 별도의 토큰을 사용하는 것이 권장됩니다. 이렇게 하면 사용자의 민감한 비밀번호를 인터넷을 통해 전송하는 빈도를 최소화할 수 있습니다. 또한 로그인 시에만 비밀번호 해싱을 수행하면 되므로 인증 속도도 훨씬 빨라집니다.

### User Token

사용자 토큰을 나타내는 새로운 모델을 만드세요.

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

이 모델에는 토큰의 고유 문자열을 저장하는 `value` 필드가 있어야 합니다. 또한 사용자 모델에 대한 [parent 관계](../fluent/overview.md#parent)도 있어야 합니다. 필요에 따라 만료 날짜와 같은 추가 프로퍼티를 이 토큰에 추가할 수도 있습니다.

다음으로, 이 모델에 대한 마이그레이션을 만드세요.

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

이 마이그레이션은 `value` 필드를 고유하게 만듭니다. 또한 `user_id` 필드와 users 테이블 사이에 외래 키(foreign key) 참조도 생성합니다.

`app.migrations`에 마이그레이션을 추가하는 것을 잊지 마세요.

```swift
app.migrations.add(UserToken.Migration())
``` 

마지막으로, 새로운 토큰을 생성하기 위한 메서드를 `User`에 추가하세요. 이 메서드는 로그인 시에 사용됩니다.

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

여기서는 무작위 토큰 값을 생성하기 위해 `[UInt8].random(count:)`을 사용하고 있습니다. 이 예제에서는 16바이트, 즉 128비트의 무작위 데이터가 사용됩니다. 이 숫자는 필요에 따라 조정할 수 있습니다. 무작위 데이터는 HTTP 헤더로 쉽게 전송할 수 있도록 base-64로 인코딩됩니다.

이제 사용자 토큰을 생성할 수 있으니, `POST /login` 라우트를 업데이트하여 토큰을 생성하고 반환하도록 합니다.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

위와 동일한 로그인 요청을 사용하여 이 라우트가 동작하는지 테스트해 보세요. 이제 로그인하면 다음과 같은 형태의 토큰을 얻게 될 것입니다.

```
8gtg300Jwdhc/Ffw784EXA==
```

곧 사용할 것이므로 이 토큰을 잘 보관해 두세요.

#### Model Token Authenticatable

`UserToken`을 `ModelTokenAuthenticatable`에 준수시키세요. 이렇게 하면 토큰으로 `User` 모델을 인증할 수 있게 됩니다.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    var isValid: Bool {
        true
    }
}
```

첫 번째 프로토콜 요구사항은 토큰의 고유 값을 저장하는 필드를 지정합니다. 이 값이 바로 Bearer 인증 헤더로 전송될 값입니다. 두 번째 요구사항은 `User` 모델에 대한 parent 관계를 지정합니다. 이를 통해 Fluent가 인증된 사용자를 조회하게 됩니다.

마지막 요구사항은 `isValid`라는 불리언 값입니다. 이 값이 `false`이면, 토큰은 데이터베이스에서 삭제되고 사용자는 인증되지 않습니다. 여기서는 간단히 하기 위해 이 값을 `true`로 하드코딩하여 토큰이 영구히 유효하도록 만들겠습니다.

이제 토큰이 `ModelTokenAuthenticatable`을 준수하니, 라우트를 보호하는 Authenticator를 만들 수 있습니다.

현재 인증된 사용자를 가져오는 새로운 엔드포인트 `GET /me`를 만드세요.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

`User`와 마찬가지로, `UserToken`도 이제 Authenticator를 생성할 수 있는 정적 `authenticator()` 메서드를 가지고 있습니다. 이 Authenticator는 Bearer 인증 헤더에 제공된 값과 일치하는 `UserToken`을 찾으려고 시도합니다. 일치하는 값을 찾으면, 관련된 `User`를 가져와 인증합니다.

`POST /login` 요청에서 저장해 둔 값을 토큰으로 사용하여 다음 HTTP 요청을 전송해 보고, 이 라우트가 동작하는지 테스트해 보세요.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

인증된 `User`가 반환되는 것을 볼 수 있을 것입니다.

## 세션(Session)

Vapor의 [세션 API](../advanced/sessions.md)를 사용하면 요청 간에 사용자 인증을 자동으로 유지할 수 있습니다. 이는 로그인에 성공한 후 요청의 세션 데이터에 사용자의 고유 식별자를 저장하는 방식으로 동작합니다. 이후 요청에서는 세션에서 사용자의 식별자를 가져와, 라우트 핸들러를 호출하기 전에 사용자를 인증하는 데 사용합니다.

세션은 HTML을 웹 브라우저에 직접 제공하는, Vapor로 만든 프런트엔드 웹 애플리케이션에 매우 유용합니다. API의 경우, 요청 간에 사용자 데이터를 유지하기 위해 상태를 갖지 않는(stateless) 토큰 기반 인증을 사용하는 것을 권장합니다.

### Session Authenticatable

세션 기반 인증을 사용하려면, `SessionAuthenticatable`을 준수하는 타입이 필요합니다. 이 예제에서는 간단한 구조체를 사용하겠습니다.

```swift
import Vapor

struct User {
    var email: String
}
```

`SessionAuthenticatable`을 준수하려면, `sessionID`를 지정해야 합니다. 이는 세션 데이터에 저장될 값이며, 반드시 사용자를 고유하게 식별할 수 있어야 합니다.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

간단한 `User` 타입에서는, 고유한 세션 식별자로 이메일 주소를 사용하겠습니다.

### Session Authenticator

다음으로, 유지된 세션 식별자로부터 User 인스턴스를 알아내는 작업을 처리할 `SessionAuthenticator`가 필요합니다.


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

`async`/`await`를 사용하고 있다면, `AsyncSessionAuthenticator`를 사용할 수 있습니다.

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

예제로 든 `User`를 초기화하는 데 필요한 모든 정보가 세션 식별자에 담겨 있으므로, 사용자를 동기적으로 생성하고 로그인시킬 수 있습니다. 실제 애플리케이션에서는, 사용자를 인증하기 전에 세션 식별자를 사용하여 데이터베이스 조회나 API 요청을 수행하여 나머지 사용자 데이터를 가져오는 경우가 많을 것입니다.

다음으로, 초기 인증을 수행할 간단한 bearer authenticator를 만들어 보겠습니다.

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

이 Authenticator는 bearer 토큰 `test`가 전송되면 이메일 `hello@vapor.codes`를 가진 사용자를 인증합니다.

마지막으로, 이 모든 부분들을 애플리케이션에서 하나로 결합해 보겠습니다.

```swift
// 사용자 인증을 요구하는 보호된 라우트 그룹을 만듭니다.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// 사용자의 이메일을 읽기 위한 GET /me 라우트를 추가합니다.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

먼저 애플리케이션에서 세션 지원을 활성화하기 위해 `SessionsMiddleware`가 추가됩니다. 세션을 설정하는 방법에 대한 더 자세한 정보는 [세션 API](../advanced/sessions.md) 섹션에서 확인할 수 있습니다.

다음으로, `SessionAuthenticator`가 추가됩니다. 이는 세션이 활성 상태일 경우 사용자를 인증하는 역할을 담당합니다.

세션에 아직 인증 정보가 저장되어 있지 않다면, 요청은 다음 Authenticator로 전달됩니다. `UserBearerAuthenticator`는 bearer 토큰을 확인하여, 그 값이 `"test"`와 같으면 사용자를 인증합니다.

마지막으로, `User.guardMiddleware()`는 앞선 미들웨어들 중 하나가 `User`를 인증했는지 확인합니다. 사용자가 인증되지 않았다면 에러가 던져집니다.

이 라우트를 테스트하려면, 먼저 다음 요청을 전송하세요.

```http
GET /me HTTP/1.1
authorization: Bearer test
```

이렇게 하면 `UserBearerAuthenticator`가 사용자를 인증하게 됩니다. 인증되고 나면, `UserSessionAuthenticator`가 사용자의 식별자를 세션 저장소에 저장하고 쿠키를 생성합니다. 응답에서 받은 쿠키를 사용하여 이 라우트에 두 번째 요청을 보내세요.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

이번에는 `UserSessionAuthenticator`가 사용자를 인증하며, 다시 한번 사용자의 이메일이 반환되는 것을 볼 수 있을 것입니다.

### Model Session Authenticatable

Fluent 모델은 `ModelSessionAuthenticatable`을 준수시킴으로써 `SessionAuthenticator`를 생성할 수 있습니다. 이렇게 하면 모델의 고유 식별자를 세션 식별자로 사용하고, 세션으로부터 모델을 복원하기 위한 데이터베이스 조회를 자동으로 수행합니다.

```swift
import Fluent

final class User: Model { ... }

// 이 모델이 세션에 저장될 수 있도록 허용합니다.
extension User: ModelSessionAuthenticatable { }
```

기존의 어떤 모델에든 빈 준수(empty conformance)로 `ModelSessionAuthenticatable`을 추가할 수 있습니다. 추가하고 나면, 해당 모델에 대한 `SessionAuthenticator`를 생성하는 새로운 정적 메서드를 사용할 수 있게 됩니다.

```swift
User.sessionAuthenticator()
```

이렇게 하면 사용자를 조회하는 데 애플리케이션의 기본 데이터베이스가 사용됩니다. 특정 데이터베이스를 지정하려면, 식별자를 전달하세요.

```swift
User.sessionAuthenticator(.sqlite)
```

## 웹사이트 인증

웹사이트는 인증에 있어 특별한 경우인데, 브라우저를 사용한다는 특성상 브라우저에 자격 증명을 첨부하는 방식에 제약이 있기 때문입니다. 이로 인해 두 가지 서로 다른 인증 시나리오가 생겨납니다.

* 폼(form)을 통한 초기 로그인
* 세션 쿠키로 인증되는 이후의 호출들

Vapor와 Fluent는 이를 매끄럽게 만들어주는 여러 헬퍼를 제공합니다.

### 세션 인증

세션 인증은 앞서 설명한 대로 동작합니다. 사용자가 접근하게 될 모든 라우트에 세션 미들웨어와 세션 Authenticator를 적용해야 합니다. 여기에는 모든 보호된 라우트, 공개되어 있지만 사용자가 로그인되어 있다면 그 정보에 접근하고 싶을 수 있는 라우트(예를 들어 계정 버튼을 표시하기 위해), **그리고** 로그인 라우트가 포함됩니다.

**configure.swift**에서 다음과 같이 앱 전체에 이를 전역적으로 활성화할 수 있습니다.

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

이 미들웨어들은 다음과 같은 작업을 수행합니다.

* 세션 미들웨어는 요청에 제공된 세션 쿠키를 가져와 이를 세션으로 변환합니다
* 세션 Authenticator는 세션을 가져와 해당 세션에 인증된 사용자가 있는지 확인합니다. 있다면, 미들웨어는 요청을 인증합니다. 응답에서는, 세션 Authenticator가 요청에 인증된 사용자가 있는지 확인하고, 다음 요청에서도 인증되도록 그 사용자를 세션에 저장합니다.

!!! note
    세션 쿠키는 기본적으로 `secure`와 `httpOnly`로 설정되지 않습니다. 쿠키를 구성하는 방법에 대한 더 자세한 정보는 Vapor의 [세션 API](../advanced/sessions.md#configuration)를 확인하세요.

### 라우트 보호하기

API를 위해 라우트를 보호할 때는, 전통적으로 요청이 인증되지 않은 경우 **401 Unauthorized**와 같은 상태 코드를 가진 HTTP 응답을 반환합니다. 그러나 이는 브라우저를 사용하는 사람에게는 그리 좋은 사용자 경험이 아닙니다. Vapor는 이러한 시나리오에서 사용할 수 있도록, 모든 `Authenticatable` 타입에 대한 `RedirectMiddleware`를 제공합니다.

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

고급 URL 처리를 위해, `RedirectMiddleware` 객체는 생성 시 리다이렉트 경로를 `String`으로 반환하는 클로저를 전달하는 것도 지원합니다. 예를 들어, 상태 관리를 위해 리다이렉트 대상 경로에 리다이렉트 출발지 경로를 쿼리 매개변수로 포함시킬 수 있습니다.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

이는 `GuardMiddleware`와 유사하게 동작합니다. `protectedRoutes`에 등록된 라우트로의 요청 중 인증되지 않은 것은 모두 제공된 경로로 리다이렉트됩니다. 이를 통해 단순히 **401 Unauthorized**를 제공하는 대신, 사용자에게 로그인하도록 안내할 수 있습니다.

`RedirectMiddleware`가 실행되기 전에 인증된 사용자가 로드되도록, `RedirectMiddleware` 앞에 Session Authenticator를 반드시 포함시키세요.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### 폼 로그인

세션으로 사용자와 이후의 요청들을 인증하려면, 사용자를 로그인시켜야 합니다. Vapor는 준수할 수 있는 `ModelCredentialsAuthenticatable` 프로토콜을 제공합니다. 이는 폼을 통한 로그인을 처리합니다. 먼저 `User`를 이 프로토콜에 준수시키세요.

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

이는 `ModelAuthenticatable`과 동일하며, 이미 이를 준수하고 있다면 별도로 할 작업이 없습니다. 다음으로, 로그인 폼의 POST 요청에 `ModelCredentialsAuthenticator` 미들웨어를 적용하세요.

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

이는 기본 credentials Authenticator를 사용하여 로그인 라우트를 보호합니다. POST 요청에는 `username`과 `password`를 반드시 전송해야 합니다. 폼은 다음과 같이 구성할 수 있습니다.

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

`CredentialsAuthenticator`는 요청 본문에서 `username`과 `password`를 추출하고, 사용자 이름으로 사용자를 찾아 비밀번호를 검증합니다. 비밀번호가 유효하면, 미들웨어는 요청을 인증합니다. 이후 `SessionAuthenticator`가 다음 요청들을 위해 세션을 인증합니다.

## JWT

[JWT](jwt.md)는 들어오는 요청에서 JSON Web Token을 인증하는 데 사용할 수 있는 `JWTAuthenticator`를 제공합니다. JWT를 처음 사용한다면, [개요](jwt.md)를 확인하세요.

먼저, JWT 페이로드를 나타내는 타입을 만드세요.

```swift
// 예제 JWT 페이로드.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // 상수
    let expirationTime: TimeInterval = 60 * 15
    
    // 토큰 데이터
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

다음으로, 성공적인 로그인 응답에 담길 데이터를 나타내는 표현을 정의할 수 있습니다. 지금은 응답이 서명된 JWT를 나타내는 문자열 프로퍼티 하나만 가지도록 하겠습니다.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

JWT 토큰과 응답을 위한 모델을 사용하여, `ClientTokenResponse`를 반환하고 서명된 `SessionToken`을 포함하는 비밀번호 보호 로그인 라우트를 만들 수 있습니다.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

또는, Authenticator를 사용하고 싶지 않다면 다음과 같은 형태를 사용할 수도 있습니다.
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // 사용자에 대해 제공된 자격 증명을 검증합니다
    // 제공된 사용자의 userId를 가져옵니다
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

페이로드를 `Authenticatable`과 `JWTPayload`에 준수시킴으로써, `authenticator()` 메서드를 사용하여 라우트 Authenticator를 생성할 수 있습니다. 라우트가 호출되기 전에 JWT를 자동으로 가져와 검증하도록 라우트 그룹에 이를 추가하세요.

```swift
// SessionToken JWT를 요구하는 라우트 그룹을 만듭니다.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

선택적인 [guard 미들웨어](#guard-middleware)를 추가하면 인가(authorization)가 성공했음을 요구하게 됩니다.

보호된 라우트 내부에서는, `req.auth`를 사용하여 인증된 JWT 페이로드에 접근할 수 있습니다.

```swift
// 사용자가 제공한 토큰이 유효하면 ok 응답을 반환합니다.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
