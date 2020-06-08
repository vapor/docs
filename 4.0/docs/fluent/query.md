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

TODO: filter groups

## Aggregate

TODO: count, sum, average, min, max

## Chunk

TODO: chunk results

## Field

TODO: partial read

## Unique

TODO: only unique values

## Range

TODO: range, limit, offset

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
