# Controllers

Mit Controllers kannst du deinen Code strukturieren und in deinem Projekt für Ordnung sorgen. Ein Controller kann ein oder mehrere Methoden besitzen, die dazu da sind die Anfrage entgegenzunehmen und ein enstprechendes Ergebnis zurückzuliefern.

## Beispiel

Das folgende Beispiel zeigt einen möglichen Aufbau eines Controllers:

```swift
/// [TodoController.swift]

import Vapor

struct TodosController: RouteCollection {

    /// [1]
    func index(req: Request) async throws -> String {
        // ...
    }

    /// [2]
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

Die Methoden sollten immer ein Object vom Typ _Request_ annehmen und ein Wert von Typ _ResponseEncodable_ zurückgegeben. Dabei kann die Methode sowohl asynchron (siehe im Beispiel Punkt [1]), als auch synchron (siehe im Beispiel, Punkt [2]) ausgeführt werden.

### Register

Zum Schluss muss der Anwendung noch der Controller in der Datei _routes.swift_ bekannt gemacht werden.

```swift
/// [routes.swift]

try app.register(collection: TodosController())
```