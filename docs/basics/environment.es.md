# Entorno

La API de entorno (Environment) de Vapor te ayuda a configurar tu app de manera dinámica. Por defecto, tu app usará el entorno `development`. Puedes definir otros entornos útiles como `production` o `staging` y cambiar la configuración de la app para cada caso. También puedes cargar variables desde el entorno del proceso o desde ficheros `.env` (dotenv) dependiendo de tus necesidades.

Para acceder al entorno actual, usa `app.environment`. Puedes hacer un switch de esta propiedad en `configure(_:)` para ejecutar distintas lógicas de configuración. 

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Cambiando de Entorno

Por defecto, tu app se ejecutará en el entorno `development`. Puedes cambiar esto pasando el argumento (flag) `--env` (`-e`) durante el arranque de la app.

```swift
swift run App serve --env production
```

Vapor incluye los siguientes entornos:

|nombre|abreviación|descripción|
|-|-|-|
|production|prod|Distribuido a tus usuarios.|
|development|dev|Desarrollo local.|
|testing|test|Para test unitario (unit testing).|

!!! info "Información"
    El entorno `production` usará el nivel de registro `notice` por defecto si no se especifica otro. El resto de entornos usarán `info` por defecto. 

Puedes pasar tanto el nombre entero como la abreviación del nombre en el argumento `--env` (`-e`).

```swift
swift run App serve -e prod
```

## Variables de Proceso

`Environment` ofrece una API simple basada en cadenas (string) para acceder a las variables de entorno de los procesos.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Además del método `get`, `Environment` ofrece una API de búsqueda dinámica de miembros (dynamic member lookup) mediante `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Al ejecutar tu app en el terminal, puedes estableces variables de entorno usando `export`. 

```sh
export FOO=BAR
swift run App serve
```

Al ejecutar tu app en Xcode, puedes estableces variables de entorno editando el esquema (scheme) de la `App`.

## .env (dotenv)

Los fichero Dotenv contienen una lista de pares clave-valor para ser cargados automáticamente en el entorno. Estos ficheros facilitan la configuración de variables de entorno sin necesidad de establecerlas manualmente.

Vapor buscará ficheros dotenv en el directorio de trabajo actual (current working directory). Si estás usando Xcode, asegúrate de configurar el directorio de trabajo (working directory) editando el esquema (scheme) de la `App`.

Asume que el siguiente fichero `.env` está en la carpeta raíz de tu projecto:

```sh
FOO=BAR
```

Cuando tu aplicación arranque, podrás acceder a los contenidos de este fichero como si fueran otras variables de entorno de proceso.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info "Información"
    Las variables especificadas en ficheros `.env` no sobrescribirán variables ya existentes en el entorno de proceso. 

Junto con `.env`, Vapor también tratará de cargar un fichero dotenv para el entorno actual. Por ejemplo, en el entorno `development`, Vapor cargará `.env.development`. Cualquier valor en el fichero de entorno especificado tendrá prioridad frente al fichero `.env` general.

Un típico patrón a seguir en los proyectos es incluir un fichero `.env` como una plantilla con valores predeterminados. Los ficheros de entorno específico pueden ser ignorados con este patrón de `.gitignore`:

```gitignore
.env.*
```

Cuando el proyecto es clonado a otra computadora, el fichero `.env` de plantilla puede ser copiado, para después insertar los valores correctos. 

```sh
cp .env .env.development
vim .env.development
```

!!! warning "Aviso"
    Los ficheros dotenv con información sensible como contraseñas no deberían añadirse en los commits del control de versiones.

Si estás teniendo dificultades en la carga de ficheros dotenv, prueba a habilitar el registro de depuración (debug logging) con `--log debug` para obtener más información. 

## Entornos Personalizados

Para definir un nombre de entorno personalizado, realiza una extensión de `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

El entorno de la aplicación es establecido normalmente en `entrypoint.swift` usando `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

El método `detect` usa los argumentos de línea de comandos del proceso y analiza el argumento (flag) `--env` automáticamente. Puedes sobrescribir este comportamiento inicializando un struct `Environment` personalizado.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

El array de argumentos debe contener al menos uno que represente el nombre del ejecutable. Se pueden suministrar más argumentos para simular el paso de argumentos mediante línea de comandos. Esto es especialmente útil para testing.
