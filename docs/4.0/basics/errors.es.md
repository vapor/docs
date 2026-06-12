# Errores

Vapor está basado en el protocolo `Error` de Swift para el manejo de errores. Los manejadores de rutas pueden lanzar (`throw`) un error o devolver un `EventLoopFuture` fallido. Lanzar o devolver un `Error` de Swift resultará en una respuesta de estado (status response) `500` y el error será registrado. `AbortError` y `DebuggableError` pueden usarse para cambiar la respuesta resultante y el registro respectivamente. El manejo de errores lo lleva a cabo `ErrorMiddleware`. Este middleware es añadido por defecto a la aplicación y puede reemplazarse por lógica personalizada si se desea. 

## Abort

Vapor proporciona un struct de error por defecto llamado `Abort`. Este struct se conforma con ambos `AbortError` y `DebuggableError`. Puedes inicializarlo con un estado (status) HTTP y un motivo (reason) de fallo opcional.

```swift
// Error 404, motivo (reason) por defecto "Not Found" usado.
throw Abort(.notFound)

// Error 401,motivo (reason) personalizada usado.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

En situaciones asíncronas antiguas que no soportan lanzamiento de errores y en las que debes devolver un `EventLoopFuture`, como en un closure `flatMap`, puedes devolver un futuro fallido.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor incluye una extensión de ayuda para hacer unwrapping de futuro con valores opcionales: `unwrap(or:)`. 

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // User no opcional proporcionado al closure.
}
```

Si `User.find` devuelve `nil`, el futuro fallará con el error suministrado. Sino, se suministrará el `flatMap` con un valor no opcional. Si usas `async`/`await` puedes manejar el opcional de la manera habitual:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Por defecto, cualquier `Error` de Swift lanzado o devuelto por un closure de ruta resultará en una respuesta `500 Internal Server Error`. Cuando se compile en modo de depuración (debug mode), `ErrorMiddleware` incluirá una descripción del error. Esto se elimina cuando el proyecto es compilado en modo de despliegue (release mode) por razones de seguridad. 

Para configurar el estado (status) o motivo (reason) de la petición HTTP resultante para un error en específico, debes conformarlo a `AbortError`. 

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Error Depurable

`ErrorMiddleware` usa el método `Logger.report(error:)` para registrar errores lanzados por tus rutas. Este método comprobará la conformación a protocolos como `CustomStringConvertible` y `LocalizedError` para registrar mensajes legibles.

Para personalizar el registro de errores, puedes conformar tus errores con `DebuggableError`. Este protocolo incluye una variedad de útiles propiedades como un identificador único, localización de fuentes (source location) y traza de la pila (stack trace). La mayoría de estas propiedades son opcionales, lo que facilita adoptar la conformancia. 

Para conformarse de mejor forma a `DebuggableError`, tu error debe ser un struct que permita guardar información sobre las trazas de fuente y pila en caso de ser necesario. Debajo hay un ejemplo del enum `MyError` mencionado anteriormente, actualizado para usar un `struct` y capturar información sobre la fuente de error.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` tiene otras propiedades como `possibleCauses` y `suggestedFixes` que puedes usar para mejorar la depuración de tus errores. Echa un vistazo al protocolo para más información.

## Middleware de Error

`ErrorMiddleware` es el único middleware añadido a tu aplicación por defecto. Este middleware transforma errores de Swift que hayan sido lanzados o devueltos por tus controladores de rutas en respuestas HTTP. Sin este middleware, los errores lanzados darían lugar al cierre de la conexión sin una respuesta. 

Para personalizar el manejo de errores más allá de lo que `AbortError` y `DebuggableError` ofrecen, puedes reemplazar `ErrorMiddleware` con tu propia lógica de manejo de errores. Para hacerlo, elimina primero el middleware por defecto estableciendo una configuración vacía en `app.middleware`. Luego, añade tu propio middleware de manejo de errores como el primer middleware de tu aplicación.

```swift
// Elimina todos los middleware existentes.
app.middleware = .init()
// Añade middleware de manejo de errores personalizado primero.
app.middleware.use(MyErrorMiddleware())
```

Muy pocos middleware deberían ir _antes_ del middleware de manejo de errores. Una excepción a tener en cuenta de esta regla es `CORSMiddleware`.
