---
currentMenu: guide-json
---

# JSON

JSON is an integral part of Vapor. It powers Vapor's [Config](config.md) and is incredibly easy to use in both requests and responses.

## Request

JSON is automatically available in `request.data` alongside form-urlencoded data and query data. This allows you to focus on making a great API, not worrying about what content types data will be sent in.

```swift
drop.get("hello") { request in
    guard let name = request.data["name"]?.string else {
        throw Abort.badRequest
    }
    return "Hello, \(name)!"
}
```

This will return a greeting for any HTTP method or content type that the `name` is sent as, including JSON.

### JSON Only

To specifically target JSON, use the `request.json` property.

```swift
drop.post("json") { request in
    guard let name = request.json?["name"]?.string else {
        throw Abort.badRequest
    }

    return "Hello, \(name)!"
}
```
The above snippet will only work if the request is sent with JSON data.

## Response

To respond with JSON, simply wrap your data structure with `JSON(node: )`

```swift
drop.get("version") { request in
    return try JSON(node: [
    	"version": "1.0"
    ])
}
```

## Middleware

The `JSONMiddleware` is included in the `Droplet`'s middleware by default. You can remove it if you don't want JSON to be parsed.
