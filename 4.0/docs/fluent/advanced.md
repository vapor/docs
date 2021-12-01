# Advanced

Fluent strives to create a general, database-agnostic API for working with your data. This makes it easier to learn Fluent regardless of which database driver you are using. Creating generalized APIs can also make working with your database feel more at home in Swift. 

However, you may need to use a feature of your underlying database driver that is not yet supported through Fluent. This guide covers advanced patterns and APIs in Fluent that only work with certain databases.

## SQL

All of Fluent's SQL database drivers are built on [SQLKit](https://github.com/vapor/sql-kit). This general SQL implementation is shipped with Fluent in the `FluentSQL` module.

### SQL Database

Any Fluent `Database` can be cast to a `SQLDatabase`. This includes `req.db`, `app.db`, the `database` passed to `Migration`, etc. 

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

This cast will only work if the underlying database driver is a SQL database. Learn more about `SQLDatabase`'s methods in [SQLKit's README](https://github.com/vapor/sql-kit).

### Specific SQL Database

You can also cast to specific SQL databases by importing the driver. 

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

At the time of writing, the following SQL drivers are supported.

|Database|Driver|Library|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Visit the library's README for more information on the database-specific APIs.

### SQL Custom

Almost all of Fluent's query and schema types support a `.custom` case. This lets you utilize database features that Fluent doesn't support yet. 

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE supported.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE not supported.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

SQL databases support both `String` and `SQLExpression` in all `.custom` cases. The `FluentSQL` module provides convenience methods for common use cases.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // The underlying database driver is SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // The underlying database driver is _not_ SQL.
}
```

Below is an example of `.custom` via the `.sql(raw:)` convenience being used with the schema builder.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // The underlying database driver is MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // The underlying database driver is _not_ MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB is an integration between [Fluent](../fluent/overview.md) and the [MongoKitten](https://github.com/OpenKitten/MongoKitten/) driver. It leverages Swift's strong type system and Fluent's database agnostic interface using MongoDB.

The most common identifier in MongoDB is ObjectId. You can use this for your project using `@ID(custom: .id)`.
If you need to use the same models with SQL, do not use `ObjectId`. Use `UUID` instead.

```swift
final class User: Model {
    // Name of the table or collection.
    static let schema = "users"

    // Unique identifier for this User.
    // In this case, ObjectId is used
    // Fluent recommends using UUID by default, however ObjectId is also supported
    @ID(custom: .id)
    var id: ObjectId?

    // The User's email address
    @Field(key: "email")
    var email: String

    // The User's password stores as a BCrypt hash
    @Field(key: "password")
    var passwordHash: String

    // Creates a new, empty User instance, for use by Fluent
    init() { }

    // Creates a new User with all properties set.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Data Modelling

In MongoDB, Models are defined in the same as in any other Fluent environment. The main difference between SQL databases and MongoDB lies in relationships and architecture.

In SQL environments, it's very common to create join tables for relationships between two entities. In MongoDB, however, an array can be used to store related identifiers. Due to the design of MongoDB, it's more efficient and practical to design your models with nested data structures.

### Flexible Data

You can add flexible data in MongoDB, but this code will not work in SQL environments.
To create grouped arbitrary data storage you can use `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent cannot support strictly types queries on these values. You can use a dot notated key path in your query for querying.
This is accepted in MongoDB to access nested values.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### Raw Access

To access the raw `MongoDatabase` instance, cast the database instance to `MongoDatabaseRepresentable` as such:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

From here you can use all of the MongoKitten APIs.
