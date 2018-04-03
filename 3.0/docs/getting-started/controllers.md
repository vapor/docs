# Controllers

Controllers are a great way to organize your code. They are collections of methods that accept a request and return a response.

A good place to put your controllers is in the [Controllers](structure.md#controllers) folder.

## Methods

Let's take a look at an example controller.

```swift
import Vapor

final class HelloController {
	func greet(_ req: Request) throws -> String {
		return "Hello!"
	}
}
```

Controller methods should always accept a `Request` and return something `ResponseEncodable`. 

!!! note
    [Futures](async.md) whose expectations are `ResponseEncodable` (i.e, `Future<String>`) are also `ResponseEncodable`.

To use this controller, we can simply initialize it, then pass the method to a router.

```swift
let helloController = HelloController()
router.get("greet", use: helloController.greet)
```

## Using Services

You will probably want to access your [services](services.md) from within your controllers. Just use the `Request` as a container to create services from within your route closures. Vapor will take care of caching the services.

```swift
final class HelloController {
	func greet(_ req: Request) throws -> String {
		return try req.make(BCryptHasher.self).hash("hello")
	}
}
```
