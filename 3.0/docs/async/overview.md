# Async Overview

You may have noticed some APIs in Vapor expect or return a generic `Future` type. If this is your first time hearing about futures, they might seem a little confusing at first. But don't worry, Vapor makes them easy to use.

Promises and futures are related, but distinct, types. Promises are used to _create_ futures. Most of the time, you will be working with futures returned by Vapor's APIs and you will not need to worry about creating promises.

|type     |description                                          |mutability|methods                                         |
|---------|-----------------------------------------------------|----------|----------------------------------------------------|
|`Future` |Reference to an object that may not be available yet.|read-only |`.map(to:_:)` `.flatMap(to:_:)` `do(_:)` `catch(_:)`|
|`Promise`                                                     |A promise to provide some object asynchronously.     |read/write|`succeed(_:)` `fail(_:)`                            |

Futures are an alternative to callback-based asynchronous APIs. Futures can be chained and transformed in ways that simple closures cannot, making them quite powerful.

## Transforming

Just like optionals in Swift, futures can be mapped and flat-mapped. These are the most common operations you will perform on futures.

|method   |signature |description|
|---------|------------------|-----|
|`map`    |`to: U.Type, _: (T) -> U`        |Maps a future value to a different value.
|`flatMap`|`to: U.Type, _: (T) -> Future<U>`|Maps a future value to different _future_ value.|
|`transform`         |`to: U`                  |Maps a future to an already available value.|

If you look at the method signatures for `map` and `flatMap` on `Optional<T>` and `Array<T>`, you will see that they are very similar to the methods available on `Future<T>`.

### Map

The `.map(to:_:)` method allows you to transform the future's value to another value. Because the future's value may not be available yet (it may be the result of an asynchronous task) we must provide a closure to accept the value.

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

The `.flatMap(to:_:)` method allows you to transform the future's value to another future value. It gets the name "flat" map because it is what allows you to avoid creating nested futures (e.g., `Future<Future<T>>`). In other words, it helps you keep your generic futures flat.

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
    
### Transform

The `.transform(_:)` method allows you to modify a future's value, ignoring the existing value. This is especially useful for transforming the results of `Future<Void>` where the actual value of the future is not important.

!!! tip
    `Future<Void>`, sometimes called a signal, is a future whose sole purpose is to notify you of completion or failure of some async operation.

```swift
/// Assume we get a void future back from some API
let userDidSave: Future<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // Future<HTTPStatus>
```   

Even though we have supplied an already-available value to `transform`, this is still a _transformation_. The future will not complete until all previous futures have completed (or failed).

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
    
## Future

Let's take a look at some other, less commonly used methods on `Future<T>`.

### Do / Catch

Similar to Swift's `do` / `catch` syntax, futures have a `do` and `catch` method for awaiting the future's result.

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

futureString.do { string in
    print(string) // The actual String
}.catch { error in
    print(error) // A Swift Error
}
```

!!! info
    `.do` and `.catch` work together. If you forget `.catch`, the compiler will warn you about an unused result. Don't forget to handle the error case!

### Always

You can use `always` to add a callback that will be executed whether the future succeeds or fails.

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

futureString.always {
    print("The future is complete!")
}
```

!!! note
    You can add as many callbacks to a future as you want.
    
### Wait

You can use `.wait()` to synchronously wait for the future to be completed. Since a future may fail, this call is throwing.

```swift
/// Assume we get a future string back from some API
let futureString: Future<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

!!! warning
    Do not use this method in route closures or controllers. Read the section about [Blocking](#blocking) for more information.

    
## Promise

Most of the time, you will be transforming futures returned by calls to Vapor's APIs. However, at some point you may need to create a promise of your own.

To create a promise, you will need access to an `EventLoop`. All containers in Vapor have an `eventLoop` property that you can use. Most commonly, this will be the current `Request`.

```swift
/// Create a new promise for some string
let promiseString = req.eventLoop.newPromise(String.self)
print(promiseString) // Promise<String>
print(promiseString.futureResult) // Future<String>

/// Completes the associated future
promiseString.succeed(result: "Hello")

/// Fails the associated future
promiseString.fail(error: ...)
```

!!! info
    A promise can only be completed once. Any subsequent completions will be ignored.
    
### Thread Safety

Promises can be completed (`succeed(result:)` / `fail(error:)`) from any thread. This is why promises require an event-loop to be initialized. Promises ensure that the completion action gets returned to its event-loop for execution.

## Event Loop

When your application boots, it will usually create one event loop for each core in the CPU it is running on. Each event loop has exactly one thread. If you are familiar with event loops from Node.js, the ones in Vapor are very similar. The only difference is that Vapor can run multiple event loops in one process since Swift supports multi-threading.

Each time a client connects to your server, it will be assigned to one of the event loops. From that point on, all communication between the server and that client will happen on that same event loop (and by association, that event loop's thread). 

The event loop is responsible for keeping track of each connected client's state. If there is a request from the client waiting to be read, the event loop trigger a read notification, causing the data to be read. Once the entire request is read, any futures waiting for that request's data will be completed. 

### Worker

Things that have access to an event loop are called `Workers`. Every container in Vapor is a worker. 

The most common containers you will interact with in Vapor are:

- `Application`
- `Request`
- `Response`

You can use the `.eventLoop` property on these containers to gain access to the event loop.

```swift
print(app.eventLoop) // EventLoop
```

There are many methods in Vapor that require the current worker to be passed along. It will usually be labeled like `on: Worker`. If you are in a route closure or a controller, pass the current `Request` or `Response`. If you need a worker while booting your app, use the `Application`.

### Blocking

An absolutely critical rule is the following:

!!! danger
    Never make blocking calls directly on an event loop.
    
An example of a blocking call would be something like `libc.sleep(_:)`.

```swift
router.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` is a command that blocks the current thread for the number of seconds supplied. If you do blocking work directly on an event loop, the event loop will be unable to respond to any other clients assigned to it for the duration of the blocking work. In other words, if you do `sleep(5)` on an event loop, all of the other clients connected to that event loop (possibly hundreds or thousands) will be delayed for at least 5 seconds.

Make sure to run any blocking work in the background. Use promises to notify the event loop when this work is done in a non-blocking way.

```swift
router.get("hello") { req in
    /// Create a new void promise
    let promise = req.eventLoop.newPromise(Void.self)
    
    /// Dispatch some work to happen on a background thread
    DispatchQueue.global() {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// complete the promise and its associated future.
        promise.succeed()
    }
    
    /// Wait for the future to be completed, 
    /// then transform the result to a simple String
    return promise.futureResult.transform(to: "Hello, world!")
}
```

Not all blocking calls will be as obvious as `sleep(_:)`. If you are suspicious that a call you are using may be blocking, research the method itself or ask someone. Chances are if the function is doing disk or network IO and uses a synchronous API (no callbacks or futures) it is blocking.

!!! info
    If doing blocking work is a central part of your application, you should consider using a `BlockingIOThreadPool` to control the number of threads you create to do blocking work. This will help you avoid starving your event loops from CPU time while blocking work is being done.

    
