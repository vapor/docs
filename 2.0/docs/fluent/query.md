# Query

Fluent's query builder provides a simple interface for creating complex database queries. The `Query` class itself (raw queries excluded) is the sole method by which Fluent communicates with your database.

## Make

You can create a new query builder from any model class.

```swift
let query = try Post.makeQuery()
```

You can also create queries from an instance. This is especially useful if you need to use a special
database connection (like for [transactions](database.md#Transactions)) to save or update a model.

```swift
guard let post = try Post.find(42) else { ... }
post.content = "Updated"
let query = try post.makeQuery(conn).save()
```

## Fetch

You have multiple options for fetching the results of a query.

### All

The simplest option, `.all()` returns all rows relevant to the query.

```
let users = try User.makeQuery().filter(...).all()
```

### First

You can take only the first row as well with `.first()`.

```
let user = try User.makeQuery().filter(...).first()
```

Fluent will automatically limit the results to `1` to increase
the performance of the query.

### Chunk

If you want to fetch a large amount of models from the database, using `.chunk()` can help reduce the
amount of memory required for the query by fetching chunks of data at a time.

```
User.makeQuery().filter(...).chunk(32) { users in
	print(users)
}
```

## Filter

Filters allow you to choose exactly what subset of data you want to modify or fetch. There are three different
types of filters.

### Compare

Compare filters perform a comparison between a field on your model in the database and a supplied value.

```swift
try query.filter("age", .greaterThanOrEquals, 21)
```

You can also use operators.

```swift
try query.filter("age" >= 21)
```

| Case                 | Operator | Type                   |
|----------------------|----------|------------------------|
| .equals              | ==       | Equals                 |
| .greaterThan         | >        | Greater Than           |
| .lessThan            | <        | Less Than              |
| .greaterThanOrEquals | >=       | Greater Than Or Equals |
| .lessThanOrEquals    | <=       | Less Than Or Equals    |
| .notEquals           | !=       | Not Equals             |
| .hasSuffix           |          | Has Suffix             |
| .hasPrefix           |          | Has Prefix             |
| .contains            |          | Contains               |
| .custom(String)      |          | Custom                 |

!!! tip
	You can omit the comparison type for `.equals`, e.g., `query.filter("age", 23)`


### Subset

You can also filter by fields being in a set of data.

```swift
try query.filter("favoriteColor", in: ["pink", "blue"])
```

Or the opposite.


```swift
try query.filter("favoriteColor", notIn: ["brown", "black"])
```

### Group

By default, all query filters are joined by AND logic. You can create groups of filters within
your query that are joined with AND or OR logic.

```swift
try query.or { orGroup in
    try orGroup.filter("age", .greaterThan, 75)
    try orGroup.filter("age", .lessThan, 18)
}
```

This will result in SQL similar to the following:


```sql
SELECT * FROM `users` WHERE (`age` > 75 OR `age` < 18);
```

`.and()` is also available in case you need to switch back to joining filters with AND nested inside of an OR.

#### Complex Example

```swift
let users = try User
	.makeQuery()
	.filter("planetOfOrigin", .greaterThan, "Earth")
	.or { orGroup in
		orGroup.and { andGroup in
			andGroup.filter("name", "Rick")
			andGroup.filter("favoriteFood", "Beer")
		}
		orGroup.and { andGroup in
			andGroup.filter("name", "Morty")
			andGroup.filter("favoriteFood", "Eyeholes")
		}
	}
	.all()
```

This will result in SQL similar to the following:

```sql
SELECT * FROM `users`
	WHERE `planetOfOrigin` = 'Earth' AND (
		   (`name` = 'Rick' AND `favoriteFood` = 'Beer')
		OR (`name` = 'Morty' AND `favoriteFood` = 'Eyeholes')
	)
```

!!! note
	Keep in mind that the AND/OR logic for a group applies only to the filters added _within_ the group. All filters outside of a filter group will be joined by AND.

### Raw

Raw filters can be used to filter by values that should not be parameterized.

```swift
try query.filter(raw: "date >= CURRENT_TIMESTAMP")
```

### NodeConvertible Conformance

Filters can be converted to and from Node objects, which allows filters to be specified via JSON and other NodeRepresentable formats. This makes it very easy if you want to allow a consumer API to filter your entities.

Example:
```json
{  
  "entity":"MyApp.User",
  "method":{  
    "type":"group",
    "relation":"and",
    "filters":[  
      {  
        "entity":"MyApp.User",
        "method":{  
          "type":"compare",
          "comparison":"greaterThanOrEquals",
          "field":"age",
          "value":18
        }
      },
      {  
        "entity":"MyApp.User",
        "method":{  
          "type":"compare",
          "comparison":"equals",
          "field":"gender",
          "value":"male"
        }
      }
    ]
  }
}
```

!!! note
	You must include the module name in the entity field. "MyModule.MyEntity"

## Distinct

To select only distinct models from the database, add `.distinct()` to your query.

```swift
try query.distinct()
```

## Limit / Offset

To limit or offset your query, use the `.limit()` method.

```swift
try query.limit(20, offset: 5)
```

## Sort

To sort the results of your query, use the `.sort()` method.

```swift
try query.sort("age", .descending)
```

You can sort on multiple columns at once by chaining your `.sort()` calls.

```swift
try query.sort("age", .descending).sort("shoe_size")
```

## Join

You can join two model tables together, which is useful if you want to filter one model by a property of another.
For example, let's say you have a table of Employees which belong to Departments. You want to know which
Departments contain Employees who have completed ten years of service.

First you use the `.join()` method on a Department query to join it with the Employee table. Next you chain a
`.filter()` on to the query. Bear in mind you need to explicitly pass the 'joined' model to the filter, otherwise
Fluent will try to filter on the 'base' model.

```swift
let departments = try Department.makeQuery()
  .join(Employee.self)
  .filter(Employee.self, "years_of_service" >= 10)
```

Fluent will work out the relationship fields for you, but you can also specify them yourself with the `baseKey`
and `joinedKey` method parameters, where `baseKey` is the identifier field on the 'base' model (the Department)
and `joinedKey` is the foreign key field on the 'joined' model (the Employee) which relates back to the 'base' model.

!!! tip
  Fluent supports both inner and outer joins; use the invocation `.join(kind: .outer, MyModel.self)`

## Raw

Should you need to perform a query that the query builder does not support, you can use the raw query.

```swift
try drop.database?.raw("SELECT @@version")
```

You can also use the database of a given model.

```swift
User.database?.raw("SELECT * FROM `users`")
```

Besides providing a more expressive interface for querying your database, the query builder also takes measures to increase security by automatically sanitizing input. Because of this, try to use the query class wherever you can over performing raw queries.
