# Basic Controller

Instead of defining all of your request handling logic as Closures in route files, you may wish to organize this behavior
using Controller classes. 

Controllers can group related request handling logic into a single class. They are normally stored 
in the `Sources/App/Controllers` directory.

## Defining Controllers

```swift
import Vapor
import HTTP

final class HelloController {
    func sayHello(_ req: Request) throws -> ResponseRepresentable {
        return "Hello"
    }
}
```

You can define a route to this controller action like so:

```swift
let controller = HelloController()
drop.get("hello", handler: controller.sayHello)
```

Now, when a request matches the specified route URI, the Index method on the FirstController 
class will be executed. Of course, the route parameters will also be passed to the method.

# Resource Controllers

Vapor resource routing assigns the typical "CRUD" routes to a controller with a single line of code. 

```swift
drop.resource("users", UserController())
```

This single route declaration creates multiple routes to handle a variety of actions on the resource. 
The generated controller will already have methods stubbed for each of these actions, including 
notes informing you of the HTTP verbs and URIs they handle.

| Verb            | URI             |  Action       |
| :-------------: | :-------------: | :-----------: |
| GET             | test/index      | test.index    |
| POST            | test/create     | test.create   |
| GET             | test/show       | test.show     |
| PUT             | test/replace    | test.replace  |
| PATCH           | test/destroy    | test.destroy  |
| DELETE          | test/destroy    | test.destroy  |
| DELETE          | test/clear      | test.clear    |

You can also custom method name, add `makeResource` method in the controller

```swift
final class UserController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
       ...
    }

    ...

    func makeResource() -> Resource<First> {
        return Resource(
            index: index,
            store: create,
            show: show,
            replace: replace,
            modify: update,
            destroy: delete,
            clear: clear
        )
    }
}
```
