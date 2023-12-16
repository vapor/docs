# Controller

I controller sono un ottimo modo per organizzare il codice. Sono collezioni di metodi che prendono una richiesta e ritornano una risposta, e sono a tutti gli effetti gli endpoint dell'applicazione.

Il luogo migliore in cui mettere i controller è nella loro [cartella](../getting-started/folder-structure.it.md#controllers).

## Panoramica

Diamo un'occhiata ad un esempio di controller.

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

I metodi dei controller prendono sempre in input una `Request` e ritornano un qualsiasi `ResponseEncodable`. Tali metodi possono essere asincroni o sincroni.

Infine, il controller viene registrato nel `routes.swift`:

```swift
try app.register(collection: TodosController())
```
