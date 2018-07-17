# Fluent Relations

Fluent supports two methods for relating models: one-to-many (parent-child) and many-to-many (siblings). These relations help make working with a [normalized data structure](https://en.wikipedia.org/wiki/Database_normalization) easy.

## Parent-Child

The most common model relation is the one-to-many or _parent-child_ relation. In this relation, each child model stores at most one identifier of a parent model. In most cases, multiple child models can store the same parent identifier at the same time. This means that any given parent can have zero or more related child models. Hence the name, one (parent) to many (children).

!!! note
    If each child must store a _unique_ parent ID, this relation is called a one-to-one relation. 

Take a look at the following diagram in which an example parent-child relation between two models (`Galaxy` and `Planet`) is shown.

![parent_child](https://user-images.githubusercontent.com/1342803/42603097-66b1640c-853a-11e8-99ba-63f1cac50c51.png)

In the example above, `Galaxy` is the parent and `Planet` is the child. Planets store an identifier referencing exactly one galaxy (the galaxy they are in). In turn, each galaxy has zero or more planets that belong to it. 

Let's take a look at what these models would look like in Fluent.

```swift
struct Galaxy: Model {
    // ...
    var id: Int?
    var name: String
}
```

```swift
struct Planet: Model {
    // ...
    var id: Int?
    var name: String
    var galaxyID: Int
}
```

For more information on defining models see [Fluent &rarr; Models](models.md).

Fluent provides two helpers for working with parent-child relations: [`Parent`](https://api.vapor.codes/fluent/latest/Fluent/Structs/Parent.html) and [`Children`](https://api.vapor.codes/fluent/latest/Fluent/Structs/Children.html). These helpers can be created using extensions on the related models for convenient access.

```swift
extension Galaxy {
    // this galaxy's related planets
    var planets: Children<Galaxy, Planet> { 
        return children(\.galaxyID)
    }
}
```

Here the [`children(_:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE8childrenyAA8ChildrenVyxqd__Gs7KeyPathCyqd__2IDQzGAaBRd__8DatabaseQyd__AMRtzlF) method is used on `Galaxy` to create the relation. The resulting type has two generic arguments in the signature that can be thought of as `<From, To`>. Since this relation goes _from_ galaxy _to_ planet, they are ordered as such in the generic arguments.

Note that this method is not static. That is because it must access the galaxy's identifier to perform the relation lookup. 

```swift
extension Planet {
    // this planet's related galaxy
    var galaxy: Parent<Planet, Galaxy> {
        return parent(\.galaxyID)
    }
}
```

Here the [`parent(_:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6parentyAA6ParentVyxqd__Gs7KeyPathCyx2IDQyd__GAaBRd__8DatabaseQyd__AMRtzlF) method is used on `Planet` to create the inverse relation. The resulting type also has two generic arguments. In this case, they are reversed since this relation now goes _from_ planet _to_ galaxy.

Note that this method is also not static. That is because it must access the referenced identifier to perform the relation lookup.

Now that the models and relation properties are created, they can be used to create, read, update, and delete related data.

```swift
let galaxy: Galaxy = ...
let planets = galaxy.planets.query(on: ...).all()
```

The `query(on:)` method on a relation creates an instance of [`QueryBuilder`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html) filtered to the related models. See [Fluent &rarr; Querying](querying.md) for more information on working with the query builder.

```swift
let planet: Planet = ...
let galaxy = planet.galaxy.get(on: ...)
```

Since the child can have at most _one_ parent, the most useful method is [`get(on:)`] which simply returns the parent model.

## Siblings

A more powerful (and complex) relation is the many-to-many or _siblings_ relation. In this relation, two models are related by a third model called a _pivot_. The pivot is a simple model that carries one identifier for each of the two related models. Because a third model (the pivot) stores identifiers, each model can be related to zero or more models on the other side of the relation. 

Take a look at the following diagram in which an example siblings relation between two models (`Planet` and `Tag`) and a pivot (`PlanetTag`) is shown.

![siblings](https://user-images.githubusercontent.com/1342803/42603098-66c3214c-853a-11e8-84da-c228c5e90200.png)

A siblings relation is required for the above example because:

- Both **Earth** and **Venus** have the **Earth Sized** tag.
- **Earth** has both the **Earth Sized** and **Liquid Water** tag.

In other words, two planets can share one tag _and_ two tags can share one planet. This is a many-to-many relation.

Let's take a look at what these models would look like in Fluent.


```swift
struct Planet: Model {
    // ...
    var id: Int?
    var name: String
    var galaxyID: Int
}
```

```swift
struct Tag: Model {
    // ...
    var id: Int?
    var name: String
}
```

For more information on defining models see [Fluent &rarr; Models](models.md).

Now let's take a look at the pivot. It may seem a bit intimidating at first, but it's really quite simple.

```swift
struct PlanetTag: Pivot {
    // ...

    typealias Left = Planet
    typealias Right = Tag

    static var leftIDKey: LeftIDKey = \.planetID
    static var rightIDKey: RightIDKey = \.tagID
    
    var id: Int?
    var planetID: Int
    var tagID: Int
}
```

A pivot must have `Left` and `Right` model types. In this case, those model types are `Planet` and `Tag`. Although it is arbitrary which model is left vs. right, a good rule of thumb is to order things alphabetically for consistency.

Once the left and right models are defined, we must supply Fluent with key paths to the stored properties for each ID. We can use the `LeftIDKey` and `RightIDKey` type-aliases to do this.

A `Pivot` is also a `Model` itself. You are free to store any additional properties here if you like. Don't forget to create a migration for it if you are using a database that supports schemas.

Once the pivot and your models are created, you can add convenience extensions for interacting with the relation just like the parent-child relation. 

```swift
extension Planet {
    // this planet's related tags
    var tags: Siblings<Planet, Tag, PlanetTag> {
        return siblings()
    }
}
```

Because the siblings relation requires three models, it has three generic arguments. You can think of the arguments as `<From, To, Through>`. This relation goes _from_ a planet _to_ tags _through_ the planet tag pivot.

The other side of the relation (on tag) is similar. Only the first two generic arguments are flipped.

```swift
extension Tag {
    // all planets that have this tag
    var planets: Siblings<Tag, Planet, PlanetTag> {
        return siblings()
    }
}
```

Now that the relations are setup, we can query a planet's tags. This works just like the `Children` type in the parent-child relationship.

```swift
let planet: Planet = ...
planet.tags.query(on: ...).all()
```

### Modifiable Pivot

If the pivot conforms to [`ModifiablePivot`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/ModifiablePivot.html), then Fluent can help to create and delete pivots (called attaching and detaching).

Conforming a pivot is fairly simple. Fluent just needs to be able to initialize the pivot from two related models.

```swift
extension PlanetTag: ModifiablePivot {
    init(_ planet: Planet, _ tag: Tag) throws {
        planetID = try planet.requireID()
        tagID = try tag.requireID()
    }
}
```

Once the pivot type conforms, there will be extra methods available on the siblings relation.

```swift
let planet: Planet = ...
let tag: Tag = ...
planet.tags.attach(tag, on: ...)
```
