# Query

Fluent's query API allows you to create, read, update, and delete models from the database. It supports filtering results, joins, chunking, aggregates, and more. 

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Query builders are tied to a single model type and can be created using the static [`query`](model.md#query) method. They can also be created by passing the model type to the `query` method on a database object.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note
    You must `import Fluent` in the file with your queries so that the compiler can see Fluent's helper functions.

## All

The `all()` method returns an array of models.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

The `all` method also supports fetching only a single field from the result set. 

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

The `first()` method returns a single, optional model. If the query results in more than one model, only the first is returned. If the query has no results, `nil` is returned. 

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    If using `EventLoopFuture`s, this method can be combined with [`unwrap(or:)`](../errors.md#abort) to return a non-optional model or throw an error. 

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

Field filters support the same operators as [value filters](#value-filter).

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
}.all()
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
// Lowest name sorted alphabetically.
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

All aggregate methods except `count` return the field's value type as a result. `count` always returns an integer.

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

Query builder's `unique` method causes only distinct results (no duplicates) to be returned. 

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` is especially useful when fetching a single field with `all`. However, you can also select multiple fields using the [`field`](#field) method. Since model identifiers are always unique, you should avoid selecting them when using `unique`. 

## Range

Query builder's `range` methods allow you to choose a subset of the results using Swift ranges.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

Range values are unsigned integers starting at zero. Learn more about [Swift ranges](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
.range(2...)
```

## Join

Query builder's `join` method allows you to include another model's fields in your result set. More than one model can be joined to your query. 

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

The `on` parameter accepts an equality expression between two fields. One of the fields must already exist in the current result set. The other field must exist on the model being joined. These fields must have the same value type.

Most query builder methods, like `filter` and `sort`, support joined models. If a method supports joined models, it will accept the joined model type as the first parameter. 

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

Queries that use joins will still return an array of the base model. To access the joined model, use the `joined` method.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Model aliases allow you to join the same model to a query multiple times. To declare a model alias, create one or more types conforming to `ModelAlias`. 

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

These types reference the model being aliased via the `model` property. Once created, you can use model aliases like normal models in a query builder.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

All model fields are accessible through the model alias type via `@dynamicMemberLookup`.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

Query builder supports updating more than one model at a time using the `update` method.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` supports the `set`, `filter`, and `range` methods. 

## Delete

Query builder supports deleting more than one model at a time using the `delete` method.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` supports the `filter` method.

## Paginate

Fluent's query API supports automatic result pagination using the `paginate` method. 

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

The `paginate(for:)` method will use the `page` and `per` parameters available in the request URI to return the desired set of results. Metadata about current page and total number of results is included in the `metadata` key.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

The above request would yield a response structured like the following.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Page numbers start at `1`. You can also make a manual page request.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

Query results can be sorted by field values using `sort` method.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

Additional sorts may be added as fallbacks in case of a tie. Fallbacks will be used in the order they were added to the query builder.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
