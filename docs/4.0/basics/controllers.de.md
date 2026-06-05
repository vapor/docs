# Controller

Mit Controller können wir unseren Code sinnvoll aufteilen und in unserem Projekt für Ordnung sorgen. Ein Controller kann eine oder mehrere Methoden beinhalten, die Serveranfragen entgegennehmen, verarbeiten und ein entsprechendes Ergebnis zurückliefern. Das folgende Beispiel zeigt einen möglichen Aufbau eines solchen Controllers:

```swift
// [TodosController.swift]

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

    func index(req: Request) async throws -> [Todo] {
        try await Todo.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Todo {
        let todo = try req.content.decode(Todo.self)
        try await todo.save(on: req.db)
        return todo
    }

    func show(req: Request) async throws -> Todo {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return todo
    }

    func update(req: Request) async throws -> Todo {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedTodo = try req.content.decode(Todo.self)
        todo.title = updatedTodo.title
        try await todo.save(on: req.db)
        return todo
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .ok
    }
}
```

Die erwähnten Methoden sollten immer ein Objekt vom Typ _Request_ annehmen und ein Wert von Typ _ResponseEncodable_ zurückgegeben. Dabei kann die Methode sowohl asynchron, als auch synchron ausgeführt werden.

Zum Schluss müssen wir der Anwendung unseren Controller bekannt machen. Hierzu wird der Controller mit Hilfe der Methode _register(:_)_ an das Objekt _app_ übergeben.

```swift
// [routes.swift]

try app.register(collection: TodosController())
```
