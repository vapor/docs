# Authentification

L'authentification est le moyen de vérifier l'identité d'un utilisateur. Cela se fait par la vérification d'informations d'identification comme un couple nom d'utilisateur et mot de passe, ou un jeton unique. L'authentification (parfois appelée auth/c) se distingue de l'autorisation (auth/z) qui est le moyen de vérifier qu'un utilisateur précédemment authentifié possède les permissions nécessaires pour accomplir des actions données.

## Introduction

L'API d'authentification de Vapor permet l'authentification d'un utilisateur via l'entête `Authorization`, en mode [Basic](https://tools.ietf.org/html/rfc7617) ou [Bearer](https://tools.ietf.org/html/rfc6750). Elle permet aussi d'authentifier un utilisateur via les données décodées de l'API [Contenu](../basics/content.md).

L'authentification s'implémente en créant un objet `Authenticator` qui contient la logique de vérification. Cet authentificateur peut servir à protéger des groupes de routes individuels ou une application entière. Vapor fournit les authentificateurs suivants :

| Protocole                                                   | Description                                              |
|-------------------------------------------------------------|----------------------------------------------------------|
| `RequestAuthenticator`/`AsyncRequestAuthenticator`          | Authentificateur de base capable de créer un middleware. |
| [`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)    | Authentifie grâce à une entête Basic authorization.      |
| [`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer) | Authentifie grâce à une entête Bearer authorization.     |
| `CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`  | Authentifie grâce à des données du corps de la requête.  |

Si l'authentification réussit, l'authentificateur ajoute les informations vérifiées de l'utilisateur dans `req.auth`. Cet utilisateur peut ensuite être récupéré via `req.auth.get(_:)` depuis vos routes protégées par l'authentificateur. Si l'authentification échoue, l'utilisateur n'est pas ajouté à `req.auth` et toute tentative d'y accéder échouera.

## Le protocole Authenticatable

Pour utiliser l'API d'authentification, vous aurez besoin d'un type d'objet représentant un utilisateur qui soit conforme au protocole `Authenticatable`. Il peut s'agit d'une `struct`, une `class`, ou encore un `Model` Fluent. Les exemples suivants supposent la déclaration de cette simple struct `User` qui ne contient que la propriété `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Chacun des exemples ci-dessous utilisera une instance d'un authentificateur déjà créé que nous appellerons `UserAuthenticator`.

### Route

Les authentificateurs sont des middlewares, et peuvent servir à protéger des routes.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` sert à récupérer l'instance authentifiée de `User`. Si l'authentification échoue, cette méthode lèvera une erreur, protégeant l'accès à la route. 

### Guard Middleware

Vous pouvez aussi utiliser `GuardMiddleware` sur votre groupe de routes pour vous assurer de l'authentification d'un utilisateur avant d'atteindre votre route.

```swift
let protected = app
    .grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Les middlewares authentificateurs ne forcent pas un utilisateur a être authentifié, afin de permettre la combinaison d'authentificateurs multiples. Vous pouvez en lire d'avantage sur la [combinaison](#combinaison) plus bas.

## Basic

L'authentification Basic consiste à envoyer un nom d'utilisateur et un mot de passe dans l'entête `Authorization` de la requête. Ces deux chaînes sont concaténées avec le caractère `:` (ex : `test:secret`), encodées en base-64, et préfixées par `"Basic "`. La requête d'exemple suivante encode le nom d'utilisateur `test` avec le mot de passe `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

L'authentification Basic ne sert généralement qu'une seule fois pour authentifier un utilisateur et générer un jeton. Cela réduit la fréquence à laquelle doit être envoyée l'information sensible que constitue le mot de passe de l'utilisateur. Vous ne devriez jamais envoyer une requête avec une entête Authorization Basic via une connexion en texte clair ou en TLS non vérifiée.

Pour implémenter une authentification Basic dans votre application, créez un authentificateur conforme au protocole `BasicAuthenticator`. Voici un exemple d'authentificateur codé en dur pour vérifier la requête précédente :


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

Si vous utilisez `async`/`await` vous pouvez utiliser `AsyncBasicAuthenticator` à la place :

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

Ce protocole nécessite l'implémentation de `authenticate(basic:for:)` qui sera appelée lorsqu'une requête entrante contient l'entête `Authorization: Basic ...`. Une struct `BasicAuthorization` contenant le nom d'utilisateur (username) et son mot de passe (password) est fournie à cette méthode.

Dans cet authentificateur de test, les valeurs sont comparées à des chaînes codées en dur. Dans un authentificateur réel, vous vérifiriez ces données depuis une base de données ou une API externe. C'est pour cela que la méthode `authenticate` permet de retourner une valeur future. 

!!! Point d'attention
    Les mots de passe ne devraient jamais être stoqués en clair. Utilisez des valeurs de hash pour la comparaison.

Si les paramètres d'authentification sont bons, dans le cas présent s'ils correspondent aux valeurs codées en dur, un objet `User` nommé Vapor sera connecté. Dans le cas contraire, aucun utilisateur ne sera connecté, ce qui signifie que l'authentification aura échoué. 

Si vous ajoutez cet authentificateur à votre application, et testez la route définie plus haut, vous devriez voir le nom `"Vapor"` retourné pour une authentification réussie. Pour un échec d'authentification, vous devriez constater une erreur `401 Unauthorized`.

## Bearer

L'authentification Bearer consiste en l'envoi d'un jeton dans l'entête `Authorization` de la requête. Ce jeton commence par le préfixe `"Bearer "`. La requête d'exemple suivante envoie le jeton `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

L'authentification Bearer s'utilise couramment pour authentifier des utilisateurs sur des routes d'API. L'utilisateur commence par demander un jeton Bearer en envoyant des données d'identification comme son nom d'utilisateur et son mot de passe à une route d'authentification. Ce jeton peut avoir une durée de validité allant de quelques minutes à plusieurs jours en fonction des besoins de l'application. 

Tant que le jeton est valide, l'utilisateur peut s'en servir en remplacement de ses données d'identification principales pour s'authentifier auprès des autres APIs. Quand le jeton périmera, un nouveau pourra être généré depuis l'API d'authentification.

Pour implémenter l'authentification Bearer dans votre application, créez un authentificateur conforme au protocole `BearerAuthenticator`. Voici un exemple d'authentificateur codé en dur pour vérifier la requête précédente.

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

Si vous utilisez `async`/`await` vous pouvez utiliser `AsyncBearerAuthenticator` à la place :

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

Ce protocole nécessite l'implémentation de `authenticate(bearer:for:)` qui sera appelée lorsqu'une requête entrante contient l'entête `Authorization: Bearer ...`. Une struct `BearerAuthorization` contenant le jeton (token) est fournie à cette méthode.

Dans cet authentificateur de test, la valeur du jeton est comparée à une chaîne codée en dur. Dans un authentificateur réel, vous vérifiriez le jeton depuis une base de données ou via des mesures cryptographiques, comme c'est fait pour du JWT. C'est pour cela que la méthode `authenticate` permet de retourner une valeur future. 

!!! Point d'attention
    En implémentant une vérification par jeton, il est important de prendre en compte le redimensionnement horizontal. Si votre application doit gérer différents utilisateurs en parallèle, l'authentification peut former un potentiel goulot d'étranglement. Ayez en tête la façon dont votre application se comportera sur plusieurs instances tournant en même temps.

Si les paramètres d'authentification sont bons, dans le cas présent s'ils correspondent aux valeurs codées en dur, un objet `User` nommé Vapor sera connecté. Dans le cas contraire, aucun utilisateur ne sera connecté, ce qui signifie que l'authentification aura échoué.

Si vous ajoutez cet authentificateur à votre application, et testez la route définie plus haut, vous devriez voir le nom `"Vapor"` retourné pour une authentification réussie. Pour un échec d'authentification, vous devriez constater une erreur `401 Unauthorized`.

## Combinaison

Plusieurs authentificateurs peuvent être combinés pour gérer des authentifications plus complexes. Puisqu'un middleware authentificateur ne rejette pas la requête en cas d'échec d'authentification, il est possible de chaîner plusieurs de ces authentificateurs à la suite. La composition peut se faire de deux façons clés. 

### Combinaison de méthodes d'authentification

Cette première méthode de composition d'authentificateurs enchaîne plusieurs authentificateurs pour le même type d'utilisateur. Prenez l'exemple suivant :

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Faire quelque-chose avec l'utilisateur.
}
```

Cet exemple suppose l'existance des authentificateurs `UserPasswordAuthenticator` et `UserTokenAuthenticator` qui authentifient un utilisateur de type `User`. Les deux authentificateurs sont ajoutés au groupe de routes. Enfin, le `GuardMiddleware` est ajouté après les authentificateurs pour forcer à ce qu'un utilisateur de type `User` soit authentifié avant la route. 

Cette composition permet d'exposer une route accessible soit par mot de passe, soit par jeton. Une telle route pourrait permettre à un utilisateur de se connecter avec son mot de passe pour générer un jeton, puis utiliser ce jeton sur cette même route pour re-générer son jeton avant expiration.

### Combinaison de types d'utilisateurs

Cette deuxième méthode de composition d'authentificateurs enchaîne plusieurs authentificateurs pour des types d'utilisateurs différents. Prenez l'exemple suivant :

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Faire quelque-chose.
}
```

Cet exemple suppose l'existance des authentificateurs `AdminAuthenticator` et `UserAuthenticator` qui authentifient respectivement des utilisateurs de type `Admin` et `User`. Les deux authentificateurs sont ajoutés au groupe de routes. Au lieu d'utiliser le `GuardMiddleware`, une vérification dans la route est ajoutée pour voir si un `Admin` ou `User` a été identifié. Si non, une erreur est levée.

Cette composition permet d'exposer une route accessible à deux types d'utilisateurs différents, ayant potentiellement une façon différente de s'authentifier. Une telle route permet l'authentification des utilisateurs normaux tout en permettant l'accès aux administrateurs.

## Manuelle

Vous pouvez aussi gérer manuellement l'authentification via `req.auth`. Cela sert beaucoup dans le cas des tests.

Pour authentifier manuellement un utilisateur, utilisez `req.auth.login(_:)`. Tout utilisateur conforme à `Authenticatable` peut être fourni à cette méthode.

```swift
req.auth.login(User(name: "Vapor"))
```

Pour récupérer l'utilisateur authentifié, utilisez `req.auth.require(_:)`.

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Vous pouvez aussi utiliser `req.auth.get(_:)` si vous ne souhaitez pas lever une erreur automatiquement lorsque l'authentification n'a pas fonctionné.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Pour déconnecter un utilisateur, passez le type de l'utilisateur à la méthode `req.auth.logout(_:)`. 

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) définit deux protocoles `ModelAuthenticatable` et `ModelTokenAuthenticatable` qui peuvent être ajoutés à vos modèles existants. Conformer vos modèles à ces protocoles permet la création d'authentificateurs pour protéger des APIs. 

`ModelTokenAuthenticatable` authentifie par un jeton Bearer. C'est ce que vous utilisez pour protéger la plupart de vos APIs. `ModelAuthenticatable` authentifie par un nom d'utilisateur et un mot de passe, et ne sert que sur une seule API pour générer des jetons. 

Ce guide suppose une familiarité avec Fluent et que votre application soit configurée pour utiliser une base de données. Si vous ne connaissez pas encore Fluent, commencez par lire [l'aperçu](../fluent/overview.md).

### User

Pour commencer, il vous faut un modèle qui représente l'utilisateur authentifié. Pour ce guide, nous utiliserons le modèle suivant, mais vous pouvez librement utiliser un de vos modèles existants.

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

Le modèle doit pouvoir stoquer un nom d'utilisateur, dans notre cas il s'agit du champ email, et un hash de mot de passe. Nous définissons aussi une contrainte d'unicité sur le champ `email`, pour éviter d'avoir des doublons d'utilisateurs. Voici la migration correspondant à cet exemple :

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

!!! Point d'attention
    Puisque les adresses e-mail ne sont pas sensibles à la casse, vous voudrez peut-être ajouter un [`Middleware Fluent`](../fluent/model.md#cycle-de-vie) qui les convertit en minuscules avant de les enregistrer en base de données. Sachez toutefois que `ModelAuthenticatable` utilise une comparaison sensible à la casse, vous devrez-donc vous assurer que les entrées utilisateur soient aussi en minuscules si vous choisissez cette approche, soit côté client, soit par un authentificateur personnalisé.

Nous aurons besoin d'une API pour créer des utilisateurs. Nous choisirons `POST /users`. Créez une struct de [Contenu](../basics/content.md) représentant les données attendues par cette route.

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

Si vous le souhaitez, vous pouvez la conformer à [Validatable](../basics/validation.md) pour ajouter les validations requises.

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

Nous pouvons ensuite créer la route `POST /users`. 

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Les mots de passe ne correspondent pas")
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

Cette route valide la requête entrante, décode la struct `User.Create`, et vérifie la correspondance du mot de passe. Elle utilise ensuite les données décodées pour créer un nouvel objet `User` et l'enregistrer dans la base de données. Le mot de passe en clair est haché par `Bcrypt` avant d'être enregistré. 

Compilez et lancez le projet, assurez-vous de bien lancer les migrations, puis utilisez la requête suivante pour créer un nouvel utilisateur.

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

#### Modèle Authentifiable

Maintenant que vous avez un modèle pour les utilisateurs et une route pour en créer, conformons le modèle au protocole `ModelAuthenticatable`. Cela lui permettra d'être authentifié par nom d'utilisateur et mot de passe.

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

Cette extension ajoute la conformité à `ModelAuthenticatable` pour `User`. Les deux premières propriétés indiquent quels sont les champs qui stoquent le nom d'utilisateur et le hash du mot de passe. La syntaxe avec un `\` en préfixe crée un key-path vers le champ que Fluent pourra utiliser pour y accéder.

La dernière exigence est une méthode de vérification des mots de passe envoyés en clair dans l'entête Autorization Basic. Puisque nous utilisons Bcrypt pour hasher le mot de passe lors de sa création, nous utiliserons aussi Bcrypt pour vérifier que le mot de passe fourni correspond bien au hash du mot de passe stoqué.

Maintenant que `User` est conforme à `ModelAuthenticatable`, nous pouvons créer un authentificateur pour protéger la route de connexion.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` ajoute la méthode statique `authenticator` pour créer un authentificateur.

Testez que cette route fonctionne en envoyant la requête suivante.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Cette requête envoie le nom d'utilisateur `test@vapor.codes` et le mot de passe `secret42` dans l'entête Authorization Basic. Vous devriez recevoir en réponse l'utilisateur précédemment créé.

Bien que vous puissiez théoriquement utiliser une authentification de type Basic pour protéger toutes vos routes, il est plutôt recommandé d'utiliser un jeton séparé. Cela réduit la fréquence à laquelle il faudra envoyer sur Internet l'information sensible que constitue le mot de passe de l'utilisateur. Cela rend aussi l'authentification beaucoup plus rapide puisqu'il ne sera nécessaire de générer un hash qu'une seule fois lors de la connexion.

### Jeton utilisateur

Créez un nouveau modèle pour représenter les jetons des utilisateurs.

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

Ce modèle doit avoir un champ `value` pour stoquer la chaîne unique du jeton. Il doit aussi avoir une relation de type [parent](../fluent/overview.md#parent) vers le modèle de l'utilisateur associé. Vous pouvez ajouter des propriétés supplémentaires au besoin, comme une date d'expiration par exemple. 

Ensuite, créons la migration de ce modèle.

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

Remarquez que cette migration ajoute une contrainte d'unicité au champ `value`. Elle crée aussi une clé étrangère sur le champ `user_id` qui référence la table users et la colonne id. 

N'oubliez pas d'ajouter la migration à `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Enfin, ajoutez une méthode dans l'objet `User` pour générer un nouveau jeton. Cette méthode servira lors de l'authentification.

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

Nous utilisons `[UInt8].random(count:)` pour générer une valeur aléatoire pour le jeton. Pour cet exemple, 16 octets, soit 128 bits, de données aléatoires sont générés. Vous pouvez ajuster ce chiffre comme bon vous semble. Ces données aléatoires sont ensuite encodées en base-64 pour faciliter leur transmission en entêtes HTTP.

Maintenant que vous pouvez générer des jetons utilisateur, mettez à jour la route `POST /login` pour créer et retourner un jeton :

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Testez que cette route fonctionne en utilisant la même requête d'authentification que précédemment. Vous devriez désormais recevoir un jeton en réponse de la requête, similaire à ceci :

```
8gtg300Jwdhc/Ffw784EXA==
```

Conservez le jeton que vous avez obtenu, nous l'utiliserons bientôt.

#### Modèle authentifiable par jeton

Conformez `UserToken` au protocole `ModelTokenAuthenticatable`. Cela permettra aux jetons d'authentifier votre modèle `User`.

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

La première exigence du protocole est d'indiquer quel champ stoque la valeur du jeton. Il s'agit de la valeur envoyée dans l'entête Autorization Bearer. La seconde exigence est d'indiquer la relation de type parent vers le modèle `User`. C'est grâce à cela que Fluent cherchera l'utilisateur à authentifier. 

La dernière exigence est la définition d'un booléen `isValid`. S'il vaut `false`, le jeton sera supprimé de la base de données et l'utilisateur ne sera pas authentifié. Pour faire simple, déclarons les jetons avec une validité sans expiration en codant `true` en dur.

Maintenant que le jeton est conforme à `ModelTokenAuthenticatable`, vous pouvez créer un authentificateur pour protéger vos routes.

Créez une nouvelle route `GET /me` pour récupérer l'utilisateur connecté.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Comme pour `User`, `UserToken` possède maintenant une méthode statique `authenticator()` qui peut instancier un authentificateur. Ce dernier essaiera de trouver un `UserToken` correspondant à la valeur fournie par l'entête Autorization Bearer. En cas de correspondance, il récupèrera l'objet `User` associé et l'authentifiera. 

Testez que cette route fonctionne en envoyant la requête HTTP suivante en remplaçant `<token>` par la valeur que vous avez récupérée suite à votre requête sur `POST /login`. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Vous devriez recevoir un objet `User` en réponse. 

## Session

L'API [Session](../advanced/sessions.md) de Vapor peut être utilisée pour enregistrer automatiquement l'authentification utilisateur entre les requêtes. Cela fonctionne en stoquant un identifiant unique pour l'utilisateur dans les données de session de la requête après une authentification réussie. Sur les requêtes suivantes, l'identifiant de l'utilisateur est récupéré depuis la session et sert pour authentifier l'utilisateur avant d'appeler le contrôleur.

Les sessions sont adaptées pour un usage sur des applications web front-end conçues avec Vapor délivrant du HTML directement aux navigateurs web. Pour des APIs, nous recommandons d'utiliser une authentification sans état, basée sur un jeton pour stoquer les données utilisateur entre les requêtes.

### Session authentifiable

Pour utiliser une authentification basée sur une session, vous aurez besoin d'un type qui soit conforme au protocole `SessionAuthenticatable`. Pour cet exemple, nous utiliserons une simple struct.

```swift
import Vapor

struct User {
    var email: String
}
```

Pour la conformité à `SessionAuthenticatable`, vous devrez spécifier `sessionID`. Il s'agit de la valeur à stoquer en session, qui doit permettre d'identifier un utilisateur de manière unique. 

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Pour notre type `User` basique, nous utiliserons l'adresse e-mail comme identifiant de session unique.

### Authentificateur de session

Nous aurons ensuite besoin d'un `SessionAuthenticator` pour gérer la résolution d'instances de type User à partir de l'identifiant enregistré en session.


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

Si vous utilisez `async`/`await` vous pouvez utiliser `AsyncSessionAuthenticator` :

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Puisque toutes les informations dont nous avons besoin pour initialiser notre objet `User` d'exemple se trouvent dans l'identifiant de session, nous pouvons créer et connecter l'utilisateur de façon synchrone. Dans une application réelle, vous utiliseriez probablement l'identifiant de session pour chercher en base de données ou depuis une API le reste des données de l'utilisateur avant de l'authentifier. 

Créons ensuite un simple authentificateur de type Bearer pour la première authentification.

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

Cet authentificateur va authentifier un utilisateur qui aura l'e-mail `hello@vapor.codes` lorsque le jeton Bearer `test` sera envoyé.

Assemblons enfin ces pièces dans votre application.

```swift
// Crée un groupe de routes protégé par une authentification utilisateur.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Ajoute une route GET /me pour récupérer l'adresse email de l'utilisateur.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` est ajouté en premier pour activer le support des sessions sur l'application. Plus d'informations sur la configuration des sessions se trouvent dans la section de [L'API Session](../advanced/sessions.md).

Le `SessionAuthenticator` est ajouté ensuite. Il gère l'authentification de l'utilisateur en cas de session active.

Si l'authentification n'a pas encore été enregistrée en session, la requête continuera vers l'authentificateur suivant. `UserBearerAuthenticator` vérifiera le jeton Bearer et authentifiera l'utilisateur si ce jeton est égal à `"test"`.

Enfin, `User.guardMiddleware()` s'assurera qu'une instance de `User` a été authentifiée par un des middlewares précédents. Si aucun utilisateur n'a été identifié, une erreur sera levée. 

Pour tester cette route, commencez par envoyer la requête suivante :

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Cela aura pour effet d'authentifier l'utilisateur par notre `UserBearerAuthenticator`. Une fois authentifié, `UserSessionAuthenticator` enregistrera l'identifiant de l'utilisateur dans le stoquage de session et génèrera un cookie. Utilisez le cookie de la réponse dans une deuxième requête à cette route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Cette fois, ce sera `UserSessionAuthenticator` qui authentifiera l'utilisateur et vous devriez à nouveau voir l'adresse e-mail de l'utilisateur retournée.

### Modèle authentifiable par session

Les modèles Fluent peuvent instancier des `SessionAuthenticator`s en se conformant au protocole `ModelSessionAuthenticatable`. Cela utilisera l'identifiant unique du modèle comme identifiant de session et cherchera automatiquement en base de données pour restaurer le modèle à partir des données de session. 

```swift
import Fluent

final class User: Model { ... }

// Permet à ce modèle d'être enregistré en session.
extension User: ModelSessionAuthenticatable { }
```

Vous pouvez ajouter une conformité vide à `ModelSessionAuthenticatable` pour n'importe quel modèle. Une fois ajouté, une nouvelle méthode statique sera disponible pour instancier un `SessionAuthenticator` pour ce modèle. 

```swift
User.sessionAuthenticator()
```

Cela utilisera la base de données par défaut de l'application pour chercher l'utilisateur. Pour choisir une base de donnée précise, indiquez son identifiant :

```swift
User.sessionAuthenticator(.sqlite)
```

## Authentification pour sites web

Les sites web sont un cas particulier en ce qui concerne l'authentification, car l'utilisation d'un navigateur réduit les possibilités d'envoi d'informations d'identification. Cela conduit à deux scénarios d'authentification :

* la connexion initiale via un formulaire
* des appels ultérieurs authentifiés par un cookie de session

Vapor et Fluent fournissent plusieurs outils pour rendre ce processus fluide.

### Authentification de session

L'authentification de session fonctionne comme décrit plus haut. Vous devez ajouter le middleware de session et l'authentificateur de session sur toutes les routes accessibles à vos utilisateurs. Cela inclus toutes les routes protégées, toutes les routes publiques pour lesquelles vous souhaitez quand même accéder à l'utilisateur connecté (pour afficher un bouton 'mon compte' par exemple) **et** les routes de connexion.

Vous pouvez l'activer pour toute votre application dans **configure.swift** comme ceci :

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Ces middlewares ont les effets suivants :

* le middleware "sessions" prend le cookie de session fourni avec la requête et le convertit en session
* l'authentificateur de session récupère cette session et vérifie si un utilisateur authentifié y est associé. Si c'est le cas, le middleware authentifie la requête. Sur le flux de réponse, l'authentificateur de session vérifie si la requête a un utilisateur authentifié et l'enregistre en session pour le maintenir connecté sur les requêtes suivantes.

!!! Note
    Le cookie de session n'est pas configuré sur `secure` et `httpOnly` par défaut. Regarder la section concernant [l'API Session](../advanced/sessions.md#configuration) de Vapor pour plus d'informations sur la configuration des cookies.

### Protection de routes

Lorsque l'on protège des routes d'API, une réponse HTTP est généralement retournée avec un code de statut tel que **401 Unauthorized** si la requête n'est pas authentifiée. Cependant, cela n'offre pas une bonne expérience utilisateur pour quelqu'un qui utiliserait un navigateur. Vapor fournit un `RedirectMiddleware` pour chaque type conforme au protocole `Authenticatable` que vous pouvez utiliser pour ce type de scénario :

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

L'objet `RedirectMiddleware` peut aussi recevoir une closure qui retourne le chemin de redirection en type `String` lors de sa création pour une gestion plus avancée des URLs. Par exemple, inclure le chemin depuis lequel la redirection a été déclenchée en query-string de la redirection cible pour conserver l'état de la requête initiale.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Ce fonctionne est similaire à celui du `GuardMiddleware`. Toute requête vers une des routes du groupe `protectedRoutes` qui n'est pas authentifiée se verra redirigée vers le chemin renseigné. Cela vous permet de demander à vos utilisateurs de se connecter, plutôt que de leur afficher simplement une erreur **401 Unauthorized**.

Vérifiez que l'authentificateur de session soit configuré avant le `RedirectMiddleware` pour que l'utilisateur authentifié soit chargé avant l'exécution du `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Formulaire de connexion

Pour authentifier un utilisateur et ses futures requêtes via une session, vous devez permettre à un utilisateur de se connecter. Vapor fournit le protocole `ModelCredentialsAuthenticatable` auquel vous pouvez vous conformer. Il permet de gérer les authentifications par formulaire. Commencez par conformer votre type `User` à ce protocole :

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Cette conformité est identique à celle de `ModelAuthenticatable`, et si vous êtes déjà conformes à ce protocole, alors vous n'avez rien de plus à faire. Ajoutez ensuite ce middleware `ModelCredentialsAuthenticator` à votre requête POST du formulaire de connexion :

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Cela utilise l'authentificateur par défaut pour protéger la route de connexion. Il s'attent à recevoir les champs `username` et `password` dans la requête POST. Vous pouvez donc créer un formulaire comme ceci :

```html
 <form method="POST" action="/login">
    <label for="username">Identifiant de connexion</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Mot de passe</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

Le middleware `CredentialsAuthenticator` extrait les valeurs `username` et `password` du corps de la requête, trouve l'utilisateur par son identifiant de connexion, et vérifie son mot de passe. S'il est valide, le middle authentifie la requête. Le middleware `SessionAuthenticator` authentifie ensuite la session pour les requêtes suivantes.

## JWT

[JWT](jwt.md) fournit le middleware `JWTAuthenticator` qui permet d'authentifier des JSON Web Tokens associés aux requêtes entrantes. Si vous découvrez JWT, lisez notre page de [présentation](jwt.md).

Tout d'abord, créez un type représentant le contenu du JWT.

```swift
// Exemple de contenu JWT
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

Nous pouvons ensuite définir la représentation des données contenues dans une réponse d'authentification réussie. Pour le moment, la réponse n'aura qu'une propriété de type chaîne de caractères représentant un JWT signé.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

Avec notre modèle pour le jeton JWT et la réponse, nous pouvons utiliser une route de connexion protégée par mot de passe qui retourne un objet `ClientTokenResponse` incluant un objet `SessionToken` signé.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

En alternative, si vous ne souhaitez pas utiliser un authentificateur, vous pourriez faire quelque-chose de ce genre :
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Validation des informations d'identification de l'utilisateur
    // Puis récupération de userId
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

En conformant le contenu du JWT à `Authenticatable` et `JWTPayload`, vous pouvez instancier un authentificateur avec la méthode `authenticator()`. Ajoutez-le à un groupe de routes pour récupérer et vérifier automatiquement le JWT avant l'appel à votre route. 

```swift
// Crée un groupe de routes qui nécessitent le JWT défini par l'objet SessionToken.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

L'ajout facultatif du [guard middleware](#guard-middleware) forcera une authentification réussie pour accéder aux routes.

Depuis l'intérieur des routes protégées, vous pouvez accéder au contenu du JWT authentifié via `req.auth`. 

```swift
// Retourne une réponse en statut OK si le jeton JWT fourni par l'utilisateur est valide.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
