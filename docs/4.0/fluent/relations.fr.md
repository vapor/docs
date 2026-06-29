# Relations

L'[API Modèle](model.md) de Fluent vous aide à créer et maintenir des relations entre vos modèles. Trois types de relations vous sont proposées :

- [Parent](#parent) / [Enfant](#optional-child) (1 à 1)
- [Parent](#parent) / [Enfants](#children) (1 à n)
- [N à n](#n-à-n)

## Parent

La relation `@Parent` stoque une référence vers la propriété `@ID` d'un autre modèle.

```swift
final class Planet: Model {
    // Exemple d'une relation vers une entité parente.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` contient un champ `@Field` nommé `id` utilisé pour définir et mettre à jour la relation.

```swift
// Définit l'identifiant de la relation au parent.
earth.$star.id = sun.id
```

Pour exemple, l'initialiseur du modèle `Planet` pourrait ressembler à ceci :

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

Le paramètre `key` définit la clé du champ (le nom de colonne) utilisé pour stoquer l'identifiant du parent. Si l'on admet que `Star` possède un identifiant de type `UUID`, cette relation `@Parent` est compatible avec la [définition de champ](schema.md#champ) suivante :

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Veuillez noter que la contrainte [`.references`](schema.md#contraintes-de-champ) est facultative. Référez-vous au chapitre [schéma](schema.md) pour de plus amples informations.

### Optional Parent

La relation `@OptionalParent` stoque une référence optionnelle à la propriété `@ID` d'un autre modèle. Elle fonctionne d'une façon similaire à `@Parent` mais permet à la relation d'avoir la valeur `nil`.

```swift
final class Planet: Model {
    // Exemple d'une relation parent optionnelle.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

La définition du champ est semblable à celle de `@Parent`, sauf que la contrainte `.required` doit être omise.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Encodage et décodage de parents

Un point d'attention lorsque vous travaillez avec des relations de type `@Parent` est la façon dont vous les envoyez ou recevez. Par exemple, en JSON, le `@Parent` d'un modèle `Planet` pourrait avoir cette forme :

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

Remarquez comme la propriété `star` est définie comme un objet, plutôt qu'un simple champ identifiant. Lors de l'envoi du modèle dans le corps d'une requête HTTP, le format doit avoir cette même forme pour que le décodage fonctionne. C'est pour cette raison que nous vous encourageons fortement à utiliser des DTO pour représenter vos modèles lorsqu'ils transitent sur le réseau. Par exemple :

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

Vous pourrez ensuite décoder le DTO et le convertir en modèle :

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

Le même principe s'applique pour retourner votre modèle aux clients. Vos clients doivent soit gérer les structures imbriquées, soit vous devrez convertir votre modèle en DTO avant de le retourner. Pour plus de détails sur les DTOs, voir la [documentation sur les Modèles](model.md#data-transfer-object)

## Optional Child

La propriété `@OptionalChild` crée une relation 1 à 1 entre deux modèles. Elle ne stoque aucune valeur dans le modèle parent. 

```swift
final class Planet: Model {
    // Exemple d'une relation facultative vers un enfant.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

Le paramètre `for` prend une valeur key-path vers une relation de type `@Parent` ou `@OptionalParent`, qui référence ce modèle parent.

Un nouveau modèle peut être ajouté à cette relation grâce à la méthode `create`.

```swift
// Exemple d'ajout d'un nouveau modèle à une relation.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Cela définira l'identifiant du parent dans le modèle enfant automatiquement.

Puisque cette relation ne stoque aucune valeur, aucune entrée dans le schéma de la base de données n'est requise pour le modèle parent.

La nature 1 à 1 de la relation devrait être renforcée dans le schéma du modèle enfant par une contrainte `.unique` sur la colonne référençant le modèle parent.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Exemple de contrainte unique
    .unique(on: "planet_id")
    .create()
```
!!! Attention
    Omettre la contrainte unique sur le champ identifiant le parent dans le schéma de l'enfant peut causer des cas imprévisibles.
    S'il n'y a pas de contrainte d'unicité, la table enfant pourrait se retrouver dans un état où plusieurs lignes existeraient pour un parent donné; dans un tel cas, une propriété `@OptionalChild` ne saura toujours accéder qu'à un seul enfant à la fois, sans avoir moyen de contrôler lequel serait retourné. Si votre besoin est de stoquer plusieurs enfants pour un parent donné, utilisez plutôt `@Children`.

## Children

La propriété `@Children` crée une relation 1 à n entre deux modèles. Elle ne stoque aucune valeur dans le modèle parent. 

```swift
final class Star: Model {
    // Exemple d'une relation vers plusieurs enfants.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

Le paramètre `for` prend une valeur key-path vers une relation de type `@Parent` ou `@OptionalParent`, qui référence ce modèle parent. Dans notre cas présent, nous avons une référence vers la relation `@Parent` de l'[exemple précédent](#parent). 

De nouveaux modèles peuvent être ajoutés à cette relation grâce à la méthode `create`.

```swift
// Exemple d'ajout de nouveaux modèles à une relation.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Cela définira l'identifiant du parent sur le modèle enfant automatiquement.

Comme cette relation ne stoque aucune valeur, aucune entrée dans le schéma de base de données n'est requise. 

## N à n

La propriété `@Siblings` crée une relation n à n entre deux modèles. Elle accomplit cela par le biais d'un modèle tier appelé pivot.

Voyons un exemple de relation n à n entre les modèles `Planet` et `Tag`.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Exemple de modèle pivot.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

Tout modèle incluant un minimum de deux relations `@Parent`, une pour chaque modèle à lier, peut servir de pivot. Le modèle peut contenir des propriétés supplémentaires, comme son propre identifiant, ou même d'autres relations `@Parent`.

L'ajout d'une contrainte [unique](schema.md#unicité) au modèle pivot peut aider à éviter la duplication de données. Voir le chapitre [schéma](schema.md) pour plus d'informations.

```swift
// Interdit la duplication de relations.
.unique(on: "planet_id", "tag_id")
```

Une fois le pivot créé, utilisez la propriété `@Siblings` pour créer la relation. 

```swift
final class Planet: Model {
    // Exemple de relation n à n.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

La propriété `@Siblings` nécessite trois paramètres :

- `through`: Le type du modèle pivot.
- `from`: Une propriété Key-path indiquant la relation parente du pivot qui référence le modèle propriétaire.
- `to`: Une propriété Key-path indiquant la relation parente du pivot qui référence le modèle possédé.

La propriété `@Siblings` inverse définie dans le modèle lié vient compléter la relation.

```swift
final class Tag: Model {
    // Exemple de relation Siblings.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Rattachement de relation n à n

La propriété `@Siblings` a des méthodes pour ajouter des retirer des modèles de la relation. 

Utilisez la méthode `attach()` pour ajouter un ou plusieurs modèles à la relation. Les modèles pivots sont créés et enregistrés automatiquement au besoin. Une Closure de rappel peut être déclarée pour remplir des propriétés supplémentaires pour chaque pivot créé :

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Ajout du modèle à la relation.
try await earth.$tags.attach(inhabited, on: database)
// Remplissage des attributs supplémentaires du pivot lors de l'établissement de la relation.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Ajout de mutliples modèles avec attributs de pivot à la relation.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Lors de l'ajout d'un modèle unique à la relation, vous pouvez utiliser le paramètre `method` pour définir s'il faut vérifier la relation avant de la créer.

```swift
// Ne fera le lien que si la relation n'existe pas encore.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Utilisez la méthode `detach` pour supprimer un modèle de la relation. Cela supprime le modèle pivot correspondant.

```swift
// Supprime le modèle de la relation.
try await earth.$tags.detach(inhabited, on: database)
```

Vous pouvez vérifier si un modèle est lié à un autre grâce à la méthode `isAttached`.

```swift
// Vérifie si deux modèles sont liés.
earth.$tags.isAttached(to: inhabited)
```

## Get

Utilisez la méthode `get(on:)` pour récupérer la valeur de la relation. 

```swift
// Récupère toutes les planètes d'un soleil.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Ou

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Utilisez le paramètre `reload` pour définir si le modèle lié doit à nouveau être récupéré depuis la base de données s'il a déjà été récupéré auparavant. 

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Utilisez la méthode `query(on:)` sur une relation pour créer un QueryBuilder pour le modèle lié. 

```swift
// Récupère à partir d'un soleil, toutes ses planètes dont le nom commence par un M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Voir le chapitre [query](query.md) pour plus d'informations.

## Chargement anticipé

Le QueryBuilder de Fluent vous permet de pré-charger les relations d'un modèle lorsqu'il est récupéré depuis la base de données. Ce procédé s'appelle le chargement anticipé et vous permet d'accéder aux relations de façon synchrone sans avoir besoin d'appeler [`get`](#get) au préalable.

Pour charger une relation de façon anticipée, indiquez un key-path vers la relation à la méthode `with` du QueryBuilder. 

```swift
// Exemple de chargement anticipé.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` est accessible de façon synchrone ici
        // puisqu'on a anticipé son chargement.
        print(planet.star.name)
    }
}

// Ou

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` est accessible de façon synchrone ici
    // puisqu'on a anticipé son chargement.
    print(planet.star.name)
}
```

Dans l'exemple ci-dessus, une valeur key-path vers la relation [`@Parent`](#parent) nommée `star` est passée à `with`. Cela force le QueryBuilder à faire une requête supplémentaire une fois que toutes les planètes sont chargées pour récupérer les étoiles qui leurs sont liées. Les étoiles sont ensuite accessibles via la propriété `@Parent`. 

Chaque relation pré-chargée ne nécessite qu'une requête supplémentaire, peu importe le nombre de modèles retournés. Le chargement anticipé n'est possible qu'avec les méthodes `all` et `first` du QueryBuilder. 


### Chargement anticipé des ressources imbriquées

La méthode `with` du QueryBuilder vous permet le chargement anticipé des relations du modèle pour lequel vous faites une requête. Cependant, vous pouvez aussi pré-charger modèles liés à ceux liés au modèle de la première requête. 

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()

for planet in planets {
    // `star.galaxy` est accessible de façon synchrone ici 
    // grâce au chargement anticipé.
    print(planet.star.galaxy.name)
}
```

La méthode `with` accepte une Closure optionnelle en second paramètre. Cette Closure accepte un constructeur de chargement anticipé pour la relation choisie. Aucune limite ne restreint le niveau d'imbrication des ressources pouvant être chargées sur une requête. 

## Chargement anticipé différé

Pour les cas où vous avez déjà récupéré le modèle parent et souhaitez charger une de ses relations, vous pouvez utiliser la méthode `get(reload:on:)`. Cela chargera les modèles liés depuis la base de données (ou le cache s'il existe) et vous permettra d'y accéder depuis ses propriétés.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Ou

try await planet.$star.get(on: database)
print(planet.star.name)
```

Si vous voulez forcer vos données à être récupérées depuis la base de données et non un cache, utilisez le paramètre `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

Pour vérifier qu'une relation a été chargée, utilisez la propriété `value`.

```swift
if planet.$star.value != nil {
    // La relation est chargée.
    print(planet.star.name)
} else {
    // La relation n'est pas chargée.
    // Tout tentative d'accès à planet.star échouera.
}
```

Si vous avez déjà le modèle lié dans une autre variable, vous pouvez manuellement définir la relation grâce à la propriété `value` sus-mentionnée.

```swift
planet.$star.value = star
```

Cela attachera le modèle lié à son parent comme s'il avait été pré-chargé ou chargé de façon différée sans exécuter de requêtes supplémentaires vers la base de données.
