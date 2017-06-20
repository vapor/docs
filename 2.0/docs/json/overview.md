# JSON

JSON is an integral part of Vapor. It powers Vapor's [Config](../configs/config.md) and is easy to use in both requests and responses.

## Request

JSON is automatically available in `request.data` alongside Form URL Encoded, Form Data, and Query data. This allows you to focus on making a great API, not worrying about what content types data will be sent in.

```swift
drop.get("hello") { request in
    guard let name = request.data["name"]?.string else {
        throw Abort(.badRequest)
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
        throw Abort(.badRequest)
    }

    return "Hello, \(name)!"
}
```
The above snippet will only work if the request is sent with JSON data.

## Response

To respond with JSON, simply create a `JSON` object and add values to it.

```swift
drop.get("version") { request in
    var json = JSON()
    try json.set("version", 1.0)
    return json
}
```

## Convertible

Making your classes and structs JSON convertible is a great way to interact with APIs in an organized and DRY way.

### Representable

When something conforms to `JSONRepresentable`, it can be converted into JSON.

```swift
extension User: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("name", name)
        try json.set("age", age)
        return json
    }
}
```

Now you can simply return `user.makeJSON()` in your routes.

```swift
drop.get("users", User.parameter) { req in
    let user = try req.parameters.next(User.self)
    return try user.makeJSON()
}
```

You can even go a step further and conform your model to `ResponseRepresentable`. Since it's already `JSONRepresentable`
you will get the conformance for free.

```swift
extension User: ResponseRepresentable { }
```

Now you can return the model by itself. It will automatically call `.makeJSON()`.

```swift
drop.get("users", User.parameter) { req in
    let user = try req.parameters.next(User.self)
    return try user
}
```

### Initializable

When something conforms to `JSONInitializable`, it can be created from JSON.

```swift
extension User: JSONInitializable {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get("name"),
            age: json.get("age")
        )
    }
}
```

Now you can simply call `User(json: ...)` to create a user from JSON.

```swift
drop.post("users") { req in
    guard let json = req.json else {
        throw Abort(.badRequest)
    }

    let user = try User(json: json)
    try user.save()
    return user
}
```
