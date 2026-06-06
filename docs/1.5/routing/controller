---
currentMenu: routing-controller
---

# Introduction

Instead of defining all of your request handling logic as Closures in route files, you may wish to organize this behavior
using Controller classes. Controllers can group related request handling logic into a single class. Controllers are stored 
in the `Sources/App/Controllers` directory.

# Basic Controller

## Defining Controllers

```swift
import Vapor
import HTTP

final class FirstController {
    func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: [
            "message": "This is FirstController's index method"
            ])
    }
}
```
You can define a route to this controller action like so:

```swift
drop.get("getindex") {request in
    return try FirstController().index(request: request)
}
```
Now, when a request matches the specified route URI, the Index method on the FirstController 
class will be executed. Of course, the route parameters will also be passed to the method.

--------

# Resource Controllers

Vapor resource routing assigns the typical "CRUD" routes to a controller with a single line of code. 

```swift
drop.resource("URI", Controller())
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
```
