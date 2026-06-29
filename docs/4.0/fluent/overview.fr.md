# Fluent ORM

Fluent est un framework [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) pour le langage Swift. Il tire parti du système fortement typé de Swift pour exposer une interface intuitive vers votre base de données. La philosophie de Fluent est axée sur la création de types modèles qui représentent la structure des données de votre base de données. Ces modèles sont ensuite utilisés pour exécuter des opérations de création, lecture, mise à jour et suppression plutôt que d'écrire des requêtes brutes.

## Configuration

### Nouveau projet

Lorsque vous créez un projet avec la commande `vapor new` (sans -n), répondez "yes" pour l'inclusion de Fluent et choisissez le driver de base de données que vous souhaitez utiliser. Cela installera les dépendances nécessaires pour votre projet, et ajoutera un exemple de code de configuration.

### Projet existant

Si vous souhaitez ajouter Fluent à un projet déjà existant, vous devrez ajouter au moins deux dépendances à votre [package](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Au moins un driver Fluent correspondant à votre (vos) base(s) de données

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

Une fois ces packages ajoutés à votre liste de dépendances, vous pouvez configurer vos bases de données via `app.databases` dans `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Chaque driver Fluent (détaillés ci-dessous) aura sa propre configuration à ajouter.

### Drivers

Fluent supporte actuellement quatre drivers. Vous les retrouverez sur GitHub en cherchant le tag [`fluent-driver`](https://github.com/topics/fluent-driver), qui liste les drivers officiels et tiers.

#### PostgreSQL

PostgreSQL est une base de données open source conforme aux normes SQL. Elle est aisément configurable chez la majorité des hébergeurs cloud. C'est le driver **recommandé** pour Fluent.

Pour utiliser PostgreSQL, ajoutez ces dépendances à votre package.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Une fois les dépendances ajoutées, configurez l'authentification de Fluent à votre de base de données avec `app.databases.use` dans `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

Vous pouvez également fournir ces informations au format chaîne de connexion de base de données.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite est une base de données SQL embarquée open source. Sa nature simpliste en fait un candidat parfait pour le prototypage et les tests.

Pour utiliser SQLite, ajoutez ces dépendances à votre package.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Ensuite, configurez cette base de données pour Fluent avec `app.databases.use` dans `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Vous pouvez aussi configurer SQLite pour stoquer la base de données en mémoire pour un usage éphémère.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Si vous utilisez une base de données en mémoire, assurez-vous de configurer Fluent pour qu'il lance automatiquement les migrations avec `--auto-migrate`, ou ajoutez `app.autoMigrate()` après l'ajout de vos migrations.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// ou
try await app.autoMigrate()
```

!!! Info
    La configuration SQLite active automatiquement les contraintes sur les clés étrangères pour chaque connexion établie, mais ne modifie pas les configurations de clés étrangères dans la base de données elle-même. Si vous effacez des lignes directement dans la base de données, vous pourriez enfreindre des contraintes ou triggers.

#### MySQL

MySQL est une base de données SQL open source populaire. De nombreux hébergeurs cloud la propose. Ce driver est aussi compatible avec MariaDB.

Pour utiliser MySQL, ajoutez ces dépendances à votre package.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Ensuite, configurez la connexion à la base de données via Fluent avec `app.databases.use` dans `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Vous pouvez aussi utiliser le format en chaîne de connection de base de données.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Pour configurer une connexion locale sans utiliser de certificat SSL, vous devriez désactiver la vérification de certificat. Vous pourriez par exemple en avoir besoin si vous connectez une instance MySQL 8 sous Docker.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! Attention
    Ne désactivez pas la vérification de certificat en production. Vous devriez fournir un certificat à `TLSConfiguration` afin qu'il puisse effectuer les vérifications nécessaires. 

#### MongoDB

MongoDB est une base de données NoSQL populaire conçue pour les développeurs. Le driver est compatible avec tous les hébergeurs cloud et installations auto-hébergées à partir de la version 3.4.

!!! Note
    Ce driver s'appuie sur un client MongoDB créé et maintenu par la communauté, [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB maintient un client officiel, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), ainsi qu'une intégration Vapor, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Pour utiliser MongoDB, ajoutez ces dépendance à votre package.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Ensuite, configurez la connection via Fluent avec `app.databases.use` dans `configure.swift`.

Utilisez le format chaîne de connexion standard de MongoDB [documenté ici](https://docs.mongodb.com/docs/manual/reference/connection-string/).

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Modèles

Les modèles représentent des structures de données fixes de votre base de données, comme des tables ou collections. Les modèles ont un ou plusieurs champs qui stoquent des valeurs codables. Tous les modèles ont également un identifiant unique. Des Property Wrappers sont utilisés pour déclarer les identifiants et champs, ainsi que des correspondances plus complexes que nous verrons par la suite. Observez le modèle suivant qui représente une galaxie.

```swift
final class Galaxy: Model {
    // Nom de la table ou collection.
    static let schema = "galaxies"

    // Identifiant unique de cette galaxie.
    @ID(key: .id)
    var id: UUID?

    // Nom de la galaxie
    @Field(key: "name")
    var name: String

    // Crée une nouvelle galaxie vide.
    init() { }

    // Crée une nouvelle galaxie avec toutes ses propriétés initialisées.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Pour créer un nouveau modèle, créez une nouvelle classe qui se conforme à `Model`.

!!! Conseil
    Il est recommandé d'utiliser `final` pour vos classes de modèles, afin d'augmenter les performances et faciliter la conformité aux exigences du protocole.

La première exigence du protocole `Model` est la chaîne statique `schema`.

```swift
static let schema = "galaxies"
```

Cette propriété indique à Fluent quelle table ou collection correspond à ce modèle. Il peut s'agir d'une table qui existe déjà dans votre base de données ou bien que vous créerez avec une [migration](#migrations). Le schéma s'écrit communément en `snake_case` et au pluriel.

### Identifiant

L'exigence suivante est un champ d'identifiant nommé `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Ce champ doit utiliser le Property Wrapper `@ID`. Fluent recommande d'utiliser le type `UUID` et la clé de champ spéciale `.id` qui sont compatibles avec tous les drivers Fluent.

Si vous souhaitez utiliser un type ou une clé d'ID personnalisés, utilisez plutôt [`@ID(custom:)`](model.md#identifiant-personnalisé).

### Champs

Après avoir ajouté l'identifiant, vous pouvez définir autant de champs que vous désirez pour stoquer des informations additionnelles. Dans cet exemple, le seul champ additionnel est le nom de la galaxie.

```swift
@Field(key: "name")
var name: String
```

Pour des champs simples, le Property Wrapper `@Field` est utilisé. Tout comme `@ID`, le paramètre `key` indique le nom du champ en base de données. C'est particulièrement utile pour les cas où la convention de nommage diffère entre Swift et la base de données, comme l'usage de `snake_case` ou `camelCase`.

Ensuite, tout modèle a besoin d'un initialiseur vide. Cela permet à Fluent de créer de nouvelles instances du modèle.

```swift
init() { }
```

Enfin, vous pouvez définir un initialiseur pour votre modèle qui définit ses propriétés.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Cela sert particulièrement si vous ajoutez de nouvelles propriétés à votre modèle, car on obtient des erreurs à la compilation si la méthode init est modifiée.

## Migrations

Si votre base de données utilise des schémas pré-définis, comme c'est le cas pour les bases de données SQL, vous aurez besoin d'une migration pour préparer la base de données pour votre modèle. Les migrations sont aussi utiles pour injecter des données en base. Pour créer une migration, définissez un nouveau type qui se conforme au protocole `Migration` ou `AsyncMigration`. Observez la migration suivante correspondant au modèle `Galaxy` précédent :

```swift
struct CreateGalaxy: AsyncMigration {
    // Prépare la base de données pour le stoquage du modèle Galaxy.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // L'opération inverse est facultative, mais permet d'annuler les changements déclarés dans la méthode prepare.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

La méthode `prepare` permet de préparer la base de données à stoquer le modèle `Galaxy`.

### Schéma

Dans cette méthode, `database.schema(_:)` est utilisé pour créer un `SchemaBuilder`. Un ou plusieurs champs sont ensuite ajoutés grâce à  `field` avant l'appel à `create()`, qui va créer le schéma défini.

Chaque champ ajouté au builder possède un nom, un type, et des contraintes facultatives.

```swift
field(<name>, <type>, <optional constraints>)
```

La méthode `id()` ajoute le champ correspondant à la propriété annotée de `@ID` en utilisant les valeurs par défaut recommandées par Fluent.

Inverser la migration annulera les changements effectués par la méthode prepare. Dans ce cas, cela effacera le schéma galaxies.

Une fois la migration définie, vous devez en informer Fluent en l'ajoutant à `app.migrations` dans `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrer

Pour exécuter les migrations, lancez `swift run App migrate` en lignes de commande ou ajoutez `migrate` comme argument au scheme Xcode de App.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Requêter la base de données

Vous avez créé un modèle et exécuté sa migration sur votre base de données, vous êtes donc prêt pour lancer votre première requête avec Fluent.

### Tout récupérer

Observez la route suivante qui retournera un tableau de toutes les galaxies présentes dans votre base de données.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Pour retourner directement un objet Galaxy dans une Closure de route, vous devez ajouter une conformité à `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` sert à créer un objet QueryBuilder (contructeur de requête) pour le modèle. `req.db` est une référence vers la base de données par défaut de votre application. Enfin, `all()` retourne tous les modèles stoqués dans votre base de données.

Si vous compilez et lancez votre projet, et faites une requête HTTP `GET /galaxies`, vous devriez obtenir un tableau vide. Ajoutons une route pour créer une galaxie.

### Créer


Si l'on suit la convention RESTful, nous allons créer un endpoint `POST /galaxies` pour créer une nouvelle galaxie. Puisque les modèles sont codables, vous pouvez décoder une galaxie directement à partir du corps de la requête HTTP.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! Référence utile
    Voir [Décoder et encoder du contenu &rarr; Vue d'ensemble](../basics/content.md) pour plus d'informations sur le décodage des corps de requêtes.

Une fois que vous avez une instance de votre modèle, appeler `create(on:)` l'enregistrera dans la base de données. Cela retourne un `EventLoopFuture<Void>` qui signale la fin de l'enregistrement. Une fois enregistré, retournez-le avec `map`.

Si vous utilisez `async`/`await` vous pouvez rédiger votre code comme ceci :

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

Compilez et exécutez le projet, puis envoyez cette requête HTTP :

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Vous devriez obtenir pour réponse votre modèle nouvellement créé avec un identifiant associé.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Si maintenant vous appelez à nouveau `GET /galaxies`, vous devriez voir la galaxie créée qui vous est retournée dans un tableau.


## Relations

Que seraient des galaxies sans étoiles ! Voyons rapidement la puissante API de relations qu'offre Fluent en ajoutant une relation one-to-many entre `Galaxy` et un nouveau modèle, `Star`.

```swift
final class Star: Model, Content {
    // Nom de la table ou collection.
    static let schema = "stars"

    // Identifiant unique de cette étoile.
    @ID(key: .id)
    var id: UUID?

    // Nom de l'étoile.
    @Field(key: "name")
    var name: String

    // Référence vers la galaxie qui contient cette étoile.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Pour créer une nouvelle étoile vide.
    init() { }

    // Pour créer une nouvelle étoile avec ses propriétés.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

Le nouveau modèle `Star` est très similaire à `Galaxy` à l'exception d'un nouveau type de champ : `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

Une propriéré @Parent est un champ qui stoque l'identifiant d'un autre modèle. Le modèle qui définit la référence est appelé "enfant", et le modèle référencé est appelé "parent". Ce type de relation s'appelle notoirement "one-to-many". Le paramètre `key` définit le nom de la colonne à utiliser pour stoquer la clé du parent dans la table de l'enfant.

Dans la méthode init, l'identifiant du parent est défini via `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

En mettant le préfixe `$` sur la propriété référençant le parent, vous avez accès à l'objet PropertyWrapper associé. Cette syntaxe est nécessaire pour accéder à l'objet `@Field` interne qui stoque la valeur réelle de l'identifiant.

!!! A voir également
    Cette proposition sur l'évolution du langage Swift concernant les PropertyWrappers les explique plus en détail : [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

Ensuite, créez une migration pour préparer la base de données à accueillir vos objets `Star`.


```swift
struct CreateStar: AsyncMigration {
    // Prépare la base de données à stoquer le modèle Star.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // En option, implémentez l'opération inverse qui annule les changements effectués par la méthode prepare().
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Cette migration est quasiment identique à celles des galaxies, à l'exception du champ additionnel qui stoque l'identifiant de la galaxie parente.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Ce champ spécifie une contrainte optionnelle indiquant à la base de données que la valeur du champ pointe vers le champ "id" du schéma "galaxies". On appelle aussi ce champ une clé étrangère, qui aide a assurer l'intégrité des données.

Une fois la migration créée, ajoutez-la à `app.migrations` juste après la migration `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Comme les migrations sont lancées dans leur ordre d'ajout, et que `CreateStar` fait référence au schéma galaxies, leur ordre d'ajout est important. Enfin, [lancez les migrations](#migrer) pour préparer la base de données.

Ajoutez une route pour créer de nouvelles étoiles.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Créez une nouvelle étoile qui référence la galaxie précédemment ajoutée, grâce à la requête HTTP suivante.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

La route devrait vous retourner l'étoile nouvellement créée, avec son identifiant unique.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Enfants

Voyons maintenant comment utiliser le chargement anticipé (eager-loading) que propose Fluent pour récupérer automatiquement toutes les étoiles d'une galaxie dans la route `GET /galaxies`. Ajoutez cette propriété au modèle `Galaxy` :

```swift
// Toutes les étoiles de la galaxie.
@Children(for: \.$galaxy)
var stars: [Star]
```

L'objet PropertyWrapper `@Children` est l'opposé de `@Parent`. Il prend en paramètre `for` un key-path vers la propriété `@Parent` définie dans l'enfant. Sa valeur est un tableau d'objets enfants puisqu'il peut y avoir zéro ou plusieurs étoiles dans une galaxie. Aucun changement n'est requis dans la migration des galaxies puisque l'information nécessaire à cette relation est stoquée dans le modèle `Star`.

### Chargement anticipé

Une fois la relation définie, vous pouvez utiliser la méthode `with` du QueryBuilder pour récupérer et sérialiser automatiquement la relation galaxie-étoile.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Un key-path vers la relation `@Children` est passé à la méthode `with` pour indiquer à Fluent qu'il doit automatiquement inclure cette relation dans tout les résultats. Compilez et exécutez à nouveau votre application, puis faites une autre requête à `GET /galaxies`. Vous devriez désormais voir les étoiles inclues dans la réponse.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Journalisation des requêtes

Les drivers Fluent émettent des logs des requêtes SQL générées avec le niveau debug. Certains drivers, comme FluentPostgreSQL, vous permettent de configurer ce niveau de log au moment de la configuration de la connexion à votre base de données.

Pour configurer le niveau de log que votre application émettra, dans **configure.swift** (ou là où vous avez mis le code de configuration de votre application), ajoutez :

```swift
app.logger.logLevel = .debug
```

Cela indique que l'application émettre tout log défini avec le niveau debug ou supérieur. Lorsque vous compilerez et exécuterez votre application, les déclarations SQL générées par Fluent seront affichées sur la console.

## Pour aller plus loin

Bravo, vous avez créé vos premiers modèles et migrations, et avez exécuté des opérations de création et lecture simples. Pour obtenir des informations plus approfondies sur ces fonctionnalités, consultez leurs sections respectives du guide de Fluent.
