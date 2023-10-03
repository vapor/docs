# Authentifizierung

Bei der Authentifizierung handelt es sich um die Überprüfung einer Benutzeridentität, zum Beispiel anhand von Anmeldeinformationen oder einem Token. Die Authentifizierung unterscheidet sich von der Autorisierung, bei der die Berechtigung eines zuvor authentifizierten Benutzers zur Durchführung bestimmter Aufgaben überprüft wird.


## Einführung

Vapor ermöglicht die [Basis](https://tools.ietf.org/html/rfc7617)- und [Bearer](https://tools.ietf.org/html/rfc6750) Authentifizierung mittels dem `Authorization` Header. Man kann auch einen User mit den Daten die in der [Content](../basics/content.de.md) API sind authentifizieren.

Die Authentifizierung erfolgt durch einen sogenannten `Authenticator`, der die eigentliche Logik beinhaltet und dazu verwendet wird um, einzelne Endpunkte oder auch die gesamte Anwendung zu sichern. Ein `Authenticator` kann entweder einzelne Routengruppen schützen oder auch die ganze App. Die folgenden Authenticator-Helfer werden mit Vapor ausgeliefert:
| Protokoll                                                   | Beschreibung                                             |
|-------------------------------------------------------------|----------------------------------------------------------|
| `RequestAuthenticator`/`AsyncRequestAuthenticator`          |Basis Authentifizierung, der Middleware erstellen kann.      |
| [`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basis)    |Authentifiziert den Basic authorization header.           |
| [`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer) |Authentifiziert den Bearer-Autorisierungs-Header.         |
| `CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`  |Authentifiziert einen Credentials Payload aus dem Request Body.|

Bei erfolgreicher Authentifizierung übergibt der Authenticator die Benutzeridentität an die Eigenschaft `req.auth`. Mit der Methode `get(_:)` können wir auf die Identität zugreifen. Wenn die Authentifizierung fehl schlägt wird keine Identität übergeben und jeglicher Versuch, darauf zuzugreifen, schlägt fehl.

## Authentifizierbar

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

Mit der Methode `req.auth.require` können wir die Benutzeridentität abfragen. Sollte die Authentifizierung fehlschlagen, wird ein entsprechender Fehler ausgegeben und der Endpunkt bleibt unberührt.

### Guard Middleware

Wir können auch `GuardMiddleware` in der Routengruppe verwenden, um sicherzustellen, dass ein Benutzer authentifiziert wurde, bevor er den Routenhandler erreicht.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Die Authentifizierung wird nicht von der Authentifikator-Middleware durchgeführt, um die Komposition von Authentifikatoren zu ermöglichen. Lies unten mehr über [composition](#composition) weiter.

## Basis

Die Basis Authentifizierung überträgt mittels Authorization-Header Benutzername und Passwort an den Server. Benutzername und Passwort werden dabei mit einem Doppelpunkt-verkettet (z.B. `test:secret`), base-64 kodiert und mit dem Präfix `"Basic"` versehen. Die folgende Beispielanfrage kodiert den Benutzernamen "test" mit dem Passwort "secret".

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
```

Die Basis Authentifizierung wird nur einmalig verwendet, um nach der erfolgreichen Authentifizierung einen Token zu erzeugen.

Durch den Token wird die Häufigkeit einer notwendigen Übermittlung des Passwortes verringert. Zudem sollte die Basis Authentifizierung nie im Klartext oder über eine unverschlüsselte Verbindung erfolgen.


Damit wir die Basis - Authentifizierung in unserer Anwendung verwenden können, müssen wir eine Struktur anlegen und diese mit dem Protokoll `BasicAuthenticator versehen. Nachfolgend ist ein Beispiel für einen Authenticator zu sehen, der fest programmiert ist, um die obige Anfrage zu verifizieren.

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

Wenn Sie `async`/`await` verwenden, können Sie stattdessen `AsyncBasicAuthenticator` benutzen:

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

## Bearer

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

## Kombinierung

Authentikatoren können für eine höhrere Sicherheit miteinander kombiniert werden.

### Kombinieren von Methoden

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Mach etwas mit dem Benutzer.
}
```

Im folgenden Beispiel folgt das Objekt _UserTokenAuthenticator_ dem _UserPasswordAuthenticator_ und zum Schluss die _GuardMiddleware_.

In diesem Beispiel wird von zwei Authentifikatoren `UserPasswordAuthenticator` und `UserTokenAuthenticator` ausgegangen, die beide `User` authentifizieren. Diese beiden Authentifikatoren werden der Routengruppe hinzugefügt. Schließlich wird `GuardMiddleware` nach den Authentifikatoren hinzugefügt, um sicherzustellen, dass `User` erfolgreich authentifiziert wurde.

Die Zusammenstellung der Authentikator macht es möglich, dass der Benutzer sich 

Diese Zusammensetzung von Authentifikatoren führt zu einer Route, auf die entweder mit einem Passwort oder einem Token zugegriffen werden kann. Ein solcher Weg könnte es einem Benutzer ermöglichen, sich anzumelden und ein Token zu generieren, das er dann weiter zur Generierung neuer Token verwenden kann.

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
    // Mach etwas.
}
```

In diesem Beispiel werden zwei Authentifikatoren `AdminAuthenticator` und `UserAuthenticator` angenommen, die jeweils `Admin` und `User` authentifizieren. Diese beiden Authentifikatoren werden der Routengruppe hinzugefügt. Anstatt `GuardMiddleware` zu verwenden, wird eine Prüfung im Routehandler hinzugefügt, um zu sehen, ob entweder `Admin` oder `User` authentifiziert wurden. Wenn nicht, wird ein Fehler ausgelöst.

Diese Zusammensetzung von Authentifikatoren führt zu einer Route, die von zwei verschiedenen Nutzertypen mit potenziell unterschiedlichen Authentifizierungsmethoden genutzt werden kann. Ein solcher Weg könnte eine normale Benutzerauthentifizierung ermöglichen und gleichzeitig einem Superuser Zugang gewähren.

## Anleitung

Die Authenifizieung kann über die Eigenschaft _req.auth_ manuell durchgeführt werden. Das kann zu Beispiel zu Testzwecke hilfreich sein. 

Um einen Benutzer manuell anzumelden, müssen wir einen Objekt vom Typ _Authenticatble_  der Methode _req.auth.login(_:) mitgegeben.

```swift
req.auth.login(User(name: "Vapor"))
```

Um den authentifizierten Benutzer zu erhalten, verwende `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Du kannst auch `req.auth.get(_:)` verwenden, wenn du nicht automatisch einen Fehler auslösen willst, wenn die Authentifizierung fehlschlägt.

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

In dieser Anleitung wird davon ausgegangen, dass du mit Fluent vertraut bist und deine App erfolgreich für die Verwendung einer Datenbank konfiguriert hast. Wenn du neu in Fluent bist, beginne mit der [Übersicht](../fluent/overview.md).

### Benutzer-Authentifizierung

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

Das Model. Das Feld _Email_ sollte einzigartig sein, um Redundanzen zu vermeiden. Somit würde die Migration für das obere Beispiel so aussehen.

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

Jetzt kannst du den Endpunkt "POST /users" erstellen.

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

#### Modell-Authentifizierbar

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

Diese Anfrage übergibt den Benutzernamen `test@vapor.codes` und das Passwort `secret42` über den Basic Authentication Header. Du solltest den zuvor erstellten Benutzer zurückbekommen.

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

Hier verwenden wir `[UInt8].random(count:)`, um einen zufälligen Token-Wert zu erzeugen. In diesem Beispiel werden 16 Bytes bzw. 128 Bits an Zufallsdaten verwendet. Du kannst diese Zahl nach Belieben anpassen. Die Zufallsdaten werden dann base-64 kodiert, damit sie leicht in HTTP-Headern übertragen werden können.

Da Sie nun Benutzer-Tokens generieren können, aktualisieren Sie die Route "POST /login", um ein Token zu erstellen und zurückzugeben.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Teste, ob diese Route funktioniert, indem du die gleiche Login-Anfrage wie oben verwendest. Du solltest jetzt beim Einloggen ein Token erhalten, das ungefähr so aussieht:

```
8gtg300Jwdhc/Ffw784EXA==
```

Behalte den Token, den du bekommst, denn wir werden ihn bald benutzen.

#### Model Token Authenticatable

Konforme `UserToken` mit `ModelTokenAuthenticatable`. Damit können Token dein `User`-Modell authentifizieren.

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

Die erste Protokollanforderung legt fest, in welchem Feld der eindeutige Wert des Tokens gespeichert wird. Dies ist der Wert, der im Bearer-Authentifizierungs-Header gesendet wird. Die zweite Anforderung legt die übergeordnete Beziehung zum Modell "User" fest. So sucht Fluent nach dem authentifizierten Benutzer. 

Die letzte Anforderung ist ein boolescher Wert "isValid". Wenn dieser Wert "False" ist, wird das Token aus der Datenbank gelöscht und der Benutzer wird nicht authentifiziert. Der Einfachheit halber werden wir die Token für die Ewigkeit machen, indem wir den Wert "wahr" fest einprogrammieren.

Da das Token nun `ModelTokenAuthenticatable` entspricht, kannst du einen Authentifikator zum Schutz der Routen erstellen.

Erstelle einen neuen Endpunkt "GET /me", um den aktuell authentifizierten Benutzer zu erhalten.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Ähnlich wie `User` hat `UserToken` jetzt eine statische Methode `authenticator()`, die einen Authentifikator erzeugen kann. Der Authentifikator versucht, einen passenden `UserToken` mit dem Wert aus dem Bearer-Authentifizierungs-Header zu finden. Wenn er eine Übereinstimmung findet, holt er den zugehörigen `User` und authentifiziert ihn. 

Teste, ob diese Route funktioniert, indem du die folgende HTTP-Anfrage sendest, wobei der Token der Wert ist, den du in der Anfrage "POST /login" gespeichert hast.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Du solltest den authentifizierten "User" zurückbekommen.

## Sitzung

Die [Session API](../advanced/sessions.md) von Vapor kann verwendet werden, um die Benutzerauthentifizierung zwischen Anfragen automatisch aufrechtzuerhalten. Dazu wird nach erfolgreicher Anmeldung eine eindeutige Kennung für den Benutzer in den Sitzungsdaten der Anfrage gespeichert. Bei nachfolgenden Anfragen wird die Kennung des Nutzers aus der Sitzung geholt und zur Authentifizierung des Nutzers verwendet, bevor dein Route Handler aufgerufen wird.

Sessions eignen sich hervorragend für Front-End-Webanwendungen, die in Vapor erstellt wurden und HTML direkt an Webbrowser ausgeben. Für APIs empfehlen wir eine zustandslose, Token-basierte Authentifizierung, um die Benutzerdaten zwischen den Anfragen aufrechtzuerhalten.

### Session-Authentifizierbar

Um die sitzungsbasierte Authentifizierung zu nutzen, brauchst du einen Typ, der `SessionAuthenticatable` entspricht. Für dieses Beispiel verwenden wir eine einfache Struktur.

```swift
import Vapor

struct User {
    var email: String
}
```

Um `SessionAuthenticatable` zu entsprechen, musst du eine `sessionID` angeben. Dies ist der Wert, der in den Sitzungsdaten gespeichert wird und den Nutzer eindeutig identifizieren muss.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Für unseren simplen Typ "Benutzer" verwenden wir die E-Mail-Adresse als eindeutigen Sitzungsbezeichner.

### Session-Authentifikator

Als Nächstes brauchen wir einen "SessionAuthenticator", um die Instanzen unseres Benutzers aus dem persistierten Sitzungsbezeichner aufzulösen.


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

Falls du `async`/`await` benutzt, kannst du den `AsyncSessionAuthenticator` verwenden:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Da alle Informationen, die wir für die Initialisierung unseres Beispiels "Benutzer" benötigen, in der Sitzungskennung enthalten sind, können wir den Benutzer synchron erstellen und anmelden. In einer realen Anwendung würdest du wahrscheinlich den Sitzungsbezeichner verwenden, um eine Datenbankabfrage oder eine API-Anfrage durchzuführen, um die restlichen Benutzerdaten vor der Authentifizierung zu erhalten. 

Als Nächstes erstellen wir einen einfachen Bearer Authenticator, der die erste Authentifizierung durchführt.

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

Dieser Authentifikator authentifiziert einen Benutzer mit der E-Mail `hello@vapor.codes`, wenn das Träger-Token `test` gesendet wird.

Zum Schluss fügen wir all diese Teile in deiner Anwendung zusammen.

```swift
// Erstelle eine geschützte Routengruppe, die eine Benutzeranmeldung erfordert.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Füge eine GET /me Route hinzu, um die E-Mail des Benutzers zu lesen.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

Die `SessionMiddleware` wird zuerst hinzugefügt, um die Sitzungsunterstützung für die Anwendung zu aktivieren. Weitere Informationen zur Konfiguration von Sitzungen findest du im Abschnitt [Session API](../advanced/sessions.md).

Als nächstes wird der `SessionAuthenticator` hinzugefügt. Dieser sorgt für die Authentifizierung des Nutzers, wenn eine Sitzung aktiv ist. 

Wenn die Authentifizierung noch nicht in der Sitzung gespeichert wurde, wird die Anfrage an den nächsten Authentifikator weitergeleitet. Der "UserBearerAuthenticator" prüft das Inhaber-Token und authentifiziert den Benutzer, wenn es "test" entspricht.

Schließlich stellt `User.guardMiddleware()` sicher, dass `User` von einer der vorherigen Middlewares authentifiziert wurde. Wenn der Benutzer nicht authentifiziert wurde, wird ein Fehler ausgelöst. 

Um diese Route zu testen, sende zunächst die folgende Anfrage:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Dies veranlasst `UserBearerAuthenticator`, den Benutzer zu authentifizieren. Nach der Authentifizierung speichert `UserSessionAuthenticator` die Kennung des Benutzers im Sitzungsspeicher und erzeugt ein Cookie. Verwende das Cookie aus der Antwort in einer zweiten Anfrage an die Route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Diesmal authentifiziert `UserSessionAuthenticator` den Benutzer und du solltest wieder die E-Mail des Benutzers sehen.

### Modell Session-Authentifizierbar

Fluent-Modelle können `SessionAuthenticator` generieren, indem sie mit `ModelSessionAuthenticatable` konform sind. Dabei wird der eindeutige Bezeichner des Modells als Sitzungsbezeichner verwendet und automatisch eine Datenbankabfrage durchgeführt, um das Modell aus der Sitzung wiederherzustellen.

```swift
import Fluent

final class User: Model { ... }

// Erlaube, dass dieses Modell in Sitzungen bestehen bleibt.
extension User: ModelSessionAuthenticatable { }
```

Du kannst `ModelSessionAuthenticatable` als leere Konformität zu jedem bestehenden Modell hinzufügen. Nach dem Hinzufügen steht eine neue statische Methode zur Verfügung, mit der du einen `SessionAuthenticator` für dieses Modell erstellen kannst.

```swift
User.sessionAuthenticator()
```

Damit wird die Standarddatenbank der Anwendung für die Auflösung des Benutzers verwendet. Um eine Datenbank anzugeben, übergibst du den Bezeichner.

```swift
User.sessionAuthenticator(.sqlite)
```

## Website-Authentifizierung

Websites sind ein Sonderfall für die Authentifizierung, denn die Verwendung eines Browsers schränkt die Möglichkeit ein, Anmeldeinformationen mit einem Browser zu verknüpfen. Das führt zu zwei verschiedenen Authentifizierungsszenarien:

* die Erstanmeldung über ein Formular
* nachfolgende Aufrufe, die mit einem Session-Cookie authentifiziert werden

Vapor und Fluent bieten verschiedene Hilfsmittel, um dies nahtlos zu ermöglichen.

### Cookie-Authentifizierung

Die Sitzungsauthentifizierung funktioniert wie oben beschrieben. Du musst die Sitzungs-Middleware und den Sitzungsauthentifikator auf alle Routen anwenden, auf die dein Nutzer zugreifen wird. Dazu gehören alle geschützten Routen, alle Routen, die zwar öffentlich sind, auf die du aber trotzdem zugreifen willst, wenn der Benutzer eingeloggt ist (um z. B. einen Konto-Button anzuzeigen) **und** Login-Routen.

Du kannst dies global in deiner App in **configure.swift** wie folgt aktivieren:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Diese Middlewares tun Folgendes:

* Die Sitzung-Middleware wandelt den übermittelten Sitzungs-Cookie in eine Sitzung um.
* Der Authentikator gleicht die erstelle Sitzung mit den aktiven Sitzung ab. Sollte das der Fall sein, authentifiziert es die Anfrage. Die Identität wird in der Sitzung abgelegt, sodass 

* Die Sitzung-Middleware nimmt das Session-Cookie aus der Anfrage und wandelt es in eine Session um.
* der Sitzungs Authenticator nimmt die Session und prüft, ob es einen authentifizierten Benutzer für diese Session gibt. Wenn ja, authentifiziert die Middleware die Anfrage. In der Antwort sieht der Session Authenticator, ob die Anfrage einen authentifizierten Benutzer hat und speichert ihn in der Session, damit er bei der nächsten Anfrage authentifiziert ist.

### Anwendungsendpunkte schützen

Geschütze Anwendungsendpunkte, zum Beispiel einer API, geben traditionell bei fehlgeschlagener Authentifizierung eine Serverantwort mit entsprechenden Status wie **401 Unautorisiert** zurück. Das ist jedoch für jemanden, der einen Browser benutzt, keine gute Benutzererfahrung, weswegen Vapor für jedes Objekt vom Typ _Authenticatable_ eine _RedirectMiddleware_ anbietet:


```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

Das "RedirectMiddleware"-Objekt unterstützt auch die Übergabe einer Closure, die bei der Erstellung den Redirect-Pfad als String zurückgibt, um ein erweitertes Url-Handling zu ermöglichen. Zum Beispiel kann der Pfad, von dem aus umgeleitet wurde, als Abfrageparameter an das Umleitungsziel übergeben werden, um den Status zu verwalten.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Dies funktioniert ähnlich wie die `GuardMiddleware`. Alle Anfragen an Routen, die bei `protectedRoutes` registriert sind und nicht authentifiziert sind, werden an den angegebenen Pfad weitergeleitet. So kannst du deine Nutzer auffordern, sich einzuloggen, anstatt nur eine **401 Unauthorized** zu liefern.

Achte darauf, einen Session Authenticator vor der `RedirectMiddleware` einzubinden, um sicherzustellen, dass der authentifizierte Benutzer geladen wird, bevor er die `RedirectMiddleware` durchläuft.

```swift
let protectedRoutes = app.grouped([User.SessionAuthenticator(), redirecteMiddleware])
```

### Formularanfrage

Für die Authentifizierung und spätere Sitzungen, die Anmeldung erfolgt meistens über ein Formular.

Um einen Benutzer und bestehende Sitzungen zu authentifizieren, muss sich zuerst ein Benutzer anmelden. Vapor stellt uns für die Anmeldungsabwicklung das Protokoll _ModelCredentialsAuthenticatable_ zur Verfügung, mit das wir unser Objekt _User_ versehen. 

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Dies ist identisch mit `ModelAuthenticatable` und wenn du bereits damit konform gehst, brauchst du nichts weiter zu tun. Als Nächstes wendest du die Middleware `ModelCredentialsAuthenticator` auf deine POST-Anfrage für das Anmeldeformular an:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Hier wird der Standard-Authentifikator für Anmeldedaten verwendet, um die Login-Route zu schützen. Du musst `Benutzername` und `Passwort` in der POST-Anfrage senden. Du kannst dein Formular wie folgt einrichten:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

Der `CredentialsAuthenticator` extrahiert den `Benutzernamen` und das `Passwort` aus dem Request Body, findet den Benutzer anhand des Benutzernamens und verifiziert das Passwort. Wenn das Passwort gültig ist, authentifiziert die Middleware die Anfrage. Der `SessionAuthenticator` authentifiziert dann die Sitzung für nachfolgende Anfragen.

## JWT

[JWT](jwt.md) bietet einen `JWTAuthenticator`, der zur Authentifizierung von JSON-Web-Token in eingehenden Anfragen verwendet werden kann. Wenn du dich mit JWT noch nicht auskennst, schau dir den [Überblick](jwt.md) an.

Erstelle zunächst einen Typ, der eine JWT-Nutzlast repräsentiert.

```swift
// Beispiel JWT-Payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Konstanten
    let expirationTime: TimeInterval = 60 * 15
    
    // Token Daten
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

Als Nächstes können wir eine Darstellung der Daten definieren, die in einer erfolgreichen Anmeldeantwort enthalten sind. Zunächst wird die Antwort nur eine Eigenschaft haben, nämlich einen String, der ein signiertes JWT darstellt.

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

Mit unserem Modell für das JWT-Token und die Antwort können wir eine passwortgeschützte Login-Route verwenden, die eine "ClientTokenReponse" zurückgibt und ein signiertes "SessionToken" enthält.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Wenn du keinen Authentifikator verwenden willst, kannst du auch etwas haben, das wie folgt aussieht.

```swift
app.post("login") { req -> ClientTokenReponse in
    // Überprüfe die angegebenen Anmeldeinformationen für den Benutzer
    // UserId für den angegebenen Benutzer abrufen
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Indem du die Payload an `Authenticatable` und `JWTPayload` anpasst, kannst du mit der Methode `authenticator()` einen Routen-Authentifikator erzeugen. Füge diesen zu einer Routengruppe hinzu, um den JWT automatisch abzurufen und zu verifizieren, bevor deine Route aufgerufen wird.

```swift
// Erstelle eine Routengruppe, die das SessionToken JWT benötigt.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Das Hinzufügen der optionalen [guard middleware](#guard-middleware) setzt voraus, dass die Autorisierung erfolgreich war.

Innerhalb der geschützten Routen kannst du mit `req.auth` auf die authentifizierten JWT-Nutzdaten zugreifen.

```swift
// Gibt eine ok-Antwort zurück, wenn das vom Benutzer bereitgestellte Token gültig ist.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```