# Async

## Async Await

Swift 5.5 introduced concurrency to the language in the form of `async`/`await`. This provides a first-class way of handling asynchronous code in Swift and Vapor applications.

Vapor is built on top of [SwiftNIO](https://github.com/apple/swift-nio.git), which provides primitive types for low-level asynchronous programming. These were (and still are) used throughout Vapor before `async`/`await` arrived. However, most app code can now be written using `async`/`await` instead of using `EventLoopFuture`s. This will simplify your code and make it much easier to reason about.

Most of Vapor's APIs now offer both `EventLoopFuture` and `async`/`await` versions for you to choose which is best. In general, you should only use one programming model per route handler and not mix and match in your code. For applications that need explicit control over event loops, or very high performance applications, you should continue to use `EventLoopFuture`s until custom executors are implemented. For everyone else, you should use `async`/`await` as the benefits or readability and maintainability far outweigh any small performance penalty.

### Migrating to async/await

There are a few steps needed to migrate to async/await. To start with, if using macOS you must be on macOS 12 Monterey or greater and Xcode 13.1 or greater. For other platforms you need to be running Swift 5.5 or greater. Next, make sure you've updated all your dependencies.

In your Package.swift, set the tools version to 5.5 at the top of the file:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Next, set the platform version to macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Finally update the `Run` target to mark it as an executable target:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Note: if you are deploying on Linux make sure you update the version of Swift there as well, e.g. on Heroku or in your Dockerfile. For example your Dockerfile would change to:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Now you can migrate existing code. Generally functions that return `EventLoopFuture`s are now `async`. For example:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Now becomes:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Working with old and new APIs

If you encounter APIs that don't yet offer an `async`/`await` version, you can call `.get()` on a function that returns an `EventLoopFuture` to convert it.

E.g.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

Can become

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

If you need to go the other way around you can convert

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

to

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`s

You may have noticed some APIs in Vapor expect or return a generic `EventLoopFuture` type. If this is your first time hearing about futures, they might seem a little confusing at first. But don't worry, this guide will show you how to take advantage of their powerful APIs. 

Promises and futures are related, but distinct, types. Promises are used to _create_ futures. Most of the time, you will be working with futures returned by Vapor's APIs and you will not need to worry about creating promises.

|type|description|mutability|
|-|-|-|
|`EventLoopFuture`|Reference to a value that may not be available yet.|read-only|
|`EventLoopPromise`|A promise to provide some value asynchronously.|read/write|

Futures are an alternative to callback-based asynchronous APIs. Futures can be chained and transformed in ways that simple closures cannot.

## Transforming

Just like optionals and arrays in Swift, futures can be mapped and flat-mapped. These are the most common operations you will perform on futures.

|method|argument|description|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Maps a future value to a different value.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Maps a future value to a different value or an error.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Maps a future value to different _future_ value.|
|[`transform`](#transform)|`U`|Maps a future to an already available value.|

If you look at the method signatures for `map` and `flatMap` on `Optional<T>` and `Array<T>`, you will see that they are very similar to the methods available on `EventLoopFuture<T>`.

### map

The `map` method allows you to transform the future's value to another value. Because the future's value may not be available yet (it may be the result of an asynchronous task) we must provide a closure to accept the value.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

The `flatMapThrowing` method allows you to transform the future's value to another value _or_ throw an error. 

!!! info
    Because throwing an error must create a new future internally, this method is prefixed `flatMap` even though the closure does not accept a future return.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

The `flatMap` method allows you to transform the future's value to another future value. It gets the name "flat" map because it is what allows you to avoid creating nested futures (e.g., `EventLoopFuture<EventLoopFuture<T>>`). In other words, it helps you keep your generics flat.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    If we instead used `map` in the above example, we would have ended up with: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

To call a throwing method inside of a `flatMap`, use Swift's `do` / `catch` keywords and create a [completed future](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

The `transform` method allows you to modify a future's value, ignoring the existing value. This is especially useful for transforming the results of `EventLoopFuture<Void>` where the actual value of the future is not important.

!!! tip
    `EventLoopFuture<Void>`, sometimes called a signal, is a future whose sole purpose is to notify you of completion or failure of some async operation.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Even though we have supplied an already-available value to `transform`, this is still a _transformation_. The future will not complete until all previous futures have completed (or failed).

### Chaining

The great part about transformations on futures is that they can be chained. This allows you to express many conversions and subtasks easily.

Let's modify the examples from above to see how we can take advantage of chaining.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

After the initial call to map, there is a temporary `EventLoopFuture<URL>` created. This future is then immediately flat-mapped to a `EventLoopFuture<Response>`
    
## Future

Let's take a look at some other methods for using `EventLoopFuture<T>`.

### makeFuture

You can use an event loop to create pre-completed future with either the value or an error.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


You can use `whenComplete` to add a callback that will be executed when the future succeeds or fails.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    You can add as many callbacks to a future as you want.
    
### Wait

You can use `.wait()` to synchronously wait for the future to be completed. Since a future may fail, this call is throwing.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` can only be used on a background thread or the main thread, i.e., in `configure.swift`. It can _not_ be used on an event loop thread, i.e., in route closures.

!!! warning
    Attempting to call `wait()` on an event loop thread will cause an assertion failure.

    
## Promise

Most of the time, you will be transforming futures returned by calls to Vapor's APIs. However, at some point you may need to create a promise of your own.

To create a promise, you will need access to an `EventLoop`. You can get access to an event loop from `Application` or `Request` depending on context.

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    A promise can only be completed once. Any subsequent completions will be ignored.

Promises can be completed (`succeed` / `fail`) from any thread. This is why promises require an event loop to be initialized. Promises ensure that the completion action gets returned to its event loop for execution.

## Event Loop

When your application boots, it will usually create one event loop for each core in the CPU it is running on. Each event loop has exactly one thread. If you are familiar with event loops from Node.js, the ones in Vapor are similar. The main difference is that Vapor can run multiple event loops in one process since Swift supports multi-threading.

Each time a client connects to your server, it will be assigned to one of the event loops. From that point on, all communication between the server and that client will happen on that same event loop (and by association, that event loop's thread). 

The event loop is responsible for keeping track of each connected client's state. If there is a request from the client waiting to be read, the event loop triggers a read notification, causing the data to be read. Once the entire request is read, any futures waiting for that request's data will be completed. 

In route closures, you can access the current event loop via `Request`. 

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor expects that route closures will stay on `req.eventLoop`. If you hop threads, you must ensure access to `Request` and the final response future all happen on the request's event loop. 

Outside of route closures, you can get one of the available event loops via `Application`. 

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

You can change a future's event loop using `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

Calling blocking code on an event loop thread can prevent your application from responding to incoming requests in a timely manner. An example of a blocking call would be something like `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` is a command that blocks the current thread for the number of seconds supplied. If you do blocking work like this directly on an event loop, the event loop will be unable to respond to any other clients assigned to it for the duration of the blocking work. In other words, if you do `sleep(5)` on an event loop, all of the other clients connected to that event loop (possibly hundreds or thousands) will be delayed for at least 5 seconds. 

Make sure to run any blocking work in the background. Use promises to notify the event loop when this work is done in a non-blocking way.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

Not all blocking calls will be as obvious as `sleep(_:)`. If you are suspicious that a call you are using may be blocking, research the method itself or ask someone. The sections below go over how methods can block in more detail.

### I/O Bound

I/O bound blocking means waiting on a slow resource like a network or hard disk which can be orders of magnitude slower than the CPU. Blocking the CPU while you wait for these resources results in wasted time. 

!!! danger
    Never make blocking I/O bound calls directly on an event loop.

All of Vapor's packages are built on SwiftNIO and use non-blocking I/O. However, there are many Swift packages and C libraries in the wild that use blocking I/O. Chances are if a function is doing disk or network IO and uses a synchronous API (no callbacks or futures) it is blocking.
    
### CPU Bound

Most of the time during a request is spent waiting for external resources like database queries and network requests to load. Because Vapor and SwiftNIO are non-blocking, this downtime can be used for fulfilling other incoming requests. However, some routes in your application may need to do heavy CPU bound work as the result of a request.

While an event loop is processing CPU bound work, it will be unable to respond to other incoming requests. This is normally fine since CPUs are fast and most CPU work web applications do is lightweight. But this can become a problem if routes with long running CPU work are preventing requests to faster routes from being responded to quickly. 

Identifying long running CPU work in your app and moving it to background threads can help improve the reliability and responsiveness of your service. CPU bound work is more of a gray area than I/O bound work, and it is ultimately up to you to determine where you want to draw the line. 

A common example of heavy CPU bound work is Bcrypt hashing during user signup and login. Bcrypt is deliberately very slow and CPU intensive for security reasons. This may be the most CPU intensive work a simple web application actually does. Moving hashing to a background thread can allow the CPU to interleave event loop work while calculating hashes which results in higher concurrency.
