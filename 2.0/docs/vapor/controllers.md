# Controllers

Controllers help you organize related functionality into a single place. They can also be used to create RESTful resources.

## Basic

A basic controller looks like the following:

```swift
import Vapor
import HTTP

final class HelloController {
	func sayHello(_ req: Request) throws -> ResponseRepresentable {
		guard let name = req.data["name"]?.string else { 
			throw Abort(.badRequest)
		}

		return "Hello, \(name)"
	}
}
```

Simple controllers don't need to conform to any protocols. You are free to design them however you see fit.

### Registering

The only required structure is the signature of each method in the controller. In order to register this method into the router, it must have a signature like `(Request) throws -> ResponseRepresentable`. `Request` and `ResponseRepresentable` are made available by importing the `HTTP` module.

```swift
import Vapor
let drop = try Droplet()

let hc = HelloController()
drop.get("hello", handler: hc.sayHello)
```

Since the signature of our `sayHello` method matches the signature of the closure for the `drop.get` method, we can pass it directly. If you want to test it locally simply open [http://localhost:8080/hello?name=John](http://localhost:8080/hello?name=John).

### Type Safe

You can also use controller methods with type-safe routing.

```swift
final class HelloController {
	...

	func sayHelloAlternate(_ req: Request) throws -> ResponseRepresentable {
        let name: String = try req.parameters.next(String.self)
		return "Hello, \(name)"
	}
}
```

We add a new method called `sayHelloAlternate` to the `HelloController` that fetches a `String` from the request's parameters.

```swift
let hc = HelloController()
drop.get("hello", String.parameter, handler: hc.sayHelloAlternate)
```

Since `drop.get` accepts a signature `(Request) throws -> ResponseRepresentable`, our method can now be used as the closure for this route. In this case to test it locally open [http://localhost:8080/hello/John](http://localhost:8080/hello/John).

!!! note 
    Read more about type safe routing in the [Routing Parameters](https://docs.vapor.codes/2.0/routing/parameters/#type-safe) section.

## Resources

Controllers that conform to `ResourceRepresentable` can be easily registered into a router as a RESTful resource. Let's look at an example of a `UserController`.

```swift
final class UserController {
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try User.all().makeJSON()
    }

    func show(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.parameters.next(User.self)
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

Conforming `UserController` to `ResourceRepresentable` requires that the signatures of 
the `index` and `show` methods match what the `Resource<User>` is expecting.


Now that `UserController` conforms to `ResourceRepresentable`, registering the routes is easy.

```swift
let users = UserController()
drop.resource("users", users)
```

 `drop.resource` will take care of registering only the routes that have been supplied by the call to `makeResource()`. In this case, only the `index` and `show` routes will be supplied.

### Actions

Below is a table describing all of the actions available.

| Action        | Method  | Path            | Note                                                                                     |
|---------------|---------|-----------------|------------------------------------------------------------------------------------------|
| index         | GET     | /users          | Returns all users, optionally filtered by the request data.                              |
| store         | POST    | /users          | Creates a new user from the request data.                                                |
| show          | GET     | /users/:id      | Returns the user with the ID supplied in the path.                                       |
| replace       | PUT     | /users/:id      | Updates the specified user, setting any fields not present in the request data to `nil`. |
| update        | PATCH   | /users/:id      | Updates the specified user, only modifying fields present in the request data.           |
| destroy       | DELETE  | /users/:id      | Deletes the specified user.                                                              |
| clear         | DELETE  | /users          | Deletes all users, optionally filtered by the request data.                              |
| create        | GET     | /users/create   | Displays a form for creating a new user.                                                 |
| edit          | GET     | /users/:id/edit | Displays a form for editing the specified user.                                          |
| aboutItem     | OPTIONS | /users/:id      | Meta action. Displays information about which actions are supported.                     |
| aboutMultiple | OPTIONS | /users          | Meta action. Displays information about which actions are supported.                     |

!!! note
    The `aboutItem` and `aboutMultiple` meta actions are implemented automatically if not overridden. 

!!! tip
    The difference between `replace` and `update` is subtle but important:
    If a field does not exist in the request data (for example, the user's age is missing),
    `update` should simply not update that field where as `replace` should set it to `nil`.
    If required data is missing from a `replace` request, an error should be thrown.

## Folder

Controllers can go anywhere in your application, but they are most often stored in the `App/Controllers/` directory. 

!!! tip
    If you are building a large application, you may want to create your controllers in a separate module. This will allow you to perform unit tests on your controllers. 
