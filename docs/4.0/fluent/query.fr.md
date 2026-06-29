# Requêter des entités

L'API de requêtes de Fluent vous permet de créer, lire, mettre à jour, et supprimer des modèles de la base de données. Elle supporte le filtrage de résultats, les jointures, la segmentation, l'aggrégation, et d'autres fonctionnalités. 

```swift
// Exemple de l'API de requêtes de Fluent.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Les QueryBuilders sont liés à un type de modèle unique, et peuvent être instanciés par la méthode statique [`query`](model.md#query). Ils peuvent aussi être instanciés en passant le type de votre modèle à la méthode `query` d'un objet Database.

```swift
// Crée aussi un QueryBuilder.
database.query(Planet.self)
```

!!! Note
    Vous devez avoir la ligne `import Fluent` dans le fichier contenant vos requêtes pour que le compilateur voit toutes les fonctions d'aide exposées par Fluent.

## All

La méthode `all()` retourne un tableau de modèles.

```swift
// Récupère toutes les planètes.
let planets = try await Planet.query(on: database).all()
```

La méthode `all` supporte aussi la récupération d'un champ/colonne unique du résultat. 

```swift
// Récupère tous les noms de planètes.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

La méthode `first()` retourne un seul modèle optionnel. Si la requête donne plusieurs résultats, seul le premier est retourné. Si la requête n'a aucun résultat, `nil` est retourné. 

```swift
// Récupère la première planète dont le nom est Terre.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Terre")
    .first()
```

!!! Astuce
    Si vous utilisez des `EventLoopFuture`s, vous pouvez combiner cette méthode avec [`unwrap(or:)`](../basics/errors.md#abort) pour retourner un modèle non-optionnel ou lever une erreur. 

## Filtrage

La méthode `filter` vous permet de définir des règles pour limiter le nombre de résultats retournés. Il existe plusieurs surcharges de cette méthode. 

### Filtre par valeur

La méthode la plus utilisée, `filter` accepte une expression avec opérateur et valeur.

```swift
// Exemple de filtrage de champ par valeur.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Ces expressions à opérateur acceptent un key-path vers un champ de l'entité à gauche de l'opérateur, et une valeur à sa droite. La valeur fournie doit correspondre au type de celle attendue par le champ; elle sera liée à la requête qui en résulte. Les expressions de filtres sont fortement typées, permettant l'usage de la syntaxe à point en préfixe.

Voici la liste des opérateurs supportés : 

|Operator|Description|
|-|-|
|`==`|Égal à.|
|`!=`|Différent de.|
|`>=`|Supérieur ou égal à.|
|`>`|Strictement supérieur à.|
|`<`|Strictement inférieur à.|
|`<=`|Inférieur ou égal à.|

### Filtre par champ

La méthode `filter` permet de comparer deux champs entre eux. 

```swift
// Tous les utilisateurs qui ont un nom égal à leur prénom.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Le filtrage par champ supporte les mêmes opérateurs que ceux du [filtrage par valeur](#filtre-par-valeur).

### Filtre par sous-ensemble

La méthode `filter` peut permettre de vérifier si la valeur d'un champ est incluse dans un sous-ensemble de valeurs définies. 

```swift
// Toute planète de type "géante gazeuse" ou "petite rocheuse".
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

Le sous-ensemble de donné fourni peut être tout type `Collection` dont le type d'`Element` correspond au type de valeur du champ comparé.

Voici la liste des opérateurs valables pour les sous-ensembles : 

|Opérateur|Description|
|-|-|
|`~~`|Valeur incluse dans le sous-ensemble.|
|`!~`|Valeur non incluse dans le sous-ensemble.|

### Filtre contient

La méthode `filter` si une chaîne de caractères est présente dans un champ de type chaîne de caractères. 

```swift
// Toute planète dont le nom commence par la lettre M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Ces opérateurs ne sont disponibles que pour les champs dont la valeur est de type chaîne de caractères. 

Voici la liste des opérateurs de contenance de chaîne : 

|Opérateur|Description|
|-|-|
|`~~`|Contient la chaîne.|
|`!~`|Ne contient pas la chaîne.|
|`=~`|Commence par la chaîne.|
|`!=~`|Ne commence pas par la chaîne.|
|`~=`|Termine par la chaîne.|
|`!~=`|Ne termine pas par la chaîne.|

### Groupement de conditions

Par défaut, l'ensemble des filtres ajoutés à la requête devront correspondre à une ligne pour l'inclure dans le résultat. Le QueryBuilder permet de grouper des filtres où une seule condition est requise pour fournir un résultat. 

```swift
// Toute planète nommée Terre ou Mars.
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Terre").filter(\.$name == "Mars")
}.all()
```

La méthode `group` permet des combinaisons de filtres avec les logiques `and` ou `or`. Vous pouvez imbriquer ces groupes à souhait. Des filtres ajoutés au niveau racine peuvent être considérés comme un groupe `and`.

## Aggrégation de données

Le QueryBuilder supporte différentes méthodes de calcul sur des lots de données, comme compter ou calculer une moyenne. 

```swift
// Nombre de planètes dans la base de données. 
Planet.query(on: database).count()
```

Toutes les méthodes d'aggrégation autres que `count` ont besoin de revoir une valeur key-path vers un champ.

```swift
// Le plus petit nom par ordre alphabétique.
Planet.query(on: database).min(\.$name)
```

Voici la liste des méthodes d'aggrégation disponibles :

|Méthode|Description|
|-|-|
|`count`|Nombre de résultats.|
|`sum`|Somme des valeurs du résultat.|
|`average`|Moyenne des valeurs du résultat.|
|`min`|Plus petite valeur du résultat.|
|`max`|Plus grande valeur du résultat.|

Toutes les méthodes d'aggrégation à part `count` retournent le même type de données que celui du champ concerné. `count` retourne toujours un entier.

## Segmentation

Le QueryBuilder permet de retourner un résultat en plusieurs segments. Cela vous aide à maîtriser la consommation mémoire lors de la lecture de jeux de données importants.

```swift
// Récupère toutes les planètes par lots de 64 maximum.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Gestion du segment de planètes retourné.
}
```

La Closure fournie sera appelée zéro, une, ou plusieurs fois en fonction du nombre de résultats. Chaque élément retourné est de type `Result` et contient soit le modèle, soit une erreur liée au décodage de la ligne de données. 

## Sélection de champs

Par défaut, une requête lira tous les champs du modèle. Vous pouvez ne sélectionner que certains champs grâce à la méthode `field`.

```swift
// Ne sélectionne que les champs id et name des planètes.
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Tout champ de modèle qui n'a pas été sélectionné lors de la requête restera en état non-initialisé. L'accès à un de ces champs causera une erreur fatale. Pour vérifier si la valeur d'un champ de modèle est définie, utilisez la propriété `value`. 

```swift
if let name = planet.$name.value {
    // Le nom a été récupéré.
} else {
    // Le nom n'a pas été récupéré.
    // Accéder à `planet.name` échouera.
}
```

## Unique

La méthode `unique` du QueryBuilder ne retournera que des résultats distincts, sans duplicata. 

```swift
// Retourne la liste des prénoms des utilisateurs, sans doublons. 
User.query(on: database).unique().all(\.$firstName)
```

La méthode `unique` est particulièrement pratique lorsque vous récupérez un seul champ avec `all`. Cependant, vous pouvez sélectionner plusieurs champs via la méthode [`field`](#sélection-de-champs). Puisque les identifiants de modèles sont toujours uniques, vous devriez éviter de les sélectionner lorsque vous utilisez la méthode `unique`. 

## Portée

La méthode `range` du QueryBuilder vous permet de sélectionner un sous-ensemble du résultat grâce à la syntaxe `range` de Swift.

```swift
// Récupère les 5 premières planètes.
Planet.query(on: self.database)
    .range(..<5)
```

Les valeurs de la portée sont des entiers non signés commençant à zéro. Plus d'infos sur le type [Swift range](https://developer.apple.com/documentation/swift/range).

```swift
// Saute les 2 premiers résultats.
.range(2...)
```

## Jointures

La méthode `join` du QueryBuilder vous permet d'inclure des champs en provenance d'un autre modèle dans vos résultats. Vous pouvez joindre plusieurs modèles dans vos requêtes. 

```swift
// Récupère toute les planètes liées à une étoile nommée Soleil.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Soleil")
    .all()
```

Le paramètre `on` s'attend à recevoir une expression d'égalité entre deux champs. Un des champs doit exister sur le modèle requêté. L'autre champ doit exister sur le modèle joint. Les deux champs doivent avoir une valeur du même type.

La plupart des méthodes du QueryBuilder, comme `filter` et `sort`, fonctionnent sur des modèles joints. Pour les méthodes compatibles avec ces jointures, il faudra passer le type du modèle joint en tant que premier paramètre. 

```swift
// Tri des résultats en fonction du champ "name" provenant du modèle Star joint.
.sort(Star.self, \.$name)
```

Les requêtes à jointures retourneront toujours un tableau des modèles de base. Pour accéder aux modèles joints, utilisez la méthode `joined`.

```swift
// Accès à un modèle joint depuis un résultat de requête.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Les alias de modèles vous permettent de faire une jointure sur le même modèle plusieurs fois dans une requête. Pour déclarer un alias de modèle, créez un ou plusieurs types conformes à `ModelAlias`. 

```swift
// Exemples d'alias de modèles pour des équipes de sport (modèle Team).
// HomeTeam représente une équipe jouant à domicile.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
// AwayTeam représente une équipe jouant à l'extérieur.
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Ces types référencent le modèle pour lequel l'alias est créé via la propriété `model`. Une fois définis, vous pouvez utiliser vos alias de modèles comme des modèles normaux dans le QueryBuilder.

```swift
// Cherche tous les résultats des matchs où l'équipe qui joue à domicile est Vapor,
// en classant par le nom de l'équipe qui joue à l'extérieur.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Tous les champs des modèles sont accessibles via le type alias du modèle grâce à `@dynamicMemberLookup`.

```swift
// Accès aux modèles joints depuis les résultats obtenus.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Mise à jour

Le QueryBuilder permet la mise à jour de plus d'un modèle à la fois grâce à la méthode `update`.

```swift
// Met à jour toutes les planètes nommées "Pluton"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluton")
    .update()
```

`update` est compatible avec les méthodes `set`, `filter`, et `range`. 

## Suppression

Le QueryBuilder permet la suppression de plus d'un modèle à la fois grâce à la méthode `delete`.

```swift
// Supprime toutes les planètes nommées "Vulcain"
Planet.query(on: database)
    .filter(\.$name == "Vulcain")
    .delete()
```

`delete` est compatible avec la méthode `filter`.

## Pagination

L'API de requêtes de Fluent permet la pagination automatique des résultats grâce à la méthode `paginate`. 

```swift
// Exemple de pagination basée sur la requête HTTP.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

La méthode `paginate(for:)` utilisera les paramètres `page` et `per` disponibles dans l'URI de la requête HTTP pour retourner le lot de résultats demandé. Les métadonnées de la page actuelle et du nombre total de résultats de la requête sont incluses sous la clé `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

La requête ci-dessus vous retournerait une réponse structurée comme ceci :

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Le numéro de page commence à `1`. Vous pouvez aussi configurer la pagination dans le code grâce à l'objet `PageRequest` :

```swift
// Pagination avec objet PageRequest
.paginate(PageRequest(page: 1, per: 2))
```

## Tri

Les résultats de requête peuvent être triés par valeur de champs grâce à la méthode `sort`.

```swift
// Récupère les planètes, triées par leur nom.
Planet.query(on: database).sort(\.$name)
```

Des règles de tri additionnelles peuvent être ajoutées en cas d'égalité sur un champ. Le tri se fait par ordre d'ajout au QueryBuilder.

```swift
// Récupère les utilisateurs triés par leur nom. Si deux utilisateurs ont le même nom, ils sont ensuite triés par leur âge.
User.query(on: database).sort(\.$name).sort(\.$age)
```
