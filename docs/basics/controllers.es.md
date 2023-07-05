# Controladores

Los controladores son una gran manera de organizar tu código. Son colecciones de métodos que aceptan una petición (request) y devuleven una respuesta (response).

Un buen sitio donde ubicar tus controladores sería en la carpeta [Controllers](../getting-started/folder-structure.es.md#controllers).

## Descripción

Veamos un controlador de ejemplo.

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

Los métodos de un controlador deben aceptar siempre una `Request` (petición) y devolver algo `ResponseEncodable`. Este método puede ser síncrono o asíncrono (o devolver un `EventLoopFuture`).

!!! note "Nota"
	Un [EventLoopFuture](async.md) cuya expectativa es `ResponseEncodable` (por ejemplo, `EventLoopFuture<String>`) es también `ResponseEncodable`.

Finalmente necesitas registrar el controlador en `routes.swift`:

```swift
try app.register(collection: TodosController())
```
