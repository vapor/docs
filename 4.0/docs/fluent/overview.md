# Fluent 

Fluent is an [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) framework for Swift. It takes advantage of Swift's strong type system to provide an easy-to-use interface for your database. Using Fluent centers around the creation of model types which represent data structures in your database. These models are then used to perform create, read, update, and delete operations in-place of writing raw queries.

## Configuration

If you haven't added Fluent to your Vapor project or set it up yet, check out the [configuration](../config.md) guide first. This guide assumes your app can already connect to a database.

## Models

Models represent fixed data structures in your database, like tables or collections. Models have one or more fields that store codable values. All models also have a unique identifier. Property wrappers are used to denote identifiers and fields as well as more complex mappings mentioned later. Take a look at the following model which represents a galaxy:

```swift
final class Galaxy: Model {
	// name of the table or collection
    static let schema = "galaxies"

    // unique identifier for this galaxy
	@ID(key: "id")
	var id: Int?

    // the galaxy's name
	@Field(key: "name")
	var name: String

    // creates a new, empty galaxy
    init() { }

    // creates a new galaxy with all properties set
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

To create a new model, create a new class conforming to `Model`. 

!!! tip
	Making model classes `final` is recommended as it improves performance and simplifies conformance requirements.

The model protocol's first requirement is the static string `schema`.

```swift
static let schema = "galaxies"
```

This property tells Fluent which table or collection the model corresponds to. This can be a table that already exists in the database or one that you will create with a [migration](#migration). The schema is usually `snake_case` and plural.

The next requirement is an identifier field named `id`. 

```swift
@ID(key: "id")
var id: Int?
```

This field must use the `@ID` property wrapper where the `key` specifies the id field's name in the database. The value can be any Swift type that is both codable and hashable.

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

## Query Builder

## Relations
