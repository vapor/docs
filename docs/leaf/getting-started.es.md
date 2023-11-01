# Leaf

Leaf es un potente lenguaje de plantillas con una sintaxis inspirada en Swift. Puedes usarlo para generar páginas HTML dinámicas para el front-end de un sitio web o generar correos electrónicos enriquecidos para enviar desde una API.

## Paquete

El primer paso para usar Leaf es agregarlo como una dependencia en tu proyecto en tu archivo de manifiesto del paquete SPM.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Cualquier otra dependencia ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Cualquier otra dependencia
        ]),
        // Otros targets
    ]
)
```

## Configuración

Una vez agregado el paquete a tu proyecto, puedes configurar Vapor para usarlo. Esto generalmente se hace en [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Esto le indica a Vapor que use el `LeafRenderer` cuando llames a `req.view` en tu código.

!!! note "Nota"
    Leaf tiene un caché interno para renderizar páginas. Cuando el entorno de `Application` está configurado en `.development`, este caché está deshabilitado, de modo que los cambios en las plantillas surten efecto de inmediato. En `.production` y en todos los demás entornos, el caché está habilitado de forma predeterminada; cualquier cambio realizado en las plantillas no surtirá efecto hasta que se reinicie la aplicación.

!!! warning "Advertencia"
    Para que Leaf pueda encontrar las plantillas al ejecutar desde Xcode, debes establecer [el directorio de trabajo personalizado](../getting-started/xcode.md#custom-working-directory) para tu espacio de trabajo en Xcode.

## Estructura de Carpetas

Una vez que hayas configurado Leaf, deberás asegurarte de tener una carpeta `Views` para almacenar tus archivos `.leaf`. Por defecto, Leaf espera que la carpeta de vistas esté en `./Resources/Views` relativo a la raíz de tu proyecto.

También es probable que quieras habilitar el [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) de Vapor para servir archivos desde tu carpeta `/Public` si planeas servir archivos Javascript y CSS, por ejemplo.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (recursos de imágenes)
│   ├── styles (recursos css)
└── Sources
    └── ...
```

## Renderizando una Vista

Ahora que Leaf está configurado, vamos a renderizar tu primera plantilla. Dentro de la carpeta `Resources/Views`, crea un nuevo archivo llamado `hello.leaf` con el siguiente contenido:

```leaf
Hello, #(name)!
```

!!! tip "Consejo"
    Si estás usando VSCode como tu editor de código, te recomendamos instalar la extensión de Leaf para habilitar el resaltado de sintaxis: [Leaf HTML](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf).

Luego, registra una ruta (generalmente en `routes.swift` o en un controlador) para renderizar la vista.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// o

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Esto utiliza la propiedad genérica `view` en `Request` en lugar de llamar directamente a Leaf, permitiéndote cambiar a otro renderizador en tus pruebas.

Abre tu navegador y visita `/hello`. Deberías ver `Hello, Leaf!`. ¡Felicidades por renderizar tu primera vista Leaf!
