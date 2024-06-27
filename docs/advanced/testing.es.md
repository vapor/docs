# Testing

Vapor incluye un módulo llamado `XCTVapor` que proporciona ayudas de prueba basadas en `XCTest`. Estas ayudas te permiten enviar solicitudes de prueba a tu aplicación Vapor de manera programática o ejecutándose a través de un servidor HTTP.

## Comenzando

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

### Ejecutando Pruebas

Utiliza `cmd+u` con el esquema `-Package` seleccionado para ejecutar pruebas en Xcode. Utiliza `swift test --enable-test-discovery` para realizar pruebas a través de la línea de comando.

## Probando la Aplicación

Inicializa una instancia de `Application` utilizando el entorno `.testing`. Debes llamar a `app.shutdown()` antes de que esta aplicación se desinicialice.

El cierre (shutdown) es necesario para ayudar a liberar los recursos que ha reclamado la aplicación. En particular, es importante liberar los subprocesos que la aplicación solicita al inicio. Si no llamas a `shutdown()` en la aplicación después de cada prueba unitaria, es posible que el conjunto de pruebas falle con una condición previa fallida al asignar subprocesos para una nueva instancia de `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Pasa `Application` al método `configure(_:)` de tu paquete para aplicar su configuración. Cualquier configuración de "solo prueba" se puede aplicar después.

### Enviar una Petición

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

### Probando un Método

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
