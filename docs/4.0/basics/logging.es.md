# Logging (Registro)

La API de logging (registro) de Vapor está hecha sobre [SwiftLog](https://github.com/apple/swift-log). Esto implica que Vapor es compatible con todas las [implementaciones de backend](https://github.com/apple/swift-log#backends) de SwiftLog. 

## Logger

Las instancias de `Logger` son usadas para emitir mensajes de registro. Vapor proporciona varias formas sencillas de acceso a un logger (registrador).

### Petición (Request)

Cada `Request` entrante tiene un logger único que debes usar para cualquier registro específico de la propia petición.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

El logger de la petición incluye un UUID único que identifica la petición entrante para facilitar el seguimiento de los registros.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info "Información"
	Los metadatos del logger solo se mostrarán en el nivel de registro de depuración (debug) o inferiores.

### Aplicación

Para los mensajes de registro durante el arranque y la configuración de la app, usa el logger de `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Logger Personalizado

En situaciones donde no tengas acceso a `Application` o `Request`, puedes inicializar un nuevo `Logger`. 

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Si bien los loggers personalizados emitirán registros al backend de registro que tengas configurado, los registros no contendrán metadatos adicionales relevantes, como el UUID de la petición. Utiliza los loggers específicos de las petición o de la aplicación siempre que puedas. 

## Nivel

SwiftLog soporta una variedad de niveles de registro.

|nombre|descripción|
|-|-|
|trace|Apropiado para mensajes que contengan información usada normalmente cuando se está trazando la ejecución de un programa.|
|debug|Apropiado para mensajes que contengan información usada normalmente en procesos de debug de un programa.|
|info|Apropiado para mensajes informativos.|
|notice|Apropiado para condiciones que no sean errores pero puedan requerir un manejo especial.|
|warning|Apropiado para mensajes que no sean condiciones de error pero más severos que un aviso.|
|error|Apropiado para condiciones de error.|
|critical|Apropiado para el manejo de condiciones críticas de error que requieran atención inmediata.|

Cuando un mensaje `critical` es registrado, el backend de registro es libre de realizar operaciones más pesadas para capturar el estado del sistema, como la captura de rastros de pila (stack traces), para facilitar el proceso de depuración (debugging).

Por defecto, Vapor usará en nivel de registro `info`. Cuando sea ejecutado en el entorno `production`, se usará `notice` para mejorar el rendimiento. 

### Cambiando el nivel de registro

Puedes cambiar el nivel de registro independientemente del modo de entorno para aumentar o disminuir la cantidad de registros producidos. 

El primer método consiste en pasar la flag opcional `--log` cuando arranques tu aplicación.

```sh
swift run App serve --log debug
```

El segundo método consiste en establecer la variable de entorno `LOG_LEVEL`.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Ambos métodos pueden realizarse en Xcode editando el `App` scheme (esquema de la app).

## Configuración

SwiftLog se configura arrancando (bootstrapping) el `LoggingSystem` una vez por cada proceso. Los projectos de Vapor normalmente hacen esto en `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` es un método de ayuda (helper method) proporcionado por Vapor que configurará el handler de registros predeterminado en base a argumentos de línea de comandos y variables de entorno. El handler de registros predeterminado soporta la emisión de mensajes a la terminal con soporte de color ANSI. 

### Handler Personalizado

Puedes sobrescribir el handler de registros predeterminado de Vapor y registrar el tuyo propio.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

 Todos los backend soportados por SwiftLog funcionarán con Vapor. Sin embargo, cambiar el nivel de registro con argumentos de línea de comandos y variables de entorno es compatible únicamente con el handler de registros predeterminado de Vapor.
