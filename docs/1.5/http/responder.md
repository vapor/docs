---
currentMenu: http-responder
---

> Module: `import HTTP`

# Responder

The `Responder` is a simple protocol defining the behavior of objects that can accept a `Request` and return a `Response`. Most notably in Vapor, it is the core API endpoint that connects the `Droplet` to the `Server`. Let's look at the definition:

```swift
public protocol Responder {
    func respond(to request: Request) throws -> Response
}
```

> The responder protocol is most notably related to Droplet and it's relationship with a server. Average users will not likely interact with it much.

## Simple

Of course, Vapor provides some conveniences for this, and in practice, we will often call:

```swift
try drop.run()
```

## Manual

As we just mentioned, the Vapor `Droplet` itself conforms to `Responder`, connecting it to the `Server`. This means if we wanted to serve our droplet manually, we could do:

```swift
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)
try server.start(responder: droplet)  { error in
    print("Got error: \(error)")
}
```

## Advanced

We can conform our own objects to `Responder` and pass them to `Servers`. Let's look at an example:

```swift
final class Responder: HTTP.Responder {
    func respond(to request: Request) throws -> Response {
        let body = "Hello World".makeBody()
        return Response(body: body)
    }
}
```

This only returns `"Hello World"` for every request, it's most commonly going to be linked with a router of some type.


```swift
final class Responder: HTTP.Responder {
    let router: Router = ...

    func respond(to request: Request) throws -> Response {
        return try router.route(request)
    }
}
```

We'll then pass this responder to a server and let it go.

```swift
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)

print("visit http://localhost:\(port)/")
try server.start(responder: Responder()) { error in
    print("Got error: \(error)")
}
```

This can be used as a jumping off point for applications looking to implement features manually.

## Client

The `HTTP.Client` is itself a `Responder` although, instead of handling the `Request` itself, it passes it on to the underlying URI. 
