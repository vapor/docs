# 認証 {#authentication}

認証は、ユーザーの身元を確認する行為です。これは、ユーザー名とパスワードまたは一意のトークンのような認証情報の検証を通じて行われます。認証（auth/cとも呼ばれる）は、以前に認証されたユーザーが特定のタスクを実行する権限を確認する行為である認可（auth/z）とは異なります。

## はじめに {#introduction}

VaporのAuthentication APIは、[Basic](https://tools.ietf.org/html/rfc7617)および[Bearer](https://tools.ietf.org/html/rfc6750)を使用して、`Authorization`ヘッダーを介したユーザー認証をサポートします。また、[Content](../basics/content.md) APIからデコードされたデータを介したユーザー認証もサポートしています。

認証は、検証ロジックを含む`Authenticator`を作成することで実装されます。オーセンティケータは、個々のルートグループまたはアプリ全体を保護するために使用できます。Vaporには以下のオーセンティケータヘルパーが付属しています：

|プロトコル|説明|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|ミドルウェアを作成できる基本オーセンティケータ。|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Basic認証ヘッダーを認証します。|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Bearer認証ヘッダーを認証します。|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|リクエストボディから認証情報のペイロードを認証します。|

認証が成功した場合、オーセンティケータは検証されたユーザーを`req.auth`に追加します。このユーザーは、オーセンティケータによって保護されているルートで`req.auth.get(_:)`を使用してアクセスできます。認証が失敗した場合、ユーザーは`req.auth`に追加されず、アクセスしようとしても失敗します。

## Authenticatable {#authenticatable}

Authentication APIを使用するには、まず`Authenticatable`に準拠するユーザータイプが必要です。これは`struct`、`class`、またはFluentの`Model`でも構いません。以下の例では、`name`という1つのプロパティを持つシンプルな`User`構造体を想定しています。

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

以下の各例では、作成したオーセンティケータのインスタンスを使用します。これらの例では、`UserAuthenticator`と呼んでいます。

### ルート {#route}

オーセンティケータはミドルウェアであり、ルートの保護に使用できます。

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require`は認証された`User`を取得するために使用されます。認証が失敗した場合、このメソッドはエラーをスローし、ルートを保護します。

### ガードミドルウェア {#guard-middleware}

ルートグループで`GuardMiddleware`を使用して、ルートハンドラに到達する前にユーザーが認証されていることを確認することもできます。

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

認証の要求は、オーセンティケータの構成を可能にするため、オーセンティケータミドルウェアによって行われません。[構成](#composition)の詳細については以下をお読みください。

## Basic {#basic}

Basic認証は、`Authorization`ヘッダーでユーザー名とパスワードを送信します。ユーザー名とパスワードはコロン（例：`test:secret`）で連結され、base-64エンコードされ、`"Basic "`でプレフィックスされます。次の例のリクエストは、ユーザー名`test`とパスワード`secret`をエンコードしています。

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Basic認証は通常、ユーザーのログインとトークンの生成に一度だけ使用されます。これにより、ユーザーの機密パスワードを送信する頻度を最小限に抑えます。プレーンテキストまたは未検証のTLS接続でBasic認証を送信しないでください。

アプリでBasic認証を実装するには、`BasicAuthenticator`に準拠する新しいオーセンティケータを作成します。以下は、上記のリクエストを検証するためにハードコードされた例のオーセンティケータです。

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

`async`/`await`を使用している場合は、代わりに`AsyncBasicAuthenticator`を使用できます：

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

このプロトコルでは、着信リクエストに`Authorization: Basic ...`ヘッダーが含まれているときに呼び出される`authenticate(basic:for:)`を実装する必要があります。ユーザー名とパスワードを含む`BasicAuthorization`構造体がメソッドに渡されます。

このテストオーセンティケータでは、ユーザー名とパスワードはハードコードされた値と照合されます。実際のオーセンティケータでは、データベースや外部APIと照合する可能性があります。これが`authenticate`メソッドがフューチャーを返すことができる理由です。

!!! tip
    パスワードはプレーンテキストでデータベースに保存しないでください。比較には常にパスワードハッシュを使用してください。

認証パラメータが正しい場合（この場合はハードコードされた値と一致）、Vaporという名前の`User`がログインされます。認証パラメータが一致しない場合、ユーザーはログインされず、認証が失敗したことを示します。

このオーセンティケータをアプリに追加し、上記で定義したルートをテストすると、ログインが成功した場合に名前`"Vapor"`が返されるはずです。認証情報が正しくない場合は、`401 Unauthorized`エラーが表示されるはずです。

## Bearer {#bearer}

Bearer認証は、`Authorization`ヘッダーでトークンを送信します。トークンには`"Bearer "`がプレフィックスされます。次の例のリクエストはトークン`foo`を送信しています。

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Bearer認証は、一般的にAPIエンドポイントの認証に使用されます。ユーザーは通常、ユーザー名とパスワードなどの認証情報をログインエンドポイントに送信してBearerトークンをリクエストします。このトークンは、アプリケーションのニーズに応じて数分から数日間有効です。

トークンが有効である限り、ユーザーは認証情報の代わりにそれを使用してAPIに対して認証できます。トークンが無効になった場合、ログインエンドポイントを使用して新しいトークンを生成できます。

アプリでBearer認証を実装するには、`BearerAuthenticator`に準拠する新しいオーセンティケータを作成します。以下は、上記のリクエストを検証するためにハードコードされた例のオーセンティケータです。

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

`async`/`await`を使用している場合は、代わりに`AsyncBearerAuthenticator`を使用できます：

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

このプロトコルでは、着信リクエストに`Authorization: Bearer ...`ヘッダーが含まれているときに呼び出される`authenticate(bearer:for:)`を実装する必要があります。トークンを含む`BearerAuthorization`構造体がメソッドに渡されます。

このテストオーセンティケータでは、トークンはハードコードされた値と照合されます。実際のオーセンティケータでは、データベースと照合したり、JWTで行われるような暗号化手段を使用してトークンを検証する可能性があります。これが`authenticate`メソッドがフューチャーを返すことができる理由です。

!!! tip
	トークン検証を実装する際は、水平方向のスケーラビリティを考慮することが重要です。アプリケーションが多くのユーザーを同時に処理する必要がある場合、認証が潜在的なボトルネックになる可能性があります。同時に実行される複数のアプリケーションインスタンスにわたって設計がどのようにスケールするかを検討してください。

認証パラメータが正しい場合（この場合はハードコードされた値と一致）、Vaporという名前の`User`がログインされます。認証パラメータが一致しない場合、ユーザーはログインされず、認証が失敗したことを示します。

このオーセンティケータをアプリに追加し、上記で定義したルートをテストすると、ログインが成功した場合に名前`"Vapor"`が返されるはずです。認証情報が正しくない場合は、`401 Unauthorized`エラーが表示されるはずです。

## 構成 {#composition}

複数のオーセンティケータを構成（組み合わせ）して、より複雑なエンドポイント認証を作成できます。オーセンティケータミドルウェアは認証が失敗してもリクエストを拒否しないため、これらのミドルウェアの複数を連鎖させることができます。オーセンティケータは2つの主要な方法で構成できます。

### メソッドの構成 {#composing-methods}

認証構成の最初の方法は、同じユーザータイプに対して複数のオーセンティケータを連鎖させることです。次の例を見てください：

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // ユーザーで何かを行う。
}
```

この例では、両方とも`User`を認証する2つのオーセンティケータ`UserPasswordAuthenticator`と`UserTokenAuthenticator`を想定しています。これらのオーセンティケータの両方がルートグループに追加されます。最後に、`User`が正常に認証されたことを要求するため、オーセンティケータの後に`GuardMiddleware`が追加されます。

このオーセンティケータの構成により、パスワードまたはトークンのいずれかでアクセスできるルートが作成されます。このようなルートは、ユーザーがログインしてトークンを生成し、その後そのトークンを使用して新しいトークンを生成し続けることができます。

### ユーザーの構成 {#composing-users}

認証構成の2番目の方法は、異なるユーザータイプのオーセンティケータを連鎖させることです。次の例を見てください：

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // 何かを行う。
}
```

この例では、それぞれ`Admin`と`User`を認証する2つのオーセンティケータ`AdminAuthenticator`と`UserAuthenticator`を想定しています。これらのオーセンティケータの両方がルートグループに追加されます。`GuardMiddleware`を使用する代わりに、ルートハンドラに`Admin`または`User`のいずれかが認証されたかどうかを確認するチェックが追加されます。そうでない場合は、エラーがスローされます。

このオーセンティケータの構成により、潜在的に異なる認証方法を持つ2つの異なるタイプのユーザーがアクセスできるルートが作成されます。このようなルートは、通常のユーザー認証を許可しながら、スーパーユーザーへのアクセスも提供できます。

## 手動 {#manual}

`req.auth`を使用して認証を手動で処理することもできます。これは特にテストに便利です。

ユーザーを手動でログインするには、`req.auth.login(_:)`を使用します。任意の`Authenticatable`ユーザーをこのメソッドに渡すことができます。

```swift
req.auth.login(User(name: "Vapor"))
```

認証されたユーザーを取得するには、`req.auth.require(_:)`を使用します

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

認証が失敗したときに自動的にエラーをスローしたくない場合は、`req.auth.get(_:)`を使用することもできます。

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

ユーザーの認証を解除するには、ユーザータイプを`req.auth.logout(_:)`に渡します。

```swift
req.auth.logout(User.self)
```

## Fluent {#fluent}

[Fluent](../fluent/overview.md)は、既存のモデルに追加できる`ModelAuthenticatable`と`ModelTokenAuthenticatable`の2つのプロトコルを定義しています。モデルをこれらのプロトコルに準拠させることで、エンドポイントを保護するためのオーセンティケータを作成できます。

`ModelTokenAuthenticatable`はBearerトークンで認証します。これは、ほとんどのエンドポイントを保護するために使用するものです。`ModelAuthenticatable`はユーザー名とパスワードで認証し、トークンを生成するための単一のエンドポイントで使用されます。

このガイドは、Fluentに精通しており、データベースを使用するようにアプリを正常に設定していることを前提としています。Fluentを初めて使用する場合は、[概要](../fluent/overview.md)から始めてください。

### ユーザー {#user}

開始するには、認証されるユーザーを表すモデルが必要です。このガイドでは、次のモデルを使用しますが、既存のモデルを自由に使用できます。

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

モデルは、この場合はメールアドレスであるユーザー名とパスワードハッシュを保存できる必要があります。また、重複ユーザーを避けるために、`email`を一意のフィールドに設定します。この例のモデルに対応するマイグレーションは次のとおりです：

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

`app.migrations`にマイグレーションを追加することを忘れないでください。

```swift
app.migrations.add(User.Migration())
``` 

!!! tip
     メールアドレスは大文字小文字を区別しないため、データベースに保存する前にメールアドレスを小文字に強制する[`Middleware`](../fluent/model.md#lifecycle)を追加することをお勧めします。ただし、`ModelAuthenticatable`は大文字小文字を区別する比較を使用するため、これを行う場合は、クライアントでの大文字小文字の強制、またはカスタムオーセンティケータを使用して、ユーザーの入力がすべて小文字であることを確認する必要があります。

最初に必要なのは、新しいユーザーを作成するためのエンドポイントです。`POST /users`を使用しましょう。このエンドポイントが期待するデータを表す[Content](../basics/content.md)構造体を作成します。

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

必要に応じて、この構造体を[Validatable](../basics/validation.md)に準拠させて、検証要件を追加できます。

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

これで`POST /users`エンドポイントを作成できます。

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

このエンドポイントは、着信リクエストを検証し、`User.Create`構造体をデコードし、パスワードが一致することを確認します。次に、デコードされたデータを使用して新しい`User`を作成し、データベースに保存します。プレーンテキストのパスワードは、データベースに保存する前に`Bcrypt`を使用してハッシュされます。

プロジェクトをビルドして実行し、最初にデータベースをマイグレートしてから、次のリクエストを使用して新しいユーザーを作成します。

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

#### Model Authenticatable {#model-authenticatable}

これで、ユーザーモデルと新しいユーザーを作成するためのエンドポイントができたので、モデルを`ModelAuthenticatable`に準拠させましょう。これにより、モデルをユーザー名とパスワードを使用して認証できるようになります。

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

この拡張は`User`に`ModelAuthenticatable`準拠を追加します。最初の2つのプロパティは、ユーザー名とパスワードハッシュをそれぞれ保存するために使用するフィールドを指定します。`\`記法は、Fluentがそれらにアクセスするために使用できるフィールドへのキーパスを作成します。

最後の要件は、Basic認証ヘッダーで送信されたプレーンテキストパスワードを検証するメソッドです。サインアップ中にパスワードをハッシュするためにBcryptを使用しているため、Bcryptを使用して、提供されたパスワードが保存されたパスワードハッシュと一致することを検証します。

`User`が`ModelAuthenticatable`に準拠したので、ログインルートを保護するためのオーセンティケータを作成できます。

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable`は、オーセンティケータを作成するための静的メソッド`authenticator`を追加します。

次のリクエストを送信して、このルートが機能することをテストします。

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

このリクエストは、Basic認証ヘッダーを介してユーザー名`test@vapor.codes`とパスワード`secret42`を渡します。以前に作成したユーザーが返されるはずです。

理論的にはBasic認証を使用してすべてのエンドポイントを保護できますが、代わりに別のトークンを使用することをお勧めします。これにより、ユーザーの機密パスワードをインターネット経由で送信する頻度が最小限に抑えられます。また、パスワードハッシュはログイン中にのみ実行する必要があるため、認証がはるかに高速になります。

### ユーザートークン {#user-token}

ユーザートークンを表す新しいモデルを作成します。

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

このモデルには、トークンの一意の文字列を保存するための`value`フィールドが必要です。また、ユーザーモデルへの[親関係](../fluent/overview.md#parent)も必要です。有効期限などの追加のプロパティを必要に応じてこのトークンに追加できます。

次に、このモデルのマイグレーションを作成します。

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

このマイグレーションは`value`フィールドを一意にすることに注意してください。また、`user_id`フィールドとusersテーブル間の外部キー参照も作成します。

`app.migrations`にマイグレーションを追加することを忘れないでください。

```swift
app.migrations.add(UserToken.Migration())
``` 

最後に、新しいトークンを生成するメソッドを`User`に追加します。このメソッドはログイン中に使用されます。

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

ここでは、`[UInt8].random(count:)`を使用してランダムなトークン値を生成しています。この例では、16バイト（128ビット）のランダムデータを使用しています。必要に応じてこの数値を調整できます。ランダムデータは、HTTPヘッダーで簡単に送信できるようにbase-64エンコードされます。

ユーザートークンを生成できるようになったので、`POST /login`ルートを更新してトークンを作成して返すようにします。

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

上記と同じログインリクエストを使用して、このルートが機能することをテストします。ログイン時に次のようなトークンを取得するはずです：

```
8gtg300Jwdhc/Ffw784EXA==
```

後で使用するので、取得したトークンを保持してください。

#### Model Token Authenticatable {#model-token-authenticatable}

`UserToken`を`ModelTokenAuthenticatable`に準拠させます。これにより、トークンが`User`モデルを認証できるようになります。

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

最初のプロトコル要件は、トークンの一意の値を保存するフィールドを指定します。これは、Bearer認証ヘッダーで送信される値です。2番目の要件は、`User`モデルへの親関係を指定します。これは、Fluentが認証されたユーザーを検索する方法です。

最後の要件は`isValid`ブール値です。これが`false`の場合、トークンはデータベースから削除され、ユーザーは認証されません。簡単にするために、これを`true`にハードコードしてトークンを永続的にします。

トークンが`ModelTokenAuthenticatable`に準拠したので、ルートを保護するためのオーセンティケータを作成できます。

現在認証されているユーザーを取得するための新しいエンドポイント`GET /me`を作成します。

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

`User`と同様に、`UserToken`にはオーセンティケータを生成できる静的な`authenticator()`メソッドがあります。オーセンティケータは、Bearer認証ヘッダーで提供された値を使用して一致する`UserToken`を見つけようとします。一致するものが見つかった場合、関連する`User`を取得して認証します。

`POST /login`リクエストから保存した値をトークンとして使用して、次のHTTPリクエストを送信してこのルートが機能することをテストします。

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

認証された`User`が返されるはずです。

## セッション {#session}

Vaporの[Session API](../advanced/sessions.md)を使用して、リクエスト間でユーザー認証を自動的に永続化できます。これは、ログインに成功した後、ユーザーの一意の識別子をリクエストのセッションデータに保存することで機能します。後続のリクエストでは、ユーザーの識別子がセッションから取得され、ルートハンドラを呼び出す前にユーザーを認証するために使用されます。

セッションは、Webブラウザに直接HTMLを提供するVaporで構築されたフロントエンドWebアプリケーションに最適です。APIの場合、リクエスト間でユーザーデータを永続化するために、ステートレスなトークンベースの認証を使用することをお勧めします。

### Session Authenticatable {#session-authenticatable}

セッションベースの認証を使用するには、`SessionAuthenticatable`に準拠するタイプが必要です。この例では、シンプルな構造体を使用します。

```swift
import Vapor

struct User {
    var email: String
}
```

`SessionAuthenticatable`に準拠するには、`sessionID`を指定する必要があります。これは、セッションデータに保存される値であり、ユーザーを一意に識別する必要があります。

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

シンプルな`User`タイプの場合、セッションの一意の識別子としてメールアドレスを使用します。

### セッションオーセンティケータ {#session-authenticator}

次に、永続化されたセッション識別子からUserのインスタンスを解決する処理を行う`SessionAuthenticator`が必要です。

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

`async`/`await`を使用している場合は、`AsyncSessionAuthenticator`を使用できます：

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

例の`User`を初期化するために必要なすべての情報がセッション識別子に含まれているため、ユーザーを同期的に作成してログインできます。実際のアプリケーションでは、セッション識別子を使用してデータベース検索やAPIリクエストを実行し、認証する前に残りのユーザーデータを取得する可能性があります。

次に、初期認証を実行するためのシンプルなベアラーオーセンティケータを作成しましょう。

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

このオーセンティケータは、ベアラートークン`test`が送信されたときに、メール`hello@vapor.codes`を持つユーザーを認証します。

最後に、これらのすべての部分をアプリケーションで組み合わせましょう。

```swift
// ユーザー認証を必要とする保護されたルートグループを作成します。
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// ユーザーのメールを読み取るためのGET /meルートを追加します。
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware`が最初に追加され、アプリケーションでセッションサポートが有効になります。セッションの設定に関する詳細は、[Session API](../advanced/sessions.md)セクションにあります。

次に、`SessionAuthenticator`が追加されます。これは、セッションがアクティブな場合にユーザーを認証する処理を行います。

認証がまだセッションに永続化されていない場合、リクエストは次のオーセンティケータに転送されます。`UserBearerAuthenticator`はベアラートークンをチェックし、それが`"test"`と等しい場合にユーザーを認証します。

最後に、`User.guardMiddleware()`は、`User`が前のミドルウェアのいずれかによって認証されたことを確認します。ユーザーが認証されていない場合、エラーがスローされます。

このルートをテストするには、まず次のリクエストを送信します：

```http
GET /me HTTP/1.1
authorization: Bearer test
```

これにより、`UserBearerAuthenticator`がユーザーを認証します。認証されると、`UserSessionAuthenticator`はユーザーの識別子をセッションストレージに永続化し、クッキーを生成します。レスポンスからのクッキーを使用して、ルートへの2番目のリクエストを行います。

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

今回は、`UserSessionAuthenticator`がユーザーを認証し、再びユーザーのメールが返されるはずです。

### Model Session Authenticatable {#model-session-authenticatable}

Fluentモデルは、`ModelSessionAuthenticatable`に準拠することで`SessionAuthenticator`を生成できます。これは、モデルの一意の識別子をセッション識別子として使用し、セッションからモデルを復元するためのデータベース検索を自動的に実行します。

```swift
import Fluent

final class User: Model { ... }

// このモデルをセッションに永続化できるようにします。
extension User: ModelSessionAuthenticatable { }
```

`ModelSessionAuthenticatable`を既存のモデルに空の準拠として追加できます。追加されると、そのモデルの`SessionAuthenticator`を作成するための新しい静的メソッドが利用可能になります。

```swift
User.sessionAuthenticator()
```

これは、ユーザーを解決するためにアプリケーションのデフォルトデータベースを使用します。データベースを指定するには、識別子を渡します。

```swift
User.sessionAuthenticator(.sqlite)
```

## ウェブサイト認証 {#website-authentication}

ウェブサイトは、ブラウザの使用により認証情報をブラウザに添付する方法が制限されるため、認証の特殊なケースです。これにより、2つの異なる認証シナリオが発生します：

* フォームを介した初回ログイン
* セッションクッキーで認証される後続の呼び出し

VaporとFluentは、これをシームレスにするためのいくつかのヘルパーを提供します。

### セッション認証 {#session-authentication}

セッション認証は上記で説明したとおりに機能します。ユーザーがアクセスするすべてのルートにセッションミドルウェアとセッションオーセンティケータを適用する必要があります。これには、保護されたルート、ログインしている場合にユーザーにアクセスしたいパブリックルート（アカウントボタンを表示するためなど）、**および**ログインルートが含まれます。

**configure.swift**でアプリにグローバルに有効にできます：

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

これらのミドルウェアは次のことを行います：

* セッションミドルウェアは、リクエストで提供されたセッションクッキーを取得し、セッションに変換します
* セッションオーセンティケータはセッションを取得し、そのセッションに認証されたユーザーがいるかどうかを確認します。いる場合、ミドルウェアはリクエストを認証します。レスポンスでは、セッションオーセンティケータはリクエストに認証されたユーザーがいるかどうかを確認し、次のリクエストで認証されるようにセッションに保存します。

!!! note
    セッションクッキーはデフォルトで`secure`と`httpOnly`に設定されていません。クッキーの設定方法の詳細については、Vaporの[Session API](../advanced/sessions.md#configuration)を確認してください。

### ルートの保護 {#protecting-routes}

APIのルートを保護する場合、従来はリクエストが認証されていない場合に**401 Unauthorized**などのステータスコードでHTTPレスポンスを返します。しかし、これはブラウザを使用している人にとって良いユーザーエクスペリエンスではありません。Vaporは、このシナリオで使用する任意の`Authenticatable`タイプ用の`RedirectMiddleware`を提供します：

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

`RedirectMiddleware`オブジェクトは、高度なURL処理のために作成時にリダイレクトパスを`String`として返すクロージャを渡すこともサポートしています。例えば、状態管理のためにリダイレクト元のパスをリダイレクト先のクエリパラメータとして含めることができます。

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

これは`GuardMiddleware`と同様に機能します。`protectedRoutes`に登録されたルートへの認証されていないリクエストは、提供されたパスにリダイレクトされます。これにより、単に**401 Unauthorized**を提供するのではなく、ユーザーにログインするよう指示できます。

`RedirectMiddleware`を実行する前に認証されたユーザーが読み込まれるように、`RedirectMiddleware`の前にセッションオーセンティケータを含めてください。

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### フォームログイン {#form-log-in}

ユーザーとセッションでの将来のリクエストを認証するには、ユーザーをログインする必要があります。Vaporは、フォームを介したログインを処理する`ModelCredentialsAuthenticatable`プロトコルを提供します。まず、`User`をこのプロトコルに準拠させます：

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

これは`ModelAuthenticatable`と同じであり、すでにそれに準拠している場合は何もする必要はありません。次に、この`ModelCredentialsAuthenticator`ミドルウェアをログインフォームのPOSTリクエストに適用します：

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

これは、ログインルートを保護するためにデフォルトの認証情報オーセンティケータを使用します。POSTリクエストで`username`と`password`を送信する必要があります。次のようにフォームを設定できます：

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

`CredentialsAuthenticator`は、リクエストボディから`username`と`password`を抽出し、ユーザー名からユーザーを見つけ、パスワードを検証します。パスワードが有効な場合、ミドルウェアはリクエストを認証します。その後、`SessionAuthenticator`が後続のリクエストのためにセッションを認証します。

## JWT {#jwt}

[JWT](jwt.md)は、着信リクエストでJSON Web Tokenを認証するために使用できる`JWTAuthenticator`を提供します。JWTを初めて使用する場合は、[概要](jwt.md)を確認してください。

まず、JWTペイロードを表すタイプを作成します。

```swift
// 例のJWTペイロード。
struct SessionToken: Content, Authenticatable, JWTPayload {

    // 定数
    let expirationTime: TimeInterval = 60 * 15
    
    // トークンデータ
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

次に、ログインレスポンスの成功時に含まれるデータの表現を定義できます。今のところ、レスポンスには署名されたJWTを表す文字列であるプロパティが1つだけあります。

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

JWTトークンとレスポンスのモデルを使用して、`ClientTokenResponse`を返し、署名された`SessionToken`を含むパスワード保護されたログインルートを使用できます。

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

また、オーセンティケータを使用したくない場合は、次のようなものを使用できます。
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // ユーザーの提供された認証情報を検証
    // 提供されたユーザーのuserIdを取得
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

ペイロードを`Authenticatable`と`JWTPayload`に準拠させることで、`authenticator()`メソッドを使用してルートオーセンティケータを生成できます。ルートグループにこれを追加して、ルートが呼び出される前にJWTを自動的に取得して検証します。

```swift
// SessionToken JWTを必要とするルートグループを作成します。
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

オプションの[ガードミドルウェア](#guard-middleware)を追加すると、認証が成功したことが必要になります。

保護されたルート内では、`req.auth`を使用して認証されたJWTペイロードにアクセスできます。

```swift
// ユーザーが提供したトークンが有効な場合、okレスポンスを返します。
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```