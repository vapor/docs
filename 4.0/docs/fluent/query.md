# Query

Fluent's query API allows you to create, read, update, and delete models from the database. It supports filtering results, joins, chunking, aggregates, and more. 

```swift
// An example of Fluent's query API.
let planets = Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(by: \.$name)
    .with(\.$star)
    .all()
```

Query builders are tied to a single model type and can be created using the static [`query`](model.md#query) method. They can also be created by passing the model type to the `query` method on a database object.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

## All

The `all()` method returns an array of models.

```swift
// Fetches all planets.
let planets = Planet.query(on: database).all()
```

The `all` method also supports fetching only a single field from the result set. 

```swift
// Fetches all planet names.
let names = Planet.query(on: database).all(\.$name)
```

### First

The `first()` method returns a single, optional model. If the query results in more than one model, only the first is returned. If the query has no results, `nil` is returned. 

```swift
// Fetches the first planet named Earth.
let earth = Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    This method can be combined with [`unwrap(or:)`](../errors.md#abort) to return a non-optional model or throw an error. 

## Filter

The `filter` method allows you to constrain the models included in the result set. There are several overloads for this method. 

### Value Filter

The most commonly used `filter` method accept an operator expression with a value.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

These operator expressions accept a field key path on the left hand side and a value on the right. The supplied value must match the field's expected value type and is bound to the resulting query. Filter expressions are strongly typed allowing for leading-dot syntax to be used.

Below is a list of all supported value operators. 

|Operator|Description|
|-|-|
|`==`|Equal to.|
|`!=`|Not equal to.|
|`>=`|Greater than or equal to.|
|`>`|Greater than.|
|`<`|Less than.|
|`<=`|Less than or equal to.|

### Field Filter

The `filter` method supports comparing two fields. 

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

All [value filter](#value-filter) operators are supported with field filters.

### Subset Filter

The `filter` method supports checking whether a field's value exists in a given set of values. 

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

The supplied set of values can be any Swift `Collection` whose `Element` type matches the field's value type.

Below is a list of all supported subset operators. 

|Operator|Description|
|-|-|
|`~~`|Value in set.|
|`!~`|Value not in set.|

### Contains Filter

The `filter` method supports checking whether a string field's value contains a given substring. 

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

These operators are only available on fields with string values. 

Below is a list of all supported contains operators. 

|Operator|Description|
|-|-|
|`~~`|Contains substring.|
|`!~`|Does not contain substring.|
|`=~`|Matches prefix.|
|`!=~`|Does not match prefix.|
|`~=`|Matches suffix.|
|`!~=`|Does not match suffix.|

### Group

By default, all filters added to a query will be required to match. Query builder supports creating a group of filters where only one filter must match. 

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}
```

The `group` method supports combining filters by `and` or `or` logic. These groups can be nested indefinitely. Top-level filters can be thought of as being in an `and` group.

## Aggregate

Query builder supports several methods for performing calculations on a set of values like counting or averaging. 

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

All aggregate methods besides `count` require a key path to a field to be passed.

```swift
// First name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

Below is a list of all available aggregate methods.

|Aggregate|Description|
|-|-|
|`count`|Number of results.|
|`sum`|Sum of result values.|
|`average`|Average of result values.|
|`min`|Minimum result value.|
|`max`|Maximum result value.|

All aggregate methods except `count` return the field's value type as a result. `count` always returns an integer. `count` is also the only method that can be called without specifying a field.


## Chunk

Query builder supports returning a result set as separate chunks. This helps you to control memory usage when handling large database reads.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

The supplied closure will be called zero or more times depending on the total number of results. Each item returned is a `Result` containing either the model or an error returned attempting to decode the database entry. 

## Field

By default, all of a model's fields will be read from the database by a query. You can choose to select only a subset of a model's fields using the `field` method.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Any model fields not selected during a query will be in an unitialized state. Attempting to access uninitialized fields directly will result in a fatal error. To check if a model's field value is set, use the `value` property. 

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

Query builder's `unique` method causes duplicate results to be omitted. 

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` is especially useful when fetching a single field with `all`. However, you can also select multiple fields using the [`field`](#field) method. Since model identifiers are always unique, you should avoid selecting them when using `unique`. 

## Range

Query builder's `range` methods allow you to select a subset of the results using Swift ranges.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

Range values are unsigned integers starting at zero. Learn more about [Swift ranges](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
range(2...)
```

## Join

TODO: join, operators, model alias

## Update

TODO: set

## Delete

TODO: delete filters

## Paginate

TODO: paginate results

## Sort

TODO: sort results
