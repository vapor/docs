# Controllers

Controllers zijn een goede manier om je code te organiseren. Het zijn verzamelingen van methodes die een verzoek accepteren en een antwoord teruggeven.

Een goede plaats om je controllers te plaatsen is in de [Controllers](../getting-started/folder-structure.md#controllers) map.

## Overzicht

Laten we eens kijken naar een voorbeeldcontroller.

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

Controller methodes moeten altijd een `Request` accepteren en iets `ResponseEncodable` teruggeven. Deze methode kan asynchroon of synchroon zijn (of een `EventLoopFuture` teruggeven).

!!! opmerking
	[EventLoopFuture](async.md) waarvan de verwachting `ResponseEncodable` is (d.w.z. `EventLoopFuture<String>`) is ook `ResponseEncodable`.

Tenslotte moet je de controller registreren in `routes.swift`:

```swift
try app.register(collection: TodosController())
```
