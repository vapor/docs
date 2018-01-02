# Prepared statements

Preparing statements is important in many SQL operations to prevent SQL injection.

You first have to set up your query to make use of statement binding.

To design your query for preparation you must replace all user inputted values with a `?` such as the following statement:

```sql
SELECT * FROM users WHERE username = ?
```

## Preparing a statement

To prepare a statement from a query you call the `withPreparation` function on `Connection`.

```swift
try connection.withPreparation(statement: "SELECT * FROM users WHERE username = ?") { statement in
  // Bind
}
```

## Binding to a statement

The statement can be bound by calling the `bind` function on `statement`. This will provide you with a temporary binding context.

You must bind the same or a similar type to the one related to the field being bound to. Bindings must be added in the same order they appear in the query.

```swift
try statement.bind { binding in
  try binding.bind("ExampleUser")
}
```

Bindings will throw an error if the inputted value did not meet the query's required type.

## Binding encodable data

When inserting entities, often you need to encode all of the values to the query, preferably with type safety.

```swift
try binding.withEncoder { encoder in
    try model.encode(to: encoder)
}
```

You can use this `withEncoder` closure to bind multiple structures, too.

## Reading the query's results

You can then use the [Future or Streaming query functions as described in the basics](basics.md) to receive the queried results from the prepared and bound `statement` object.
