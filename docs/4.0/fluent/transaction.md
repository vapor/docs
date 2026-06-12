# Transactions

Transactions allow you to ensure multiple operations complete successfully before saving data to your database. 
Once a transaction is started, you may run Fluent queries normally. However, no data will be saved to the database until the transaction completes. 
If an error is thrown at any point during the transaction (by you or the database), none of the changes will take effect.

To perform a transaction, you need access to something that can connect to the database. This is usually an incoming HTTP request. For this, use `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // use database
}
```
Once inside the transaction closure, you must use the database supplied in the closure parameter (named `database` in the example) to perform queries.

Once this closure returns successfully, the transaction will be committed.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
The above example will save `sun` and *then* `sirius` before completing the transaction. If either star fails to save, neither will save.

Once the transaction completes, the result can be transformed into a different future, for example into a HTTP status to indicate completion as shown below:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

If using `async`/`await` you can refactor the code to the following:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
