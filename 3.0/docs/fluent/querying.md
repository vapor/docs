# Fluent Queries

Once you have a [model](models.md) you can start querying your database to create, read, update, and delete data.

## Connection

The first thing you need to query your database, is a connection to it. Luckily, they are easy to get.

### Request

The easiest way to connect to your database is simply using the incoming `Request`. This will use the model's [`defaultDatabase`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE15defaultDatabase0D3Kit0D10IdentifierVy0D0QzGSgvpZ) property to automatically fetch a pooled connection to the database. 

```swift
router.get("galaxies") { req in
    return Galaxy.query(on: req).all()
}
```

You can use convenience methods on a `Container` to create connections manually. Learn more about that in [DatabaseKit &rarr; Overview &rarr; Connections](../database-kit/overview/#connections).

## Create

One of the first things you will need to do is save some data to your database. You do this by initializing an instance of your model then calling [`create(on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6create2on3NIO15EventLoopFutureCyxG11DatabaseKit0I11Connectable_p_tF).

```swift
router.post("galaxies") { req in
    let galaxy: Galaxy = ... 
    return galaxy.create(on: req)
}
```

The create method will return the saved model. The returned model will include any generated fields such as the ID or fields with default values.

If your model also conforms to [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html) you can return the result of the Fluent query directly.


## Read

To read models from the database, you can use [`query(on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6create2on3NIO15EventLoopFutureCyxG11DatabaseKit0I11Connectable_p_tF) or [`find(_:on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE4find_2on3NIO15EventLoopFutureCyxSgG2IDQz_11DatabaseKit0J11Connectable_ptFZ).

### Find

The easiest way to find a single model is by passing its ID to [`find(_:on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE4find_2on3NIO15EventLoopFutureCyxSgG2IDQz_11DatabaseKit0J11Connectable_ptFZ).

```swift
Galaxy.find(42, on: conn)
```

The result will be a future containing an optional value. You can use [`unwrap(or:)`](https://api.vapor.codes/core/latest/Core/Extensions/Future.html#/s:3NIO15EventLoopFutureC4CoreAD12OptionalTypeRzlE6unwrap2orACy07WrappedG0QzGs5Error_pyXA_tF) to unwrap the future value or throw an error.

```swift
Galaxy.find(42, on: conn).unwrap(or: Abort(...))
```

### Query

You can use the [`query(on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6create2on3NIO15EventLoopFutureCyxG11DatabaseKit0I11Connectable_p_tF) method to build database queries with filters, joins, sorts, and more. 

```swift
Galaxy.query(on: conn).filter(\.name == "Milky Way")
```

### Filter

The [`filter(_:)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC6filteryACyxq_GXDAA14FilterOperatorVyxq_GF) method accepts filters created from Fluent's operators. This provides a concise, Swifty way for building Fluent queries.

Calls to filter can be chained and even grouped.

```swift
Galaxy.query(on: conn).filter(\.mass >= 500).filter(\.type == .spiral)
```

Below is a list of all supported operators.

|operator|type|
|-|-|
|`==`|Equal|
|`!=`|Not equal|
|`>`|Greater than|
|`<`|Less than|
|`>=`|Greater than or equal|
|`<=`|Less than or equal|

By default, all chained filters will be used to limit the result set. You can use filter groups to change this behavior.

```swift
Galaxy.query(on: conn).group(.or) {
    $0.filter(\.mass <= 250).filter(\.mass >= 500)
}.filter(\.type == .spiral)
```

The above query will include results where the galaxy's mass is below 250 _or_ above 500 _and_ the type is spiral.

### Range

You can apply Swift ranges to a query builder to limit the result set.

```swift
Galaxy.query(on: conn).range(..<50)
```

The above query will include only the first 50 results.

For more information on ranges, see docs for Swift's [Range](https://developer.apple.com/documentation/swift/range) type.

### Sort

Query results can be sorted by a given field. 

```swift
Galaxy.query(on: conn).sort(\.name, .descending)
```

You can sort by multiple fields to perform tie breaking behavior where there is duplicate information in the one of the sorted fields.

### Join

Other models can be joined to an existing query in order to further filter the results. 

```swift
Galaxy.query(on: conn).join(\Planet.galaxyID, to: \Galaxy.id)
    .filter(\Planet.name == "Earth")
```

Once a table has been joined using [`join(_:to:)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderCA2A14JoinSupportingRzrlE4join_2to6methodACyxq_GXDs7KeyPathCyqd__qd_0_G_AJyqd_1_qd_2_G0bD6MethodQztr2_lF), you can use fully-qualified key paths to filter results based on data in the joined table.

The above query fetches all galaxies that have a planet named Earth.

You can even decode the joined models using [`alsoDecode(...)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC10alsoDecodeyACyxq__qd__tGqd__mAA5ModelRd__lF).

```swift
Galaxy.query(on: conn)
    // join Planet and filter
    .alsoDecode(Planet.self).all()
```

The above query will decode an array of `(Galaxy, Planet)` tuples.

### Fetch

To fetch the results of a query, use [`all()`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC3all3NIO15EventLoopFutureCySayq_GGyF), [`chunk(max:closure:)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC5chunk3max7closure3NIO15EventLoopFutureCyytGSi_ySayq_GKctF),  [`first()`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC5first3NIO15EventLoopFutureCyq_SgGyF) or an aggregate method.

#### All

The most common method for fetching results is with `all()`. This will return all matching results according to any fliters applied. 

```swift
Galaxy.query(on: conn).all()
```

When combined with [`range(_:)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC5rangeyACyxq_GXDSnySiGF), you can efficiently limit how many results are returned by the database.

```swift
Galaxy.query(on: conn).range(..<50).all()
```

#### Chunk

For situations where memory conservation is important, use [`chunk(...)`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC5chunk3max7closure3NIO15EventLoopFutureCyytGSi_ySayq_GKctF). This method returns the result set in multiple calls of a maximum chunk size.

```swift
Galaxy.query(on: conn).chunk(max: 32) { galaxies in
    print(galaxies) // Array of 32 or less galaxies
}
```

#### First

The [`first()`](https://api.vapor.codes/fluent/latest/Fluent/Classes/QueryBuilder.html#/s:6Fluent12QueryBuilderC5first3NIO15EventLoopFutureCyq_SgGyF) method is a convenience for fetching the first result of a query. It will automatically apply a range restriction to avoid transferring unnecessary data.

```swift
Galaxy.query(on: conn).filter(\.name == "Milky Way").first()
```

This method is more efficient than calling `all` and getting the first item in the array.

## Update

After a model has been fetched from the database and mutated, you can use [`update(on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6update2on10originalID3NIO15EventLoopFutureCyxG11DatabaseKit0K11Connectable_p_0F0QzSgtF) to save the changes.

```swift
var planet: Planet ... // fetched from database
planet.name = "Earth"
planet.update(on: conn)
```

## Delete

After a model has been fetched from the database, you can use [`delete(on:)`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE6delete5force2on3NIO15EventLoopFutureCyytGSb_11DatabaseKit0J11Connectable_ptF) to delete it.

```swift
var planet: Planet ... // fetched from database
planet.delete(on: conn)
```
