# Querying Models

Once you have a [model](models.md) (and optionally a [migration](migrations.md)) you can start
querying your database to create, read, update, and delete data.

## Connection

The first thing you need to query your database, is a connection to it. Luckily, they are easy to get.

You can use either the application or an incoming request to create a database connection. You just need
access to the database identifier.

### Request

The preferred method for getting access to a database connection is via an incoming request.

```swift
router.get(...) { req in
    return req.withConnection(to: .foo) { db in
        // use the db here
    }
}
```

The first parameter is the database's identifier. The second parameter is a closure
that accepts a connection to that database.

!!! tip
    Although the closure to `.withConnection(to: ...)` accepts a database _connection_, we often use just `db` for short.

The closure is expected to return a `Future<Void>`. When this future is completed, the connection will be released
back into Fluent's connection pool. This is usually acheived by simply returning the query as we will soon see.

### Application

You can also create a database connection using the application. This is useful for cases where you must access
the database from outside a request/response event.

```swift
let res = app.withConnection(to: .foo) { db in
    // use the db here
}
print(res) // Future<T>
```

This is usually done in the [boot section](../getting-started/structure.md#boot) of your application.

!!! warning
    Do not use database connections created by the application in a route closure (when responding to a request).
    Always use the incoming request to create a connection to avoid threading issues.

## Create

To create (save) a model to the database, first initialize an instance of your model, then call `.save(on: )`.

```swift
router.post(...) { req in
    return req.withConnection(to: .foo) { db -> Future<User> in
        let user = User(name: "Vapor", age: 3)
        return user.save(on: db).transform(to: user) // Future<User>
    }
}
```

### Response

`.save(on: )` returns a `Future<Void>` that completes when the user has finished saving. In this example, we then
map that `Future<Void>` to a `Future<User>` by calling `.map` and passing in the recently-saved user.

You can also use `.map` to return a simple success response.

```swift

router.post(...) { req in
    return req.withConnection(to: .foo) { db -> Future<HTTPResponse> in
        let user = User(name: "Vapor", age: 3)
        return user.save(on: db).map(to: HTTPResponse.self) {
            return HTTPResponse(status: .created)
        }
    }
}
```

### Multiple

If you have multiple instances to save, do so using an array. Arrays containing only futures behave like futures.

```swift
router.post(...) { req in
    return req.withConnection(to: .foo) { db -> Future<HTTPResponse> in
        let marie = User(name: "Marie Curie", age: 66)
        let charles = User(name: "Charles Darwin", age: 73)
        return [
            marie.save(on: db),
            charles.save(on: db)
        ].map(to: HTTPResponse.self) {
            return HTTPResponse(status: .created)
        }
    }
}
```

## Read

To read models from the database, use `.query()` on the database connection to create a [QueryBuilder](../query-builder).

### All

Fetch all instances of a model from the database using `.all()`.

```swift
router.get(...) { req in
    return req.withConnection(to: .foo) { db -> Future<[User]> in
        return db.query(User.self).all()
    }
}
```

### Filter

Use `.filter(...)` to apply [filters](../query-builder#filters) to your query.

```swift
router.get(...) { req in
    return req.withConnection(to: .foo) { db -> Future<[User]> in
        return try db.query(User.self).filter(\User.age > 50).all()
    }
}
```

### First

You can also use `.first()` to just get the first result.

```swift
router.get(...) { req in
    return req.withConnection(to: .foo) { db -> Future<User> in
        return try db.query(User.self).filter(\User.name == "Vapor").first().map(to: User.self) { user in
            guard let user = user else {
                throw Abort(.notFound, reason: "Could not find user.")
            }

            return user
        }
    }
}
```

Notice we use `.map(to:)` here to convert the optional user returned by `.first()` to a non-optional
user, or we throw an error.

## Update

```swift
router.put(...) { req in
    return req.withConnection(to: .foo) { db -> Future<User> in
        return db.query(User.self).first().map(to: User.self) { user in
            guard let user = $0 else {
                throw Abort(.notFound, reason: "Could not find user.")
            }

            return user
        }.flatMap(to: User.self) { user in
            user.age += 1
            return user.update(on: db).map(to: User.self) { user }
        }
    }
}
```

Notice we use `.map(to:)` here to convert the optional user returned by `.first()` to a non-optional
user, or we throw an error.

## Delete
```swift
router.delete(...) { req in
    return req.withConnection(to: .foo) { db -> Future<User> in
        return db.query(User.self).first().map(to: User.self) { user in
            guard let user = $0 else {
                throw Abort(.notFound, reason: "Could not find user.")
            }
            return user
        }.flatMap(to: User.self) { user in
            return user.delete(on: db).transfom(to: user)
        }
    }
}
```

Notice we use `.map(to:)` here to convert the optional user returned by `.first()` to a non-optional
user, or we throw an error.
