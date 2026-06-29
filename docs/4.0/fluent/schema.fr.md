# Schéma

L'API schéma de Fluent vous permet de créer et mettre à jour le schéma de votre base de données via le code. C'est souvent utilisé de paire avec les [migrations](migration.md) pour préparer la base de données à recevoir vos [modèles](model.md).

```swift
// Exemple de l'API schéma de Fluent
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Pour créer un objet `SchemaBuilder`, utilisez la méthode `schema` sur votre objet base de données. Passez en paramètre le nom de la table ou collection que vous souhaitez modifier. Si vous modifiez le schéma d'un modèle, assurez vous que ce nom corresponde à la propriété [`schema`](model.md#schéma) du modèle en question.

## Actions

L'API schéma permet de créer, mettre à jour, et supprimer des schémas. Chaque action supporte un sous-ensemble de méthodes fournies par l'API.

### Création

Appeler la méthode `create()` créera une nouvelle table ou collection dans la base de données. Toutes les méthodes pour définir de nouveaux champs et contraintes sont supportées. Les méthodes liées à la mise à jour ou suppression sont ignorées.

```swift
// Exemple de création de schéma.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Si une table ou collection existe déjà pour le nom choisi, une erreur sera levée. Pour ignorer ce cas, utilisez `.ignoreExisting()`.

### Mise à jour

Appeler `update()` mettra à jour la table ou collection en base de données. Toutes les méthodes pour créer, mettre à jour, et supprimer des champs ou contraintes sont supportées.

```swift
// Exemple de mise à jour de schéma.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Suppression

Appeler `delete()` supprime une table ou collection existante de la base de données. Aucune autre méthode n'est supportée.

```swift
// Exemple de suppression de schéma.
database.schema("planets").delete()
```

## Champ

Des champs peuvent être ajoutés au moment de la création ou de la modification d'un schéma.

```swift
// Ajoute un nouveau champ
.field("name", .string, .required)
```

Le premier paramètre est le nom du champ. Le nom doit correspondre à la clé utilisée sur la propriété du modèle associé. Le second paramètre est le [type de données](#types-de-données) du champ. Enfin, vous pouvez ajouter autant de [contraintes](#contraintes-de-champ) que vous le souhaitez, ou laisser le troisième paramètre vide.

### Types de données

Voici la liste des types de données supportées :

|Type Fluent|Type Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (recommandé)|
|`.date`|`Date` (sans information relative à l'heure)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Voir [dictionnaire](#dictionnaire)|
|`.array`|Voir [tableau](#tableau)|
|`.enum`|Voir [énumération](#énumération)|

### Contraintes de champ

Voici la liste de contraintes de champs supportées :

|Contrainte|Description|
|-|-|
|`.required`|Ne permet pas de valeurs à `nil`.|
|`.references`|Nécessite que la valeur de ce champ corresponde à une valeur du schéma référencé. Voir [clé étrangère](#clé-étrangère).|
|`.identifier`|Indique la clé primaire. Voir [identifiant](#identifiant).|
|`.sql(SQLColumnConstraintAlgorithm)`|Définit toute contrainte qui ne soit pas encore supportée par Fluent (comme `default`). Voir [SQL](#sql) et [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/).|

### Identifiant

Si votre modèle utilise une propriété `@ID` standard, vous pouvez utiliser la méthode `id()` pour créer son champ correspondant. Cela utilise la clé de champ spécifique `.id` et le type de données `UUID`.

```swift
// Ajoute le champ identifiant par défaut.
.id()
```

Pour les types d'identifiants personnalisés, vous devrez déclarer le champ manuellement.

```swift
// Ajoute le champ pour un identifiant personnalisé.
.field("id", .int, .identifier(auto: true))
```

La contrainte `.identifier` peut s'appliquer sur un champ unique et indiquera la clé primaire. Le drapeau `auto` définira si la base de données doit générer les valeurs automatiquement.

### Mise à jour

Vous pouvez changer le type de données d'un champ via `updateField`.

```swift
// Change le type de données du champ en `double`.
.updateField("age", .double)
```

Voir le chapitre [avancé](advanced.md#sql) pour plus d'informations sur les mises à jour de schéma avancées.

### Suppression

Vous pouvez supprimer un champ d'un schéma avec `deleteField`.

```swift
// Supprime le champ "age".
.deleteField("age")
```

## Contraintes

Les contraintes peuvent être ajoutées lors de la création ou mise à jour d'un schéma. Contrairement aux [contraintes de champs](#contraintes-de-champ), les contraintes au niveau racine peuvent affecter plusieurs champs.

### Unicité

La contrainte d'unicité force à n'avoir aucun duplicata de valeur sur un ou plusieurs champs.

```swift
// Empêche d'avoir la même adresse e-mail sur plusieurs enregistrements.
.unique(on: "email")
```

Si la contrainte liste plusieurs champs, la combinaison précise de la valeur de chaque champ doit être unique.

```swift
// Empêche d'avoir plusieurs utilisateurs avec la même combinaison de nom de famille et prénom.
.unique(on: "first_name", "last_name")
```

Pour supprimer une contrainte d'unicité, utilisez `deleteUnique`.

```swift
// Supprime la contrainte d'unicité des e-mails.
.deleteUnique(on: "email")
```

### Nom de contrainte

Fluent génère automatiquement des noms de contraintes uniques par défaut. Cependant, si vous souhaitez leur donner un nom personnalisé, vous pouvez utiliser le paramètre `name`.

```swift
// Empêche d'avoir des doublons d'adresses e-mail.
.unique(on: "email", name: "no_duplicate_emails")
```

Pour supprimer une contrainte nommée, vous devez utiliser `deleteConstraint(name:)`.

```swift
// Supprime la contrainte d'unicité des e-mails.
.deleteConstraint(name: "no_duplicate_emails")
```

## Clé étrangère

Une contrainte de clé étrangère force les valeurs d'un champ à correspondre à une des valeurs du champ référencé. Cela sert particulièrement pour éviter d'enregistrer des données non valides. Les contraintes de clés étrangères peuvent être ajoutées soit au niveau du champ, soit en contrainte au niveau racine.

Pour ajouter une contrainte clé étrangère sur un champ, utilisez `.references`.

```swift
// Exemple d'ajout d'une contrainte clé étrangère sur un champ.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

La contrainte ci-dessus force les valeurs du champ "star_id" à correspondre à une des valeurs du champ "id" du schéma stars.

Cette même contrainte pourrait être ajoutée au niveau racine via `foreignKey`.

```swift
// Exemple d'ajout de clé étrangère au niveau racine.
.foreignKey("star_id", references: "stars", "id")
```

Contrairement aux contraintes de champs, les contraintes racines peuvent être ajoutées lors d'une mise à jour du schéma. Elles peuvent aussi être [nommées](#nom-de-contrainte).

Les contraintes clé étrangère supportent les actions optionnelles `onDelete` et `onUpdate`.

|Action de clé étrangère|Description|
|-|-|
|`.noAction`|Évite les violations de clé étrangère (comportement par défaut).|
|`.restrict`|Identique à `.noAction`.|
|`.cascade`|Propage la suppression via les clés étrangères.|
|`.setNull`|Définir le champ à null si la référence est rompue.|
|`.setDefault`|Définit le champ à sa valeur par défaut si la référence est rompue.|

Voici un exemple d'usage d'action sur une clé étrangère :

```swift
// Ajout d'une clé étrangère à la racine.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! Avertissement
    Les actions de clé étrangèrent se passent entièrement en base de données, sans passer par Fluent.
    Cela implique que des choses comme le ModelMiddleware ou la suppression douce pourraient ne pas fonctionner correctement.

## SQL

Le paramètre `.sql` vous permet d'ajouter du SQL arbitraire à vos schémas. C'est utile pour l'ajout de types de données ou contraintes spécifiques.
Un cas d'usage courant est la définition d'une valeur par défaut pour un champ :

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

ou une valeur par défaut pour un timestamp :

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionnaire

Le type de données dictionnaire permet de stoquer des valeurs de dictionnaire imbriquées. Cela inclue les structs qui se conforment à `Codable` et les dictionnaires Swift avec une valeur `Codable`.

!!! Note
    Les pilotes de bases de données SQL de Fluent stoquent les dictionnaires imbriqués dans des colonnes JSON.

Prenez la struct `Codable` suivante :

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Puisque cette struct `Pet` représentant un animal de compagnie est `Codable`, on peut la stoquer dans un champ `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

Ce champ peut être stoqué avec le type de données `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Puisque les types `Codable`s sont des dictionnaires hétérogènes, on ne renseigne pas le paramètre `of`.

Si les valeurs de dictionnaire étaient homogènes, par exemple `[String: Int]`, le paramètre `of` préciserait le type des valeurs :

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Les clés de dictionnaire doivent toujours être de type string.

## Tableau

Le type tableau permet le stoquage de tableaux imbriqués. Ça couvre les tableaux Swift contenant des valeurs `Codable`s comme les types `Codable`s utilisant un conteneur sans clés.

Prenez le champ `@Field` suivant qui stoque un tableau de strings :

```swift
@Field(key: "tags")
var tags: [String]
```

Ce champ peut être stoqué avec le type `.array(of:)` :

```swift
.field("tags", .array(of: .string), .required)
```

Puisque le tableau est homogène, on précise le paramètre `of`.

Les objets `Array` de Swift conformes à Codable auront toujours un type de valeur homogène. Les types personnalisés conformes à `Codable` qui sérialisent des valeurs hétérogènes vers des conteneurs sans clés représentent l'exception et devraient utiliser le type `.array`.

## Énumération

Le type énumération peut stoquer nativement des enums Swift à valeurs de type string. Les énumérations natives en base de données ajoutent une couche sécurisante de typage fort à votre base de données et peuvent avoir de meilleures performances que des enums brutes.

Pour définir une énumération native en base de données, utilisez la méthode `enum` exposée par `Database`. Utilisez `case` pour définir chaque valeur de l'énumération.

```swift
// Exemple de création d'une énumération.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Une fois l'énumération créée, vous pouvez utiliser la méthode `read()` pour générer le type de données pour votre champ de schéma.

```swift
// Exemple de lecture d'une énumération pour la définition d'un nouveau champ.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Ou

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Pour mettre à jour une énumération, appelez `update()`. On peut supprimer des valeurs d'une énumération existante.

```swift
// Exemple de mise à jour d'énumération.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Pour supprimer une énumération, appelez `delete()`.

```swift
// Exemple de suppression d'une énumération.
database.enum("planet_type").delete()
```

## Couplage de modèles

La construction de schéma est intentionnellement découplée des modèles. À l'inverse des constructions de requêtes, la construction de schéma ne s'appuie pas sur les key-paths est n'accepte que des chaînes de caractères. Ce point est important, puisque la définition de schéma, en particulier ceux écrits pour les migrations, peuvent avoir besoin de référencer des propriétés du modèle qui n'existent plus.

Pour mieux appréhender cela, observez l'exemple de migration suivant :

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Supposons que cette migration ait déjà été envoyée en production. Supposons maintenant que nous devions appliquer les modifications suivantes à notre modèle User :

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Nous pouvons faire les ajustements nécessaires au schéma de notre base de données avec la migration suivante :

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // Il n'est actuellement pas possible d'exprimer cette mise à jour sans utiliser de SQL personnalisé.
        // Nous n'essayons pas non plus de séparer le champ name en prénom et nom de famille,
        // car la syntaxe est spécifique à chaque base de données.
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

Veuillez noter que pour que cette migration fonctionne, nous avons besoin de pouvoir référencer et le champ `name` supprimé, et les champs `firstName` et `lastName` ajoutés dans la même migration. De plus, la migration originale `UserMigration` doit rester valide, ce qui serait impossible à réaliser avec des key-paths.

## Définir l'espace d'un modèle

Pour définir l'[espace d'un modèle](model.md#espace-de-base-de-données), passez le nom de l'espace à `schema(_:space:)` lors de la création de la table :

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
