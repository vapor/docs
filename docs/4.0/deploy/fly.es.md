# Fly

Fly es una plataforma de alojamiento que permite ejecutar aplicaciones de servidor y bases de datos, con un enfoque en la computación descentralizada. Consulta [su página web](https://fly.io/) para más información.

!!! note "Nota"
    Los comandos especificados en este documento están sujetos a [los precios de Fly](https://fly.io/docs/about/pricing/). Asegúrate de entenderlos correctamente antes de continuar.

## Registrarse

Si no tienes una cuenta, necesitas [crear una](https://fly.io/app/sign-up).

## Instalando flyctl

La principal forma de interactuar con Fly es utilizando su herramienta CLI dedicada, `flyctl`, que necesitarás instalar.

### macOS

```bash
brew install flyctl
```

### Linux

```bash
curl -L https://fly.io/install.sh | sh
```

### Otras opciones de instalación

Para más opciones y detalles, consulta la [documentación sobre la instalación de flyctl](https://fly.io/docs/flyctl/install/).

## Iniciar sesión

Para iniciar sesión desde tu terminal, ejecuta el siguiente comando:

```bash
fly auth login
```

## Configurando tu proyecto de Vapor

Antes de desplegar en Fly, debes asegurarte de tener un proyecto de Vapor con un Dockerfile configurado adecuadamente, ya que Fly lo requiere para construir tu aplicación. En la mayoría de los casos, esto será muy sencillo porque las plantillas predeterminadas de Vapor ya incluyen uno.

### Nuevo proyecto de Vapor

La forma más fácil de crear un nuevo proyecto es comenzar con una plantilla. Puedes crear uno utilizando las plantillas de GitHub o la herramienta Vapor toolbox. Si necesitas una base de datos, se recomienda usar Fluent con Postgres, ya que Fly facilita la creación de una base de datos Postgres para conectar tus aplicaciones (consulta la [sección dedicada](#configurando-postgres) más abajo).

#### Usando la Vapor toolbox

Primero, asegúrate de haber instalado la Vapor toolbox (consulta las instrucciones para instalarla en [macOS](../install/macos.md#install-toolbox) o [Linux](../install/linux.md#install-toolbox)).

Crea tu nueva aplicación con el siguiente comando, reemplazando `app-name` por el nombre que desees:

```bash
vapor new app-name
```

Este comando mostrará un asistente interactivo que te permitirá configurar tu proyecto de Vapor. Aquí es donde puedes seleccionar Fluent y Postgres si los necesitas.

#### Usando plantillas de GitHub

Elige la plantilla que mejor se adapte a tus necesidades de la siguiente lista. Puedes clonarla localmente usando Git o crear un proyecto en GitHub con el botón “Use this template”.

- [Barebones template](https://github.com/vapor/template-bare)
- [Fluent/Postgres template](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf template](https://github.com/vapor/template-fluent-postgres-leaf)

### Proyecto existente de Vapor

Si ya tienes un proyecto de Vapor, asegúrate de tener un `Dockerfile` configurado adecuadamente en la raíz de tu directorio. La [documentación de Vapor sobre el uso de Docker](../deploy/docker.md) y la [documentación de Fly sobre el despliegue de una app mediante un Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) pueden ser útiles.

## Lanzando tu aplicación en Fly

Una vez que tu proyecto de Vapor esté listo, puedes lanzarlo en Fly.

Primero, asegúrate de que tu directorio actual esté en la raíz de tu aplicación de Vapor y ejecuta el siguiente comando:

```bash
fly launch
```

Esto iniciará un asistente interactivo para configurar los ajustes de tu aplicación en Fly:

- **Name:** puedes escribir un nombre o dejarlo en blanco para que se genere automáticamente.
- **Region:** el valor predeterminado será la más cercana a ti. Puedes usarla o elegir otra de la lista. Esto es fácil de cambiar más tarde.
- **Database:** puedes pedir a Fly que cree una base de datos para usar con tu aplicación. Si prefieres, siempre puedes hacerlo más tarde con los comandos `fly pg create` y `fly pg attach` (consulta la sección [Configurando Postgres](#configurando-postgres) para más detalles).

El comando `fly launch` crea automáticamente un archivo `fly.toml`. Éste contiene configuraciones como asignaciones de puertos privados y/o públicos, parámetros de comprobación de estado, entre otros. Si acabas de crear un proyecto nuevo con `vapor new`, el archivo `fly.toml` predeterminado no necesita cambios. Si tienes un proyecto existente, es probable que el archivo `fly.toml` también esté bien sin cambios o solo con ajustes menores. Puedes encontrar más información en la [documentación de `fly.toml`](https://fly.io/docs/reference/configuration/).

Nota que si solicitas a Fly crear una base de datos, tendrás que esperar un poco a que se cree y que pasen las verificaciones de estado.

Antes de salir, el comando `fly launch` te preguntará si deseas desplegar tu aplicación de inmediato. Puedes aceptarlo o hacerlo más tarde usando `fly deploy`.

!!! tip "Consejo"
    Cuando tu directorio actual está en la raíz de tu aplicación, la herramienta CLI de Fly detecta automáticamente la presencia de un archivo `fly.toml`, lo que permite a Fly saber a qué aplicación están dirigidos tus comandos. Si deseas apuntar a una aplicación específica sin importar en qué directorio te encuentres, puedes agregar `-a name-of-your-app` a la mayoría de los comandos de Fly.

## Desplegando

Ejecuta el comando `fly deploy` cada vez que necesites desplegar nuevos cambios en Fly.

Fly lee los archivos `Dockerfile` y `fly.toml` de tu directorio para determinar cómo construir y ejecutar tu proyecto de Vapor.

Una vez que tu contenedor se construye, Fly inicia una instancia de él. Ejecutará varias comprobaciones de estado para asegurarse de que tu aplicación funciona correctamente y responde a las solicitudes. El comando `fly deploy` saldrá con un error si las comprobaciones de estado fallan.

Por defecto, Fly volverá a la última versión funcional de tu aplicación si las comprobaciones de estado fallan para la nueva versión que intentaste desplegar.

Al desplegar un worker en segundo plano (con Vapor Queues), no cambies el CMD ni el ENTRYPOINT en tu Dockerfile; déjalos tal cual para que la aplicación web principal se inicie normalmente. En su lugar, añade una sección [processes] en tu archivo fly.toml como esta:

```
[processes]
  app = ""
  worker = "queues"
```

Esto indica a Fly.io que ejecute el proceso de la aplicación con el punto de entrada predeterminado de Docker (tu servidor web) y que el proceso del worker ejecute tu cola de tareas utilizando la interfaz de línea de comandos de Vapor (es decir, swift run App queues).

## Configurando Postgres

### Creando una base de datos Postgres en Fly

Si no creaste una aplicación de base de datos cuando lanzaste tu aplicación por primera vez, puedes hacerlo más tarde con:

```bash
fly pg create
```

Este comando crea una aplicación de Fly que podrá alojar bases de datos disponibles para tus otras aplicaciones en Fly. Consulta la [documentación dedicada de Fly](https://fly.io/docs/postgres/) para más detalles.

Una vez que tu aplicación de base de datos esté creada, ve al directorio raíz de tu aplicación de Vapor y ejecuta:

```bash
fly pg attach name-of-your-postgres-app
```

Si no sabes el nombre de tu aplicación Postgres, puedes encontrarlo con `fly pg list`.

El comando `fly pg attach` crea una base de datos y un usuario destinado a tu aplicación, y luego la expone a través de la variable de entorno `DATABASE_URL`.

!!! note "Nota"
    La diferencia entre `fly pg create` y `fly pg attach` es que el primero asigna y configura una aplicación de Fly que puede alojar bases de datos Postgres, mientras que el segundo crea una base de datos real y un usuario destinado a la aplicación de tu elección. Siempre que cumpla con tus requisitos, una sola aplicación de Postgres en Fly puede alojar múltiples bases de datos utilizadas por varias aplicaciones. Cuando pides a Fly crear una aplicación de base de datos en `fly launch`, hace el equivalente a llamar tanto a `fly pg create` como a `fly pg attach`.

### Conectando tu aplicación de Vapor a la base de datos

Una vez que tu aplicación esté conectada a tu base de datos, Fly configura la variable de entorno `DATABASE_URL` con la URL de conexión que contiene tus credenciales (debe tratarse como información sensible).

En la mayoría de las configuraciones comunes de proyectos de Vapor, configuras tu base de datos en `configure.swift`. Aquí tienes un ejemplo de cómo hacerlo:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Manejar la ausencia de DATABASE_URL aquí...
    //
    // Alternativamente, también podrías establecer una configuración 
    // diferente dependiendo de si app.environment está configurado como 
    // `.development` o `.production`.
}
```

En este punto, tu proyecto debería estar listo para ejecutar migraciones y usar la base de datos.

### Ejecutando migraciones

Con el comando `release_command` de `fly.toml`, puedes pedir a Fly que ejecute un cierto comando antes de ejecutar tu proceso principal del servidor. Agrega esto a `fly.toml`:

```toml
[deploy]
 release_command = "migrate -y"
```

!!! note "Nota"
    El fragmento de código anterior asume que estás utilizando el Dockerfile predeterminado de Vapor, que establece tu `ENTRYPOINT` como `./App`. Concretamente, esto significa que cuando configuras `release_command` como `migrate -y`, Fly llamará a `./App migrate -y`. Si tu `ENTRYPOINT` está configurado en un valor diferente, necesitarás adaptar el valor de `release_command`.

Fly ejecutará tu comando de lanzamiento en una instancia temporal que tiene acceso a tu red interna de Fly, secrets y variables de entorno.

Si tu comando de lanzamiento falla, el despliegue no continuará.

### Otras bases de datos

Aunque Fly facilita la creación de una aplicación de base de datos Postgres, es posible alojar otros tipos de bases de datos también (por ejemplo, consulta [“Use a MySQL database”](https://fly.io/docs/app-guides/mysql-on-fly/) en la documentación de Fly).

## Secrets y variables de entorno

### Secrets

Usa secrets para establecer cualquier valor sensible como variables de entorno.

```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning "Advertencia"
    Ten en cuenta que la mayoría de las shells mantienen un historial de los comandos que escribes. Sé cauteloso al configurar secrets de esta manera. Algunas shells pueden configurarse para no recordar comandos que están precedidos por un espacio. Consulta también el [comando `fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Para más información, consulta la [documentación de `fly secrets`](https://fly.io/docs/apps/secrets/).

### Variables de entorno

Puedes establecer otras [variables de entorno no sensibles en `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), por ejemplo:

```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Conexión SSH

Puedes conectarte a las instancias de una aplicación utilizando:

```bash
fly ssh console -s
```

## Verificando los registros

Puedes verificar los registros en vivo de tu aplicación utilizando:

```bash
fly logs
```

## Próximos pasos

Ahora que tu aplicación de Vapor está desplegada, hay mucho más que puedes hacer, como escalar tus aplicaciones vertical y horizontalmente en múltiples regiones, añadir volúmenes persistentes, configurar despliegues contínuos, o incluso crear clústeres de aplicaciones distribuidas. El mejor lugar para aprender cómo hacer todo esto y más es la [documentación de Fly](https://fly.io/docs/).
