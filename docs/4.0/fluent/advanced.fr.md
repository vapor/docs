# Avancé

Fluent aspire à créer une API générique et non dépendante d'une base de données spécifique pour manipuler vos données. Cela facilite l'apprentissage de Fluent indépendamment du pilote que vous utilisez. Créer des API génériques rend également l'interaction à vos bases de données plus ancrée dans le langage Swift. 

Cependant, vous aurez peut-être besoin d'utiliser des fonctionnalités propres à votre pilote spécifique qui ne sont pas encore proposées par Fluent. Ce guide présente des APIs et usages avancés de Fluent qui ne sont compatibles qu'avec certaines bases de données.

## SQL

Tous les pilotes de bases de données SQL de Fluent sont construits sur [SQLKit](https://github.com/vapor/sql-kit). Cette implémentation SQL générique est intégrée à Fluent dans le module `FluentSQL`.

### Bases de données SQL

Tout objet `Database` de Fluent peut tenter d'être casté en `SQLDatabase`. Cela inclue les objets `req.db`, `app.db`, le paramètre `database` passé à un objet `Migration`, etc. 

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // Le pilote de base de données encapsulé est un pilote SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // Le pilote de base de données encapsulé n'est _pas_ un pilote SQL.
}
```

Le cast ne fonctionnera que si le pilote de base de données encapsulé par l'abstraction est un pilote de base de données SQL. Pour en apprendre plus sur les méthodes disponibles sur les objets `SQLDatabase`, veuillez vous référer au [README de SQLKit](https://github.com/vapor/sql-kit).

### Base de données SQL spécifique

Vous pouvez aussi caster vers un pilote SQL spécifique en l'important : 

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // Le pilote encapsulé est PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // Le pilote encapsulé n'est _pas_ PostgreSQL.
}
```

A l'heure où cette documentation est rédigée, voici les drivers SQL supportés :

|Base de données|Pilote|Librairie|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Référez-vous au README de chaque librairie pour plus d'informations sur les APIs spécifiques à chaque base de donnée.

### SQL personnalisé

Presque tous les types de schéma et requête de Fluent supportent le cas d'énumération `.custom`. Cela vous permet d'utiliser des fonctionnalités de votre base de données que Fluent ne propose pas encore. 

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE est supporté.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE n'est pas supporté.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

Les bases de données SQL supportent des objets `String` et `SQLExpression` dans chaque cas `.custom`. Le module `FluentSQL` fournit des méthodes de commodité pour les cas d'usage les plus courants.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // Le pilote encapsulé est de type SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // Le pilote encapsulé n'est _pas_ de type SQL.
}
```

Voici un exemple utilisant `.custom` via la méthode `.sql(raw:)` utilisée avec le SchemaBuilder :

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // Le pilote encapsulé est MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // Le pilote encapsulé n'est _pas_ MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB est une intégration entre [Fluent](../fluent/overview.md) et le pilote [MongoKitten](https://github.com/OpenKitten/MongoKitten/). Elle tire parti du système fortement typé de Swift et de l'interface de Fluent indépendante des bases de données pour utiliser MongoDB.

L'identifiant le plus commun dans MongoDB est ObjectId. Vous pouvez l'utiliser dans vos projets avec `@ID(custom: .id)`.
Si vous devez partager vos modèles avec SQL, n'utilisez pas `ObjectId`. Préférez `UUID` à la place.

```swift
final class User: Model {
    // Nom de la table ou collection.
    static let schema = "users"

    // Identifiant unique pour cet utilisateur (User).
    // Ici, on utilise ObjectId.
    // Fluent recommande d'utiliser UUID par défaut, mais ObjectId est aussi supporté.
    @ID(custom: .id)
    var id: ObjectId?

    // L'adresse e-mail de l'utilisateur.
    @Field(key: "email")
    var email: String

    // Le mot de passe de l'utilisateur stoqué en hash BCrypt.
    @Field(key: "password")
    var passwordHash: String

    // Crée une nouvelle instance vide de la classe User, utilisé en interne par Fluent.
    init() { }

    // Crée une nouvelle instance de la classe User avec ses propriétés définies.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Modélisation de données

Dans MongoDB, les modèles sont définis de la même façon que dans les autres environnements Fluent. La différence majeure entre des bases SQL et MongoDB se trouve dans les relations et l'architecture.

En environnement SQL, il est très courant d'utiliser des jointures de tables pour définir les relations entre deux entités. En MongoDB, cependant, on peut utiliser un tableau pour stoquer les ID liés. En raison de l'architecture de MongoDB relative aux problématiques auxquelles il apporte une solution, il est plus efficace et pratique de concevoir vos modèles avec des structures de données imbriquées.

### Flexibilité des données

En MongoDB, vous pouvez insérer des données à structure flexible, mais cela ne fonctionnera pas en environnement SQL.
Pour définir un stoquage de données arbitraires groupées, vous pouvez utiliser `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent ne peut pas supporter des requêtes fortement typées sur ces valeurs. Vous pouvez utiliser des key-paths avec la syntaxe à points pour vos requêtes.
Cette syntaxe est supportée dans MongoDB pour accéder aux valeurs imbriquées.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### Usage d'expressions régulières

Vous pouvez requêter MongoDB via le cas d'énumération `.custom()`, et lui passer une expression régulière. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) accepte des expression régulières compatibles avec Perl. 

Par exemple, vous pouvez requêter des caractères insensibles à la casse sous le champ `name` :

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Cela vous retournera les planètes contenant les caractères 'e' ou 'E' dans leur nom. Vous pouvez aussi créer d'autres RegEx complexes compatibles avec MongoDB.

### Accès brut

pour accéder à l'instance `MongoDatabase` brute, castez l'instance de base de données en `MongoDatabaseRepresentable` comme ceci :

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

A partir d'ici, vous pourrez accéder à toutes les APIs de MongoKitten.
