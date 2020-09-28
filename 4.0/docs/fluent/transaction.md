# Transactions

Transactions allow you to ensure multiple operations complete succesfully before saving data to your database. 
Once a transaction is started, you may run Fluent queries normally. However, no data will be saved to the database until the transaction completes. 
If an error is thrown at any point during the transaction (by you or the database), none of the changes will take effect.

To perform a transcation, you need access to something that can connect to the database.
This is usually an incoming HTTP request. Use the `req.db.transaction(_ closure:)` method.
```swift
req.db.transaction { (database) -> EventLoopFuture<Void> in
    // use database
}
```
Once inside the transaction closure, you must use the supplied database (named `database` in the example) to perform queries.

The closure expects an `EventLoopFuture<T>` return value. Once this future completes succesfully, the transaction will be commited.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { (database) -> EventLoopFuture<Void> in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
The above example will save `sun` and *then* `sirius` before completing the transaction. If either star fails to save, neither will save.

Once the transaction is completed, the result can be transformed to, for example, a simple HTTP status response to indicate completion as shown below.
```swift
return req.db.transaction { (database) -> EventLoopFuture<Void> in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```
