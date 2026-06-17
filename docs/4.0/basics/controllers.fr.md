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

En se conformant au protocole RouteCollection, le contrôleur doit implémenter la méthode boot(routes:) pour enregistrer les routes qu'il expose.

Toutes ses autres méthodes prennent ensuite un objet `Request` et retourne quelque-chose qui se conforme à `ResponseEncodable`. Ces méthodes peuvent être synchrones comme asynchrones.

Vous devez enfin enregistrer votre contrôleur dans le fichier `routes.swift`:

```swift
try app.register(collection: TodosController())
```
