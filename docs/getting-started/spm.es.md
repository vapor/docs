# Swift Package Manager

El [Swift Package Manager](https://swift.org/package-manager/) (SPM) es usado para compilar el código fuente y las dependencias de tu proyecto. Dado que Vapor depende en gran medida de SPM, entender su funcionamiento básico es una buena idea.

SPM es similar a Cocoapods, Ruby gems y NPM. Puedes usar SPM desde la línea de comandos con comandos como `swift build` y `swift test`, o con IDEs compatibles. Sin embargo, a diferencia de otros package managers, no hay un índice de paquete central para los paquetes de SPM. En su lugar, SPM utiliza URLs de repositorios Git y dependencias de versiones utilizando [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging). 

## Manifiesto del Paquete

El primer lugar en el que SPM mira en tu proyecto es el manifiesto del paquete. Éste debería estar alojado siempre en el directorio raíz de tu proyecto y llamarse `Package.swift`.

Echa un vistazo a este ejemplo de manifiesto de paquete.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Cada parte del manifiesto se explica en las secciones a continuación.

### Versión de Herramientas

La primera línea del manifiesto del paquete indica la versión requerida de las herramientas de Swift. Esto especifica la versión mínima de Swift que el paquete soporta. La API de descripción del paquete puede sufrir cambios entre versiones de Swift, así que esta línea asegura que Swift sepa analizar tu manifiesto. 

### Nombre del Paquete

El primer argumento de `Package` es el nombre del paquete. Si el paquete es público, deberás usar el último segmento de la URL del repositorio de Git como nombre.

### Plataformas

El array `platforms` especifica las plataformas que el paquete soporta. Especificando `.macOS(.v12)` este paquete requiere macOS 12 o superior. Cuando Xcode cargue este proyecto, ajustará automáticamente la versión mínima de despliegue a macOS 12 para que puedas usar todas las APIs disponibles.

### Dependencias

Las dependencias son otros paquetes de SPM de los que tu paquete depende. Todas las aplicaciones de Vapor dependen del paquete Vapor, pero puedes agregar tantas dependencias como quieras.

En el ejemplo anterior, puedes ver que [vapor/vapor](https://github.com/vapor/vapor), en su versión 4.76.0 o superior, es una dependencia de este paquete. Al agregar una dependencia a tu paquete, deberás señalar a continuación los [targets](#targets) que dependen
de los módulos recién agregados.

### Targets

Los targets son todos los módulos, ejecutables y tests que tu paquete contiene. La mayoría de aplicaciones Vapor tendrán dos targets, aunque puedes añadir tantos como quieras para organizar tu código. Cada target declara los módulos de los que depende. Debes añadir los nombres de los módulos aquí para poder importarlos en tu código. Un target puede depender de otros targets en tu proyecto o de cualquiera de los módulos expuestos por los paquetes que hayas agregado en
el array de [main dependencies](#dependencies).

## Estructura de Carpetas

A continuación se muestra la estructura de carpetas típica para un paquete SPM.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Cada `.target` o `.executableTarget` se corresponde con una carpeta en la carpeta `Sources`. 
Cada `.testTarget` se corresponde con una carpeta en la carpeta `Tests`.

## Package.resolved

La primera vez que construyas tu proyecto, SPM creará un fichero `Package.resolved` que guarda la versión de cada dependencia. La próxima vez que construyas tu proyecto, estas mismas versiones serán usadas aunque haya versiones nuevas disponibles. 

Para actualizar tus dependencias, ejecuta `swift package update`.

## Xcode

Si estás usando Xcode 11 o superior, los cambios en dependencias, targets, productos y demás se harán de manera automática cuando el fichero `Package.swift` sea modificado. 

Si quieres actualizar las dependencias, ve a File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

En general, es recomendable añadir el fichero `.swiftpm` a tu `.gitignore`. En este fichero se guardará la configuración de tu proyecto de Xcode.
