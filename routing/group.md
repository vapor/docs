---
currentMenu: routing-group
---

# Route Groups

Grouping routes together makes it easy to add common prefixes, middleware, or hosts to multiple routes.

Route groups have two different forms: Group and Grouped.

### Group

Group (without the "ed" at the end) takes a closure that is passed a `GroupBuilder`.

```swift
drop.group("v1") { v1 in
    v1.get("users") { request in
        // get the users
    }
}
```

### Grouped

Grouped returns a `GroupBuilder` that you can pass around.

```swift
let v1 = drop.grouped("v1")
v1.get("users") { request in
    // get the users
}
```

### Middleware

You can add middleware to a group of routes. This is especially useful for authentication.

```swift
drop.group(AuthMiddleware()) { authorized in 
    authorized.get("token") { request in
        // has been authorized
    }
}
```

### Host

You can limit the host for a group of routes.

```swift
drop.group(host: "vapor.codes") { vapor
    vapor.get { request in
        // only responds to requests to vapor.codes
    }
}
```

### Chaining

Groups can be chained together.

```swift
drop.grouped(host: "vapor.codes").grouped(AuthMiddleware()).group("v1") { authedSecureV1 in
    // add routes here
}
```

