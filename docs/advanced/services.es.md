# Servicios

`Application` y `Request` de Vapor están construidos para ser extendidos por tu aplicación y por paquetes de terceros. Las nuevas funcionalidades añadidas a estos tipos a menudo se denominan servicios.

## Sólo Lectura

El tipo de servicio más simple es el de sólo lectura. Estos servicios consisten en variables calculadas o métodos añadidos a la aplicación o a la petición.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Los servicios de sólo lectura pueden depender de cualquier servicio preexistente, como `client` en este ejemplo. Una vez añadida la extensión, tu servicio personalizado se puede usar como cualquier otra propiedad bajo petición.

```swift
req.myAPI.foos()
```

## Escribible

Los servicios que necesitan estado o configuración pueden utilizar `Application` y `Request` para almacenar datos. Supongamos que quieres añadir la siguiente estructura `MyConfiguration` a tu aplicación.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Para utilizar el almacenamiento, debes declarar una `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Esta es una estructura vacía con un typealias `Value` que especifica qué tipo se está almacenando. Al utilizar un tipo vacío como clave, puedes controlar qué código puede acceder a su valor de almacenamiento. Si el tipo es interno o privado, sólo tu código podrá modificar el valor asociado en el almacenamiento.

Finalmente, añade una extensión a `Application` para obtener y configurar la estructura `MyConfiguration`.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Una vez añadida la extensión, puedes usar `myConfiguration` como una propiedad normal en `Application`.

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Ciclo De Vida

`Application` de Vapor te permite registrar manejadores del ciclo de vida. Estos permiten conectarte a eventos como el arranque y el apagado.

```swift
// Imprime Hello! durante el arranque.
struct Hello: LifecycleHandler {
    // Se llama antes de que se inicie la aplicación.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Se llama después de que se inicie la aplicación.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Se llama antes de que se apague la aplicación.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Añade el manejador del ciclo de vida
app.lifecycle.use(Hello())
```

## Bloqueos

`Application` de Vapor incluye facilidades para sincronizar código usando bloqueos. Declarando un `LockKey`, puedes obtener un único bloqueo compartido para sincronizar el acceso a tu código.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Hacer algo.
}
```

Cada llamada a `lock(for:)` con la misma `LockKey` devolverá el mismo bloqueo. Este método es seguro para hilos (subprocesos concurrentes).

Para un bloqueo a nivel de aplicación, puedes usar `app.sync`.

```swift
app.sync.withLock {
    // Hacer algo.
}
```

## Solicitudes

Los servicios que están destinados a ser utilizados en los manejadores de ruta se deben añadir a `Request`. Los servicios de solicitudes deben usar el registrador de la solicitud y el bucle de eventos. Es importante que una solicitud permanezca en el mismo bucle de eventos o se producirá una aserción cuando se devuelva la respuesta a Vapor.

Si un servicio debe abandonar el bucle de eventos de la solicitud para realizar un trabajo, debes asegurarte de volver al bucle de eventos antes de terminar. Esto puede hacerse usando `hop(to:)` en `EventLoopFuture`.

Los servicios de solicitud que necesitan acceder a servicios de aplicación, como las configuraciones, pueden usar `req.application`. Ten cuidado de considerar la seguridad de los subprocesos al acceder a la aplicación desde un manejador de ruta. Generalmente, sólo las solicitudes deben realizar operaciones de lectura. Las operaciones de escritura deben estar protegidas por bloqueos.
