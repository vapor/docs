---
currentMenu: guide-middleware
---

# Middleware

Middleware is an essential part of any modern web framework. It allows you to modify requests and responses as they pass between the client and your server.

You can imagine middleware as a chain of logic connecting your server to the client requesting your web app.

## Basic

As an example, let's create a middleware that will add the version of our API to each response. The middleware would look something like this:

```swift
final class VersionMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        response.headers["Version"] = "API v1.0"

        return response
    }
}
```

We then supply this middleware to our `Droplet`.

```swift
let drop = Droplet()
drop.middleware.append(VersionMiddleware())
```

You can imagine our `VersionMiddleware` sitting in the middle of a chain that connects the client and our server. Every request and response that hits our server must go through this chain of middleware.

![Middleware](https://cloud.githubusercontent.com/assets/1342803/17382676/0b51d6d6-59a0-11e6-9cbb-7585b9ab9803.png)


## Breakdown

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
        throw Abort.badRequest
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

Say there is a custom error that either you defined or one of the APIs you are using `throws`. This error must be caught when thrown, or else it will end up as a server error which may be unexpected to a user. The most obvious solution is to catch the error in the route closure.

```swift
app.get("foo") { request in
    let foo: Foo
    do {
        foo = try getFooFromService()
    } catch {
        throw Abort.badRequest
    }

    // continue with Foo object
}
```

This solution works, but it would get repetitive if repeated throughout multiple routes. It can also easily lead to code duplication. Luckily, this error could be caught in a middleware instead.

```swift
final class FooErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch FooError.fooServiceUnavailable {
            throw Abort.custom(
                status: .badRequest,
                message: "Sorry, we were unable to query the Foo service."
            )
        }
    }
}
```

We just need to append this middleware to the `Droplet`.

```swift
drop.middleware.append(FooErrorMiddleware())
```

Now our route closures look a lot better and we don't have to worry about code duplication.

```swift
app.get("foo") { request in
    let foo = try getFooFromService()

    // continue with Foo object
}
```

Interestingly, this is how `Abort` itself is implemented in Vapor. `AbortMiddleware` catches any `Abort` errors and returns a JSON response. Should you want to customize how `Abort` errors appear, you can remove this middleware and add your own.

## Configuration

Appending middleware to the `drop.middleware` array is the simplest way to add middleware--it will be used every time the application starts.

You can also use the [configuration](config.md) files to enabled or disable middleware for more control. This is especially useful if you have middleware that should, for example, run only in production.

Appending configurable middleware looks like the following:

```swift
let drop = Droplet()
drop.addConfigurable(middleware: myMiddleware, name: "my-middleware")
```

Then, in the `Config/droplet.json` file, add `my-middleware` to the appropriate `middleware` array.

```json
{
    ...
    "middleware": {
        "server": [
            ...
            "my-middleware",
            ...
        ],
        "client": [
            ...
        ]
    },
    ...
}
```

If the name of the added middleware appears in the `server` array for the loaded configuration, it will be added to the server's middleware when the application boots.

Likewise, if the middleware appears in the `client` array for the loaded configuration, it will be added to the client's middleware.

One middleware can be appended to both the Client and the Server, and can be added multiple times. The ordering of middleware is respected.

## Extensions (Advanced)

Middleware pairs great with request/response extensions and storage.

```swift
final class PokemonMiddleware: Middleware {
    let drop: Droplet
    init(drop: Droplet) {
        self.drop = drop
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        if let pokemon = response.pokemon {
            if request.accept.prefers("html") {
                response.view = try drop.view("pokemon.mustache", context: pokemon)
            } else {
                response.json = try pokemon.makeJSON()
            }
        }

        return response
    }
}
```

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

Your closures can now look something like this:

```swift
import HTTP

drop.get("pokemon", Pokemon.self) { request, pokemon in
    let response = Response()
    response.pokemon = pokemon
    return response
}
```

Or, if you want to go a step further, you can make `Pokemon` conform to `ResponseRepresentable`.

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

Now your route closures are greatly simplified and you don't need to `import HTTP`.

```swift
drop.get("pokemon", Pokemon.self) { request, pokemon in
    return pokemon
}
```

Middleware is incredibly powerful. Combined with extensions, it allows you to add functionality that feels native to the framework.

For those that are curious, this is how Vapor manages JSON internally. Whenever you return JSON in a closure, it sets the `json: JSON?` property on `Response`. The `JSONMiddleware` then detects this property and serializes the JSON into the body of the response.
