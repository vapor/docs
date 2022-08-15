# Authenticatie

Authenticatie is het verifiëren van de identiteit van een gebruiker. Dit gebeurt door middel van de verificatie van inloggegevens zoals een gebruikersnaam en wachtwoord of een uniek token. Authenticatie (soms auth/c genoemd) is te onderscheiden van autorisatie (auth/z), waarbij wordt nagegaan of een eerder geauthenticeerde gebruiker toestemming heeft om bepaalde taken uit te voeren.

## Introductie

Vapor's Authenticatie API biedt ondersteuning voor het authenticeren van een gebruiker via de `Authorization` header, met gebruik van [Basic](https://tools.ietf.org/html/rfc7617) en [Bearer](https://tools.ietf.org/html/rfc6750). Het ondersteunt ook het authenticeren van een gebruiker via de data gedecodeerd uit de [Content](../basics/content.md) API.

Authenticatie wordt geïmplementeerd door een `Authenticator` aan te maken die de verificatielogica bevat. Een authenticator kan worden gebruikt om individuele route groepen of een hele app te beschermen. De volgende authenticator helpers worden met Vapor meegeleverd:

|Protocol|Beschrijving|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Basisauthenticator die in staat is om middleware te maken.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Authenticeert Basic autorisatie header.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Authenticeert Bearer autorisatie header.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Authenticeert een credentials payload van de request body.|

Als de authenticatie succesvol is, voegt de authenticator de geverifieerde gebruiker toe aan `req.auth`. Deze gebruiker kan dan worden benaderd met `req.auth.get(_:)` in routes die door de authenticator worden beschermd. Als de authenticatie mislukt, wordt de gebruiker niet toegevoegd aan `req.auth` en alle pogingen om toegang te krijgen tot de gebruiker zullen mislukken.

## Authenticatable

Om de Authenticatie API te gebruiken, heb je eerst een gebruikerstype nodig dat voldoet aan `Authenticatable`. Dit kan een `struct`, `class`, of zelfs een Fluent `Model` zijn. De volgende voorbeelden gaan uit van een eenvoudige `User` struct die één eigenschap heeft: `naam`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Elk voorbeeld hieronder zal een instantie van een authenticator gebruiken die we hebben gemaakt. In deze voorbeelden noemen we het `UserAuthenticator`.

### Route

Authenticators zijn middleware en kunnen worden gebruikt om routes te beveiligen.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` wordt gebruikt om de geauthenticeerde `User` op te halen. Als de authenticatie mislukt, zal deze methode een foutmelding geven en de route beschermen. 

### Guard Middleware

Je kunt ook `GuardMiddleware` in je route groep gebruiken om er zeker van te zijn dat een gebruiker geauthenticeerd is voordat hij je route handler bereikt.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Het vereisen van authenticatie wordt niet gedaan door de authenticator middleware om samenstelling van authenticators mogelijk te maken. Lees hieronder meer over [composition](#composition).

## Basic

Basis authenticatie stuurt een gebruikersnaam en wachtwoord in de `Authorization` header. De gebruikersnaam en het wachtwoord worden samengevoegd met een dubbele punt (bijv. `test:secret`), base-64 gecodeerd, en voorafgegaan door `"Basic"`. Het volgende voorbeeld request codeert de gebruikersnaam `test` met wachtwoord `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Basisauthenticatie wordt meestal eenmalig gebruikt om een gebruiker aan te melden en een token te genereren. Dit minimaliseert hoe vaak het gevoelige wachtwoord van de gebruiker moet worden verzonden. U moet nooit Basis-authenticatie verzenden over een platte tekst of ongeverifieerde TLS-verbinding.

Om Basic authenticatie in je app te implementeren, maak je een nieuwe authenticator die voldoet aan `BasicAuthenticator`. Hieronder staat een voorbeeld authenticator die hard gecodeerd is om het verzoek van hierboven te verifiëren.


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

Als je `async`/`await` gebruikt, kun je in plaats daarvan `AsyncBasicAuthenticator` gebruiken:

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

Dit protocol vereist dat je `authenticate(basic:for:)` implementeert, dat aangeroepen wordt als een inkomend verzoek de `Authorization: Basic ...` header bevat. Een `BasicAuthorization` struct met de gebruikersnaam en wachtwoord wordt doorgegeven aan de methode.

In deze test authenticator worden de gebruikersnaam en het wachtwoord getest aan de hand van hard gecodeerde waarden. In een echte authenticator, zou je kunnen controleren tegen een database of externe API. Dit is waarom de `authenticate` methode je toestaat om een future terug te sturen. 

!!! tip
    Wachtwoorden mogen nooit als plaintext in een database worden opgeslagen. Gebruik altijd hashes van wachtwoorden ter vergelijking.

Als de authenticatie parameters correct zijn, in dit geval overeenkomend met de hard gecodeerde waarden, wordt een `Gebruiker` genaamd Vapor ingelogd. Als de authenticatie parameters niet overeenkomen, wordt er geen gebruiker ingelogd, wat betekent dat de authenticatie is mislukt. 

Als je deze authenticator aan je app toevoegt, en de route die hierboven is gedefinieerd test, zou je de naam `"Vapor"` terug moeten zien bij een succesvolle login. Als de inloggegevens niet correct zijn, zou u een `401 Unauthorized` foutmelding moeten zien.

## Bearer

Bearer authenticatie stuurt een token in de `Authorization` header. Het token wordt voorafgegaan door `"Bearer"`. Het volgende voorbeeld request stuurt het token `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Bearer authenticatie wordt vaak gebruikt voor authenticatie van API eindpunten. De gebruiker vraagt typisch een Bearer token aan door credentials zoals een gebruikersnaam en wachtwoord naar een login endpoint te sturen. Deze token kan minuten of dagen geldig zijn, afhankelijk van de behoeften van de applicatie. 

Zolang het token geldig is, kan de gebruiker het gebruiken in plaats van zijn of haar inloggegevens om zich te authenticeren tegen de API. Als het token ongeldig wordt, kan een nieuw worden gegenereerd met het login eindpunt.

Om Bearer authenticatie in je app te implementeren, maak je een nieuwe authenticator die voldoet aan `BearerAuthenticator`. Hieronder staat een voorbeeld authenticator die hard gecodeerd is om het verzoek van hierboven te verifiëren.

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

Als je `async`/`await` gebruikt kun je in plaats daarvan `AsyncBearerAuthenticator` gebruiken:

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

Dit protocol vereist dat je `authenticate(bearer:for:)` implementeert, dat aangeroepen wordt als een inkomend verzoek de `Authorization: Bearer ...` header bevat. Een `BearerAuthorization` struct met het token wordt doorgegeven aan de methode.

In deze test-authenticator wordt het token getest tegen een hard gecodeerde waarde. In een echte authenticator, zou je het token kunnen verifiëren door het te vergelijken met een database of door gebruik te maken van cryptografische maatregelen, zoals wordt gedaan met JWT. Dit is waarom de `authenticate` methode je toestaat om een future terug te sturen. 

!!! tip
	Bij het implementeren van tokenverificatie is het belangrijk om rekening te houden met horizontale schaalbaarheid. Als uw applicatie veel gebruikers tegelijk moet verwerken, kan verificatie een potentieel knelpunt zijn. Bedenk hoe uw ontwerp zal schalen over meerdere instanties van uw applicatie die tegelijkertijd draaien.

Als de authenticatie parameters correct zijn, in dit geval overeenkomend met de hard gecodeerde waarde, wordt een `Gebruiker` genaamd Vapor ingelogd. Als de authenticatie parameters niet overeenkomen, wordt er geen gebruiker ingelogd, wat betekent dat de authenticatie is mislukt. 

Als je deze authenticator aan je app toevoegt, en de route die hierboven is gedefinieerd test, zou je de naam `"Vapor"` terug moeten zien bij een succesvolle login. Als de inloggegevens niet correct zijn, zou u een `401 Unauthorized` foutmelding moeten zien.

## Compositie

Meerdere authenticators kunnen worden samengesteld (met elkaar gecombineerd) om complexere eindpunt-authenticatie te creëren. Aangezien een authenticator middleware het verzoek niet zal weigeren als de authenticatie mislukt, kunnen meer dan één van deze middleware aan elkaar worden gekoppeld. Authenticators kunnen op twee belangrijke manieren worden samengesteld. 

### Compositie Methodes


De eerste methode om authenticatie samen te stellen is het ketenen van meer dan één authenticator voor hetzelfde gebruikerstype. Neem het volgende voorbeeld:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Doe iets met de gebruiker.
}
```

Dit voorbeeld gaat uit van twee authenticators `UserPasswordAuthenticator` en `UserTokenAuthenticator` die beide `User` authenticeren. Deze beide authenticators worden toegevoegd aan de route groep. Tenslotte wordt `GuardMiddleware` toegevoegd na de authenticators om te eisen dat `User` succesvol is geauthenticeerd. 

Deze samenstelling van authenticatoren resulteert in een route die zowel met een wachtwoord als met een token kan worden benaderd. Zo'n route zou een gebruiker kunnen toestaan in te loggen en een token te genereren, en dat token vervolgens te blijven gebruiken om nieuwe tokens te genereren.

### Gebruikers Samenstellen

De tweede methode van authenticatiecompositie is het ketenen van authenticatoren voor verschillende gebruikerstypen. Neem het volgende voorbeeld:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Doe iets.
}
```

Dit voorbeeld gaat uit van twee authenticators `AdminAuthenticator` en `UserAuthenticator` die respectievelijk `Admin` en `User` authenticeren. Beide authenticators zijn toegevoegd aan de route groep. In plaats van `GuardMiddleware` te gebruiken, wordt een controle in de route handler toegevoegd om te zien of `Admin` of `User` geauthenticeerd zijn. Zo niet, dan wordt er een foutmelding gegeven.

Deze samenstelling van authenticatoren resulteert in een route die toegankelijk is voor twee verschillende soorten gebruikers met potentieel verschillende authenticatiemethoden. Zo'n route zou normale gebruikersauthenticatie mogelijk kunnen maken en toch toegang kunnen verlenen aan een super-gebruiker.

## Manueel

Je kunt de authenticatie ook handmatig afhandelen met `req.auth`. Dit is vooral handig voor testen.

Om een gebruiker handmatig in te loggen, gebruik `req.auth.login(_:)`. Elke `Authenticeerbare` gebruiker kan aan deze methode worden doorgegeven.

```swift
req.auth.login(User(name: "Vapor"))
```

Om de geauthenticeerde gebruiker te krijgen, gebruik `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Je kunt ook `req.auth.get(_:)` gebruiken als je niet automatisch een foutmelding wilt krijgen als de authenticatie mislukt.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Om een gebruiker te de-authenticeren, geef je het gebruikerstype door aan `req.auth.logout(_:)`. 

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) definieert twee protocollen `ModelAuthenticatable` en `ModelTokenAuthenticatable` die kunnen worden toegevoegd aan uw bestaande modellen. Het conformeren van je modellen aan deze protocollen maakt het mogelijk om authenticators te maken voor het beschermen van endpoints. 

`ModelTokenAuthenticatable` authenticeert met een Bearer token. Dit is wat je gebruikt om de meeste van je endpoints te beveiligen. `ModelAuthenticatable` authenticeert met gebruikersnaam en wachtwoord en wordt door een enkel endpoint gebruikt voor het genereren van tokens. 

Deze handleiding gaat ervan uit dat u bekend bent met Fluent en dat u uw app succesvol heeft geconfigureerd om een database te gebruiken. Als u nieuw bent met Fluent, begin dan met het [overview](../fluent/overview.md).

### Gebruiker

Om te beginnen hebt u een model nodig dat de gebruiker voorstelt die zal worden geauthenticeerd. Voor deze handleiding gebruiken we het volgende model, maar u bent vrij om een bestaand model te gebruiken.

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

Het model moet in staat zijn om een gebruikersnaam, in dit geval een email, en een wachtwoord-hash op te slaan. We stellen ook in dat `email` een uniek veld moet zijn, om dubbele gebruikers te voorkomen. De bijbehorende migratie voor dit voorbeeldmodel is hier:

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

Vergeet niet om de migratie toe te voegen aan `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

Het eerste wat je nodig hebt is een endpoint om nieuwe gebruikers aan te maken. Laten we `POST /users` gebruiken. Maak een [Content](../basics/content.md) struct aan die de gegevens weergeeft die dit endpoint verwacht.

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

Als je wilt, kun je deze struct conformeren aan [Validatable](../basics/validation.md) om validatie-eisen toe te voegen.

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

Nu kun je het `POST /users` eindpunt maken. 

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

Dit eindpunt valideert het inkomende verzoek, decodeert de `User.Create` struct, en controleert of de wachtwoorden overeenkomen. Het gebruikt dan de gedecodeerde gegevens om een nieuwe `User` aan te maken en slaat deze op in de database. Het plaintext wachtwoord wordt gehashed met `Bcrypt` voordat het in de database wordt opgeslagen. 

Bouw en draai het project, zorg ervoor dat je eerst de database migreert, gebruik dan het volgende verzoek om een nieuwe gebruiker aan te maken. 

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

Nu dat je een gebruikersmodel hebt en een eindpunt om nieuwe gebruikers aan te maken, laten we het model conformeren aan `ModelAuthenticatable`. Dit maakt het mogelijk om het model te authenticeren met gebruikersnaam en wachtwoord.

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

Deze uitbreiding voegt `ModelAuthenticatable` conformiteit toe aan `User`. De eerste twee eigenschappen specificeren welke velden gebruikt moeten worden om respectievelijk de gebruikersnaam en de wachtwoord hash op te slaan. De `Notatie` creëert een sleutelpad naar de velden die Fluent kan gebruiken om ze te benaderen.

De laatste vereiste is een methode om plaintext wachtwoorden te verifiëren die in de Basic authenticatie header worden meegezonden. Aangezien we Bcrypt gebruiken om het wachtwoord te hashen tijdens het aanmelden, zullen we Bcrypt gebruiken om te verifiëren of het geleverde wachtwoord overeenkomt met de opgeslagen wachtwoord hash.

Nu dat de `User` voldoet aan `ModelAuthenticatable`, kunnen we een authenticator maken om de login route te beveiligen.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` voegt een statische methode `authenticator` toe voor het aanmaken van een authenticator.

Test of deze route werkt door het volgende verzoek te sturen.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Dit verzoek geeft de gebruikersnaam `test@vapor.codes` en wachtwoord `secret42` door via de Basic authenticatie header. Je zou de eerder aangemaakte gebruiker terug moeten zien.

Hoewel u theoretisch al uw eindpunten met Basic authenticatie zou kunnen beveiligen, is het aan te raden om in plaats daarvan een aparte token te gebruiken. Dit minimaliseert hoe vaak u het gevoelige wachtwoord van de gebruiker over het Internet moet sturen. Het maakt authenticatie ook veel sneller, omdat u alleen het hashen van wachtwoorden hoeft uit te voeren tijdens het inloggen.

### Gebruikers Token

Maak een nieuw model om gebruikers tokens te representeren.

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

Dit model moet een `value` veld hebben voor het opslaan van de unieke string van het token. Het moet ook een [parent-relatie](../fluent/overview.md#parent) hebben met het gebruikersmodel. U kunt naar eigen inzicht extra eigenschappen aan dit token toevoegen, zoals een vervaldatum. 

Maak vervolgens een migratie voor dit model.

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

Merk op dat deze migratie het `value` veld uniek maakt. Het creëert ook een vreemde sleutel verwijzing tussen het `user_id` veld en de gebruikers tabel. 

Vergeet niet om de migratie toe te voegen aan `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Voeg tenslotte een methode toe op `User` voor het genereren van een nieuw token. Deze methode zal worden gebruikt tijdens het inloggen.

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

Hier gebruiken we `[UInt8].random(count:)` om een willekeurige token waarde te genereren. In dit voorbeeld worden 16 bytes, oftewel 128 bits, aan willekeurige gegevens gebruikt. Je kunt dit aantal naar eigen inzicht aanpassen. De willekeurige gegevens worden dan base-64 gecodeerd, zodat ze gemakkelijk in HTTP headers kunnen worden verzonden.

Nu dat u gebruikers tokens kunt genereren, update de `POST /login` route om een token aan te maken en terug te sturen.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Test dat deze route werkt door hetzelfde login verzoek van hierboven te gebruiken. U zou nu een token moeten krijgen bij het inloggen dat er ongeveer zo uitziet:

```
8gtg300Jwdhc/Ffw784EXA==
```

Hou de token die je krijgt bij je, want die gebruiken we binnenkort.

#### Model Token Authenticatable

Conformeer `UserToken` aan `ModelTokenAuthenticatable`. Hierdoor kunnen tokens je `User` model authenticeren.

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

De eerste protocolvereiste specificeert in welk veld de unieke waarde van het token wordt opgeslagen. Dit is de waarde die zal worden verzonden in de Bearer authenticatie header. De tweede eis specificeert de parent-relatie naar het `User` model. Dit is hoe Fluent de geauthenticeerde gebruiker opzoekt. 

De laatste vereiste is een `isValid` boolean. Als deze `false` is, zal het token uit de database worden verwijderd en de gebruiker zal niet worden geauthenticeerd. Voor de eenvoud maken we de tokens eeuwig door dit hard te coderen naar `true`.

Nu dat het token voldoet aan `ModelTokenAuthenticatable`, kun je een authenticator maken om routes te beveiligen.

Maak een nieuw eindpunt `GET /me` voor het ophalen van de huidige geauthenticeerde gebruiker.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Vergelijkbaar met `User`, heeft `UserToken` nu een statische `authenticator()` methode die een authenticator kan genereren. De authenticator zal proberen een overeenkomende `UserToken` te vinden door gebruik te maken van de waarde die in de Bearer authenticatie header staat. Als het een overeenkomst vindt, zal het de bijbehorende `User` ophalen en deze authenticeren. 

Test dat deze route werkt door het volgende HTTP verzoek te sturen waarbij het token de waarde is die je hebt opgeslagen van het `POST /login` verzoek. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Je zou de geauthenticeerde `Gebruiker` terug moeten zien. 

## Sessie

Vapor's [Session API](../advanced/sessions.md) kan worden gebruikt om automatisch de authenticatie van de gebruiker tussen verzoeken te behouden. Dit werkt door een unieke identifier voor de gebruiker op te slaan in de request's sessie data na succesvolle login. Bij volgende verzoeken wordt de identificatiecode van de gebruiker opgehaald uit de sessie en gebruikt om de gebruiker te authenticeren voordat je je route handler aanroept.

Sessies zijn zeer geschikt voor front-end web applicaties gebouwd in Vapor die HTML direct aan web browsers serveren. Voor API's raden we aan om stateless, token-gebaseerde authenticatie te gebruiken om gebruikersgegevens tussen verzoeken te bewaren.

### Session Authenticatable

Om sessie-gebaseerde authenticatie te gebruiken, heb je een type nodig dat voldoet aan `SessionAuthenticatable`. Voor dit voorbeeld gebruiken we een eenvoudige struct.

```swift
import Vapor

struct User {
    var email: String
}
```

Om te voldoen aan `SessionAuthenticatable`, moet je een `sessionID` opgeven. Dit is de waarde die zal worden opgeslagen in de sessie gegevens en moet de gebruiker uniek identificeren. 

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Voor ons eenvoudige `User` type, gebruiken we het email adres als de unieke sessie identifier.

### Sessie Authenticator

Vervolgens hebben we een `SessionAuthenticator` nodig om instanties van onze gebruiker te herkennen op basis van de bewaarde sessie identifier.


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

Als je `async`/`await` gebruikt kun je de `AsyncSessionAuthenticator` gebruiken:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Omdat alle informatie die we nodig hebben om onze voorbeeld `Gebruiker` te initialiseren in de sessie identifier zit, kunnen we de gebruiker synchroon aanmaken en aanmelden. In een echte applicatie, zou je waarschijnlijk de sessie identifier gebruiken om een database lookup of API verzoek uit te voeren om de rest van de gebruikersgegevens op te halen voordat je authenticeert. 

Laten we nu een eenvoudige bearer authenticator maken om de initiële authenticatie uit te voeren.

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

Deze authenticator zal een gebruiker authenticeren met het emailadres `hello@vapor.codes` wanneer het token `test` wordt verstuurd.

Laten we tenslotte al deze stukken samenvoegen in uw toepassing.

```swift
// Creëer beveiligde route groep die auth van de gebruiker vereist.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Voeg GET /me route toe voor het lezen van de email van de gebruiker.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` wordt eerst toegevoegd om sessie ondersteuning op de applicatie mogelijk te maken. Meer informatie over het configureren van sessies kan worden gevonden in de [Session API](../advanced/sessions.md) sectie.

Vervolgens wordt de `SessionAuthenticator` toegevoegd. Deze zorgt voor de authenticatie van de gebruiker als er een sessie actief is. 

Als de authenticatie nog niet is opgeslagen in de sessie, zal het verzoek worden doorgestuurd naar de volgende authenticator. `UserBearerAuthenticator` zal de bearer token controleren en de gebruiker authenticeren als deze gelijk is aan `"test"`.

Tenslotte zal `User.guardMiddleware()` ervoor zorgen dat `User` geauthenticeerd is door een van de vorige middleware. Als de gebruiker niet is geauthenticeerd, zal er een foutmelding worden gegeven. 

Om deze route te testen, stuurt u eerst het volgende verzoek:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Dit zorgt ervoor dat `UserBearerAuthenticator` de gebruiker authentiseert. Eenmaal geauthenticeerd, zal `UserSessionAuthenticator` de identifier van de gebruiker bewaren in de sessie opslag en een cookie genereren. Gebruik de cookie uit het antwoord in een tweede verzoek aan de route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Deze keer zal `UserSessionAuthenticator` de gebruiker authenticeren en je zou weer de email van de gebruiker moeten zien.

### Model Session Authenticatable

Fluent modellen kunnen `SessionAuthenticator`s genereren door zich te conformeren aan `ModelSessionAuthenticatable`. Dit zal de unieke identifier van het model gebruiken als de sessie identifier en automatisch een database lookup uitvoeren om het model terug te zetten uit de sessie. 

```swift
import Fluent

final class User: Model { ... }

// Sta toe dat dit model wordt bewaard in sessies.
extension User: ModelSessionAuthenticatable { }
```

U kunt `ModelSessionAuthenticatable` toevoegen aan een bestaand model als een lege conformance. Eenmaal toegevoegd, zal een nieuwe statische methode beschikbaar zijn om een `SessionAuthenticator` voor dat model te maken. 

```swift
User.sessionAuthenticator()
```

Dit zal de standaarddatabase van de toepassing gebruiken om de gebruiker om te zetten. Om een database te specificeren, geef de identifier door.

```swift
User.sessionAuthenticator(.sqlite)
```

## Website Authenticatie

Websites vormen een speciaal geval voor authenticatie omdat het gebruik van een browser beperkingen oplegt aan de manier waarop je credentials aan een browser kunt koppelen. Dit leidt tot twee verschillende authenticatiescenario's:

* de eerste aanmelding via een formulier
* volgende oproepen geauthentiseerd met een sessie cookie

Vapor and Fluent biedt verschillende hulpmiddelen om dit vlekkeloos te laten verlopen.

### Sessie Authenticatie

Sessie authenticatie werkt zoals hierboven beschreven. U moet de sessie middleware en sessie authenticator toepassen op alle routes die uw gebruiker zal bezoeken. Dit omvat alle beveiligde routes, alle routes die publiek zijn maar waar je nog steeds toegang wil tot de gebruiker als hij ingelogd is (om een account knop te tonen bijvoorbeeld) **en** login routes.

U kunt dit globaal inschakelen in uw app in **configure.swift** zoals dit:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Deze middlewares doen het volgende:

* de sessies middleware neemt de sessie cookie uit het verzoek en converteert het in een sessie
* de sessie-authenticator neemt de sessie en kijkt of er een geauthenticeerde gebruiker voor die sessie is. Zo ja, dan authenticeert de middleware het verzoek. In het antwoord kijkt de sessie-authenticator of het verzoek een geauthenticeerde gebruiker heeft en slaat die op in de sessie, zodat hij bij het volgende verzoek geauthenticeerd is.

### Routes Beschermen

Bij het beveiligen van routes voor een API, retourneer je traditioneel een HTTP antwoord met een status code zoals **401 Unauthorized** als het verzoek niet is geauthenticeerd. Dit is echter geen goede gebruikerservaring voor iemand die een browser gebruikt. Vapor biedt een `RedirectMiddleware` voor elk `Authenticatable` type om te gebruiken in dit scenario:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

Het `RedirectMiddleware` object ondersteunt ook het doorgeven van een closure die het redirect pad als een `String` retourneert tijdens het aanmaken voor geavanceerde url afhandeling. Bijvoorbeeld, het opnemen van het pad waar vandaan omgeleid wordt als query parameter naar het redirect doel voor state management.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Dit werkt vergelijkbaar met de `GuardMiddleware`. Alle verzoeken naar routes geregistreerd bij `protectedRoutes` die niet geauthenticeerd zijn, worden doorgestuurd naar het opgegeven pad. Hiermee kunt u uw gebruikers vertellen dat ze moeten inloggen, in plaats van alleen een **401 Unauthorized** te geven.

Zorg ervoor dat je een Session Authenticator toevoegt voor de `RedirectMiddleware` om er zeker van te zijn dat de geauthenticeerde gebruiker geladen is voordat hij door de `RedirectMiddleware` gaat.

```swift
let protectedRoutes = app.grouped([User.SessionAuthenticator(), redirecteMiddleware])
```

### Formulier Aanmelden

Om een gebruiker te authenticeren en toekomstige verzoeken met een sessie te doen, moet je een gebruiker aanmelden. Vapor biedt een `ModelCredentialsAuthenticatable` protocol om aan te voldoen. Dit handelt het inloggen via een formulier af. Conformeer eerst je `User` aan dit protocol:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Dit is identiek aan `ModelAuthenticatable` en als je daar al aan voldoet dan hoef je verder niets te doen. Pas vervolgens deze `ModelCredentialsAuthenticator` middleware toe op je inlogformulier POST verzoek:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Dit gebruikt de standaard credentials authenticator om de login route te beveiligen. Je moet `username` en `password` meesturen in het POST verzoek. Je kunt je formulier als volgt instellen:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

De `CredentialsAuthenticator` haalt de `username` en `password` uit de request body, vindt de gebruiker uit de gebruikersnaam en verifieert het wachtwoord. Als het wachtwoord geldig is, authenticeert de middleware het verzoek. De `SessionAuthenticator` authenticeert vervolgens de sessie voor volgende verzoeken.

## JWT

[JWT](jwt.md) voorziet in een `JWTAuthenticator` die gebruikt kan worden om JSON Web Tokens te authenticeren in binnenkomende requests. Als JWT nieuw voor je is, bekijk dan het [overzicht](jwt.md).

Maak eerst een type dat een JWT payload voorstelt.

```swift
// Voorbeeld JWT payload.
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

Vervolgens kunnen we een representatie definiëren van de gegevens in een succesvol login antwoord. Voorlopig zal het antwoord slechts één eigenschap hebben, namelijk een string die een ondertekende JWT voorstelt.

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

Met behulp van ons model voor de JWT token en respons, kunnen we een wachtwoord beveiligde login route gebruiken die een `ClientTokenReponse` retourneert en een ondertekende `SessionToken` bevat.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Als alternatief, als u geen authenticator wilt gebruiken, kunt u iets hebben dat er als volgt uitziet.
```swift
app.post("login") { req -> ClientTokenReponse in
    // Valideer verstrekte inloggegevens voor gebruiker
    // Verkrijg gebruikersId voor opgegeven gebruiker
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Door de payload te conformeren aan `Authenticatable` en `JWTPayload`, kun je een route authenticator genereren met de `authenticator()` methode. Voeg deze toe aan een route groep om automatisch de JWT op te halen en te verifiëren voordat je route wordt aangeroepen. 

```swift
// Maak een route groep aan die de SessionToken JWT nodig heeft.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Het toevoegen van de optionele [guard middleware](#guard-middleware) zal vereisen dat de authorisatie geslaagd is.

Binnen de beschermde routes, kunt u de geauthenticeerde JWT payload benaderen met `req.auth`. 

```swift
// Antwoord ok terug als het door de gebruiker verstrekte token geldig is.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
