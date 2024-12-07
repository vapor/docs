# Colas (Queues)

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) es un sistema de colas desarrollado completamente en Swift que permite descargar la responsabilidad de ciertas tareas a un proceso paralelo.

Algunas de las tareas para las que funciona bien este paquete:

- Enviar emails fuera del hilo de principal de solicitudes
- Realizar operaciones complejas o de larga duración en base de datos
- Asegurar la integridad y la resiliencia de los trabajos
- Acelerar el tiempo de respuesta retrasando el procesamiento no crítico
- Programar trabajos para que se realicen en un momento específico

Este paquete es similar a [Ruby Sidekiq](https://github.com/mperham/sidekiq). Ofrece las siguientes características:

- Manejo seguro de las señales `SIGTERM` y `SIGINT` enviadas por los proveedores de alojamiento para indicar un apagado, reinicio, o un nuevo despliegue.
- Prioridades diferentes para colas. Por ejemplo, puedes especificar que un trabajo se ejecute en la cola de correos electrónicos y otro en la cola de procesamiento de datos.
- Implementa el proceso de cola confiable para manejar fallos inesperados.
- Incluye la característica `maxRetryCount`, que reintenta el trabajo hasta que se complete correctamente o hasta que se alcance un número máximo de intentos.
- Utiliza NIO para aprovechar todos los núcleos disponibles y EventLoops para trabajos.
- Permite a los usuarios programar tareas repetitivas.

Actualmente, Queues tiene oficialmente un controlador compatible que interactúa con el protocolo principal:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues también tiene controladores basados en la comunidad:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/m-barthelemy/vapor-queues-fluent-driver)

!!! tip "Consejo"
    No deberías instalar el paquete `vapor/queues` directamente a menos que estés desarrollando un controlador nuevo. En su lugar, instala uno de los controladores existentes.

## Primeros pasos

Veamos cómo puedes comenzar a usar Queues.

### Paquete

El primer paso para usar Queues es añadir uno de los controladores como dependencia a tu proyecto en tu archivo de manifiesto del paquete SwiftPM. En este ejemplo, utilizaremos el controlador Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Cualquier otra dependencia ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Otras dependencias
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Si editas el archivo de manifiesto directamente dentro de Xcode, este detectará automáticamente los cambios y descargará la dependencia nueva al guardar el archivo. Si no, desde Terminal, ejecuta `swift package resolve` para descargar la dependencia.

### Configuración

El próximo paso es configurar Queues en `configure.swift`. Utilizaremos la librería Redis como ejemplo:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Registrando un trabajo (`Job`)

Después de modelar un trabajo, debes añadirlo a tu sección de configuración de la siguiente manera:

```swift
//Registrar trabajos
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Ejecutar Workers como procesos

Para iniciar una nueva cola de workers, ejecuta `swift run App queues`. También puedes especificar un tipo concreto de worker: `swift run App queues --queue emails`.

!!! tip "Consejo"
    Los workers deben permanecer ejecutándose en producción. Consulta a tu proveedor de alojamiento para averiguar cómo mantener activos procesos de larga duración. Por ejemplo, Heroku permite configurar un "worker" dynos en el archivo Procfile: `worker: Run queues`. Una vez configurado, puedes iniciar los workers desde el panel de control en la pestaña de recursos, o con `heroku ps:scale worker=1` (o el número de dynos que prefieras).

### Ejecutar Workers en el proceso principal

Para ejecutar un worker en el mismo proceso que tu aplicación (en lugar de iniciar un servidor independiente para manejarlo), llama a los métodos de conveniencia en `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Para ejecutar trabajos programados en el mismo proceso, llama al siguiente método:

```swift
try app.queues.startScheduledJobs()
```

!!! warning "Advertencia"
    Si no inicias el worker de la cola desde la línea de comandos o en el mismo proceso principal, los trabajos no se ejecutarán.

## El Protocolo `Job`

Los trabajos se definen utilizando los protocolos `Job` o `AsyncJob`.

### Modelando un objeto `Job`:

```swift
import Vapor 
import Foundation 
import Queues 

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // Aquí es donde enviarías el email
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // Si no deseas manejar errores, simplemente devuelve un futuro vacío. También puedes omitir esta función por completo.
        return context.eventLoop.future()
    }
}
```

Si utilizas `async`/`await`, deberías usar `AsyncJob`:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // Aquí es donde enviarías el email
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // Si no deseas manejar errores, simplemente haz un return. También puedes omitir esta función por completo.
    }
}
```

!!! info "Información"
    Asegúrate de que tu tipo `Payload` implemente el protocolo `Codable`.

!!! tip "Consejo"
    No olvides seguir las instrucciones en **Primeros pasos** para añadir este trabajo a tu archivo de configuración.

## Enviando trabajos

Para enviar un trabajo a la cola, necesitas acceso a una instancia de `Application` o `Request`. Lo más probable es que envíes trabajos dentro de un manejador de ruta:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "mensaje")
        ).map { "hecho" }
}

// o

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "mensaje"))
    return "hecho"
}
```

En cambio, si necesitas enviar un trabajo desde un contexto en el que el objeto `Request` no está disponible (como, por ejemplo, desde dentro de un `Command`), tendrás que utilizar la propiedad `queues` dentro del objeto `Application`, como:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "mensaje")
            )
    }
}
```

### Configurar `maxRetryCount`

Los trabajos se reintentarán automáticamente en caso de error si especificas un `maxRetryCount`. Por ejemplo:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "mensaje"),
            maxRetryCount: 3
        ).map { "hecho" }
}

// o

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "mensaje"),
        maxRetryCount: 3)
    return "hecho"
}
```

### Especificar un retraso

Puedes configurar que los trabajos se ejecuten únicamente tras una fecha determinada. Para especificar un retraso, pasa una fecha en el parámetro `delayUntil` de `dispatch`:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un día
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "mensaje"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "hecho"
}
```

Si un trabajo se saca de la cola antes de su parámetro de retraso, el controlador volverá a ponerlo en cola.

### Especificar una prioridad

Los trabajos pueden clasificarse en diferentes tipos de colas/prioridades en función de tus necesidades. Por ejemplo, puede que desees abrir una cola de `email` y una cola de `background-processing` para ordenar los trabajos.

Empieza por ampliar `QueueName`:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

A continuación, especifique el tipo de cola cuando recupere el objeto `jobs`:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un día
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "mensaje"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "hecho" }
}

// o

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un día
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "mensaje"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "hecho"
}
```

Cuando accedes desde el objeto `Application` deberás hacer lo siguiente:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "mensaje"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

Si no especificas una cola, el trabajo se ejecutará en la cola por defecto. Asegúrate de seguir las instrucciones de **Primeros pasos** para iniciar los workers para cada tipo de cola.

## Programando trabajos

El paquete Queues también permite programar trabajos para que se ejecuten en determinados momentos.

!!! warning "Advertencia"
    Los trabajos programados solo funcionan si se configuran antes de que la aplicación se inicie, como en el archivo `configure.swift`. No funcionarán en manejadores de rutas.

### Iniciando el planificador de workers

El planificador requiere que se ejecute un proceso worker independiente, similar al worker de colas. Puedes iniciar el worker ejecutando este comando: 

```sh
swift run App queues --scheduled
```

!!! tip "Consejo"
    Los workers deben permanecer en ejecución en producción. Consulta con tu proveedor de alojamiento para saber cómo mantener vivos los procesos de larga duración. Por ejemplo, Heroku permite especificar dynos "worker" como este en tu archivo Procfile: `worker: App queues --scheduled`

### Creando un `ScheduledJob`

Para empezar, crea un nuevo `ScheduledJob` o `AsyncScheduledJob`:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Añade servicios adicionales aquí usando inyección de dependencias, si los necesitas.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Haz algún trabajo aquí, tal vez encolando otro trabajo.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Añade servicios adicionales aquí usando inyección de dependencias, si los necesitas.

    func run(context: QueueContext) async throws {
        // Haz algún trabajo aquí, tal vez encolando otro trabajo.
    }
}
```

Luego, en el código de configuración, registra el trabajo programado:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

El trabajo del ejemplo anterior se ejecutará cada año el 23 de mayo a las 12:00 PM.

!!! tip "Consejo"
    El planificador toma la zona horaria del servidor.

### Métodos disponibles para el constructor

Hay cinco métodos principales que pueden ser llamados en un planificador, cada uno de los cuales crea su respectivo objeto constructor que contiene más métodos de ayuda. Debes continuar construyendo un objeto planificador hasta que el compilador no dé una advertencia sobre un resultado no utilizado. A continuación se listan todos los métodos disponibles:

| Función auxiliar | Modificadores disponibles             | Descripción                                                                      |
|------------------|---------------------------------------|----------------------------------------------------------------------------------|
| `yearly()`       | `in(_ month: Month) -> Monthly`       | Mes en el que se ejecutará el trabajo. Devuelve un objeto `Monthly` para su posterior construcción.  |
| `monthly()`      | `on(_ day: Day) -> Daily`             | Día en el que se ejecutará el trabajo. Devuelve un objeto `Daily` para su posterior construcción.  |
| `weekly()`       | `on(_ weekday: Weekday) -> Daily`     | Día de la semana en el que se ejecutará el trabajo. Devuelve un objeto `Daily`.  |
| `daily()`        | `at(_ time: Time)`                    | Hora a la que se ejecutará el trabajo. Último método de la cadena.               |
|                  | `at(_ hour: Hour24, _ minute: Minute)`| Hora y minuto en los que se ejecutará el trabajo. Último método de la cadena.    |
|                  | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | Hora, minuto y período en los que se ejecutará el trabajo. Último método.  |
| `hourly()`       | `at(_ minute: Minute)`                 | Minuto en que se ejecutará el trabajo. Último método.                           |
| `minutely()`     | `at(_ second: Second)`                 | Segundo en que se ejecutará el trabajo. Último método.                          |

### Ayudas disponibles

Las colas vienen con algunos enums de ayuda para facilitar la planificación: 

| Función auxiliar	| Enum disponibles de ayuda             |
|-------------------|---------------------------------------|
| `yearly()`        | `.january`, `.february`, `.march`, ...|
| `monthly()`       | `.first`, `.last`, `.exact(1)`        |
| `weekly()`        | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`         | `.midnight`, `.noon`                  |

Para utilizar el enum de ayuda, llama al modificador apropiado en la función de ayuda y pasa el valor. Por ejemplo:

```swift
// Cada año en enero
.yearly().in(.january)

// El primer día de cada mes
.monthly().on(.first)

// Cada domingo de la semana
.weekly().on(.sunday)

// Cada día a medianoche
.daily().at(.midnight)
```

## Delegados de Evento (Event Delegates)
El paquete Queues permite especificar objetos `JobEventDelegate` que recibirán notificaciones cuando el trabajador realice una acción en un trabajo. Esto puede utilizarse con fines de supervisión, información o alerta.

Para empezar, conforma un objeto a `JobEventDelegate` e implementa los métodos necesarios

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Se llama cuando el trabajo es enviado al queue worker desde una ruta
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Se llama cuando el trabajo se coloca en la cola de procesamiento y comienza a trabajar
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Se llama cuando el trabajo ha terminado de procesarse y se ha eliminado de la cola
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Se llama cuando el trabajo ha terminado de procesarse pero ha tenido un error
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Entonces, añádelo en tu archivo de configuración:

```swift
app.queues.add(MyEventDelegate())
```

Hay una serie de paquetes de terceros que utilizan la funcionalidad del delegado para proporcionar información adicional sobre sus workers de colas:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Pruebas (Testing)

Para evitar problemas de sincronización y garantizar pruebas deterministas, el paquete Queues proporciona una librería `XCTQueue` y un driver `AsyncTestQueuesDriver` dedicado a pruebas que puedes utilizar de la siguiente manera:

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Sobrescribe el controlador utilizado para pruebas
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

Más detalles en [la entrada del blog de Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).
