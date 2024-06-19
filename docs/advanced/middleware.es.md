# Middleware

Middleware es una cadena lógica entre el cliente y el controlador de ruta de Vapor. Le permite realizar operaciones en solicitudes entrantes antes de que lleguen al controlador de ruta y en respuestas antes de que lleguen al cliente. 

## Configuración

Middleware se puede registrar de forma global (en cada ruta) en la función `configure(_:)` usando `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

También puedes añadir middleware a rutas individuales utilizando grupos de rutas.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// Esta solicitud ha pasado por MyMiddleware
}
```

### Orden

El orden en que se agrega middleware es importante. Solicitudes que ingresan a tu aplicación pasarán por el middleware en el orden en que se agregan. Las respuestas que salgan de tu aplicación pasarán de nuevo por el middleware en el orden inverso. El middleware específico de ruta siempre se ejecuta después del middleware de la aplicación. Tomemos el siguiente ejemplo:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

Una solicitud `GET /hello` visitará el middleware en el siguiente orden:

```
Solicitud → A → B → C → Controlador → C → B → A → Respuesta
```

Middleware también puede ser _antepuesto_, lo cual es útil cuando desea agregar un middleware antes de que el middleware predeterminado se agregue automáticamente:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Creando un Middleware

Vapor viene con algunos middlewares útiles, pero es posible que necesites crear el tuyo propio debido a los requisitos de tu aplicación. Por ejemplo, podrías crear un middleware que impida que cualquier usuario que no sea administrador acceda a un grupo de rutas.

> Recomendamos crear una carpeta llamada `Middleware` dentro del directorio `Sources/App` para mantener tu codigo organizado

Middleware son tipos que se ajustan al protocolo `Middleware` o `AsyncMiddleware` de Vapor. Se insertan en la cadena de respuesta y pueden acceder y manipular una solicitud antes de que llegue a un controlador de ruta y modificar una respuesta antes de que se devuelva.

Usando el ejemplo mencionado anteriormente, cree un middleware para bloquear acceso al usuario si no es administrador:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

O si estas usando `async`/`await` puedes escribir:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

Si deseas modificar la respuesta, por ejemplo, para añadir un cabecero personalizado, puedes usar un middleware para esto también. Middlewares pueden esperar hasta que la respuesta sea recibida por parte de la cadena de respuesta y manipular la respuesta:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

O si estas usando `async`/`await` puedes escribir:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` permite servir activos desde la carpeta pública de su proyecto al cliente. Puede incluir archivos estáticos como hojas de estilo o imágenes de mapa de bits.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Una vez que `FileMiddleware` esté registrado, un archivo como `Public/images/logo.png` se puede vincular desde una plantilla Leaf como `<img src="/images/logo.png"/>`.

Si tu servidor está almacenado en un projecto Xcode, como una applicación de iOS, use esto en su lugar:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Tambien asegúrese de usar referencias de carpetas en lugar de grupos en Xcode para mantener la estructura de carpetas en los recursos despues de crear la applicación.

## CORS Middleware

El intercambio de recursos entre orígenes (CORS, por sus siglas en inglés) es un mecanismo que permite solicitar recursos restringidos en una página web desde otro dominio fuera del dominio desde el que se sirvió el primer recurso. Las API REST integradas en Vapor requerirán una política CORS para poder devolver solicitudes de forma segura a los navegadores web modernos.

Una configuración de ejemplo podría verse así:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware debería aparecer antes del middleware de error predeterminado usando `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Dado que los errores generados se devuelven inmediatamente al cliente, `CORSMiddleware` debe aparecer antes de `ErrorMiddleware`. De lo contrario, la respuesta de error HTTP se devolverá sin encabezados CORS y el navegador no podrá leerla.
