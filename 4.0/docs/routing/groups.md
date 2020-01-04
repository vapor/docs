# Route Groups

Route grouping allows you to create a set of routes with a path prefix or specific middleware. Grouping supports a builder and closure based syntax.

All grouping methods return a `RouteBuilder` meaning you can infinitely mix, match, and nest your groups with other route building methods.

## Path Prefix

Path prefixing route groups allow you to prepend one or more path components to a group of routes. 

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Any path component you can pass into methods like `get` or `post` can be passed into `grouped`. There is an alternative, closure-based syntax as well.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

Nesting path prefixing route groups allows you to concisely define CRUD APIs.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

## Middleware

In addition to prefixing path components, you can also add middleware to route groups. 

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


This is especially useful for protecting subsets of your routes with different authentication middleware. 

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```