# Instalación en macOS

Para usar Vapor en macOS, necesitarás Swift 5.9 o superior. Swift y todas sus dependencias vienen incluidas con Xcode.

## Instalar Xcode

Instala [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) desde la Mac App Store.

![Xcode en la Mac App Store](../images/xcode-mac-app-store.png)

Una vez que se haya descargado Xcode, debes abrirlo para completar la instalación. Este paso puede tardar un rato.

Para asegurarse de que la instalación se haya realizado correctamente, abre la Terminal e imprime la versión de Swift.

```sh
swift --version
```

Deberías ver la información de la versión de Swift.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4 requiere Swift 9 o superior.

## Instalar Toolbox

Ahora que tienes Swift instalado, vamos a instalar [Vapor Toolbox](https://github.com/vapor/toolbox). Esta aplicación de línea de comando (CLI) no es necesaria para usar Vapor, pero incluye útiles herramientas como un nuevo creador de proyectos.

Toolbox se distribuye a través de Homebrew. Si aún no tienes Homebrew, visita <a href="https://brew.sh" target="_blank">brew.sh</a> para obtener instrucciones de instalación.

```sh
brew install vapor
```

Verifica que la instalación fue exitosa imprimiendo la ayuda.

```sh
vapor --help
```

Deberías ver una lista de comandos disponibles.


## Siguientes Pasos

Ahora que tienes instalados Swift y Vapor Toolbox, crea tu primera app en [Comenzando &rarr; Hola, mundo](../getting-started/hello-world.md).
