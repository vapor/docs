# Instalación en Linux

Para usar Vapor, necesitas Swift 5.9 o superior. Esto se puede instalar utilizando la herramienta CLI [Swiftly](https://swiftlang.github.io/swiftly/) proporcionada por el Swift Server Workgroup (recomendado), o las toolchains disponibles en [Swift.org](https://swift.org/download/).

## Distribuciones y Versiones Soportadas

Vapor es compatible con las mismas versiones de distribuciones de Linux que soportan Swift 5.9 o versiones posteriores. Por favor, consulta la [página oficial de soporte](https://www.swift.org/platform-support/) para obtener información actualizada sobre los sistemas operativos oficialmente compatibles.

Las distribuciones de Linux que no son oficialmente compatibles también pueden ejecutar Swift al compilar el código fuente, pero Vapor no puede garantizar estabilidad. Puedes aprender más sobre cómo compilar Swift desde [Swift Repo](https://github.com/apple/swift#getting-started).

## Instalar Swift

### Instalación automatizada usando la herramienta Swiftly CLI (recomendada)

Visita el [sitio web de Swiftly](https://swiftlang.github.io/swiftly/) para obtener instrucciones sobre cómo instalar Swiftly y Swift en Linux. Después de eso, instala Swift con el siguiente comando:

#### Uso básico

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Instalación manual con la toolchain

Visita la guía [Using Downloads](https://swift.org/download/#using-downloads) de Swift.org para ver las instrucciones de cómo instalar Swift en Linux.

### Fedora

Los usuarios de Fedora pueden simplemente utilizar el siguiente comando para instalar Swift:

```sh
sudo dnf install swift-lang
```

Si utilizas Fedora 35, deberás agregar EPEL 8 para obtener Swift 5.9 o versiones más nuevas.

## Docker

También puedes usar las imágenes de Docker oficiales de Swift que vienen con el compilador preinstalado. Obtenga más información en [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Instalar Toolbox

Ahora que tienes Swift instalado, vamos a instalar [Vapor Toolbox](https://github.com/vapor/toolbox). Esta aplicación de línea de comando (CLI) no es necesaria para usar Vapor, pero incluye útiles herramientas.

En Linux deberás compilar Toolbox desde el código fuente. Puedes ver las <a href="https://github.com/vapor/toolbox/releases" target="_blank">versiones</a> de Toolbox en GitHub para encontrar la versión más reciente.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Verifica que la instalación fue exitosa imprimiendo la ayuda.

```sh
vapor --help
```

Deberías ver una lista de comandos disponibles.

## Siguientes Pasos

Después de instalar Swift, crea tu primera app en [Comenzando &rarr; Hola, mundo](../getting-started/hello-world.md).
