# Modèles

Les modèles représentent les données stoquées dans les tables ou collections de votre base de données. Ils comportent un ou plusiseurs champs capables de stoquer des valeurs codables. Chaque modèle a un identifiant unique. Des PropertyWrappers sont utilisés pour marquer les identifiants, champs, et relations. 

L'exemple ci-dessous représente un modèle simple avec un champ unique. Notez qu'un modèle ne représente pas en totalité un schéma en base de données, comme les contraintes, index, ou clés étrangères. Les schémas sont définis par des [migrations](migration.md). Les modèles ont le rôle spécifique de représenter les données stoquées par le schéma de votre base de données.  

```swift
final class Planet: Model {
    // Nom de la table ou collection.
    static let schema = "planets"

    // Identifiant unique de la planète.
    @ID(key: .id)
    var id: UUID?

    // Nom de la planète.
    @Field(key: "name")
    var name: String

    // Crée une nouvelle planète vide.
    init() { }

    // Crée une nouvelle planète avec ses propriétés.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## Schéma

Chaque modèle a besoin d'une propriété statique `schema` en lecture seule. Cette chaîne de caractères référence le nom de la table ou collection que représente ce modèle. 

```swift
final class Planet: Model {
    // Nom de la table ou collection.
    static let schema = "planets"
}
```

Lorsque vous requêterez ce modèle, les données seront récupérées depuis et enregistrées dans le schéma nommé `"planets"`.

!!! Info
    Le nom du schéma est généralement le nom de la classe au pluriel et en minuscules. 

## Identifiant

Chaque modèle a besoin d'une propriété `id` complétée du PropertyWrapper `@ID`. Ce champ identifie de façon unique les instances de votre modèle.

```swift
final class Planet: Model {
    // Identifiant unique de cette planète.
    @ID(key: .id)
    var id: UUID?
}
```

Par défaut, la propriété `@ID` devrait utiliser la clé spécialisée `.id`, qui correspondra à une clé appropriée dans le driver sous-jacent. Pour SQL, il s'agirat de `"id"`, là où NoSQL sélectionnera `"_id"`. 

`@ID` devrait aussi s'appliquer à un champ typé en `UUID`. C'est la seule valeur d'identifiant actuellement supportée par tous les drivers de base de données. Fluent génèrera automatiquement des identifiants au format UUID lorsque de nouveaux modèles seront créés. 

`@ID` contient aussi une valeur optionnelle, car les nouveaux modèles qui n'ont pas encore été enregistrés n'auront naturellement pas encore d'identifiant associé. Pour récupérer l'identifiant ou lever une erreur, utilisez `requireID`.

```swift
let id = try planet.requireID()
```

### Existance

`@ID` possède une propriété `exists` qui représente l'état d'existence du modèle en base de données. Lorsque vous initialisez un nouveau modèle, sa valeur est définie à `false`. Une fois que vous enregistrez un modèle, ou lorsque vous en récupérez depuis une base de données, sa valeur est à `true`. Cette propriété est accessible en lecture/écriture.

```swift
if planet.$id.exists {
    // Ce modèle existe en base de données.
}
```

### Identifiant personnalisé

Fluent supporte des clés et types d'identifiant personnalisé avec la surcharge `@ID(custom:)`. 

```swift
final class Planet: Model {
    // Identifiant unique de cette planète.
    @ID(custom: "foo")
    var id: Int?
}
```

L'exemple précédent utilise `@ID` avec la clé personnalisée `"foo"` et le type `Int`. C'est compatible avec les bases de données SQL qui utilisent des clés primaires en auto-incrément, mais n'est en revanche pas compatible avec NoSQL. 

Des `@ID`s personnalisés vous permettent de spécifier comment les identifiants doivent être générés grâce au paramètre `generatedBy`.

```swift
@ID(custom: "foo", generatedBy: .user)
```

Le paramètre `generatedBy` peut accepter les valeurs suivantes :

|Valeur|Description|
|-|-|
|`.user`|`@ID` doit se voir affecter une valeur avant d'enregistrer le modèle en base.|
|`.random`|Le type sur lequel `@ID` est positionné doit être conforme à `RandomGeneratable`.|
|`.database`|La responsabilité de génération de l'identifiant est déléguée à la base de données au moment de l'insertion.|

Si le paramètre `generatedBy` est omis, Fluent essaiera de déduire un comportement approprié selon le type de valeur démarqué par `@ID`. Par exemple, `Int` se verra attribué la stratégie `.database` par défaut.

## Initialisateur

Les modèles doivent avoir une méthode d'initialisation vide.

```swift
final class Planet: Model {
    // Crée une nouvelle planète vide.
    init() { }
}
```

Fluent a besoin de cet méthode pour son fonctionnement interne afin d'initialiser les modèles retournés par les requêtes. Cette méthode est également utilisée dans les processus de réflexion. 

Vous souhaiterez peut-être ajouter votre initialisateur personnalisé pour vous simplifier la vie. 

```swift
final class Planet: Model {
    // Crée une nouvelle planète avec toutes ses propriétés.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

L'usage de ce genre d'initialisateur rend l'ajout de propriétés futures au modèle plus aisé.

## Champs

Chaque modèle peut avoir zéro champs ou plus, dénotés par `@Field`, pour stoquer des données. 

```swift
final class Planet: Model {
    // Nom de la planète.
    @Field(key: "name")
    var name: String
}
```

Les champs ont besoin que le nom de la colonne en base de données soit défini de façon explicite. Il n'est pas obligatoire que le nom de colonne corresponde au nom de propriété du modèle. 

!!! Conseil
    Fluent recommande la convention `snake_case` pour les clés en base de données, et `camelCase` pour les noms de propriétés. 

Les valeurs de champs peuvent être de tout type qui se conforme à `Codable`. Le stoquage de structures imbriquées et de tableaux dans des champs `@Field` est possible, mais les opérations de filtrage sont limitées. Se référer à [`@Group`](#group) pour une solution alternative.

Pour les champs dont la valeur est facultative, utilisez `@OptionalField` à la place. 

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! Attention
    Un champ non optionnel qui possède la PropertyObserver `willSet` qui référence sa valeur actuelle, ou la PropertyObserver `didSet` qui référence `oldValue` causera une erreur fatale.

## Relations

Les modèles peuvent avoir zéro, une, ou plusieurs relations vers d'autres modèles, telles que `@Parent`, `@Children`, et `@Siblings`. Un chapitre entier est dédié aux [relations](relations.md).

## Timestamp

`@Timestamp` est un type de champ `@Field` spécial qui stoque un objet de type `Foundation.Date`. Les timestamps sont automatiquement définis par Fluent en fonction du déclencheur choisi.

```swift
final class Planet: Model {
    // Indique le moment où cette planète a été créée.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // Indique le moment où cette planète a été mise à jour pour la dernière fois.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp` peut avoir un déclencheur parmi les valeurs suivantes :

|Déclencheur|Description|
|-|-|
|`.create`|Déclenché lors de la création de la ligne en base de données.|
|`.update`|Déclenché lorsqu'une ligne existante en base de données est mise à jour.|
|`.delete`|Déclenché lorsqu'une ligne existante en base de données est marquée pour suppression. Voir [suppression douce (soft delete)](#suppression-douce).|

La valeur date de `@Timestamp` est optionnelle, et devrait être définie à `nil` lors de l'initialisation d'un nouveau modèle. 

### Format de Timestamp

Par défaut, un `@Timestamp` utilisera un encodage `datetime` efficace et adapté à votre driver de base de données. Vous pouvez personnaliser la manière dont le timestamp est enregistré dans la base en utilisant le paramètre `format`.

```swift
// Stoque un timestamp au format ISO 8601 qui représente le moment
// où la ligne a été mise à jour pour la dernière fois.
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

Notez que la migration associée à cet exemple de format `.iso8601` nécessiterait un stoquage au format `.string`.

```swift
.field("updated_at", .string)
```

Voici une liste des formats timestamp disponibles :

|Format|Description|Type|
|-|-|-|
|`.default`|Utilise un encodage `datetime` efficace et spécifique à votre driver de base de données.|Date|
|`.iso8601`|Chaîne [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601). Accepte un paramètre `withMilliseconds`.|String|
|`.unix`|Le nombre de secondes écoulées depuis l'Epoch Unix, avec ses décimales.|Double|

Vous pouvez accéder à la valeur brute du timestamp grâce à la propriété `timestamp`.

```swift
// Définition manuelle de la valeur du timestamp sur propriété
// @Timestamp formattée en ISO 8601.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

###  Suppression douce

L'ajout d'un `@Timestamp` utilisant le déclencheur `.delete` activera la fonctionnalité de suppression douce pour votre modèle.

```swift
final class Planet: Model {
    // Indique le moment où cette planète a été supprimée.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

La suppression douce conserve les données dans votre base, mais les lignes en question ne seront plus retournées par les requêtes. 

!!! Astuce
    Vous pouvez manuellement définir un timestamp de suppression à une date future. Cela peut vous servir de mécanisme d'expiration.

Pour forcer un modèle qui a la suppression douce activée a être supprimé définitivement de votre base de données, utilisez le paramètre `force` de la méthode `delete`. 

```swift
// Suppression de la base de données, même si la
// suppression douce est activée pour ce modèle.
model.delete(force: true, on: database)
```

Vous pouvez restaurer un modèle en état de suppression douce grâce à la méthode `restore`.

```swift
// Supprime le timestamp enregistré par le déclencheur .delete,
// permettant à ce modèle d'être requêté à nouveau. 
model.restore(on: database)
```

Vous pouvez également inclure les modèles marqués en suppression douce dans vos résultats de requêtes classiques en ajoutant un appel à `withDeleted`. 

```swift
// Récupère toutes les planètes, dont celles qui ont été marquées en suppression douce.
Planet.query(on: database).withDeleted().all()
```

## Enum

`@Enum` est un type `@Field` particulier, qui permet le stoquage de valeurs textuelles en énumérations natives pour les bases de données. Les énumérations natives de bases de données vous offrent une couche supplémentaire de sécurisation au niveau du type de données et peuvent avoir de meilleures performances que des énumérations brutes.

```swift
// Enumération textuelle et codable représentant des types d'animaux.
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // Stoque le type d'animal en tant qu'énumération native en base de données.
    @Enum(key: "type")
    var type: Animal
}
```

Seuls les types conformes à `RawRepresentable`, où `RawValue` est de type `String` sont compatibles avec `@Enum`. Les énumérations basées sur le type `String` remplissent cette condition par défaut.

Pour stoquer une énumération facultative, utilisez `@OptionalEnum`. 

La base de données doit être préparée en amont par une migration. Voir [enum](schema.md#énumération) pour plus d'informations à ce sujet.

### Enums brutes

Toute énumération basée sur un type `Codable`, comme `String` ou `Int`, peut être stoquée dans un `@Field`. Sa valeur brute sera stoquée en base.

## Group

Le type `@Group` vous permet de stoquer un groupe de plusieurs champs imbriqués en tant que propriété unique dans votre modèle. À l'inverse d'une struct Codable stoquée dans un champ `@Field`, les champs présents dans un `@Group` sont requêtables. Fluent accomplit ce résultat en stoquant les champs `@Group` comme une structure plate dans votre base de données, chaque propriété correspondant à une colonne de la table ou collection du modèle dans lequel le groupe est inclus.

Pour utiliser un `@Group`, commencez par définir la structure imbriquée que vous souhaitez enregistrer, et conformez-la au protocole `Fields`. Vous remarquerez des similitudes avec le protocole `Model`, mais aucun identifiant ou nom de schéma n'est nécessaire ici. Vous pouvez stoquer ici plusieurs propriétés compatibles avec `Model`, comme `@Field`, `@Enum`, ou même d'autres `@Group`. 

```swift
// Un animal de compagnie, avec son nom et son espèce.
final class Pet: Fields {
    // Le nom de l'animal.
    @Field(key: "name")
    var name: String

    // L'espèce de l'animal. 
    @Field(key: "type")
    var type: String

    // Crée un nouvel animal vide.
    init() { }
}
```

Quand vous avez fini de créer le définition des champs, vous pouvez l'utiliser pour définir la valeur d'une propriété `@Group`.

```swift
final class User: Model {
    // L'animal de compagnie de l'utilisateur, imbriqué dans le schéma utilisateur.
    @Group(key: "pet")
    var pet: Pet
}
```

Les champs d'un `@Group` sont accessibles avec la syntaxe à points suivante :

```swift
let user: User = ...
print(user.pet.name) // String
```

Vous pouvez inclure des champs imbriqués dans vos requêtes avec cette même syntaxe à points au niveau des PropertyWrappers.

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

Dans la base de données, le `@Group` est stoqué à plat, les clés étant définies par un préfixe représentant le nom de votre groupe, et contanénées avec le nom du champ par un underscore intermédiaire (`_`). Voici un exemple de ce à quoi ressemblerait le modèle `User` dans votre base de données :

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

Les modèles sont conformes à `Codable` par défaut. Vous pouvez donc les utiliser avec [l'API contenu](../basics/content.md) de Vapor en les conformant au protocole `Content`.

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // Retourne un tableau de toutes les planètes.
    try await Planet.query(on: req.db).all()
}
```

Pendant la sérialisation vers / depuis `Codable`, les noms utilisés seront ceux des propriétés du modèle et non les clés de la base de données. Les relations seront sérialisées comme structures imbriquées, et toute donnée de relation pré-chargée sera également incluse. 

!!! Info
    Pour la majorité des cas, nous vous recommandons d'utiliser un DTO plutôt qu'un modèle pour vos réponses d'API et corps de requêtes. Voir la section [Data Transfer Object](#data-transfer-object) pour plus de détails.

### Data Transfer Object

La conformité par défaut des modèles à `Codable` peut simplifier les prototypages et cas de base. Cependant, cela a comme inconvénient d'exposer les informations internes de votre base de données à votre API. Cela n'est généralement pas souhaitable d'un point de vue sécurité - retourner des informations sensibles telles que le hash d'un mot de passe utilisateur est une mauvaise idée - mais aussi d'un point de vue praticité de maintenance et d'évolution. Cela complexifie les changements au niveau du schéma de base de données qui ne devrait pas avoir d'impact sur l'API, comme accepter ou modifier des données dans un format différent, ou bien y ajouter ou en supprimer des champs.

Vous devriez utiliser un DTO (data transfer object) dans la plupart des cas, au lieu d'un modèle (aussi appelé "domain transfer object"). Un DTO est un type `Codable` différent qui représente une structure de données que vous souhaitez encoder ou décoder. Ils permettent le découplage entre votre API et votre schéma de base de données, et vous permettent de modifier vos modèles sans casser vos API publiques, de maintenir différentes versions en parallèle, et rendre vos API plus propres pour vos clients.

Supposez le modèle `User` ci-dessous pour les exemples suivants :

```swift
// Modèle User simplifié, pour référence.
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

Un exemple de cas d'usage classique pour les DTOs est l'implémentation de requêtes HTTP `PATCH`. Ces requêtes n'incluent que les valeurs des champs à mettre à jour. Essayer de décoder directement un `Model` depuis une de ces requêtes échouerait si un seul des champs requis était manquant. Dans l'exemple ci-dessous, vous pouvez observer l'usage d'un DTO pour décoder une requête et mettre à jour un modèle.

```swift
// Structure d'une requête HTTP PATCH sur /users/:id.
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // Décode les données de la requête.
    let patch = try req.content.decode(PatchUser.self)
    // Récupère l'utilisateur depuis la base de données.
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // Si le prénom est fourni, on le met à jour.
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // Si le nom de famille est fourni, on le met à jour.
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // L'utilisateur est mis à jour, puis retourné en réponse.
    try await user.save(on: req.db)
    return user
}
```

Un autre cas d'usage parlant pour un DTO est la personnalisation du format de vos réponses. L'exemple ci-dessous démontre comment un DTO peut être utilisé pour ajouter un champ calculé à une réponse.

```swift
// Structure d'une réponse à GET /users.
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // Récupère tous les utilisateurs de la base de données.
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // Convertit chaque utilisateur au bon format de réponse.
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

Un autre cas d'usage concerne les relations, comme celles de parent à enfants ou d'enfant à parent. Voir la [documentation de Parent](relations.md#encodage-et-décodage-de-parents) pour un exemple couvrant le décodage d'un modèle comportant une relation de type `@Parent`.

Même si la structure du DTO est strictement identique au modèle conforme à `Codable`, le déclarer comme type séparé peut aider de gros projets à rester organisés. Si vous veniez à devoir changer les propriétés de votre modèle, vous n'auriez pas à vous soucier de casser votre API publique. Vous pourriez également définir vos DTO dans un package séparé que vous pourriez partager avec les clients de votre API, et ajouter la conformité à `Content` dans votre application Vapor.

## Alias

Le protocole `ModelAlias` vous permet d'identifier de façon unique un même modèle utilisé plusieurs fois dans la même requête. Plus d'informations sont disponibles dans la section sur les [jointures](query.md#jointures). 

## Enregistrement

Pour enregistrer un modèle dans la base, utilisez la méthode `save(on:)`.

```swift
planet.save(on: database)
```

Cette méthode appellera `create` ou `update` en interne, en fonction de si le modèle existe déjà en base de données ou non.

### Création

Vous pouvez utiliser la méthode `create` pour enregistrer un nouveau modèle en base de données.

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` est également disponible sur les tableaux de modèles. Cela enregistre tout les modèles en base de données en un seul lot / une seule requête.

```swift
// Exemple de lot à créer.
[earth, mars].create(on: database)
```

!!! Avertissement
    Les modèles qui utilisent [`@ID(custom:)`](#identifiant-personnalisé) avec le générateur `.database` (souvent un `Int` en auto-incrément) n'auront pas leur identifiant nouvellement créé accessible juste après la création par lot. Si vous avez besoin d'accéder à cet identifiant juste après, appelez `create` sur chaque modèle.

Pour une création séparée de chaque modèle du tableau, utilisez `map` + `flatten`.

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

Ou si vous utilisez la syntaxe `async`/`await` :

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### Mise à jour

Vous pouvez utiliser la méthode `update` pour enregistrer un modèle précédemment récupéré depuis la base de données.

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

Pour mettre à jour un tableau de modèles, utilisez `map` + `flatten`.

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TODO
```

## Query

Les modèles exposent la méthode statique `query(on:)` qui retourne un QueryBuilder. 

```swift
Planet.query(on: database).all()
```

Vous en apprendrez d'avantage sur les requêtes dans la [section dédiée](query.md).

## Find

Les modèles exposent la méthode statique `find(_:on:)` pour chercher une instance de modèle par son identifiant.

```swift
Planet.find(req.parameters.get("id"), on: database)
```

Cette méthode retourne `nil` si aucune correspondance n'est trouvée pour cet identifiant.

## Cycle de vie

Le ModelMiddleware vous permet d'écouter  les évènements du cycle de vie de votre modèle pour y exécuter votre propre logique. Les évènements suivants sont disponibles :

|Methode|Description|
|-|-|
|`create`|S'exécute avant la création du modèle.|
|`update`|S'exécute avant la mise à jour du modèle.|
|`delete(force:)`|S'exécute avant la suppression du modèle.|
|`softDelete`|S'exécute avant le mise en suppression douce du modèle.|
|`restore`|S'exécute avant la restauration d'un modèle en état de suppression douce.|

Un ModelMiddleware se déclare en utilisant les protocoles `ModelMiddleware` ou `AsyncModelMiddleware`. Chaque méthode du cycle de vie possède une implémentation par défaut, vous n'avez donc besoin d'implémenter que celles qui vous seront réellement utiles. Chaque méthode reçoit le modèle en question, une référence vers la base de données, et la prochaine action de la chaîne. Le middleware peut choisir de faire un retour anticipé, de retourner un futur compromis, ou d'appeler l'action suivante et continuer normalement.

Grâce à ces méthodes, vous pourrez exécuter des actions avant et/ou après l'évènement écouté. L'exécution d'actions à postériori peut se faire en mappant le futur retourné par le répondeur suivant de la chaîne.

```swift
// Exemple de middleware qui change la casse du nom.
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // Le modèle peut être modifié ici avant d'être créé.
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // Une fois la planète créée, ce code 
            // sera exécuté.
            print ("Planet \(model.name) was created")
        }
    }
}
```

Ou si vous utilisez `async`/`await` :

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyAsyncModelResponder) async throws {
        // Le modèle peut être modifié ici avant d'être créé.
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // Une fois la planète créée, ce code 
        // sera exécuté.
        print ("Planet \(model.name) was created")
    }
}
```

Une fois votre middleware créé, vous pouvez l'activer grâce à `app.databases.middleware`.

```swift
// Exemple de configuration de middleware de modèle.
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## Espace de base de données

Fluent permet de définir un espace pour chaque Model, ce qui permet le partitionnement de modèles individuels dans Fluent entre les schémas PostgreSQL, les bases de données MySQL, et de multiples bases de données SQLites associées. MongoDB ne propose pas la fonctionnalité d'espaces de bases de données au moment où cette documentation est écrite. Pour placer un modèle dans un autre espace que celui par défaut, ajoutez une nouvelle propriété statique au modèle :

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

Fluent l'utilisera pour toutes ses requêtes à la base de données. 
