---
currentMenu: guide-sessions
---

# Sessions

Sessions help you store information about a user between requests. As long as the client supports cookies, sessions are easy to create.

## Middleware

Enable sessions on your `Droplet` by adding an instance of `SessionMiddleware`.

```swift
import Sessions

let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
```

Then add to the `Droplet`.

```
let drop = Droplet()
drop.middleware.append(sessions)
```

> Note: If you'd like to enable or disable the middleware based on config files, check out [middleware](../guide/middleware.md).

## Request

After `SessionMiddleware` has been enabled, you can access the `req.sessions()` method to get access to session data.

```swift
let data = try req.session().data
```

## Example

Let's create an example that remembers the user's name.

### Store

```swift
drop.post("remember") { req in
    guard let name = req.data["name"]?.string else {
        throw Abort.badRequest
    }

    try req.session().data["name"] = Node.string(name)

    return "Remebered name."
}
```

On `POST /remember`, fetch a `name` from the request input, then store this name into the session data.

### Fetch

On `GET /remember`, fetch the `name` from the session data and return it.

```swift
drop.get("remember") { req in
    guard let name = try req.session().data["name"]?.string else {
        return throw Abort.custom(status: .badRequest, message: "Please POST the name first.")
    }

    return name
}
```

## Cookie

The session will be stored using the `vapor-session` cookie. 




