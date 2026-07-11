# Authentification

L'authentification est l'acte de vérifier l'identité d'un utilisateur. Cela se fait par la vérification d'identifiants comme un nom d'utilisateur et un mot de passe, ou un jeton unique. L'authentification (parfois appelée auth/c) est distincte de l'autorisation (auth/z), qui est l'acte de vérifier les permissions d'un utilisateur déjà authentifié pour effectuer certaines tâches.

## Introduction

L'API Authentication de Vapor fournit un support pour authentifier un utilisateur via l'en-tête `Authorization`, en utilisant [Basic](https://tools.ietf.org/html/rfc7617) et [Bearer](https://tools.ietf.org/html/rfc6750). Elle prend également en charge l'authentification d'un utilisateur via les données décodées depuis l'API [Content](../basics/content.md).

L'authentification est mise en œuvre en créant un `Authenticator` qui contient la logique de vérification. Un authentificateur peut être utilisé pour protéger des groupes de routes individuels ou une application entière. Les authentificateurs suivants sont fournis avec Vapor :

|Protocole|Description|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Authentificateur de base capable de créer un middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Authentifie l'en-tête d'autorisation Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Authentifie l'en-tête d'autorisation Bearer.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Authentifie une charge utile d'identifiants provenant du corps de la requête.|

Si l'authentification réussit, l'authentificateur ajoute l'utilisateur vérifié à `req.auth`. Cet utilisateur peut ensuite être accédé en utilisant `req.auth.get(_:)` dans les routes protégées par l'authentificateur. Si l'authentification échoue, l'utilisateur n'est pas ajouté à `req.auth` et toute tentative d'y accéder échouera.

## Authenticatable

Pour utiliser l'API Authentication, vous avez d'abord besoin d'un type utilisateur qui se conforme à `Authenticatable`. Cela peut être une `struct`, une `class`, ou même un `Model` Fluent. Les exemples suivants supposent cette simple struct `User` qui possède une propriété : `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Chaque exemple ci-dessous utilisera une instance d'un authentificateur que nous avons créé. Dans ces exemples, nous l'avons appelé `UserAuthenticator`.

### Route

Les authentificateurs sont des middlewares et peuvent être utilisés pour protéger des routes.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` est utilisé pour récupérer l'`User` authentifié. Si l'authentification a échoué, cette méthode lèvera une erreur, protégeant ainsi la route.

### Guard Middleware

Vous pouvez également utiliser `GuardMiddleware` dans votre groupe de routes pour vous assurer qu'un utilisateur a été authentifié avant d'atteindre votre gestionnaire de route.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Exiger l'authentification n'est pas fait par le middleware authentificateur afin de permettre la composition d'authentificateurs. Lisez-en davantage sur la [composition](#composition) ci-dessous.

## Basic

L'authentification Basic envoie un nom d'utilisateur et un mot de passe dans l'en-tête `Authorization`. Le nom d'utilisateur et le mot de passe sont concaténés avec deux-points (par ex. `test:secret`), encodés en base 64, et préfixés avec `"Basic "`. L'exemple de requête suivant encode le nom d'utilisateur `test` avec le mot de passe `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

L'authentification Basic est généralement utilisée une seule fois pour connecter un utilisateur et générer un jeton. Cela minimise la fréquence à laquelle le mot de passe sensible de l'utilisateur doit être envoyé. Vous ne devriez jamais envoyer une autorisation Basic sur une connexion en clair ou une connexion TLS non vérifiée.

Pour implémenter l'authentification Basic dans votre application, créez un nouvel authentificateur se conformant à `BasicAuthenticator`. Voici un exemple d'authentificateur codé en dur pour vérifier la requête ci-dessus.


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

Si vous utilisez `async`/`await`, vous pouvez utiliser `AsyncBasicAuthenticator` à la place :

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

Ce protocole vous oblige à implémenter `authenticate(basic:for:)`, qui sera appelée lorsqu'une requête entrante contient l'en-tête `Authorization: Basic ...`. Une struct `BasicAuthorization` contenant le nom d'utilisateur et le mot de passe est passée à la méthode.

Dans cet authentificateur de test, le nom d'utilisateur et le mot de passe sont testés par rapport à des valeurs codées en dur. Dans un authentificateur réel, vous pourriez vérifier par rapport à une base de données ou une API externe. C'est pourquoi la méthode `authenticate` vous permet de retourner un futur.

!!! tip
    Les mots de passe ne devraient jamais être stockés en clair dans une base de données. Utilisez toujours des hachages de mot de passe pour la comparaison.

Si les paramètres d'authentification sont corrects, dans ce cas correspondant aux valeurs codées en dur, un `User` nommé Vapor est connecté. Si les paramètres d'authentification ne correspondent pas, aucun utilisateur n'est connecté, ce qui signifie que l'authentification a échoué.

Si vous ajoutez cet authentificateur à votre application et testez la route définie ci-dessus, vous devriez voir le nom `"Vapor"` retourné pour une connexion réussie. Si les identifiants ne sont pas corrects, vous devriez voir une erreur `401 Unauthorized`.

## Bearer

L'authentification Bearer envoie un jeton dans l'en-tête `Authorization`. Le jeton est préfixé avec `"Bearer "`. L'exemple de requête suivant envoie le jeton `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

L'authentification Bearer est couramment utilisée pour l'authentification des points d'accès (endpoints) d'API. L'utilisateur demande généralement un jeton Bearer en envoyant des identifiants comme un nom d'utilisateur et un mot de passe à un point d'accès de connexion. Ce jeton peut durer des minutes ou des jours selon les besoins de l'application.

Tant que le jeton est valide, l'utilisateur peut l'utiliser à la place de ses identifiants pour s'authentifier auprès de l'API. Si le jeton devient invalide, un nouveau peut être généré en utilisant le point d'accès de connexion.

Pour implémenter l'authentification Bearer dans votre application, créez un nouvel authentificateur se conformant à `BearerAuthenticator`. Voici un exemple d'authentificateur codé en dur pour vérifier la requête ci-dessus.

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

Si vous utilisez `async`/`await`, vous pouvez utiliser `AsyncBearerAuthenticator` à la place :

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

Ce protocole vous oblige à implémenter `authenticate(bearer:for:)`, qui sera appelée lorsqu'une requête entrante contient l'en-tête `Authorization: Bearer ...`. Une struct `BearerAuthorization` contenant le jeton est passée à la méthode.

Dans cet authentificateur de test, le jeton est testé par rapport à une valeur codée en dur. Dans un authentificateur réel, vous pourriez vérifier le jeton en le comparant à une base de données ou en utilisant des mesures cryptographiques, comme c'est le cas avec JWT. C'est pourquoi la méthode `authenticate` vous permet de retourner un futur.

!!! tip
    Lors de l'implémentation de la vérification de jeton, il est important de prendre en compte la scalabilité horizontale. Si votre application doit gérer de nombreux utilisateurs simultanément, l'authentification peut représenter un goulot d'étranglement potentiel. Réfléchissez à la façon dont votre conception s'adaptera à plusieurs instances de votre application s'exécutant en même temps.

Si les paramètres d'authentification sont corrects, dans ce cas correspondant à la valeur codée en dur, un `User` nommé Vapor est connecté. Si les paramètres d'authentification ne correspondent pas, aucun utilisateur n'est connecté, ce qui signifie que l'authentification a échoué.

Si vous ajoutez cet authentificateur à votre application et testez la route définie ci-dessus, vous devriez voir le nom `"Vapor"` retourné pour une connexion réussie. Si les identifiants ne sont pas corrects, vous devriez voir une erreur `401 Unauthorized`.

## Composition

Plusieurs authentificateurs peuvent être composés (combinés ensemble) pour créer une authentification de point d'accès plus complexe. Étant donné qu'un middleware authentificateur ne rejettera pas la requête si l'authentification échoue, plusieurs de ces middlewares peuvent être enchaînés ensemble. Les authentificateurs peuvent être composés de deux façons principales.

### Composer des méthodes


La première méthode de composition d'authentification consiste à enchaîner plusieurs authentificateurs pour le même type d'utilisateur. Prenez l'exemple suivant :

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Faire quelque chose avec user.
}
```

Cet exemple suppose deux authentificateurs, `UserPasswordAuthenticator` et `UserTokenAuthenticator`, qui authentifient tous deux `User`. Ces deux authentificateurs sont ajoutés au groupe de routes. Enfin, `GuardMiddleware` est ajouté après les authentificateurs pour exiger que `User` ait été authentifié avec succès.

Cette composition d'authentificateurs résulte en une route accessible soit par mot de passe soit par jeton. Une telle route pourrait permettre à un utilisateur de se connecter et de générer un jeton, puis de continuer à utiliser ce jeton pour générer de nouveaux jetons.

### Composer des utilisateurs

La deuxième méthode de composition d'authentification consiste à enchaîner des authentificateurs pour différents types d'utilisateurs. Prenez l'exemple suivant :

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Faire quelque chose.
}
```

Cet exemple suppose deux authentificateurs, `AdminAuthenticator` et `UserAuthenticator`, qui authentifient respectivement `Admin` et `User`. Ces deux authentificateurs sont ajoutés au groupe de routes. Au lieu d'utiliser `GuardMiddleware`, une vérification est ajoutée dans le gestionnaire de route pour voir si `Admin` ou `User` a été authentifié. Si non, une erreur est levée.

Cette composition d'authentificateurs résulte en une route accessible par deux types d'utilisateurs différents avec potentiellement des méthodes d'authentification différentes. Une telle route pourrait permettre l'authentification normale des utilisateurs tout en donnant accès à un super-utilisateur.

## Manuel

Vous pouvez également gérer l'authentification manuellement en utilisant `req.auth`. Ceci est particulièrement utile pour les tests.

Pour connecter manuellement un utilisateur, utilisez `req.auth.login(_:)`. N'importe quel utilisateur `Authenticatable` peut être passé à cette méthode.

```swift
req.auth.login(User(name: "Vapor"))
```

Pour obtenir l'utilisateur authentifié, utilisez `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Vous pouvez également utiliser `req.auth.get(_:)` si vous ne souhaitez pas lever automatiquement une erreur lorsque l'authentification échoue.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Pour déconnecter un utilisateur, passez le type d'utilisateur à `req.auth.logout(_:)`.

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) définit deux protocoles, `ModelAuthenticatable` et `ModelTokenAuthenticatable`, qui peuvent être ajoutés à vos modèles existants. Conformer vos modèles à ces protocoles permet la création d'authentificateurs pour protéger les points d'accès.

`ModelTokenAuthenticatable` authentifie avec un jeton Bearer. C'est ce que vous utiliserez pour protéger la plupart de vos points d'accès. `ModelAuthenticatable` authentifie avec un nom d'utilisateur et un mot de passe et est utilisé par un unique point d'accès pour générer des jetons.

Ce guide suppose que vous êtes familier avec Fluent et que vous avez configuré avec succès votre application pour utiliser une base de données. Si vous découvrez Fluent, commencez par l'[aperçu](../fluent/overview.md).

### User

Pour commencer, vous aurez besoin d'un modèle représentant l'utilisateur qui sera authentifié. Pour ce guide, nous utiliserons le modèle suivant, mais vous êtes libre d'utiliser un modèle existant.

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

Le modèle doit pouvoir stocker un nom d'utilisateur, dans ce cas un email, et un hachage de mot de passe. Nous définissons également `email` comme un champ unique, afin d'éviter les utilisateurs en double. La migration correspondante pour ce modèle d'exemple est la suivante :

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

N'oubliez pas d'ajouter la migration à `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

!!! tip
     Étant donné que les adresses email ne sont pas sensibles à la casse, vous pourriez vouloir ajouter un [`Middleware`](../fluent/model.md#cycle-de-vie) qui convertit l'adresse email en minuscules avant de l'enregistrer dans la base de données. Sachez, cependant, que `ModelAuthenticatable` utilise une comparaison sensible à la casse, donc si vous faites cela, vous voudrez vous assurer que la saisie de l'utilisateur est entièrement en minuscules, soit avec une conversion de casse côté client, soit avec un authentificateur personnalisé.

La première chose dont vous aurez besoin est un point d'accès pour créer de nouveaux utilisateurs. Utilisons `POST /users`. Créez une struct [Content](../basics/content.md) représentant les données attendues par ce point d'accès.

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

Si vous le souhaitez, vous pouvez conformer cette struct à [Validatable](../basics/validation.md) pour ajouter des exigences de validation.

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

Vous pouvez maintenant créer le point d'accès `POST /users`.

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

Ce point d'accès valide la requête entrante, décode la struct `User.Create`, et vérifie que les mots de passe correspondent. Il utilise ensuite les données décodées pour créer un nouvel `User` et l'enregistre dans la base de données. Le mot de passe en clair est haché en utilisant `Bcrypt` avant d'être enregistré dans la base de données.

Compilez et lancez le projet, en veillant à migrer la base de données au préalable, puis utilisez la requête suivante pour créer un nouvel utilisateur.

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

Maintenant que vous avez un modèle utilisateur et un point d'accès pour créer de nouveaux utilisateurs, conformons le modèle à `ModelAuthenticatable`. Cela permettra au modèle d'être authentifié en utilisant un nom d'utilisateur et un mot de passe.

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

Cette extension ajoute la conformité `ModelAuthenticatable` à `User`. Les deux premières propriétés spécifient quels champs doivent être utilisés pour stocker respectivement le nom d'utilisateur et le hachage du mot de passe. La notation `\` crée un key path vers les champs que Fluent peut utiliser pour y accéder.

La dernière exigence est une méthode pour vérifier les mots de passe en clair envoyés dans l'en-tête d'authentification Basic. Puisque nous utilisons Bcrypt pour hacher le mot de passe lors de l'inscription, nous utiliserons Bcrypt pour vérifier que le mot de passe fourni correspond au hachage de mot de passe stocké.

Maintenant que `User` se conforme à `ModelAuthenticatable`, nous pouvons créer un authentificateur pour protéger la route de connexion.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` ajoute une méthode statique `authenticator` pour créer un authentificateur.

Testez que cette route fonctionne en envoyant la requête suivante.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Cette requête transmet le nom d'utilisateur `test@vapor.codes` et le mot de passe `secret42` via l'en-tête d'authentification Basic. Vous devriez voir l'utilisateur précédemment créé retourné.

Bien que vous puissiez théoriquement utiliser l'authentification Basic pour protéger tous vos points d'accès, il est recommandé d'utiliser à la place un jeton séparé. Cela minimise la fréquence à laquelle vous devez envoyer le mot de passe sensible de l'utilisateur sur Internet. Cela rend également l'authentification beaucoup plus rapide puisque vous n'avez besoin d'effectuer le hachage de mot de passe que lors de la connexion.

### User Token

Créez un nouveau modèle représentant les jetons utilisateur.

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

Ce modèle doit avoir un champ `value` pour stocker la chaîne unique du jeton. Il doit également avoir une [relation parent](../fluent/overview.md#parent) vers le modèle utilisateur. Vous pouvez ajouter des propriétés supplémentaires à ce jeton comme bon vous semble, comme une date d'expiration.

Ensuite, créez une migration pour ce modèle.

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

Remarquez que cette migration rend le champ `value` unique. Elle crée également une référence de clé étrangère entre le champ `user_id` et la table users.

N'oubliez pas d'ajouter la migration à `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Enfin, ajoutez une méthode sur `User` pour générer un nouveau jeton. Cette méthode sera utilisée lors de la connexion.

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

Ici, nous utilisons `[UInt8].random(count:)` pour générer une valeur de jeton aléatoire. Pour cet exemple, 16 octets, soit 128 bits, de données aléatoires sont utilisées. Vous pouvez ajuster ce nombre comme bon vous semble. Les données aléatoires sont ensuite encodées en base 64 pour faciliter leur transmission dans les en-têtes HTTP.

Maintenant que vous pouvez générer des jetons utilisateur, mettez à jour la route `POST /login` pour créer et retourner un jeton.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Testez que cette route fonctionne en utilisant la même requête de connexion que ci-dessus. Vous devriez maintenant obtenir un jeton lors de la connexion qui ressemble à quelque chose comme :

```
8gtg300Jwdhc/Ffw784EXA==
```

Conservez le jeton que vous obtenez car nous l'utiliserons bientôt.

#### Model Token Authenticatable

Conformez `UserToken` à `ModelTokenAuthenticatable`. Cela permettra aux jetons d'authentifier votre modèle `User`.

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

La première exigence du protocole spécifie quel champ stocke la valeur unique du jeton. C'est la valeur qui sera envoyée dans l'en-tête d'authentification Bearer. La deuxième exigence spécifie la relation parent vers le modèle `User`. C'est ainsi que Fluent recherchera l'utilisateur authentifié.

La dernière exigence est un booléen `isValid`. Si celui-ci est `false`, le jeton sera supprimé de la base de données et l'utilisateur ne sera pas authentifié. Par souci de simplicité, nous rendrons les jetons éternels en codant cette valeur en dur à `true`.

Maintenant que le jeton se conforme à `ModelTokenAuthenticatable`, vous pouvez créer un authentificateur pour protéger des routes.

Créez un nouveau point d'accès `GET /me` pour obtenir l'utilisateur actuellement authentifié.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Comme `User`, `UserToken` possède maintenant une méthode statique `authenticator()` qui peut générer un authentificateur. L'authentificateur tentera de trouver un `UserToken` correspondant en utilisant la valeur fournie dans l'en-tête d'authentification Bearer. S'il trouve une correspondance, il récupérera l'`User` associé et l'authentifiera.

Testez que cette route fonctionne en envoyant la requête HTTP suivante où le jeton est la valeur que vous avez enregistrée depuis la requête `POST /login`.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Vous devriez voir l'`User` authentifié retourné.

## Session

L'[API Session](../advanced/sessions.md) de Vapor peut être utilisée pour persister automatiquement l'authentification de l'utilisateur entre les requêtes. Cela fonctionne en stockant un identifiant unique pour l'utilisateur dans les données de session de la requête après une connexion réussie. Lors des requêtes suivantes, l'identifiant de l'utilisateur est récupéré depuis la session et utilisé pour authentifier l'utilisateur avant d'appeler votre gestionnaire de route.

Les sessions sont idéales pour les applications web front-end construites avec Vapor qui servent directement du HTML aux navigateurs web. Pour les API, nous recommandons d'utiliser une authentification par jeton sans état pour persister les données utilisateur entre les requêtes.

### Session Authenticatable

Pour utiliser l'authentification basée sur les sessions, vous aurez besoin d'un type conforme à `SessionAuthenticatable`. Pour cet exemple, nous utiliserons une simple struct.

```swift
import Vapor

struct User {
    var email: String
}
```

Pour vous conformer à `SessionAuthenticatable`, vous devrez spécifier un `sessionID`. C'est la valeur qui sera stockée dans les données de session et doit identifier de manière unique l'utilisateur.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Pour notre simple type `User`, nous utiliserons l'adresse email comme identifiant de session unique.

### Session Authenticator

Ensuite, nous aurons besoin d'un `SessionAuthenticator` pour gérer la résolution des instances de notre User à partir de l'identifiant de session persisté.


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

Si vous utilisez `async`/`await`, vous pouvez utiliser l'`AsyncSessionAuthenticator` :

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Puisque toutes les informations dont nous avons besoin pour initialiser notre `User` d'exemple sont contenues dans l'identifiant de session, nous pouvons créer et connecter l'utilisateur de manière synchrone. Dans une application réelle, vous utiliseriez probablement l'identifiant de session pour effectuer une recherche en base de données ou une requête API afin de récupérer le reste des données de l'utilisateur avant de l'authentifier.

Ensuite, créons un simple authentificateur bearer pour effectuer l'authentification initiale.

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

Cet authentificateur authentifiera un utilisateur avec l'email `hello@vapor.codes` lorsque le jeton bearer `test` est envoyé.

Enfin, combinons toutes ces pièces ensemble dans votre application.

```swift
// Créer un groupe de routes protégées qui nécessite l'authentification de l'utilisateur.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Ajouter la route GET /me pour lire l'email de l'utilisateur.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` est ajouté en premier pour activer la prise en charge des sessions sur l'application. Plus d'informations sur la configuration des sessions se trouvent dans la section [API Session](../advanced/sessions.md).

Ensuite, le `SessionAuthenticator` est ajouté. Il gère l'authentification de l'utilisateur si une session est active.

Si l'authentification n'a pas encore été persistée dans la session, la requête sera transmise à l'authentificateur suivant. `UserBearerAuthenticator` vérifiera le jeton bearer et authentifiera l'utilisateur s'il est égal à `"test"`.

Enfin, `User.guardMiddleware()` s'assurera que `User` a été authentifié par l'un des middlewares précédents. Si l'utilisateur n'a pas été authentifié, une erreur sera levée.

Pour tester cette route, envoyez d'abord la requête suivante :

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Cela amènera `UserBearerAuthenticator` à authentifier l'utilisateur. Une fois authentifié, `UserSessionAuthenticator` persistera l'identifiant de l'utilisateur dans le stockage de session et générera un cookie. Utilisez le cookie de la réponse dans une seconde requête vers la route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Cette fois, `UserSessionAuthenticator` authentifiera l'utilisateur et vous devriez à nouveau voir l'email de l'utilisateur retourné.

### Model Session Authenticatable

Les modèles Fluent peuvent générer des `SessionAuthenticator`s en se conformant à `ModelSessionAuthenticatable`. Cela utilisera l'identifiant unique du modèle comme identifiant de session et effectuera automatiquement une recherche en base de données pour restaurer le modèle à partir de la session.

```swift
import Fluent

final class User: Model { ... }

// Permettre à ce modèle d'être persisté dans les sessions.
extension User: ModelSessionAuthenticatable { }
```

Vous pouvez ajouter `ModelSessionAuthenticatable` à n'importe quel modèle existant sous forme de conformité vide. Une fois ajoutée, une nouvelle méthode statique sera disponible pour créer un `SessionAuthenticator` pour ce modèle.

```swift
User.sessionAuthenticator()
```

Cela utilisera la base de données par défaut de l'application pour résoudre l'utilisateur. Pour spécifier une base de données, passez l'identifiant.

```swift
User.sessionAuthenticator(.sqlite)
```

## Authentification pour sites web

Les sites web constituent un cas particulier pour l'authentification, car l'utilisation d'un navigateur limite la façon dont vous pouvez attacher des identifiants à un navigateur. Cela mène à deux scénarios d'authentification différents :

* la connexion initiale via un formulaire
* les appels suivants authentifiés avec un cookie de session

Vapor et Fluent fournissent plusieurs aides pour rendre cela transparent.

### Authentification par session

L'authentification par session fonctionne comme décrit ci-dessus. Vous devez appliquer le middleware de session et l'authentificateur de session à toutes les routes que votre utilisateur accédera. Cela inclut toutes les routes protégées, toutes les routes qui sont publiques mais pour lesquelles vous voudriez toujours accéder à l'utilisateur s'il est connecté (pour afficher un bouton de compte par exemple) **et** les routes de connexion.

Vous pouvez activer cela globalement dans votre application dans **configure.swift** comme ceci :

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Ces middlewares font ce qui suit :

* le middleware de sessions prend le cookie de session fourni dans la requête et le convertit en une session
* l'authentificateur de session prend la session et vérifie s'il existe un utilisateur authentifié pour cette session. Si oui, le middleware authentifie la requête. Dans la réponse, l'authentificateur de session vérifie si la requête a un utilisateur authentifié et l'enregistre dans la session afin qu'il soit authentifié lors de la prochaine requête.

!!! note
    Le cookie de session n'est pas défini sur `secure` et `httpOnly` par défaut. Consultez l'[API Session](../advanced/sessions.md#configuration) de Vapor pour plus d'informations sur la façon de configurer les cookies.

### Protéger des routes

Lors de la protection des routes pour une API, vous retournez traditionnellement une réponse HTTP avec un code de statut tel que **401 Unauthorized** si la requête n'est pas authentifiée. Cependant, ce n'est pas une très bonne expérience utilisateur pour quelqu'un utilisant un navigateur. Vapor fournit un `RedirectMiddleware` pour tout type `Authenticatable` à utiliser dans ce scénario :

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

L'objet `RedirectMiddleware` prend également en charge le passage d'une closure qui retourne le chemin de redirection sous forme de `String` lors de la création, pour une gestion avancée des URL. Par exemple, inclure le chemin d'où provient la redirection comme paramètre de requête dans la cible de redirection pour la gestion d'état.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Cela fonctionne de manière similaire à `GuardMiddleware`. Toute requête vers des routes enregistrées dans `protectedRoutes` qui ne sont pas authentifiées sera redirigée vers le chemin fourni. Cela vous permet de dire à vos utilisateurs de se connecter, plutôt que de simplement fournir un **401 Unauthorized**.

Assurez-vous d'inclure un Session Authenticator avant le `RedirectMiddleware` pour vous assurer que l'utilisateur authentifié est chargé avant de passer par le `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Connexion par formulaire

Pour authentifier un utilisateur et les requêtes futures avec une session, vous devez connecter un utilisateur. Vapor fournit un protocole `ModelCredentialsAuthenticatable` auquel se conformer. Cela gère la connexion via un formulaire. Conformez d'abord votre `User` à ce protocole :

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Ceci est identique à `ModelAuthenticatable`, et si vous vous y conformez déjà, vous n'avez rien d'autre à faire. Appliquez ensuite ce middleware `ModelCredentialsAuthenticator` à votre requête POST de formulaire de connexion :

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Cela utilise l'authentificateur d'identifiants par défaut pour protéger la route de connexion. Vous devez envoyer `username` et `password` dans la requête POST. Vous pouvez configurer votre formulaire comme ceci :

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

Le `CredentialsAuthenticator` extrait `username` et `password` du corps de la requête, trouve l'utilisateur à partir du nom d'utilisateur et vérifie le mot de passe. Si le mot de passe est valide, le middleware authentifie la requête. Le `SessionAuthenticator` authentifie ensuite la session pour les requêtes suivantes.

## JWT

[JWT](jwt.md) fournit un `JWTAuthenticator` qui peut être utilisé pour authentifier les JSON Web Tokens dans les requêtes entrantes. Si vous découvrez JWT, consultez l'[aperçu](jwt.md).

Tout d'abord, créez un type représentant une charge utile JWT.

```swift
// Exemple de charge utile JWT.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constantes
    let expirationTime: TimeInterval = 60 * 15
    
    // Données du jeton
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

Ensuite, nous pouvons définir une représentation des données contenues dans une réponse de connexion réussie. Pour l'instant, la réponse n'aura qu'une seule propriété, qui est une chaîne représentant un JWT signé.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

En utilisant notre modèle pour le jeton JWT et la réponse, nous pouvons utiliser une route de connexion protégée par mot de passe qui retourne un `ClientTokenResponse` et inclut un `SessionToken` signé.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Alternativement, si vous ne souhaitez pas utiliser un authentificateur, vous pouvez avoir quelque chose qui ressemble à ce qui suit.
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Valider l'identifiant fourni pour l'utilisateur
    // Obtenir l'userId pour l'utilisateur fourni
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

En conformant la charge utile à `Authenticatable` et `JWTPayload`, vous pouvez générer un authentificateur de route en utilisant la méthode `authenticator()`. Ajoutez ceci à un groupe de routes pour récupérer et vérifier automatiquement le JWT avant que votre route ne soit appelée.

```swift
// Créer un groupe de routes qui nécessite le JWT SessionToken.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Ajouter le [guard middleware](#guard-middleware) optionnel exigera que l'autorisation ait réussi.

À l'intérieur des routes protégées, vous pouvez accéder à la charge utile JWT authentifiée en utilisant `req.auth`.

```swift
// Retourner une réponse ok si le jeton fourni par l'utilisateur est valide.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
