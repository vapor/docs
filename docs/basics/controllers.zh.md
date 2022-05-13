# Controllers

`Controller` 是将应用程序的不同逻辑进行分组的优秀方案，大多数 Controller 都具备接受多种请求的功能，并根据需要进行响应。

建议将其放在 [Controllers](../gettingstarted/folder-structure.md#controllers) 文件夹下，具体情况可以根据需求划分模块。


## 概述

让我们看一个示例 Controller：

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

`Controller` 的方法接受 `Request` 参数，并返回 `ResponseEncodable` 对象。该方法可以是异步或者同步(或者返回一个 `EventLoopFuture`)

!!! 注意
	[EventLoopFuture](async.md) 期望返回值为 `ResponseEncodable` (i.e, `EventLoopFuture<String>`) 或 `ResponseEncodable`.

最后，你需要在 `routes.swift` 中注册 Controller：

```swift
try app.register(collection: TodosController())
```
