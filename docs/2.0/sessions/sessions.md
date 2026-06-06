# Sessions

Sessions help you store information about a user between requests. As long as the client supports cookies, sessions are easy to create.

## Middleware

Enable sessions on your `Droplet` by adding `"sessions"` to your middleware array.

`Config/droplet.json`
```json
{
    ...,
    "middleware": [
        ...,
        "sessions",
        ...,
    ],
    ...,
}
```

By default, the memory sessions driver will be used. You can change this with the `droplet.sessions` key.


`Config/droplet.json`
```json
{
    ...,
    "sessions": "memory",
    ...,
}
```

## Request

After `SessionMiddleware` has been enabled, you can access the `req.assertSession()` method to get access to session.

```swift
import Sessions

let session = try req.assertSession()
print(session.data)
```

## Example

Let's create an example that remembers the user's name.

### Store

```swift
drop.post("remember") { req in
    guard let name = req.data["name"]?.string else {
        throw Abort(.badRequest)
    }

    let session = try req.assertSession()
    try session.data.set("name", name)

    return "Remebered name."
}
```

On `POST /remember`, fetch a `name` from the request input, then store this name into the session data.

### Fetch

On `GET /remember`, fetch the `name` from the session data and return it.

```swift
drop.get("remember") { req in
    let session = try req.assertSession()

    guard let name = session.data["name"]?.string else {
        return throw Abort(.badRequest, reason: "Please POST the name first.")
    }

    return name
}
```

## Cookie

The session will be stored using the `vapor-session` cookie. 
