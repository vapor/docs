# MySQL Driver

Fluent uses the MySQL driver to talk to your MySQL database. Although you won't need to use it most of the time, it does 
have some handy features.

## Raw

Sometimes you need to bypass Fluent and send raw queries to the database.

```swift
let result = try mysqlDriver.raw("SELECT @@version")
```

!!! note:
	If you are using Vapor, you can get access to the MySQL Driver with `drop.mysql()`

## Transaction

If you are performing multiple queries that depend on eachother, you can use transactions to make sure nothing gets saved
to the database if one of the queries fails.

```swift
try mysqlDriver.transaction { conn in
	// delete user's pets, then delete user
	// if one of these fails, the transaction will rollback
	try user.pets.makeQuery(conn).delete()
	try user.makeQuery(conn).delete()
}
```

!!! warning
	Make sure to use the connection supplied to the closure for all queries you want included in the transaction.

## Manual

You can also manually send a query to the driver without going through Fluent.

```swift
let query = try User.makeQuery()
...

let results = try mysqlDriver.query(query)
```
