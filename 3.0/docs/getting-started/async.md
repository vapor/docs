# Async

You may have noticed some APIs in Vapor expect or return a generic `Future` type. If this is your first time hearing about futures, they might seem a little confusing at first. But don't worry, Vapor makes them easy to use.

This guide will give you a quick introduction to working with Async. Check out [Async → Overview](../async/overview.md) for more information.

## Futures

Since `Future`s work asynchronously, we must use closures to interact with and transform their values. Just like optionals in Swift, futures can be mapped and flat-mapped. 

### Map

The `.map(to:_:)` method allows you to transform the future's value to another value. The closure provided will be called once the `Future`'s data becomes available. 

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map(to: Int.self) { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // Future<Int>
```

### Flat Map

The `.flatMap(to:_:)` method allows you to transform the future's value to another future value. It gets the name "flat" map because it is what allows you to avoid creating nested futures (e.g., `Future<Future<T>>`). In other words, it helps you keep your futures flat.

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Flat-map the future string to a future response
let futureResponse = futureString.flatMap(to: Response.self) { string in
    return client.get(string) // Future<Response>
}

/// We now have a future response
print(futureResponse) // Future<Response>
```

!!! info
    If we instead used `.map(to:_:)` in the above example, we would have ended up with a `Future<Future<Response>>`. Yikes!
    

### Chaining

The great part about transformations on futures is that they can be chained. This allows you to express many conversions and subtasks easily.

Let's modify the examples from above to see how we can take advantage of chaining.

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.map(to: URL.self) { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap(to: Response.self) { url in
    return client.get(url)
}

print(futureResponse) // Future<Response>
```

After the initial call to map, there is a temporary `Future<URL>` created. This future is then immediately flat-mapped to a `Future<Response>`

!!! tip
    You can `throw` errors inside of map and flat-map closures. This will result in the future failing with the error thrown.

## Worker

You may see methods in Vapor that have an `on: Worker` parameter. These are usually methods that perform asynchronous work and require access to the `EventLoop`.

The most common `Worker`s you will interact with in Vapor are:

- `Application`
- `Request`
- `Response`

```swift
/// Assume we have a Request and some ViewRenderer
let req: Request = ...
let view: ViewRenderer = ...

/// Render the view, using the Request as a worker. 
/// This ensures the async work happens on the correct event loop.
///
/// This assumes the signature is:
/// func render(_: String, on: Worker)
view.render("home.html", on: req)
```