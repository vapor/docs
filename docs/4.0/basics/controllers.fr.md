# Les contrôleurs

Les contrôleurs sont un bon moyen d'organiser votre code. Ils sont composés d'un ensemble de méthodes qui acceptent une requête et retournent une réponse.

Le dossier [Controllers](../getting-started/folder-structure.md#controllers) est un bon endroit pour mettre vos contrôleurs.

## Vue d'ensemble

Prenons un contrôleur pour exemple.

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

Les méthodes d'un contrôleur doivent toujours accepter une `Request` et retourner quelque chose qui se conforme à `ResponseEncodable`. Cette méthode peut être asynchrone ou synchrone.

Vous devez enfin enregistrer le contrôleur dans `routes.swift` :

```swift
try app.register(collection: TodosController())
```
