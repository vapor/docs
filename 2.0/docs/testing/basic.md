!!! warning
    This section may contain outdated information.

# Basic Testing

Testing is a critical part of any software application, and Vapor apps should be no different. In this documentation, we'll cover some of the basic setup required to be able to test against our `Droplet`.

## Displacing Droplet Creation Logic

Up to this point, a lot of our documentation has centered around putting our `Droplet` creation logic in `main.swift`. Unfortunately, when testing against our application, this code becomes largely inaccessible. The first thing we'll need to do is break this out into the `AppLogic` module.

Here's an example of my setup file. I name mine `Droplet+Setup.swift`. Here's how it might look:

```swift
import Vapor

public func load(_ drop: Droplet) throws {
    drop.preparations.append(Todo.self)

    drop.get { _ in return "put my droplet's logic in this `load` function" }

    drop.post("form") { req in
      ...
      return Response(body: "Successfully posted form.")
    }

    // etc.
}
```

> [WARNING] Do **not** call `run()` anywhere within the `load` function as `run()` is a blocking call.

## Updated `main.swift`

Now that we've abstracted our loading logic, we'll need to update our `main.swift` **in the `App` module** to reflect those changes. Here's how it should look after:

```swift
let drop = Droplet(...)
try load(drop)
drop.run()
```

> The reason we still initialize `Droplet` outside of the scope of `load` is so that we can have the option to initialize differently for testing. We'll cover that soon.

## Testable Droplet

The first thing we'll do is in my testing target, add a file called `Droplet+Test.swift`. It will look like this:

```swift
@testable import Vapor

func makeTestDroplet() throws -> Droplet {
    let drop = Droplet(arguments: ["dummy/path/", "prepare"], ...)
    try load(drop)
    try drop.runCommands()
    return drop
}
```

This looks a lot like our initializer in `main.swift`, but there are 3 very key differences.

### Droplet(arguments: ["dummy/path/", "prepare"], ...

The `arguments:` parameter in our `Droplet` creation. This is rarely used except for advanced situations, but we'll use it here in testing to ensure that our `Droplet` doesn't try to automatically `serve` and block our thread. You can use arguments besides `"prepare"`, but unless you're doing something specific for an advanced situation, these arguments should suffice.

### try drop.runCommands()

You'll notice here that we're calling `runCommands()` instead of `run()`. This allows the `Droplet` to do all the setup it would normally do before booting without actually binding to a socket or exiting.

### `@testable import Vapor`

We'll need to import the testable compilation of Vapor to access the `runCommands` function. This is currently not public as a protection against accidental bugs in live apps.

## Test Our Droplet

Now that all of this has been created, we're ready to start testing our application's `Droplet`. Here's how a really basic test might look:

```swift
@testable import AppLogic

func testEndpoint() throws {
    let drop = try makeTestDroplet()
    let request = ...
    let expectedBody = ...

    let response = try drop.respond(to: request)
    XCTAssertEqual(expectedBody, response.body.bytes)
}
```

Notice that now you can use `CMD-U` to run your tests in Xcode with in-line results. In addition, you can run `vapor test` to test your code from the command line. If you choose to use `swift build` instead and you are using MySQL in your app, make sure you add the correct build flags to the call. 

Good luck, and happy testing!
