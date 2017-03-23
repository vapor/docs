---
currentMenu: auth-protect
---

# Protect

Once the `AuthMiddleware` has been enabled, you can use `ProtectMiddleware` to prevent certain routes from being accessed without authorization.

## Create

To create a `ProtectMiddleware`, you must give it the error to throw in case authorization fails.

```swift
let error = Abort.custom(status: .forbidden, message: "Invalid credentials.")
let protect = ProtectMiddleware(error: error)
```

Here we pass it a simple 403 response.

## Route Group

Once the middleware has been created, you can add it to route groups. Learn more about middleware and routing in [route groups](../routing/group.md).

```
drop.grouped(protect).group("secure") { secure in
    secure.get("about") { req in
        let user = try req.user()
        return user
    }
}
```

Visiting `GET /secure/about` will return the authorized user, or an error if no user is authorized.
