# Hola, mundo

Esta guía te llevará paso a paso por el proceso de creación, construcción y ejecución de un nuevo proyecto de Vapor.

Si todavía no has instalado Swift o Vapor Toolbox, echa un vistazo a la sección de instalaciones.

- [Instalación &rarr; macOS](../install/macos.md)
- [Instalación &rarr; Linux](../install/linux.md)

## Nuevo Proyecto

El primer paso es crear un nuevo proyecto de Vapor en tu computadora. Abre el terminal y usa el comando de nuevo proyecto de Toolbox. Esto generará una nueva carpeta con el proyecto en el directorio actual.

```sh
vapor new hello -n
```

!!! tip "Consejo"
	La marca `-n` te da una plantilla básica contestando negativamente a todas las preguntas de manera automática.

!!! tip "Consejo"
    También puedes obtener la plantilla más reciente desde GitHub sin usar Vapor Toolbox clonando [template respository](https://github.com/vapor/template-bare)

!!! tip "Consejo"
	Vapor y la plantilla ahora usan `async`/`await` por defecto.
	Si no puedes actualizar a macOS 12 y/o necesitas seguir usando los `EventLoopFuture`, 
	usa la marca `--branch macos10-15`.

Cuando el comando haya terminado, cambia a la nueva carpeta recién creada:


```sh
cd hello
```

## Compilar y Ejecutar

### Xcode

Primero, abre el proyecto en Xcode:

```sh
open Package.swift
```

Automáticamente comenzará a descargar las dependencias de Swift Package Manager. Este proceso puede requerir cierto tiempo la primera vez que abras el proyecto. Cuando la resolución de dependencias se haya completado Xcode poblará los esquemas disponibles. 

En la parte superior de la ventana, a la derecha de los botones Play y Stop, pulsa en el nombre de tu proyecto para seleccionar el esquema (Scheme) del proyecto, y selecciona un target de ejecución apropiado—preferiblemente, "My Mac". Pulsa en el botón de play para compilar y ejecutar tu proyecto.

La consola debería aparecer en la parte inferior de la ventana de Xcode.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

En Linux y otros sistemas operativos (e inclusive en macOS si no quieres usar Xcode) puedes editar el proyecto en el editor que prefieras, por ejemplo Vim o VSCode. Visita [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md) para detalles actualizados sobre cómo configurar otros IDEs.

Para construir y ejecutar tu proyecto, ejecuta en el Terminal:

```sh
swift run
```

Eso compilará y ejecutará tu proyecto. La primera vez que lo ejecutes necesitará un tiempo para buscar y resolver las dependencias. Una vez esté ejecutándose deberías ver en la consola lo siguiente:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visitar Localhost

Abre tu navegador web y dirígete <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> or <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

Deberías ver la página a continuación.

```html
Hello, world!
```

¡Enhorabuena! ¡Has creado, compilado y ejecutado tu primera app de Vapor! 🎉
