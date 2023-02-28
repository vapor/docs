# Controller

Mit Controller kannst du deinen Code sinnvoll aufteilen und in deinem Projekt für Ordnung sorgen. Ein Controller kann beispielsweise ein oder mehrere Methoden beinhalten, die Serveranfragen entgegennehmen und ein enstprechendes Ergebnis zurückliefern. Das folgende Beispiel zeigt einen möglichen Aufbau eines solchen Controllers:

```swift
/// [TodoController.swift]

import Vapor

struct TodosController: RouteCollection {

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
        // ...
    }

    func delete(req: Request) throws -> String {
        // ...
    }
    
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
}
```

Die Methoden sollten immer ein Object vom Typ _Request_ annehmen und ein Wert von Typ _ResponseEncodable_ zurückgegeben. Dabei kann die Methode sowohl asynchron mittels _async/await_ oder _EventLoopFuture_, als auch synchron ausgeführt werden.

Zum Schluss muss der Controller der Anwendung bekannt gemacht werden. Hierzu wird der Controller mit Hilfe der Methode _register(:_)_ an das Object _app_ übergeben.

```swift
/// [routes.swift]

try app.register(collection: TodosController())
```