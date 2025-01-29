# Testing

## VaporTesting

Vapor incluye un módulo llamado `VaporTesting`que proporciona métodos auxiliares de test basados en `Swift Testing`. Estos métodos de pruebas te permiten enviar solicitudes de prueba a tu aplicación Vapor programáticamente o ejecutándose sobre un servidor HTTP.

!!! note "Nota"
    Para nuevos proyectos o equipos que adopten la concurrencia de Swift, Se recomienda usar `Swift Testing` por encima de `XCTest`.

### Primeros Pasos

Para usar el módulo `VaporTesting`, asegúrate de que ha sido añadido al target de test de tu paquete.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning "Advertencia"
    Asegúrate de usar el módulo de prueba correspondiente, de no hacerlo puede provocar que los fallos de las prueba de Vapor no sean informados correctamente.

Luego, añade `ìmport VaporTesting` y `ìmport Testing` al principio de tus archivos de prueba. Crea estructuras con el nombre `@Suite` para escribir casos de prueba.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // Prueba aquí.
    }
}
```

Cada función marcada con `@Test` se ejecutará automáticamente cuando se pruebe tu aplicación.

Para garantizar que tus pruebas se ejecuten de manera serializada (por ejemplo, al realizar pruebas con una base de datos), incluye la opción `.serialized` en la declaración de la suite de pruebas.

```swift
@Suite("App Tests with DB", .serialized)
```

### Probando la Aplicación

Define una función de método privado `withApp` para agilizar y estandarizar la configuración y el desmontaje de nuestras pruebas. Este método encapsula la gestión del ciclo de vida de la instancia `Application`, asegurando que la aplicación está correctamente inicializada, configurada y apagada para cada prueba.

En particular, es importante liberar los subprocesos que solicita la aplicación al iniciarse. Si no llamas a `asyncShutdown()` en la aplicación después de cada prueba unitaria, es posible que tu conjunto de pruebas se bloquee con un error de condición previa al asignar subprocesos para una nueva instancia de `Application`.

```swift
private func withApp(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await test(app)
    }
    catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

Pasa `Application` al método `configure(_:)` de tu paquete para aplicar tu configuración. Luego, prueba la aplicación llamando al método `test()`. También se puede aplicar cualquier configuración que sólo sea de prueba.

#### Enviar Solicitud

Para enviar una solicitud de prueba a tu aplicación, usa el método privado `withApp` y, dentro, usa el método `app.testing().test()`:

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

Los dos primeros parámetros son el método HTTP y la URL a solicitar. El cierre final acepta la respuesta HTTP que puedes verificar usando la macro `#expect`.

Para solicitudes más complejas, puedes proporcionar un cierre `beforeRequest` para modificar los encabezados o codificar el contenido. La [API de contenido](../basics/content.md) de Vapor está disponible tanto en la solicitud de prueba como en la respuesta.

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### Método de Prueba

La API de pruebas de Vapor admite el envío de solicitudes de prueba de manera programática y a través de un servidor HTTP activo. Puedes especificar qué método deseas utilizar a través del método `testing`.

```swift
// Utiliza pruebas programáticas.
app.testing(method: .inMemory).test(...)

// Ejecuta pruebas a través de un servidor HTTP activo.
app.testing(method: .running).test(...)
```

La opción `inMemory` se utiliza de manera predeterminada.

La opción `running` admite pasar un puerto específico a usar. De manera predeterminada, se utiliza `8080`.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Pruebas de Integración de Bases de Datos

Configura la base de datos específicamente para realizar pruebas para asegurarse de que tu base de datos activa nunca se utiliza durante las pruebas.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Luego, puedes mejorar tus pruebas utilizando `autoMigrate()` y `autoRevert()` para gestionar el esquema de la base de datos y el ciclo de vida de los datos durante las pruebas:

Al combinar estos métodos, puedes asegurarte de que cada prueba comienza con un estado de base de datos nuevo y consistente, lo que hace que tus pruebas sean más confiables y reduce la probabilidad de falsos positivos o negativos causados ​​por datos persistentes.

Así es como se ve la función `withApp` con la configuración actualizada:

```swift
private func withApp(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

## XCTVapor

Vapor incluye un módulo llamado `XCTVapor` que proporciona ayudas de prueba basadas en `XCTest`. Estas ayudas te permiten enviar solicitudes de prueba a tu aplicación Vapor de manera programática o ejecutándose a través de un servidor HTTP.

### Primeros Pasos

Para utilizar el módulo `XCTVapor`, asegúrate de tenerlo agregado al target de prueba de tu paquete.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Luego, agrega `import XCTVapor` en la parte superior de tus archivos de prueba. Crea clases que extiendan de `XCTestCase` para escribir casos de prueba.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Prueba aquí.
    }
}
```

Cada función que comience con `test` se ejecutará automáticamente cuando se pruebe tu aplicación.

### Probando la Aplicación

Inicializa una instancia de `Application` utilizando el entorno `.testing`. Debes llamar a `app.shutdown()` antes de que esta aplicación se desinicialice.

El cierre (shutdown) es necesario para ayudar a liberar los recursos que ha reclamado la aplicación. En particular, es importante liberar los subprocesos que la aplicación solicita al inicio. Si no llamas a `shutdown()` en la aplicación después de cada prueba unitaria, es posible que el conjunto de pruebas falle con una condición previa fallida al asignar subprocesos para una nueva instancia de `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Pasa `Application` al método `configure(_:)` de tu paquete para aplicar su configuración. Cualquier configuración de "solo prueba" se puede aplicar después.

#### Enviar una Petición

Para enviar una solicitud de prueba a tu aplicación, utiliza el método `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

Los primeros dos parámetros son el método HTTP y la URL a solicitar. El closure final acepta la respuesta HTTP que puedes verificar utilizando los métodos de tipo `XCTAssert`.

Para solicitudes más complejas, puedes proporcionar un closure llamado `beforeRequest` para modificar encabezados o codificar contenido. La [API de Content](../basics/content.md) de Vapor está disponible tanto en la solicitud de prueba como en la respuesta.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
	try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Probando un Método

La API de prueba de Vapor admite el envío de solicitudes de prueba de forma programática y a través de un servidor HTTP en vivo. Puedes especificar qué método te gustaría probar utilizando el método `testable`.

```swift
// Utilizar pruebas programáticas.
app.testable(method: .inMemory).test(...)

// Ejecutar pruebas a través de un servidor HTTP en vivo.
app.testable(method: .running).test(...)
```

La opción `inMemory` se utiliza de forma predeterminada.

La opción `running` admite pasar un puerto específico. Por defecto se utiliza el puerto `8080`.

```swift
.running(port: 8123)
```
