# Relations

Fluent's [model API](model.md) helps you create and maintain references between your models through relations. Two types of relations are supported:

- [Parent](#parent) / [Child](#child) (One-to-many)
- [Siblings](#siblings) (Many-to-many)

## Parent

The `@Parent` relation stores a reference to another model's `@ID` property.

```swift
final class Planet: Model {
    // Example of a parent relation.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` contains a `@Field` named `id` which is used for setting and updating the relation.

```swift
// Set parent relation id
earth.$star.id = sun.id
```

The `key` parameter defines the field key to use for storing the parent's identifier. Assuming `Star` has a `UUID` identifier, this `@Parent` relation is compatible with the following [field definition](schema.md#field).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Note that the [`.references`](schema.md#field-constraint) constraint is optional. See [schema](schema.md) for more information.

### Optional Parent

The `@OptionalParent` relation stores an optional reference to another model's `@ID` property. It works similarly to `@Parent` but allows for the relation to be `nil`.

```swift
final class Planet: Model {
    // Example of an optional parent relation.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

The field definition is similar to `@Parent`'s except that the `.required` constraint should be omitted.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

## Children

The `@Children` property creates a one-to-many relation between two models. It does not store any values on the root model. 

```swift
final class Star: Model {
    // Example of a children relation.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

The `for` parameter accepts a key path to a `@Parent` or `@OptionalParent` relation referencing the root model. In this case, we are referencing the `@Parent` relation from the previous [example](#parent). 

New models can be added to this relation using the `create` method.

```swift
// Example of adding a new model to a relation.
let earth = Planet(name: "Earth")
sun.$planets.create(earth, on: database)
```

This will set the parent id on the child model automatically.

Since this relation does not store any values, no database schema entry is required. 

## Siblings

The `@Siblings` property creates a many-to-many relation between two models. It does this through a tertiary model called a pivot.

Let's take a look at an example of a many-to-many relation between a `Planet` and a `Tag`.

```swift
// Example of a pivot model.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
    }
}
```

Pivots are normal models that contain two `@Parent` relations. One for each of the models to be related. Additional properties can be stored on the pivot if desired. 

Adding a [unique](schema.md#unique) constraint to the pivot model can help prevent redundant entries. See [schema](schema.md) for more information.

```swift
// Disallows duplicate relations.
.unique(on: "planet_id", "tag_id")
```

Once the pivot is created, use the `@Siblings` property to create the relation. 

```swift
final class Planet: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

The `@Siblings` property requires three parameters:

- `through`: The pivot model's type.
- `from`: Key path from the pivot to the parent relation referencing the root model.
- `to`: Key path from the pivot to the parent relation referencing the related model.

The inverse `@Siblings` property on the related model completes the relation.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

The `@Siblings` property has methods adding and removing models from the relation. 

Use the `attach` method to add a model to the relation. This creates and saves the pivot model automatically.

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Adds the model to the relation.
earth.$tags.attach(inhabited, on: database)
```

When attaching a single model, you can use the `method` parameter to choose whether or not the relation should be checked before saving.

```swift
// Only attaches if the relation doesn't already exist.
earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Use the `detach` method to remove a model from the relation. This deletes the corresponding pivot model.

```swift
// Removes the model from the relation.
earth.$tags.detach(inhabited)
```

You can check if a model is related or not using the `isAttached` method.

```swift
// Checks if the models are related.
earth.$tags.isAttached(to: inhabited)
```

## Get

Use the `get(on:)` method to fetch a relation's value. 

```swift
// Fetches all of the sun's planets.
sun.$planets.get(on: database).map { planets in
    print(planets)
}
```

Use the `reload` parameter to choose whether or not the relation should be re-fetched from the database if it has already been already loaded. 

```swift
sun.$planets.get(reload: true, on: database)
```

## Query

Use the `query(on:)` method on a relation to create a query builder for the related models. 

```swift
// Fetch all of the sun's planets that have a naming starting with M.
sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

See [query](query.md) for more information.

## Load

Use the `load(on:)` method to load a relation. This allows the related model to be accessed as a local property.

```swift
// Example of loading a relation.
planet.$star.load(on: database).map {
    print(planet.star.name)
}
```

To check whether or not a relation has been loaded, use the `value` property.

```swift
if planet.$star.value != nil {
    // Relation has been loaded.
    print(planet.star.name)
} else {
    // Relation has not been loaded.
    // Attempting to access planet.star will fail.
}
```

You can set the `value` property manually if needed.

## Eager Load

Fluent's query builder allows you to preload a model's relations when it is fetched from the database. This is called eager loading and allows you to access relations synchronously without needing to call [`load`](#load) or [`get`](#get) first. 

To eager load a relation, pass a key path to the relation to the `with` method on query builder. 

```swift
// Example of eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` is accessible synchronously here 
        // since it has been eager loaded.
        print(planet.star.name)
    }
}
```

In the above example, a key path to the [`@Parent`](#parent) relation named `star` is passed to `with`. This causes the query builder to do an additional query after all of the planets are loaded to fetch all of their related stars. The stars are then accessible synchronously via the `@Parent` property. 

Each relation eager loaded requires only one additional query, no matter how many models are returned. Eager loading is only possible with the `all` and `first` methods of query builder. 


### Nested Eager Load

The query builder's `with` method allows you to eager load relations on the model being queried. However, you can also eager load relations on related models. 

```swift
Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all().map { planets in
    for planet in planets {
        // `star.galaxy` is accessible synchronously here 
        // since it has been eager loaded.
        print(planet.star.galaxy.name)
    }
}
```

The `with` method accepts an optional closure as a second parameter. This closure accepts an eager load builder for the chosen relation. There is no limit to how deeply eager loading can be nested. 
