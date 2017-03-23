---
currentMenu: guide-controllers
---

# Controllers

Controllers help you organize related functionality into a single place. They can also be used to create RESTful resources.

## Basic

A basic controller looks like the following:

```swift
final class HelloController {
	func sayHello(_ req: Request) throws -> ResponseRepresentable {
		guard let name = req.data["name"] else { 
			throw Abort.badRequest 
		}
		return "Hello, \(name)"
	}
}
```

Simple controllers don't need to conform to any protocols. You are free to design them however you see fit.

### Registering

The only required structure is the signature of each method in the controller. In order to register this method into the router, it must have a signature like `(Request) throws -> ResponseRepresentable`. `Request` and `ResponseRepresentable` are made available by importing the `HTTP` module.

```swift
let hc = HelloController()
drop.get("hello", handler: hc.sayHello)
```

Since the signature of our `sayHello` method matches the signature of the closure for the `drop.get` method, we can pass it directly.

### Type Safe

You can also use controller methods with type-safe routing.

```swift
final class HelloController {
	...

	func sayHelloAlternate(_ req: Request, _ name: String) -> ResponseRepresentable {
		return "Hello, \(name)"
	}
}
```

We add a new method called `sayHelloAlternate` to the `HelloController` that accepts a second parameter `name: String`.

```swift
let hc = HelloController()
drop.get("hello", String.self, handler: hc.sayHelloAlternate)
```

Since this type-safe `drop.get` accepts a signature `(Request, String) throws -> ResponseRepresentable`, our method can now be used as the closure for this route. 

## Resources

Controllers that conform to `ResourceRepresentable` can be easily registered into a router as a RESTful resource. Let's look at an example of a `UserController`.

```swift
final class UserController {
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try User.all().makeNode().converted(to: JSON.self)
    }

    func show(_ request: Request, _ user: User) -> ResponseRepresentable {
        return user
    }
}
```

Here is a typical user controller with an `index` and `show` route. Indexing returns a JSON list of all users and showing returns a JSON representation of a single user.

We _could_ register the controller like so:

```swift
let users = UserController()
drop.get("users", handler: users.index)
drop.get("users", User.self, handler: users.show)
```

But `ResourceRepresentable` makes this standard RESTful structure easy.

```swift
extension UserController: ResourceRepresentable {
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            show: show
        )
    }
}
```

Conforming `UserController` to `ResourceRepresentable` requires that the signatures of the `index` and `show` methods match what the `Resource<User>` is expecting.

Here is a peek into the `Resource` class.

```swift
final class Resource<Model: StringInitializable> {
    typealias Multiple = (Request) throws -> ResponseRepresentable
    typealias Item = (Request, Model) throws -> ResponseRepresentable

    var index: Multiple?
    var store: Multiple?
    var show: Item?
    var replace: Item?
    var modify: Item?
    var destroy: Item?
    var clear: Multiple?
    var aboutItem: Item?
    var aboutMultiple: Multiple?

    ...
}
```

Now that `UserController` conforms to `ResourceRepresentable`, registering the routes is easy.

```swift
let users = UserController()
drop.resource("users", users)
```

 `drop.resource` will take care of registering only the routes that have been supplied by the call to `makeResource()`. In this case, only the `index` and `show` routes will be supplied.

> Note: `drop.resource` also adds useful defaults for OPTIONS requests. These can be overriden.  

## Folder

Controllers can go anywhere in your application, but they are most often stored in the `Controllers/` directory. 

### Modules

If you are building a large application, you may want to create your controllers in a separate module. This will allow you to perform unit tests on your controllers. For more information on creating modules, visit the documentation for the [Swift Package Manager](https://swift.org/package-manager/).
