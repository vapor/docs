# Fluent Transactions

Transactions allow you to ensure multiple operations complete succesfully before saving data to your database. Once a transaction is started, you may run Fluent queries normally. However, no data will be saved to the database until the transaction completes. If an error is thrown at any point during the transaction (by you or the database), none of the changes will take effect.

To perform a transaction, you need access to something that can connect to the database. This is usually an incoming HTTP request. Use the [`transaction(on:_:)`](#fixme) method.

Fill in the Xcode placeholders below with your database's name from [Getting Started &rarr; Choosing a Driver](getting-started/#choosing-a-driver).

```swift
req.transaction(on: .<#dbid#>) { conn in
    // use conn as your connection
}
```

Once inside the transaction closure, you must use the supplied connection (named `conn` in the example) to perform queries. 

The closure expects a generic future return value. Once this future completes succesfully, the transaction will be committed. 

```swift
var userA: User = ...
var userB: User = ...

return req.transaction(on: .<#dbid#>) { conn in
    return userA.save(on: conn).flatMap { _ in
        return userB.save(on: conn)
    }.transform(to: HTTPStatus.ok)
}
```

The above example will save User A _then_ User B before completing the transaction. If either user fails to save, neither will save. Once the transaction has completed, the result is transformed to a simple HTTP status response indicating completion.
