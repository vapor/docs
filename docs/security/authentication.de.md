# Authentifizierung

Bei der Authentifzierung handelt sich um die Überprüfung einer Benutzeridentität, zum Beispiel anhand von Anmeldeinformationen oder einem Token. Die Authentifizierung unterscheidet sich von der Authentisierung. Bei Authentisierung geht es mehr um die Überprüfung von Berechtigungen eines Benutzers.

## Einführung

Vapor ermöglicht die Basis- und Bearerauthentifzierung mittels dem Authorization-Header. Die Authenifzierung erfolgt durch einen sogenannten _Authenticator_, der die eigentliche Logik beinhaltet und dazu verwendent wird um, einzelne Endpunkte oder auch die gesamte Anwendung zu sichern.
| Protokoll                                                   | Beschreibung                                             |
|-------------------------------------------------------------|----------------------------------------------------------|
| `RequestAuthenticator`/`AsyncRequestAuthenticator`          | Base authenticator capable of creating middleware.       |
| [`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)    |Authenticates Basic authorization header.                 |
| [`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer) |Authenticates Bearer authorization header.                |
| `CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`  |Authenticates a credentials payload from the request body.|

Bei erfolgreicher Authentifizierung, übergibt der Authenticator die Benutzeridentität an die Eigenschaft `req.auth`. Mit der Methode `get(_:)` können wir auf die Identität zugreifen. Wenn die Authentifizerung fehl schlägt, wird keine Identität übergeben und jeglicher Versuch darauf zuzugreifen schlägt fehl.

## Authenticatable

Um einen Benutzer zu authentifizieren, muss das Objekt mit dem Protokoll `Authenticatable` versehen werden. Beim Objekt kann es sich um eine Struktur, Klasse oder ein Fluent-Model handeln. Für das folgende Beispiel erstellen wir eine Struktur `User` mit der Eigenschaft `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

### Endpunkt

Endpunkte können mit Authentikatoren versehen werden.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

Mit der Methode _require(:)_ können wir die Benutzeridentität abfragen. Sollte die Authentifizierung fehlschlagen, wird ein entsprechender Fehler ausgegeben und der Endpunkt bleibt unberührt.

### Guard Middleware

Mit der Methode _guardMiddleware()_ gehen wir auf Nummer sich gehen und 

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Requiring authentication is not done by the authenticator middleware to allow for composition of authenticators. Read more about [composition](#composition) below.

## Basisauthentifizierung

Die Basisauthentifierung überträgt mittels Authorization-Header Benutzername und Passwort an den Server. Benutzername und Passwort werden dabei mit einem semikolon-getrennt in eine Base64-Zeichenfolge gewandelt und mit dem Prefix `Basic`versehen.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
```

Die Basisauthentifierzung wird nur einmalig verwendet, um nach der erfolgreichen Authentifizierung einen Token zu erzeugen.

Durch den Token wird die Häufigkeit einer notwendigen Übermittlung des Passwortes verringert. Zudem sollte die Authentifizerung nie im Klartext oder über eine unverschlüsselte Verbindung erfolgen.

Damit wir die Basisauthentifierzung in unserer Anwendung verwenden können, müssen wir einen Struktur anlegen und diese mit dem Protokoll _BasicAuthenticator_ versehen.

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

Das Protokoll verlangt, dass wir die Methode _authenticate(basic:for:)_ anlegen. Die Methode wird bei einer Anfrage mit Basis-Header aufgerufen. Eine Struktur mit Benutzername und Passwort wird somit an die Methode übergeben.

## Bearerauthentifizierung

Die Bearerauthentifierzung sendet einen Token an den Server. Der Token wird mit dem Prefix `Bearer` versehen.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Die Bearerauthentifierzung wird für die Authentifizerung von API-Endpunkten verwendet. Dabei fragt der User nach einem Token, indem er Benutzername und Passwort an einen Login-Endpunkt schickt. Der Token ist anschließend für einen gewissen Zeitraum gültig. 

Innerhalb der Gültigkeit kann der Benutzer den Token an Stelle der eigentlichen Anmeldeinformationen verwenden. Mit dem Ablauf des Tokens, muss über den Endpunkt einer neuer Token angefordert werden.

Zur Verwendung einer Bearerauthentifizierung, müssen wir eine Struktur erstellen und diese mit dem Protokoll `BearerAuthenticator` versehen.

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

Das Protokoll verlangt, dass wir die Methode _authenticate(bearer:for:)_ anlegen. Die Methode wird bei einer Anfrage mit Bearer-Header aufgerufen. Das Objekt wird an die Methode übergeben.

## Composition

Authentikatoren können für eine höhrere Sicherheit miteinander kombiniert werden.

### Kombinieren von Methoden

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Do something with user.
}
```

Im folgenden Beispiel folgt das Objekt _UserTokenAuthenticator_ dem _UserPasswordAuthenticator_ und zum Schluss die _GuardMiddleware_.

This example assumes two authenticators `UserPasswordAuthenticator` and `UserTokenAuthenticator` that both authenticate `User`. Both of these authenticators are added to the route group. Finally, `GuardMiddleware` is added after the authenticators to require that `User` was successfully authenticated. 

Die Zusammenstellung der Authentikator macht es möglich, dass der Benutzer sich 

This composition of authenticators results in a route that can be accessed by either password or token. Such a route could allow a user to login and generate a token, then continue to use that token to generate new tokens.

### Kombinieren von Benutzern

The second method of authentication composition is chaining authenticators for different user types. Take the following example:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Do something.
}
```

This example assumes two authenticators `AdminAuthenticator` and `UserAuthenticator` that authenticate `Admin` and `User`, respectively. Both of these authenticators are added to the route group. Instead of using `GuardMiddleware`, a check in the route handler is added to see if either `Admin` or `User` were authenticated. If not, an error is thrown.

This composition of authenticators results in a route that can be accessed by two different types of users with potentially different methods of authentication. Such a route could allow for normal user authentication while still giving access to a super-user.

## Manual

Die Authenifizieung kann über die Eigenschaft _req.auth_ manuell durchgeführt werden. Das kann zu Beispiel zu Testzwecke hilfreich sein. 

Um einen Benutzer manuell anzumelden, müssen wir einen Objekt vom Typ _Authenticatble_  der Methode _req.auth.login(_:) mitgegeben.

```swift
req.auth.login(User(name: "Vapor"))
```

To get the authenticated user, use `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

You can also use `req.auth.get(_:)` if you don't want to automatically throw an error when authentication fails.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Um einen Benutzer abzumelden, müssen wir die Identität an die Methode _req.auth.logout(_:)_ übergeben.

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) bietet uns hierzu bereits Protokolle an, die wir auf unseren Models anwenden können.

_ModelTokenAuthenicatable_ ist für die Authentifizierung mit einem Bearer-Token. _ModelAuthenticatable_ ist für die Authentifizierung mittels Anmeldeinformationen und wird in den meisten Fällen nur auf einen einzigen Endpunkt angewendet, um eben einen solchen Bearer-Token zu erstellen.

This guide assumes you are familiar with Fluent and have successfully configured your app to use a database. If you are new to Fluent, start with the [overview](../fluent/overview.md).

### Benutzerauthentifizierung

Für den Anfang brauchen wir ein Model zum Authentifizieren des Benutzers.

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

Das Model. Das Feld _Email_ sollte unique sein, um Redundanzen zu vermeiden. Somit würde die Migration für das obere Beispiel so aussehen.

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

Anschließend müssen wir der Anwendung noch die Migration mitgeben.

```swift
app.migrations.add(User.Migration())
``` 

Als Nächstes legen für die Benutzererstellung einen Endpunkt und eine Struktur an.

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

Wir können die Struktur mit dem Protokoll _Validatable_ versehen um weitere Validierungen hinzuzufügen.

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

Now you can create the `POST /users` endpoint. 

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

Der Endpunkt überprüft die Anfrage, entziffert die von uns erstellte Struktur _User.Create_ und gleicht das Passwort ab. Zusammen mit den entzifferten Informationen wird anschließend der Benutzer in der Datenbank angelegt. Das Klartext-Passwort wird dabei mit _Bycrypt_ verschlüsselt.

Wir können das Projekt nun starten.

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

Nachdem wir nun einen Model für den Benutzer und einen Endpunkt zum Anlegen eines Benutzers haben, können wir das Model mit dem Protokoll _ModelAuthenticatable_ versehen.

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

Mit Hilfe der ersten beiden Eigenschaften _usernameKey_ und _passwordHashKey_ bestimmen wir, welche Felder im Model für den Benutzernamen und dem Passwort-Hash verwenden werden soll. Mit der _\_ legen wir hierzu ein KeyPath an, worüber Fluent darauf zugreifen kann.

Mit der Methode _verify(password:)_ können wir das Plaintext-Passwort eines Basic-Headers gegenprüfen. Weil wir anfangs in unserem Beispiel _Bycrypt_ verwendet haben, müssen wir bei der Überprüfung des Hashwertes ebenfalls _Bycrypt_ anwenden.

Nun können wir auch einen Endpunkt mit einem Authentikator versehen.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

Dank des Protokolls _ModelAuthenticatable_ können wir die statische Methode _athenticator(:)_ verwenden, um einen Authenticator zu erstellen.

Test that this route works by sending the following request.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Die Anfragen übergibt als Benutzernamen _test@vapor.codes_ und als Passwort _secret42_: 

This request passes the username `test@vapor.codes` and password `secret42` via the Basic authentication header. You should see the previously created user returned.

In der Theorie können wir alle Endpunkte mit der Standardauthentifizierung versehen, was allerdings weniger ratsam wäre. Mit der Token-Authentifizierung übertragen wir viel seltener die sensiblen Daten über das Internet. Zumal ist die Authentifizierung um einiges schneller, da nur das Passwort-Hashing durchgeführt wird.

### Benutzertoken

Für einen Benutzertoken erstellen wir eine neues Model.

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

Für den eindeutigen Tokenwert müssen wir im Model ein Feld mit der Bezeichnung _value_ anlegen. Um eine Verbindung zum Benutzer herzustellen, müssen wir zusätzlich ein Parent-Relation anlegen.

Anschließend können wir uns der Migration widmen.

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

In der Migration geben wir an, dass der Wert für das Feld _value_ eindeutig sein soll und das ein Fremdschlüssel mit Verweis auf die Tabelle _Users_ anlegegt werden soll.

Nun müssen wir der Anwendung die Migration mitgeben.

```swift
app.migrations.add(UserToken.Migration())
``` 

Zum Schluss erweitern wir das Model _User_ noch um eine Methode für die Erstellung des Tokens. Die Methode wird beim Login aufgerufen.

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

Here we're using `[UInt8].random(count:)` to generate a random token value. For this example, 16 bytes, or 128 bits, of random data are being used. You can adjust this number as you see fit. The random data is then base-64 encoded to make it easy to transmit in HTTP headers.

Now that you can generate user tokens, update the `POST /login` route to create and return a token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Test that this route works by using the same login request from above. You should now get a token upon logging in that looks something like:

```
8gtg300Jwdhc/Ffw784EXA==
```

Hold onto the token you get as we'll use it shortly.

#### Model Token Authenticatable

Conform `UserToken` to `ModelTokenAuthenticatable`. This will allow for tokens to authenticate your `User` model.

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

The first protocol requirement specifies which field stores the token's unique value. This is the value that will be sent in the Bearer authentication header. The second requirement specifies the parent-relation to the `User` model. This is how Fluent will look up the authenticated user. 

The final requirement is an `isValid` boolean. If this is `false`, the token will be deleted from the database and the user will not be authenticated. For simplicity, we'll make the tokens eternal by hard-coding this to `true`.

Now that the token conforms to `ModelTokenAuthenticatable`, you can create an authenticator for protecting routes.

Create a new endpoint `GET /me` for getting the currently authenticated user.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Similar to `User`, `UserToken` now has a static `authenticator()` method that can generate an authenticator. The authenticator will attempt to find a matching `UserToken` using the value provided in the Bearer authentication header. If it finds a match, it will fetch the related `User` and authenticate it. 

Test that this route works by sending the following HTTP request where the token is the value you saved from the `POST /login` request. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

You should see the authenticated `User` returned. 

## Sitzung

Vapor's [Session API](../advanced/sessions.md) can be used to automatically persist user authentication between requests. This works by storing a unique identifier for the user in the request's session data after successful login. On subsequent requests, the user's identifier is fetched from the session and used to authenticate the user before calling your route handler.

Sessions are great for front-end web applications built in Vapor that serve HTML directly to web browsers. For APIs, we recommend using stateless, token-based authentication to persist user data between requests.

### Session Authenticatable

To use session-based authentication, you will need a type that conforms to `SessionAuthenticatable`. For this example, we'll use a simple struct.

```swift
import Vapor

struct User {
    var email: String
}
```

To conform to `SessionAuthenticatable`, you will need to specify a `sessionID`. This is the value that will be stored in the session data and must uniquely identify the user. 

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

For our simple `User` type, we'll use the email address as the unique session identifier.

### Session Authenticator

Next, we'll need a `SessionAuthenticator` to handle resolving instances of our User from the persisted session identifier.


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

If you're using `async`/`await` you can use the `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Since all the information we need to initialize our example `User` is contained in the session identifier, we can create and login the user synchronously. In a real-world application, you would likely use the session identifier to perform a database lookup or API request to fetch the rest of the user data before authenticating. 

Next, let's create a simple bearer authenticator to perform the initial authentication.

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

This authenticator will authenticate a user with the email `hello@vapor.codes` when the bearer token `test` is sent.

Finally, let's combine all these pieces together in your application.

```swift
// Create protected route group which requires user auth.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Add GET /me route for reading user's email.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` is added first to enable session support on the application. More information about configuring sessions can be found in the [Session API](../advanced/sessions.md) section.

Next, the `SessionAuthenticator` is added. This handles authenticating the user if a session is active. 

If the authentication has not been persisted in the session yet, the request will be forwarded to the next authenticator. `UserBearerAuthenticator` will check the bearer token and authenticate the user if it equals `"test"`.

Finally, `User.guardMiddleware()` will ensure that `User` has been authenticated by one of the previous middleware. If the user has not been authenticated, an error will be thrown. 

To test this route, first send the following request:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

This will cause `UserBearerAuthenticator` to authenticate the user. Once authenticated, `UserSessionAuthenticator` will persist the user's identifier in session storage and generate a cookie. Use the cookie from the response in a second request to the route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

This time, `UserSessionAuthenticator` will authenticate the user and you should again see the user's email returned.

### Model Session Authenticatable

Fluent models can generate `SessionAuthenticator`s by conforming to `ModelSessionAuthenticatable`. This will use the model's unique identifier as the session identifier and automatically perform a database lookup to restore the model from the session. 

```swift
import Fluent

final class User: Model { ... }

// Allow this model to be persisted in sessions.
extension User: ModelSessionAuthenticatable { }
```

You can add `ModelSessionAuthenticatable` to any existing model as an empty conformance. Once added, a new static method will be available for creating a `SessionAuthenticator` for that model. 

```swift
User.sessionAuthenticator()
```

This will use the application's default database for resolving the user. To specify a database, pass the identifier.

```swift
User.sessionAuthenticator(.sqlite)
```

## Website Authentication

Websites are a special case for authentication because the use of a browser restricts how you can attach credentials to a browser. This leads to two different authentication scenarios:

* the initial log in via a form
* subsequent calls authenticated with a session cookie

Vapor and Fluent provides several helpers to make this seamless.

### Cookie-Authentifizierung

Session authentication works as described above. You need to apply the session middleware and session authenticator to all routes that your user will access. These include any protected routes, any routes which are public but you may still want to access the user if they're logged in (to display an account button for instance) **and** login routes.

You can enable this globally in your app in **configure.swift** like so:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

These middlewares do the following:

* Die Sitzung-Middleware wandelt den übermittelten Sitzungs-Cookie in eine Sitzung um.
* Der Authentikator gleicht die erstelle Sitzung mit den aktiven Sitzung ab. Sollte das der Fall sein, authentifiziert es die Anfrage. Die Identität wird in der Sitzung abgelegt, sodass 

* the sessions middleware takes the session cookie provided in the request and converts it into a session
* the session authenticator takes the session and see if there is an authenticated user for that session. If so, the middleware authenticates the request. In the response, the session authenticator sees if the request has an authenticated user and saves them in the session so they're authenticated in the next request.

### Protecting Routes

When protecting routes for an API, you traditionally return an HTTP response with a status code such as **401 Unauthorized** if the request is not authenticated. However, this isn't a very good user experience for someone using a browser. Vapor provides a `RedirectMiddleware` for any `Authenticatable` type to use in this scenario:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

The `RedirectMiddleware` object also supports passing a closure that returns the redirect path as a `String` during creation for advanced url handling. For instance, including the path redirected from as query parameter to the redirect target for state management.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

This works similar to the `GuardMiddleware`. Any requests to routes registered to `protectedRoutes` that aren't authenticated will be redirected to the path provided. This allows you to tell your users to log in, rather than just providing a **401 Unauthorized**.

Be sure to include a Session Authenticator before the `RedirectMiddleware` to ensure the authenticated user is loaded before running through the `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.SessionAuthenticator(), redirecteMiddleware])
```

### Formularanfrage

Für die Authentifizerung und spätere Sitzungen, die Anmeldung erfolgt meistens über ein Formular.

To authenticate a user and future requests with a session, you need to log a user in. Vapor provides a `ModelCredentialsAuthenticatable` protocol to conform to. This handles log in via a form. First conform your `User` to this protocol:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

This is identical to `ModelAuthenticatable` and if you already conform to that then you don't need to do anything else. Next apply this `ModelCredentialsAuthenticator` middleware to your log in form POST request:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

This uses the default credentials authenticator to protect the login route. You must send `username` and `password` in the POST request. You can set your form up like so:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

The `CredentialsAuthenticator` extracts the `username` and `password` from the request body, finds the user from the username and verifies the password. If the password is valid, the middleware authenticates the request. The `SessionAuthenticator` then authenticates the session for subsequent requests.

## JWT

[JWT](jwt.md) provides a `JWTAuthenticator` that can be used to authenticate JSON Web Tokens in incoming requests. If you are new to JWT, check out the [overview](jwt.md).

First, create a type representing a JWT payload.

```swift
// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constants
    let expirationTime: TimeInterval = 60 * 15
    
    // Token Data
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

Next, we can define a representation of the data contained in a successful login response. For now the response will only have one property which is a string representing a signed JWT.

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

Using our model for the JWT token and response, we can use a password protected login route which returns a `ClientTokenReponse` and includes a signed `SessionToken`.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Alternatively, if you don't want to use an authenticator you can have something that looks like the following.
```swift
app.post("login") { req -> ClientTokenReponse in
    // Validate provided credential for user
    // Get userId for provided user
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

By conforming the payload to `Authenticatable` and `JWTPayload`, you can generate a route authenticator using the `authenticator()` method. Add this to a route group to automatically fetch and verify the JWT before your route is called. 

```swift
// Create a route group that requires the SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Adding the optional [guard middleware](#guard-middleware) will require that authorization succeeded.

Inside the protected routes, you can access the authenticated JWT payload using `req.auth`. 

```swift
// Return ok reponse if the user-provided token is valid.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```