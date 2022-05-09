# Controllers

Controllers are a great way to organize your code. They are collections of methods that accept a request and return a response.

A good place to put your controllers is in the [Controllers](folder-structure.md#controllers) folder.

## Overview

Let's take a look at an example controller.

```swift
import Vapor

struct TodosController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get(use: index)
        todos.post(use: create)

        todos.group(":id") { todo in
            todo.get(use: show)
            todo.put(use: update)
            todo.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> String {
        // ...
    }

    func create(req: Request) throws -> EventLoopFuture<String> {
        // ...
    }

    func show(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }

    func update(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }

    func delete(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }
}
```

Controller methods should always accept a `Request` and return something `ResponseEncodable`. This method can be asynchronous or synchronous (or return an `EventLoopFuture`)

!!! note
	[EventLoopFuture](async.md) whose expectation is `ResponseEncodable` (i.e, `EventLoopFuture<String>`) is also `ResponseEncodable`.

Finally you need to register the controller in `routes.swift`:

```swift
try app.register(collection: TodosController())
```
