# Estructura de Carpetas

Una vez has creado, construido y ejecutado tu primera app de Vapor, vamos a familiarizarte con la estructura de carpetas de Vapor. La estructura está basada en la utilizada por [SPM](spm.md), así que si has trabajado anteriormente con SPM debería ser algo conocido. 

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

Las secciones siguientes explican de manera más detallada cada parte de la estructura de carpetas.

## Public

Esta carpeta contiene los ficheros públicos que serán servidos por tu app si `FileMiddleware` está activado. Suelen ser imágenes, hojas de estilo o scripts de navegador. Por ejemplo, una petición a `localhost:8080/favicon.ico` comprobará si `Public/favicon.ico` existe y lo devolverá.

Necesitarás habilitar `FileMiddleware` en tu fichero `configure.swift` para que Vapor pueda servir ficheros públicos.

```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Esta carpeta contiene todos los ficheros Swift de código fuente para tu proyecto. 
La carpeta `App`, de nivel superior, corresponde al módulo de tu package, 
tal y como está declarado en el manifiesto de [SwiftPM](spm.md).

### App

Aquí es donde se aloja toda la lógica de tu app. 

#### Controllers

Los controladores son una buena manera de agrupar lógica de aplicación. La mayoría de controladores tienen muchas funciones que aceptan una petición y devuelven algún tipo de respuesta.

#### Migrations

En esta carpeta es donde se ubican las migraciones de tu base de datos si estás usando Fluent.

#### Models

La carpeta de modelos es un buen lugar en el que guardar los structs `Content` o los `Model` de Fluent.

#### configure.swift

Este fichero contiene la función `configure(_:)`. Este método es llamado por `entrypoint.swift` para configurar la `Application` recién creada. Aquí es donde deberías registrar servicios como rutas, bases de datos, proveedores y otros. 

#### entrypoint.swift

Este fichero contiene el punto de entrada `@main` para la aplicación, que crea, configura y ejecuta tu aplicación Vapor.

#### routes.swift

Este fichero contiene la función `routes(_:)`. Este método es llamado casi al final de `configure(_:)` para registrar rutas en tu `Application`. 

## Tests

Cada módulo no ejecutable en tu carpeta `Sources` puede tener una carpeta correspondiente en `Tests`. Esto contiene código creado en el módulo `XCTest` para hacer testing a tu package. Los tests pueden ser ejecutados usando `swift test` en la línea de comandos o pulsando ⌘+U en Xcode. 

### AppTests

Esta carpeta contiene los tests unitarios para el código en tu módulo `App`.

## Package.swift

Finalmente está el manifiesto del package [SPM](spm.md).
