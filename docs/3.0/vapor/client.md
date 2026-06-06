# Using Client

[`Client`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html) is a convenience wrapper around the lower level [HTTP &rarr; Client](../http/client.md). It automatically parses things like hostname and port from URIs and helps you encode and decode [Content](content.md).

```swift
let res = try req.client().get("http://vapor.codes")
print(res) // Future<Response>
```

## Container

The first thing you will need is a service [Container](../getting-started/services.md#container) to create your client.

If you are making this external API request as the result of an incoming request to your server, you should use the `Request` container to create a client.  This is most often the case. 

If you need a client during boot, use the `Application` or if you are in a `Command` use the command context's container.

Once you have a `Container`, use the [`client()`](https://api.vapor.codes/vapor/latest/Vapor/Extensions/Container.html#/s:5Vapor6clientXeXeF) method to create a `Client`.

```swift
// Creates a generic Client
let client = try container.client()
```

## Send

Once you have a `Client`, you can use the [`send(...)`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html#/s:5Vapor6ClientP4sendXeXeF) method to send a `Request`. Note that the request URI must include a scheme and hostname.

```swift
let req: Request ...
let res = try client.send(req)
print(res) // Future<Response>
```

You can also use the convenience methods like [`get(...)`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html#/s:5Vapor6ClientPAAE3getXeXeF), [`post(...)`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html#/s:5Vapor6ClientPAAE4postXeXeF), etc.

```swift
let user: User ...
let res = try client.post("http://api.vapor.codes/users") { post in
    try post.content.encode(user)
}
print(res) // Future<Response>
```

See [Content](./content.md) for more information on encoding and decoding content to messages.
