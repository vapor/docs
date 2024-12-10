# Instalación en Linux

Para usar Vapor, necesitas Swift 5.9 o superior. Se puede instalar usando las opciones disponibles en [Swift.org](https://swift.org/download/).

## Distribuciones y Versiones Soportadas

Vapor admite las mismas versiones de distribución de Linux que adminte Swift 5.9 o versiones más recientes.

!!! nota
    Las versiones soportadas que se enumeran a continuación pueden quedar obsoletas en cualquier momento. Puedes comprobar qué sistemas operativos son oficialmente compatibles en la página [Swift Releases](https://swift.org/download/#releases).

|Distribución|Versión|Versión de Swift|
|-|-|-|
|Ubuntu|20.04|>= 5.9|
|Fedora|>= 30|>= 5.9|
|CentOS|8|>= 5.9|
|Amazon Linux|2|>= 5.9|

Las distribuciones de Linux que no son oficialmente compatibles también pueden ejecutar Swift al compilar el código fuente, pero Vapor no puede garantizar estabilidad. Puedes aprender más sobre cómo compilar Swift desde [Swift Repo](https://github.com/apple/swift#getting-started).

## Instalar Swift

Visita la guía [Using Downloads](https://swift.org/download/#using-downloads) de Swift.org para ver las instrucciones de cómo instalar Swift en Linux.

### Fedora

Los usuarios de Fedora pueden simplemente utilizar el siguiente comando para instalar Swift:

```sh
sudo dnf install swift-lang
```

Si utilizas Fedora 30, deberás agregar EPEL 8 para obtener Swift 5.9 o versiones más nuevas.

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
