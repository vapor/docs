# Models

Models represent data stored in tables or collections in your database. Models have one or more fields that store codable values. All models have a unique identifier. Property wrappers are used to denote identifiers, fields, and relations. 

Below is an example of a simple model with one field. Note that models do not describe the entire database schema, such as constraints, indexes, and foreign keys. Schemas are defined in [migrations](migrations.md). Models are focused on handling the data stored in your database schemas.  

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

## Schema

All models require a static, get-only `schema` property. This string references the table or collection this model represents. 

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"
}
```

When querying this model, data will be fetched from and stored to the schema named `"galaxies"`.

!!! tip
    The schema name is typically the class name pluralized and lowercased. 

## Identifier

All models must have an `id` property defined using the `@ID` property wrapper. This field uniquely identifies instances of your model.

```swift
final class Galaxy: Model {
    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?
}
```
