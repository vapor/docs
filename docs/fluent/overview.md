# Fluent

Fluent is an [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) framework for Swift. It takes advantage of Swift's strong type system to provide an easy-to-use interface for your database. Using Fluent centers around the creation of model types which represent data structures in your database. These models are then used to perform create, read, update, and delete operations instead of writing raw queries.

## Configuration

When creating a project using `vapor new`, answer "yes" to including Fluent and choose which database driver you want to use. This will automatically add the dependencies to your new project as well as example configuration code.

### Existing Project

If you have an existing project that you want to add Fluent to, you will need to add two dependencies to your [package](../spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- One (or more) Fluent driver(s) of your choice

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

Once the packages are added as dependencies, you can configure your databases using `app.databases` in `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Each of the Fluent drivers below has more specific instructions for configuration.

### Drivers

Fluent currently has four officially supported drivers. You can search GitHub for the tag [`fluent-driver`](https://github.com/topics/fluent-driver) for a full list of official and third-party Fluent database drivers.

#### PostgreSQL

PostgreSQL is an open source, standards compliant SQL database. It is easily configurable on most cloud hosting providers. This is Fluent's **recommended** database driver.

To use PostgreSQL, add the following dependencies to your package.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Once the dependencies are added, configure the database's credentials with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(.postgres(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .psql)
```

You can also parse the credentials from a database connection string.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite is an open source, embedded SQL database. Its simplistic nature makes it a great candidate for prototyping and testing.

To use SQLite, add the following dependencies to your package.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Once the dependencies are added, configure the database with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

You can also configure SQLite to store the database ephemerally in memory.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

If you use an in-memory database, make sure to set Fluent to migrate automatically using `--auto-migrate` or run `app.autoMigrate()` after adding migrations.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip
    The SQLite configuration automatically enables foreign key constraints on all created connections, but does not alter foreign key configurations in the database itself. Deleting records in a database directly, might violate foreign key constraints and triggers.

#### MySQL

MySQL is a popular open source SQL database. It is available on many cloud hosting providers. This driver also supports MariaDB.

To use MySQL, add the following dependencies to your package.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0-beta")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Once the dependencies are added, configure the database's credentials with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

You can also parse the credentials from a database connection string.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

To configure a local connection without SSL certificate involved, you should disable certificate verification. You might need to do this for example if connecting to a MySQL 8 database in Docker.

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

!!! warning
    Do not disable certificate verification in production. You should provide a certificate to the `TLSConfiguration` to verify against. 

#### MongoDB

MongoDB is a popular schemaless NoSQL database designed for programmers. The driver supports all cloud hosting providers and self-hosted installations from version 3.4 and up.

!!! note
    This driver is powered by a community created and maintained MongoDB client called [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB maintains an official client, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), along with a Vapor integration, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

To use MongoDB, add the following dependencies to your package.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Once the dependencies are added, configure the database's credentials with Fluent using `app.databases.use` in `configure.swift`.

To connect, pass a connection string in the standard MongoDB [connection URI format](https://docs.mongodb.com/master/reference/connection-string/index.html).

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Models

Models represent fixed data structures in your database, like tables or collections. Models have one or more fields that store codable values. All models also have a unique identifier. Property wrappers are used to denote identifiers and fields as well as more complex mappings mentioned later. Take a look at the following model which represents a galaxy.

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"

    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?

    // The Galaxy's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Galaxy.
    init() { }

    // Creates a new Galaxy with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

To create a new model, create a new class conforming to `Model`.

!!! tip
    It's recommended to mark model classes `final` to improve performance and simplify conformance requirements.

The `Model` protocol's first requirement is the static string `schema`.

```swift
static let schema = "galaxies"
```

This property tells Fluent which table or collection the model corresponds to. This can be a table that already exists in the database or one that you will create with a [migration](#migrations). The schema is usually `snake_case` and plural.

### Identifier

The next requirement is an identifier field named `id`.

```swift
@ID(key: .id)
var id: UUID?
```

This field must use the `@ID` property wrapper. Fluent recommends using `UUID` and the special `.id` field key since this is compatible with all of Fluent's drivers.

If you want to use a custom ID key or type, use the [`@ID(custom:)`](model.md#custom-identifier) overload.

### Fields

After the identifier is added, you can add however many fields you'd like to store additional information. In this example, the only additional field is the galaxy's name.

```swift
@Field(key: "name")
var name: String
```

For simple fields, the `@Field` property wrapper is used. Like `@ID`, the `key` parameter specifies the field's name in the database. This is especially useful for cases where database field naming convention may be different than in Swift, e.g., using `snake_case` instead of `camelCase`.

Next, all models require an empty init. This allows Fluent to create new instances of the model.

```swift
init() { }
```

Finally, you can add a convenience init for your model that sets all of its properties.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Using convenience inits is especially helpful if you add new properties to your model as you can get compile-time errors if the init method changes.

## Migrations

If your database uses pre-defined schemas, like SQL databases, you will need a migration to prepare the database for your model. Migrations are also useful for seeding databases with data. To create a migration, define a new type conforming to the `Migration` or `AsyncMigration` protocol. Take a look at the following migration for the previously defined `Galaxy` model.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

The `prepare` method is used for preparing the database to store `Galaxy` models.

### Schema

In this method, `database.schema(_:)` is used to create a new `SchemaBuilder`. One or more `field`s are then added to the builder before calling `create()` to create the schema.

Each field added to the builder has a name, type, and optional constraints.

```swift
field(<name>, <type>, <optional constraints>)
```

There is a convenience `id()` method for adding `@ID` properties using Fluent's recommended defaults.

Reverting the migration undoes any changes made in the prepare method. In this case, that means deleting the Galaxy's schema.

Once the migration is defined, you must tell Fluent about it by adding it to `app.migrations` in `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrate

To run migrations, call `vapor run migrate` from the command line or add `migrate` as an argument to Xcode's Run scheme.


```
$ vapor run migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Querying

Now that you've successfully created a model and migrated your database, you're ready to make your first query.

### All

Take a look at the following route which will return an array of all the galaxies in the database.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

In order to return a Galaxy directly in a route closure, add conformance to `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` is used to create a new query builder for the model. `req.db` is a reference to the default database for your application. Finally, `all()` returns all of the models stored in the database.

If you compile and run the project and request `GET /galaxies`, you should see an empty array returned. Let's add a route for creating a new galaxy.

### Create


Following RESTful convention, use the `POST /galaxies` endpoint for creating a new galaxy. Since models are codable, you can decode a galaxy directly from the request body.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    See [Content &rarr; Overview](../content.md) for more information about decoding request bodies.

Once you have an instance of the model, calling `create(on:)` saves the model to the database. This returns an `EventLoopFuture<Void>` which signals that the save has completed. Once the save completes, return the newly created model using `map`.

If you're using `async`/`await` you can write your code as so:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

In this case, the async version doesn't return anything, but will return once the save has completed.

Build and run the project and send the following request.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

You should get the created model back with an identifier as the response.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Now, if you query `GET /galaxies` again, you should see the newly created galaxy returned in the array.


## Relations

What are galaxies without stars! Let's take a quick look at Fluent's powerful relational features by adding a one-to-many relation between `Galaxy` and a new `Star` model.

```swift
final class Star: Model, Content {
    // Name of the table or collection.
    static let schema = "stars"

    // Unique identifier for this Star.
    @ID(key: .id)
    var id: UUID?

    // The Star's name.
    @Field(key: "name")
    var name: String

    // Reference to the Galaxy this Star is in.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creates a new, empty Star.
    init() { }

    // Creates a new Star with all properties set.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

The new `Star` model is very similar to `Galaxy` except for a new field type: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

The parent property is a field that stores another model's identifier. The model holding the reference is called the "child" and the referenced model is called the "parent". This type of relation is also known as "one-to-many". The `key` parameter to the property specifies the field name that should be used to store the parent's key in the database.

In the init method, the parent identifier is set using `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

 By prefixing the parent property's name with `$`, you access the underlying property wrapper. This is required for getting access to the internal `@Field` that stores the actual identifier value.

!!! seealso
    Check out the Swift Evolution proposal for property wrappers for more information: [[SE-0258] Property Wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)

Next, create a migration to prepare the database for handling `Star`.


```swift
struct CreateStar: AsyncMigration {
    // Prepares the database for storing Star models.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

This is mostly the same as galaxy's migration except for the additional field to store the parent galaxy's identifier.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

This field specifies an optional constraint telling the database that the field's value references the field "id" in the "galaxies" schema. This is also known as a foreign key and helps ensure data integrity.

Once the migration is created, add it to `app.migrations` after the `CreateGalaxy` migration.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Since migrations run in order, and `CreateStar` references the galaxies schema, ordering is important. Finally, [run the migrations](#migrate) to prepare the database.

Add a route for creating new stars.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Create a new star referencing the previously created galaxy using the following HTTP request.

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

You should see the newly created star returned with a unique identifier.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

Now let's take a look at how you can utilize Fluent's eager-loading feature to automatically return a galaxy's stars in the `GET /galaxies` route. Add the following property to the `Galaxy` model.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

The `@Children` property wrapper is the inverse of `@Parent`. It takes a key-path to the child's `@Parent` field as the `for` argument. Its value is an array of children since zero or more child models may exist. No changes to the galaxy's migration are needed since all the information needed for this relation is stored on `Star`.

### Eager Load

Now that the relation is complete, you can use the `with` method on the query builder to automatically fetch and serialize the galaxy-star relation.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

A key-path to the `@Children` relation is passed to `with` to tell Fluent to automatically load this relation in all of the resulting models. Build and run and send another request to `GET /galaxies`. You should now see the stars automatically included in the response.

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

## Next steps

Congratulations on creating your first models and migrations and performing basic create and read operations. For more in-depth information on all of these features, check out their respective sections in the Fluent guide.
