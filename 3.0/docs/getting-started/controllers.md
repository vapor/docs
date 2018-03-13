# Controllers

Controllers are a great way to organize your code. They are collections of methods that accept
a request and return a response.

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

Controller methods should always accept a `Request` and return something `ResponseRepresentable`.
This also includes [futures](futures.md) whose expectations are `ResponseRepresentable` (i.e, `Future<String>`).

To use this controller, we can simply initialize it, then pass the method to a router.

```swift
let helloController = HelloController()
router.get("greet", use: helloController.greet)
```

## Use Services

You will probably want to access your [application's services](application.md#services) from within your controllers.
Luckily this is easy to do. First, declare what services your controller needs in its init method. Then store them
as properties on the controller.

```swift
final class HelloController {
	let hasher: BCryptHasher

	init(hasher: BCryptHasher) {
		self.hasher = hasher
	}

	...
}
```

Next, use the [application](application.md) to create these services when you initialize your controller.

```swift
let helloController = try HelloController(
	hasher: app.make()
)
```
