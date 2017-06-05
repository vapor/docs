# Middleware

Middleware is an essential part of any modern web framework. It allows you to modify requests and responses as they pass between the client and your server.

You can imagine middleware as a chain of logic connecting your server to the client requesting your web app.

## Version Middleware

As an example, let's create a middleware that will add the version of our API to each response. The middleware would look something like this:

```swift
import HTTP

final class VersionMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        response.headers["Version"] = "API v1.0"

        return response
    }
}
```

In `Config+Setup.swift`, add the setupMiddlewares methods and call it in the setup method.

```swift
public func setup() throws {
    ...
    try setupMiddlewares()
}

/// Configure middlewares
private func setupMiddlewares() throws {
    try addConfigurable(middleware: VersionMiddleware(), name: "VersionMiddleware")
}
```

Then, in the `Config/droplet.json` file, add `VersionMiddleware` to the `middleware` array.

```json
{
    ...
    "middleware": [
        ...
        "VersionMiddleware",
        ...
    ],
    ...
}
```

The ordering of middleware is respected as per the ordering in the array.

You can imagine our `VersionMiddleware` sitting in the middle of a chain that connects the client and our server. Every request and response that hits our server must go through this chain of middleware.

![Middleware](https://cloud.githubusercontent.com/assets/1342803/17382676/0b51d6d6-59a0-11e6-9cbb-7585b9ab9803.png)


### Breakdown

Let's break down the middleware line by line.

```swift
let response = try next.respond(to: request)
```

Since the `VersionMiddleware` in this example is not interested in modifying the request, we immediately ask the next middleware in the chain to respond to the request. This goes all the way down the chain to the `Droplet` and comes back with the response that should be sent to the client.

```swift
response.headers["Version"] = "API v1.0"
```

We then _modify_ the response to contain a Version header.

```swift
return response
```

The response is returned and will chain back up any remaining middleware and back to the client.

## Request

The middleware can also modify or interact with the request.

```swift
func respond(to request: Request, chainingTo next: Responder) throws -> Response {
    guard request.cookies["token"] == "secret" else {
        throw Abort(.badRequest)
    }

    return try next.respond(to: request)
}
```

This middleware will require that the request has a cookie named `token` that equals `secret` or else the request will be aborted.

## Errors

Middleware is the perfect place to catch errors thrown from anywhere in your application. When you let the middleware catch errors, you can remove a lot of duplicated logic from your route closures. Take a look at the following example:

```swift
enum FooError: Error {
    case fooServiceUnavailable
}
```

Say there is a custom error that either you defined or one of the APIs you are using `throws`. This error must be caught when thrown, or else it will end up as an internal server error (500) which may be unexpected to a user. The most obvious solution is to catch the error in the route closure.

```swift
app.get("foo") { request in
    let foo: Foo
    do {
        foo = try getFooFromService()
    } catch {
        throw Abort(.badRequest)
    }

    // continue with Foo object
}
```

This solution works, but it would get repetitive if multiple routes need to handle the error. Luckily, this error could be caught in a middleware instead.

```swift
final class FooErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch FooError.fooServiceUnavailable {
            throw Abort(
                .badRequest,
                reason: "Sorry, we were unable to query the Foo service."
            )
        }
    }
}
```

In `Config+Setup.swift`, add the setupMiddlewares methods and call it in the setup method.

```swift
public func setup() throws {
...
try setupMiddlewares()
}

/// Configure middlewares
private func setupMiddlewares() throws {
    try addConfigurable(middleware: FooErrorMiddleware(), name: "FooErrorMiddleware")
}
```

Then, in the `Config/droplet.json` file, add `VersionMiddleware` to the `middleware` array.

```json
{
    ...
    "middleware": [
        ...
        "FooErrorMiddleware",
        ...
    ],
    ...
}
```

The ordering of middleware is respected as per the ordering in the array.

Now our route closures look a lot better and we don't have to worry about code duplication.

```swift
app.get("foo") { request in
    let foo = try getFooFromService()

    // continue with Foo object
}
```

## Route Groups

For more granularity, Middleware can be applied to specific route groups.

```swift
let authed = drop.grouped(AuthMiddleware())
authed.get("secure") { req in
    return Secrets.all().makeJSON()
}
```

Anything added to the `authed` group must pass through `AuthMiddleware`. Because of this, we can assume all traffic to `/secure` has been authorized. Learn more in [Routing](../routing/group).

## Advanced

### Extensions

Middleware pairs great with request/response extensions and storage. This example shows you how to dynamically return either HTML or JSON responses for a Model depending on the type of client.

#### Middleware

```swift
final class PokemonMiddleware: Middleware {
    let view: ViewProtocol
    init(_ view: ViewProtocol) {
        self.view = view
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        if let pokemon = response.pokemon {
            if request.accept.prefers("html") {
                response.view = try view.make("pokemon.mustache", pokemon)
            } else {
                response.json = try pokemon.makeJSON()
            }
        }

        return response
    }
}
```

#### Response

And the extension to `Response`.

```swift
extension Response {
    var pokemon: Pokemon? {
        get { return storage["pokemon"] as? Pokemon }
        set { storage["pokemon"] = newValue }
    }
}
```

In this example, we added a new property to response capable of holding a Pokémon object. If the middleware finds a response with one of these Pokémon objects, it will dynamically check whether the client prefers HTML. If the client is a browser like Safari and prefers HTML, it will return a Mustache view. If the client does not prefer HTML, it will return JSON.

#### Usage

Your closures can now look something like this:

```swift
import Vapor
import HTTP

let drop = try Droplet()

let pokemonMiddleware = PokemonMiddleware(drop.view)
drop.middleware.append(pokemonMiddleware)

drop.get("pokemon", Pokemon.self) { request, pokemon in
    let response = Response()
    response.pokemon = pokemon
    return response
}
```

#### Response Representable

If you want to go a step further, you can make `Pokemon` conform to `ResponseRepresentable`.

```swift
import HTTP

extension Pokemon: ResponseRepresentable {
    func makeResponse() throws -> Response {
        let response = Response()
        response.pokemon = self
        return response
    }
}
```

Now your route closures are greatly simplified.

```swift
drop.get("pokemon", Pokemon.self) { request, pokemon in
    return pokemon
}
```

Middleware is incredibly powerful. Combined with extensions, it allows you to add functionality that feels native to the framework.
