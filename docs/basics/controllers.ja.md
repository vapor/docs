# コントローラー

コントローラーはコードを整理するのに適した方法です。これらは、リクエストを受けてレスポンスを返すメソッドの集まりです。

コントローラーを置く良い場所は、[Controllers](../getting-started/folder-structure.ja.md#controllers) フォルダーです。

## 概要

例としてコントローラーを見てみましょう。

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
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .ok
    }
}
```

コントローラーのメソッドは常に `Request` を受け取り、何か `ResponseEncodable` を返す必要があります。このメソッドは非同期でも同期でも構いません。

最後に、コントローラーを `routes.swift` に登録する必要があります：

```swift
try app.register(collection: TodosController())
```
