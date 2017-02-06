---
currentMenu: fluent-query
---

# Query

The `Query` class is what powers every interaction with Fluent. Whether you're fetching a model with `.find()` or saving to the database, there is a `Query` involved somewhere.

## Querying Models

Every type that conforms to [Model](model.md) gets a static `.query()` method.

```swift
let query = try User.query()
```

This is how you can create a `Query<User>`.

### No Database

The `.query()` method is marked with `try` because it can throw an error if the Model has not had its static database property set.

```swift
User.database = drop.database
```

This property is set automatically when you pass the Model as a preparation.

## Filter

The most common types of queries involve filtering data.

```swift
let smithsQuery = try User.query().filter("last_name", "Smith")
```

Here is the short hand for adding an `equals` filter to the query. As you can see, queries can be chained together.

In additional to `equals`, there are many other types of `Filter.Comparison`.

```swift
let over21 = try User.query().filter("age", .greaterThanOrEquals, 21)
```

### Scope

Filters can also be run on sets.

```swift
let coolPets = try Pet.query().filter("type", .in, ["Dog", "Ferret"])
```

Here only Pets of type Dog _or_ Ferret are returned. The opposite works for `notIn`.


### Contains

Partially matching filters can also be applied.

```swift
let statesWithNew = try State.query().filter("name", contains: "New")
```

## Retrieving

There are two methods for running a query.

### All

All of the matching entities can be fetched. This returns an array of `[Model]`, in this case users.

```swift
let usersOver21 = try User.query().filter("age", .greaterThanOrEquals, 21).all()
```

### First

The first matching entity can be fetched. This returns an optional `Model?`, in this case a user.

```swift
let firstSmith = try User.query().filter("last_name", "Smith").first()
```

## Union

Other Models can be joined onto your query to assist in filtering. The results must still be either `[Model]` or `Model?` for whichever type created the query.

```swift
let usersWithCoolPets = try User.query()
	.union(Pet.self)
	.filter(Pet.self, "type", .in, ["Dog", "Ferret"])
```

Here the `User` collection is unioned to the `Pet` collection. Only `User`s who have a dog or a ferret will be returned.

### Keys

The `union` method assumes that the querying table has a foreign key identifier to the joining table.

The above example with users and pets assumes the following schema.

```
users
- id
pets
- id
- user_id
```

Custom foreign keys can be provided through overloads to `union`.

## Raw Queries

Since Fluent is focused on interacting with models, each Query requires a model type. If you want to do raw database queries that aren't based on a model, you should use the underlying Fluent Driver to do so.

```swift
if let mysql = drop.database?.driver as? MySQLDriver {
    let version = try mysql.raw("SELECT @@version")
}
```
