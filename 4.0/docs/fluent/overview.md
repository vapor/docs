# Fluent 

Fluent is an [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) framework for Swift. It takes advantage of Swift's strong type system to provide an easy-to-use interface for your database. Using Fluent centers around the creation of model types which represent data structures in your database. These models are then used to perform create, read, update, and delete operations instead of writing raw queries.

## Configuration

If you haven't added Fluent to your Vapor project or set it up yet, check out the [configuration](config.md) guide first. This guide assumes your app can already connect to a database.

## Models

Models represent fixed data structures in your database, like tables or collections. Models have one or more fields that store codable values. All models also have a unique identifier. Property wrappers are used to denote identifiers and fields as well as more complex mappings mentioned later. Take a look at the following model which represents a galaxy.

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"

    // Unique identifier for this Galaxy.
    @ID(key: "id")
    var id: Int?

    // The Galaxy's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Galaxy.
    init() { }

    // Creates a new Galaxy with all properties set.
    init(id: Int? = nil, name: String) {
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

This property tells Fluent which table or collection the model corresponds to. This can be a table that already exists in the database or one that you will create with a [migration](#migration). The schema is usually `snake_case` and plural.

### Identifier

The next requirement is an identifier field named `id`. 

```swift
@ID(key: "id")
var id: Int?
```

This field must use the `@ID` property wrapper where the `key` specifies the id field's name in the database. The value can be any Swift type that is both codable and hashable.

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
init(id: Int? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Using convenience inits is especially helpful if you add new properties to your model as you can get compile-time errors if the init method changes.

## Migrations

If your database uses pre-defined schemas, like SQL databases, you will need a migration to prepare the database for your model. Migrations are also useful for seeding databases with data. To create a migration, define a new type conforming to the `Migration` protocol. Take a look at the following migration for the previously defined `Galaxy` model.

```swift
struct CreateGalaxy: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies").delete()
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

For the `id` field, the identifier constraint is added to signify that this field uniquely identifies the model. Setting `auto` to true tells the database to automatically generate identifiers for models when they are saved. 

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
app.get("galaxies") { req in
    Galaxy.query(on: req.db).all()
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
    See [Content &rarr; Overview](/content.md) for more information about decoding request bodies.

Once you have an instance of the model, calling `create(on:)` saves the model to the database. This returns an `EventLoopFuture<Void>` which signals that the save has completed. Once the save completes, return the newly created model using `map`.

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
    "id": 1,
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
    @ID(key: "id")
    var id: Int?

    // The Star's name.
    @Field(key: "name")
    var name: String

    // Reference to the Galaxy this Star is in.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creates a new, empty Star.
    init() { }

    // Creates a new Star with all properties set.
    init(id: Int? = nil, name: String, galaxyID: Int) {
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
struct CreateStar: Migration {
    // Prepares the database for storing Star models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("stars")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string)
            .field("galaxy_id", .int, .references("galaxies", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("stars").delete()
    }
}
```

This is mostly the same as galaxy's migration except for the additional field to store the parent galaxy's identifier.

```swift
field("galaxy_id", .int, .references("galaxies", "id"))
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
app.post("stars") { req -> EventLoopFuture<Star> in
    let star = try req.content.decode(Star.self)
    return star.create(on: req.db)
        .map { star }
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
        "id": 1 
    }
}
```

You should see the newly created star returned with a unique identifier.

```json
{
    "id": 1,
    "name": "Sun",
    "galaxy": { 
        "id": 1 
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

The `@Children` property wrapper is the inverse of `@Parent`. It takes a key-path to the child's `@Parent` field as the `for` argument. Its value is an array of chidlren since zero or more child models may exist. No changes to the galaxy's migration are needed since all the information needed for this relation is stored on `Star`.

### Eager Load

Now that the relation is complete, you can use the `with` method on the query builder to automatically fetch and serialize the galaxy-star relation.

```swift
app.get("galaxies") { req in
    Galaxy.query(on: req.db).with(\.$stars).all()
}
```

A key-path to the `@Children` relation is passed to `with` to tell Fluent to automatically load this relation in all of the resulting models. Build and run and send another request to `GET /galaxies`. You should now see the stars automatically included in the response.

```json
[
    {
        "id": 1,
        "name": "Milky Way",
        "stars": [
            {
                "id": 1,
                "name": "Sun",
                "galaxy": {
                    "id": 1
                }
            }
        ]
    }
]
```

## Next Steps

Congratulations on creating your first models and migrations and performing basic create and read operations. For more in-depth information on all of these features, check out their respective sections in the Fluent guide.
