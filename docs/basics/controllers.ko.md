# 컨트롤러(Controllers)

컨트롤러는 코드를 그룹화하는데 좋은 방법입니다. 컨트롤러는 요청(request)을 받고 응답(response)을 반환하는 메서드들의 모음입니다.

컨트롤러가 위치하기에 좋은 곳은 [Controllers](../getting-started/folder-structure.md#controllers) 폴더입니다.

## 개요

예시 컨트롤러를 살펴보겠습니다.

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

컨트롤러 메서드는 `Request`을 받고 `ResponseEncodable` 을 준수하는 응답을 반환해야 합니다. 동기 또는 비동기 방식 모두 가능합니다.

마지막으로 `routes.swift`에서 컨트롤러를 등록해야 합니다.

```swift
try app.register(collection: TodosController())
```
