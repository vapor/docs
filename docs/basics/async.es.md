# Asincronía

## Async Await

Swift 5.5 introdujo la concurrencia en el lenguaje en forma de `async`/`await`. Esto proporciona una forma de primer nivel de manejar código asincrónico en aplicaciones Swift y Vapor.

Vapor está construido sobre [SwiftNIO](https://github.com/apple/swift-nio.git), que proporciona tipos primitivos para programación asincrónica de bajo nivel. Estos se usaron (y todavía se usan) dentro de Vapor antes de que llegara `async`/`await`. Sin embargo, la mayoría del código ahora se puede escribir usando `async`/`await` en lugar de usar `EventLoopFuture`s. Esto simplificará nuestro código y hará que sea mucho más fácil pensar el proyecto.

La mayoría de las API de Vapor ahora ofrecen versiones `EventLoopFuture` y `async`/`await` para que elijas cuál es mejor. En general, solo debes usar un modelo de programación por controlador de ruta y no mezclar ni combinar en el código. Para aplicaciones que necesitan control explícito sobre bucles de eventos, o aplicaciones de muy alto rendimiento, debes continuar usando `EventLoopFuture`s hasta que se implementen ejecutores personalizados. Para todos los demás, debes usar `async`/`await` ya que los beneficios de legibilidad y mantenibilidad superan con creces cualquier pequeña penalización de rendimiento.

### Migrar a async/await

Hay algunos pasos necesarios para migrar a async/await. Para empezar, si usas macOS, debe tener macOS 12 Monterey o superior y Xcode 13.1 o superior. Para otras plataformas, debes ejecutar Swift 5.5 o superior. A continuación, asegúrate de haber actualizado todas tus dependencias.

En tu Package.swift, configura la versión de las herramientas en 5.5 en la parte superior del archivo:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

A continuación, configura la versión de la plataforma en macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Finalmente actualiza el target `Run` para marcarlo como un destino ejecutable:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Nota: si estás implementando en Linux, asegúrate de actualizar la versión de Swift allí también, ej. en Heroku o en su Dockerfile. Por ejemplo, su Dockerfile cambiaría a:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Ahora puedes migrar el código existente. Generalmente las funciones que devuelven `EventLoopFuture`s ahora son `async`. Por ejemplo:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Ahora se convierte en:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### APIs antiguas y nuevas

Si encuentras APIs que aún no ofrecen una versión `async`/`await`, puedes llamar a `.get()` en una función que devuelve un `EventLoopFuture` para convertirla.

Ejemplo:

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // usar futureResult
}
```

Puede convertirse en

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Si necesitas ir al revés, puedes convertir

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

en

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`s

Es posible que hayas notado que algunas API en Vapor esperan o devuelven un tipo genérico de `EventLoopFuture`. Si es la primera vez que oyes hablar de futuros, al principio puede parecerte un poco confuso. Pero no te preocupes, esta guía te mostrará cómo aprovechar sus potentes APIs.

Las promesas y los futuros son tipos relacionados, pero distintos. Las promesas se utilizan para _crear_ futuros. La mayor parte del tiempo, trabajarás con futuros devueltos por las APIs de Vapor y no tendrás que preocuparte por crear promesas.

|tipo|descripción|mutabilidad|
|-|-|-|
|`EventLoopFuture`|Referencia a un valor que puede no estar disponible todavía.|read-only|
|`EventLoopPromise`|Una promesa de proporcionar algún valor de forma asincrónica.|read/write|

Los futuros son una alternativa a las APIs asincrónicas basadas en callbacks. Los futuros pueden encadenarse y transformarse de maneras que los simples closures no pueden lograr.

## Transformando

Al igual que los opcionales y arrays en Swift, los futuros se pueden utilizar con map y flat-map. Estas son las operaciones más comunes que realizarás con futuros.

|método|argumento|descripción|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Asigna un valor futuro a un valor diferente.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Asigna un valor futuro a un valor diferente o a un error.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Asigna un valor futuro a un valor _futuro_ diferente.|
|[`transform`](#transform)|`U`|Asigna un futuro a un valor ya disponible.|

Si observas las firmas de los métodos para `map` y `flatMap` en `Optional<T>` y `Array<T>`, verás que son muy similares a los métodos disponibles en `EventLoopFuture<T>`.

### map

El método `map` te permite transformar el valor del futuro en otro valor. Debido a que es posible que el valor futuro aún no esté disponible (puede ser el resultado de una tarea asincrónica), debemos proporcionar un closure para aceptar el valor.

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

/// Asigna la cadena futura a un número entero
let futureInt = futureString.map { string in
    print(string) // La cadena de futuro
    return Int(string) ?? 0
}

/// Ahora tenemos un futuro entero
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

El método `flatMapThrowing` te permite transformar el valor del futuro a otro valor _o_ generar un error.

!!! info "Información"
    Debido a que para generar un error debes crear un nuevo futuro internamente, este método tiene el prefijo `flatMap` aunque el closure no acepte un retorno futuro.

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

/// Asigna la cadena futura a un número entero
let futureInt = futureString.flatMapThrowing { string in
    print(string) // La cadena de futuro
    // Convierta la cadena a un número entero o arroje un error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// Ahora tenemos un futuro entero
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

El método `flatMap` te permite transformar el valor futuro en otro valor futuro. Recibe el nombre de mapa "flat" porque es lo que le permite evitar la creación de futuros anidados (por ejemplo, `EventLoopFuture<EventLoopFuture<T>>`). En otras palabras, te ayuda a mantener tus genéricos planos (flat).

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

/// Supongamos que hemos creado un cliente HTTP
let client: Client = ... 

/// Transformamos la cadena de futuro con flatMap a una respuesta de futuro
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// Ahora tenemos una respuesta de futuro
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info "Información"
    Si usáramos `map` en el ejemplo anterior, habríamos terminado con: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Para llamar a un método de throws dentro de un `flatMap`, usa las palabras clave `do` / `catch` de Swift y crea un [futuro completo](#makefuture).

```swift
/// Supongamos cadena y cliente futuros del ejemplo anterior.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Algún método sincrónico con throws.
        url = try convertToURL(string)
    } catch {
        // Utiliza el bucle de eventos para crear un futuro precompletado.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

El método `transform` te permite modificar el valor de un futuro, ignorando el valor existente. Esto es especialmente útil para transformar los resultados de `EventLoopFuture<Void>` donde el valor real del futuro no es importante.

!!! tip "Consejo"
    `EventLoopFuture<Void>`, a veces llamado señal o signal, es un futuro cuyo único propósito es notificarle sobre la finalización o falla de alguna operación asíncrona.

```swift
/// Supongamos que recuperamos un futuro vacío de alguna API
let userDidSave: EventLoopFuture<Void> = ...

/// Transforma el futuro vacío a un estado HTTP
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Aunque hayamos proporcionado un valor ya disponible para `transform`, esto sigue siendo una _transformación_. El futuro no se completará hasta que todos los futuros anteriores se hayan completado (o hayan fallado).

### Encadenar

Lo bueno de las transformaciones de futuros es que pueden encadenarse. Esto te permite expresar muchas conversiones y subtareas fácilmente.

Modifiquemos los ejemplos anteriores para ver cómo podemos aprovechar el encadenamiento.

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

/// Supongamos que hemos creado un cliente HTTP
let client: Client = ... 

/// Transforma la cadena en una URL y luego en una respuesta
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

After the initial call to map, there is a temporary `EventLoopFuture<URL>` created. This future is then immediately flat-mapped to a `EventLoopFuture<Response>`
Después de la llamada inicial a map, se crea un `EventLoopFuture<URL>` temporal. Este futuro se asigna inmediatamente a un `EventLoopFuture<Response>`
    
## Futuro

Echemos un vistazo a algunos otros métodos para usar `EventLoopFuture<T>`.

### makeFuture

Puedes utilizar un bucle de eventos para crear un futuro precompletado con el valor o un error.

```swift
// Crear un futuro pre-éxito.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Crea un futuro pre-fallido.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Puedes usar `whenComplete` para agregar una respuesta de llamada que se ejecutará cuando el futuro tenga éxito o falle.

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // La cadena del futuro
    case .failure(let error):
        print(error) // Un Error de Swift
    }
}
```

!!! note "Nota"
    Puedes agregar tantos callbacks a un futuro como desees.
    
### Esperar

Puedes utilizar `.wait()` para esperar sincrónicamente a que se complete el futuro. Dado que un futuro puede fracasar, este llamado es desechado.

```swift
/// Supongamos que recuperamos una cadena futura de alguna API
let futureString: EventLoopFuture<String> = ...

/// Bloquear hasta que la cadena esté lista
let string = try futureString.wait()
print(string) /// String
```

`wait()` can only be used on a background thread or the main thread, i.e., in `configure.swift`. It can _not_ be used on an event loop thread, i.e., in route closures.
`wait()` solo se puede usar en un hilo en segundo plano o en el hilo principal, por ejemplo, en `configure.swift`. _No_ se puede utilizar en un subproceso de bucle de eventos, es decir, en closures de rutas.

!!! warning "Advertencia"
    Intentar llamar a `wait()` en un hilo de bucle de eventos provocará un error de aserción.

    
## Promesa

La mayoría de las veces, transformarás los futuros devueltos desde llamadas a APIs de Vapor. Sin embargo, en algún momento es posible que necesites crear una promesa propia.

Para crear una promesa, necesitarás acceso a un `EventLoop`. Puedes obtener acceso a un bucle de eventos desde `Application` o `Request` según el contexto.

```swift
let eventLoop: EventLoop

// Crea una nueva promesa para alguna cadena.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completa el futuro asociado.
promiseString.succeed("Hello")

// Falla el futuro asociado.
promiseString.fail(...)
```

!!! info "Información"
    Una promesa sólo puede cumplirse una vez. Cualquier finalización posterior será ignorada.

Las promesas se pueden completar (`succeed` / `fail`) desde cualquier hilo. Es por eso que las promesas requieren que se inicialice un bucle de eventos. Las promesas garantizan que la acción de finalización regrese a su bucle de eventos para su ejecución.

## Event Loop

Cuando su aplicación arranca, normalmente creará un bucle de eventos (event loop) para cada núcleo de la CPU en la que se está ejecutando. Cada bucle de eventos tiene exactamente un hilo. Si está familiarizado con los bucles de eventos de Node.js, los de Vapor son similares. La principal diferencia es que Vapor puede ejecutar múltiples bucles de eventos en un proceso, ya que Swift admite subprocesos múltiples.

Cada vez que un cliente se conecta a su servidor, será asignado a uno de los bucles de eventos. A partir de ese momento, toda la comunicación entre el servidor y ese cliente ocurrirá en ese mismo bucle de eventos (y por asociación, el hilo de ese bucle de eventos).

El bucle de eventos es responsable de realizar un seguimiento del estado de cada cliente conectado. Si hay una solicitud del cliente esperando ser leída, el bucle de eventos activa una notificación de lectura, lo que provoca que se lean los datos. Una vez que se lea la solicitud, se completarán todos los futuros que estén esperando los datos de esa solicitud.

En los closures de ruta, puedes acceder al bucle de eventos actual mediante `Request`.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning "Advertencia"
    Vapor espera que los closures de rutas permanezcan en `req.eventLoop`. Si saltas subprocesos, debes garantizar que el acceso a `Request` y la respuesta final futura ocurran en el bucle de eventos de la solicitud.

Fuera de los closures de rutas, puedes obtener uno de los bucles de eventos disponibles a través de `Application`.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Puedes cambiar el bucle de eventos de un futuro usando `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Bloqueos

Llamar a un código de bloqueo en un subproceso de bucle de eventos puede impedir que su aplicación responda a las solicitudes entrantes de manera oportuna. Un ejemplo de una llamada de bloqueo sería algo como `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Pone en suspensión el hilo del bucle de eventos.
    sleep(5)
    
    /// Devuelve una cadena simple una vez que el hilo se reactiva.
    return "Hello, world!"
}
```

`sleep(_:)` es un comando que bloquea el hilo actual durante la cantidad de segundos proporcionados. Si realiza un trabajo de bloqueo como este directamente en un bucle de eventos, el bucle de eventos no podrá responder a ningún otro cliente asignado a él mientras dure el trabajo de bloqueo. En otras palabras, si realiza `sleep(5)` en un bucle de eventos, todos los demás clientes conectados a ese bucle de eventos (posiblemente cientos o miles) se retrasarán durante al menos 5 segundos.

Asegúrate de ejecutar cualquier trabajo de bloqueo en segundo plano. Utiliza promesas para notificar al bucle de eventos cuando este trabajo se realice sin bloqueo.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Enviar algún trabajo para que se realice en un hilo en segundo plano
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Pone el hilo de fondo en suspensión
        /// Esto no afectará ninguno de los bucles de eventos
        sleep(5)
        
        /// Cuando se haya completado el "trabajo de bloqueo",
        /// se devuelve el resultado.
        return "Hello world!"
    }
}
```

No todas las llamadas de bloqueo serán tan obvias como `sleep(_:)`. Si sospechas que una llamada que estás utilizando puede estar bloqueando, investiga el método o pregúntale a alguien. Las secciones siguientes analizan con más detalle cómo se pueden bloquear los métodos.

### I/O Bound

El bloqueo I/O bound significa esperar en un recurso lento, como una red o un disco duro, que pueden ser órdenes de magnitud más lento que la CPU. Bloquear la CPU mientras espera estos recursos resulta en una pérdida de tiempo.

!!! danger "Peligro"
    Nunca realices llamadas I/O bound de bloqueo directamente en un bucle de eventos.

Todos los paquetes de Vapor están construidos en SwiftNIO y utilizan entrada o salida (I/O) sin bloqueo. Sin embargo, existen muchos paquetes de Swift y bibliotecas C que bloquean la entrada o salida. Lo más probable es que si una función realiza entrada o salida de disco o de red y utiliza una API síncrona (sin devoluciones de llamada ni futuros), esté bloqueando.

### CPU Bound

La mayor parte del tiempo durante una solicitud, se dedica a esperar a que se carguen recursos externos, como consultas de bases de datos y solicitudes de red. Debido a que Vapor y SwiftNIO no son bloqueantes, este tiempo de inactividad se puede utilizar para cumplir con otras solicitudes entrantes. Sin embargo, es posible que algunas rutas de su aplicación deban realizar un trabajo pesado vinculado a la CPU como resultado de una solicitud.

Mientras un bucle de eventos procesa el trabajo vinculado a la CPU, no podrás responder a otras solicitudes entrantes. Esto normalmente está bien, ya que las CPU son rápidas y la mayoría del trabajo de la CPU que realizan las aplicaciones web es liviano. Pero esto puede convertirse en un problema si las rutas con un trabajo prolongado de la CPU impiden que se responda rápidamente a las solicitudes de rutas más rápidas.

Identificar el trabajo de CPU de larga duración en su aplicación y moverlo a subprocesos en segundo plano, puede ayudar a mejorar la confiabilidad y la capacidad de respuesta de su servicio. El trabajo vinculado a la CPU es más un área gris que el trabajo vinculado a entrada o salida y, en última instancia, depende de ti determinar dónde deseas trazar la línea.

Un ejemplo común de trabajo pesado vinculado a la CPU es el encriptación (hashing) con Bcrypt durante el registro y el inicio de sesión del usuario. Bcrypt es deliberadamente muy lento y consume mucha CPU por razones de seguridad. Este puede ser el trabajo con mayor uso de CPU que realmente realiza una aplicación web simple. Mover el hash a un subproceso en segundo plano puede permitir que la CPU intercale el trabajo del bucle de eventos mientras calcula los hashes, lo que da como resultado una mayor concurrencia.
