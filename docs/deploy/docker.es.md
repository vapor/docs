# Despliegues Docker

Usar Docker para desplegar tu aplicación Vapor tiene varios beneficios:

1. Tu aplicación dockerizada se puede poner en marcha de manera confiable usando los mismos comandos en cualquier plataforma con un Docker Daemon -es decir, Linux (CentOS, Debian, Fedora, Ubuntu), macOS y Windows-.
2. Puedes utilizar docker-compose o manifiestos de Kubernetes para orquestar múltiples servicios necesarios para un despliegue completo (por ejemplo, Redis, Postgres, nginx, etc.).
3. Es fácil probar la capacidad de tu aplicación para escalar horizontalmente, incluso localmente, en tu máquina de desarrollo.

Esta guía no llegará a explicar cómo colocar tu aplicación dockerizada en un servidor. El despliegue más simple implicaría instalar Docker en tu servidor y ejecutar los mismos comandos que ejecutarías en tu máquina de desarrollo para poner en marcha tu aplicación.

Los despliegues más complicados y robustos suelen ser diferentes dependiendo de tu solución de alojamiento; muchas soluciones populares como AWS tienen soporte integrado para Kubernetes y soluciones de bases de datos personalizadas, lo que dificulta la redacción de las mejores prácticas de una forma que aplique a todos los despliegues.

Sin embargo, usar Docker para levantar todo el conjunto de servicios y configuraciones (stack) de tu servidor de forma local con fines de prueba es increíblemente valioso tanto para aplicaciones grandes como pequeñas en el lado del servidor. Además, los conceptos descritos en esta guía se aplican en líneas generales a todos los despliegues de Docker.

## Configuración

Deberás configurar tu entorno de desarrollador para ejecutar Docker y obtener una comprensión básica de los archivos de recursos que configuran el stack de Docker.

### Instalar Docker

Deberás instalar Docker para tu entorno de desarrollador. Puedes encontrar información para cualquier plataforma en la sección [Plataformas compatibles](https://docs.docker.com/install/#supported-platforms) de la descripción general de Docker Engine. Si estás en Mac OS, puedes ir directamente a la página de instalación [Docker para Mac](https://docs.docker.com/docker-for-mac/install/).

### Generar una Plantilla

Sugerimos utilizar la plantilla de Vapor como punto de partida. Si ya tienes una aplicación, crea la plantilla como se describe a continuación en una carpeta nueva, como punto de referencia, mientras dockerizas tu aplicación existente -puedes copiar recursos clave de la plantilla a tu aplicación y modificarlos ligeramente como punto de partida-.

1. Instala o crea Vapor Toolbox ([macOS](../install/macos.md#install-toolbox), [Linux](../install/linux.md#install-toolbox)).
2. Crea una nueva aplicación Vapor con `vapor new my-dockerized-app` y sigue las indicaciones para habilitar o deshabilitar funciones relevantes. Tus respuestas a estas preguntas afectarán la forma en que se generan los archivos de recursos de Docker.

## Recursos de Docker

Vale la pena, ya sea ahora o en un futuro próximo, familiarizarse con la [Descripción general de Docker](https://docs.docker.com/engine/docker-overview/). La descripción general explicará algunos términos clave que se utilizan en esta guía.

La plantilla Vapor App tiene dos recursos clave específicos de Docker: un archivo **Dockerfile** y un archivo **docker-compose**.

### Archivo Docker

Un Dockerfile le dice a Docker cómo construir una imagen de tu aplicación dockerizada. Esa imagen contiene tanto el ejecutable de tu aplicación como todas las dependencias necesarias para ejecutarla. Vale la pena mantener abierta la [referencia completa](https://docs.docker.com/engine/reference/builder/) cuando trabajes en la personalización de tu Dockerfile.

El Dockerfile generado para tu aplicación Vapor tiene dos etapas. La primera etapa contruye tu aplicación y configura un área de espera que contiene el resultado. La segunda etapa configura los conceptos básicos de un entorno de ejecución seguro, transfiere todo lo que está en el área de espera al lugar donde se ubicará en la imagen final y establece un punto de entrada predeterminado y un comando que ejecutará tu aplicación en modo de producción en el puerto predeterminado (8080). Esta configuración se puede reemplazar cuando se utiliza la imagen.

### Archivo Docker Compose

Un archivo Docker Compose define la forma en que Docker debe construir múltiples servicios relacionados entre sí. El archivo Docker Compose, en la plantilla de la aplicación Vapor, proporciona la funcionalidad necesaria para desplegar tu aplicación, pero si deseas obtener más información, debes consultar la [referencia completa](https://docs.docker.com/compose/compose-file/) que tiene detalles sobre todas las opciones disponibles.

!!! note "Nota"
    Si finalmente planeas usar Kubernetes para organizar tu aplicación, el archivo Docker Compose no es directamente relevante. Sin embargo, los archivos de manifiesto de Kubernetes son conceptualmente similares e incluso existen proyectos destinados a [portar archivos Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) a manifiestos de Kubernetes.

El archivo Docker Compose en tu nueva aplicación Vapor definirá los servicios para ejecutar tu aplicación, ejecutar migraciones o revertirlas, y ejecutar una base de datos como capa de persistencia de tu aplicación. Las definiciones exactas variarán según la base de datos que hayas elegido usar cuando ejecutaste `vapor new`.

Ten en cuenta que tu archivo Docker Compose tiene algunas variables de entorno compartidas cerca de la parte superior. (Puedes tener un conjunto diferente de variables predeterminadas dependiendo de si estás usando Fluent o no, y qué controlador de Fluent está en uso si lo estás usando).

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

A continuación, verás cómo estas variables se integran en múltiples servicios con la sintaxis de referencia YAML `<<: *shared_environment`.

Las variables `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` y `DATABASE_PASSWORD` están codificadas de forma específica en este ejemplo, mientras que `LOG_LEVEL` tomará su valor del entorno que ejecuta el servicio o recurrirá a `'debug'` si la variable no está configurada.

!!! note "Nota"
    Codificar de forma específica el nombre de usuario y la contraseña es aceptable para el desarrollo local, pero debes almacenar estas variables en un archivo de secretos para el despliegue en producción. Una forma de manejar esto en producción es exportar el archivo de secretos al entorno que ejecuta tu despliegue y usar líneas como las siguientes en tu archivo Docker Compose:

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Esto pasa la variable de entorno a los contenedores según lo definido por el host.

Otras cosas a tener en cuenta:

- Las dependencias de los servicios se definen mediante un arreglo `depends_on`.
- Los puertos de los servicios se exponen al sistema que ejecuta los servicios con matrices `ports` (formateadas como `<host_port>:<service_port>`).
- El `DATABASE_HOST` se define como `db`. Esto significa que tu aplicación accederá a la base de datos en `http://db:5432`. Esto funciona porque Docker va a crear una red que utiliza tus servicios, y el DNS interno de esa red enrutará el nombre `db` al servicio llamado `'db'`.
- La directiva `CMD` en el Dockerfile se reemplaza en algunos servicios con la matriz `command`. Ten en cuenta que lo que se especifica con `command` se ejecuta contra el `ENTRYPOINT` en el Dockerfile.
- En el modo Swarm (más sobre esto a continuación), los servicios recibirán 1 instancia de manera predeterminada, pero los servicios `migrate` y `revert` están definidos con `deploy` `replicas: 0`, por lo que no se inician de manera predeterminada cuando se ejecuta un Swarn.

## Construyendo

El archivo Docker Compose le dice a Docker cómo construir tu aplicación (usando el Dockerfile en el directorio actual) y cómo nombrar la imagen resultante (`my-dockerized-app:latest`). Este último es en realidad la combinación de un nombre (`my-dockerized-app`) y una etiqueta (`latest`) donde las etiquetas se usan para versionar las imágenes de Docker.

Para construir una imagen de Docker para tu aplicación, ejecuta

```shell
docker compose build
```

desde el directorio raíz del proyecto de tu aplicación (la carpeta que contiene `docker-compose.yml`).

Verás que tu aplicación y sus dependencias deben construirse nuevamente incluso si las habías construido previamente en tu máquina de desarrollo. Se están construyendo en el entorno de construcción Linux que utiliza Docker, por lo que los artefactos de construcción de tu máquina de desarrollo no son reutilizables.

Cuando hayas terminado, encontrarás la imagen de tu aplicación cuando ejecutes

```shell
docker image ls
```

## En Ejecución

Tu stack de servicios se puede ejecutar directamente desde el archivo Docker Compose o puedes usar una capa de orquestación como el modo Swarm o Kubernetes.

### Standalone

La forma más sencilla de ejecutar tu aplicación es iniciarla como un contenedor independiente (Standalone). Docker utilizará las matrices `depends_on` para asegurarse de que también se inicien los servicios dependientes.

Primero, ejecute:

```shell
docker compose up app
```

y observa que se inician los servicios `app` y `db`.

Tu aplicación está escuchando en el puerto 8080 y, según lo definido por el archivo Docker Compose, se puede acceder a ella en tu máquina de desarrollo en **http://localhost:8080**.

Esta distinción en el mapeo de puertos es muy importante porque puede ejecutar cualquier cantidad de servicios en los mismos puertos si todos se ejecutan en sus propios contenedores y cada uno expone puertos diferentes a la máquina host.

Visita `http://localhost:8080` y verás `It works!`, pero visita `http://localhost:8080/todos` y obtendrás:

```
{"error":true,"reason":"Something went wrong."}
```

Echa un vistazo a la salida de registros en la terminal donde ejecutaste `docker compose up app` y verás:

```
[ ERROR ] relation "todos" does not exist
```

¡Por supuesto! Necesitamos ejecutar migraciones en la base de datos. Presiona `Ctrl+C` para cerrar tu aplicación. Vamos a iniciar la aplicación nuevamente pero esta vez con:

```shell
docker compose up --detach app
```

Ahora tu aplicación se iniciará "desconectada" o "detached" (en segundo plano). Puedes verificar esto ejecutando:

```shell
docker container ls
```

donde verás tanto la base de datos como tu aplicación ejecutándose en contenedores. Incluso puedes verificar los registros ejecutando:

```shell
docker logs <container_id>
```

Para ejecutar migraciones, ejecuta:

```shell
docker compose run migrate
```

Después de ejecutar las migraciones, puedes visitar `http://localhost:8080/todos` nuevamente y obtendrás una lista vacía de todos en lugar de un mensaje de error.

#### Niveles de Registro (Log)

Recuerda que, anteriormente, la variable de entorno `LOG_LEVEL` en el archivo Docker Compose heredará del entorno donde se inició el servicio, si está disponible.

Puedes activar tus servicios con

```shell
LOG_LEVEL=trace docker-compose up app
```

para obtener el registro (el más granular) a nivel de `trace`. Puedes utilizar esta variable de entorno para configurar el registro en [cualquier nivel disponible](../basics/logging.md#levels).

#### Todos los Registros de Servicio

Si especificas explícitamente tu servicio de base de datos cuando activas los contenedores, verás registros tanto para tu base de datos como para tu aplicación.

```shell
docker-compose up app db
```

#### Desactivar Contenedores Independientes

Ahora que tienes contenedores ejecutándose "desconectados" de tu host shell, debes decirles que se apaguen de alguna manera. Vale la pena saber que a cualquier contenedor en ejecución se le puede pedir que se apague con

```shell
docker container stop <container_id>
```

pero la forma más fácil de desactivar estos contenedores en particular es

```shell
docker-compose down
```

#### Limpiando la base de datos

El archivo Docker Compose define un volumen `db_data` para conservar tu base de datos entre ejecuciones. Hay un par de formas de restablecer tu base de datos.

Puedes eliminar el volumen `db_data` al mismo tiempo que desactivas tus contenedores con

```shell
docker-compose down --volumes
```

Puedes ver los volúmenes que actualmente conservan datos con `docker volume ls`. Ten en cuenta que el nombre del volumen generalmente tendrá un prefijo de `my-dockerized-app_` o `test_` dependiendo de si estaba ejecutando en el modo Swarm o no.

Por ejemplo, puedes eliminar estos volúmenes de uno en uno

```shell
docker volume rm my-dockerized-app_db_data
```

También puedes limpiar todos los volúmenes con

```shell
docker volume prune
```

¡Ten cuidado de no eliminar accidentalmente un volumen con datos que deseas conservar!

Docker no te permitirá eliminar volúmenes que estén en uso actualmente por contenedores en ejecución o detenidos. Puedes obtener una lista de contenedores en ejecución con `docker container ls` y también puedes ver los contenedores detenidos con `docker container ls -a`.

### Modo Swarm

El modo Swarm es una interfaz fácil de usar cuando tienes un archivo Docker Compose a mano y quieres probar cómo tu aplicación escala horizontalmente. Puedes leer todo sobre el modo Swarm en las páginas ubicadas en [descripción general](https://docs.docker.com/engine/swarm/).

Lo primero que necesitamos es un nodo administrador para nuestro Swarm. Ejecuta

```shell
docker swarm init
```

A continuación usaremos nuestro archivo Docker Compose para abrir un stack llamado `'test'` que contiene nuestros servicios.

```shell
docker stack deploy -c docker-compose.yml test
```

Podemos ver cómo van nuestros servicios con

```shell
docker service ls
```

Deberías esperar ver réplicas `1/1` para tus servicios `app` y `db` y réplicas `0/0` para tus servicios `migrate` y `revert`.

Necesitamos usar un comando diferente para ejecutar migraciones en el modo Swarm.

```shell
docker service scale --detach test_migrate=1
```

!!! note "Nota"
    Acabamos de solicitar a un servicio de corta duración que se escale a 1 réplica. Se escalará, se ejecutará y luego saldrá correctamente. Sin embargo, eso lo dejará con `0/1` réplicas ejecutándose. Esto no es gran problema hasta que queramos ejecutar las migraciones nuevamente, pero no podemos decirle que "escale hasta 1 réplica" si ya es así. Una peculiaridad de esta configuración es que la próxima vez que queramos ejecutar migraciones dentro del mismo tiempo de ejecución de Swarm, primero debemos reducir el servicio a `0` y luego volver a subirlo a `1`.

La recompensa por nuestro problema en el contexto de esta breve guía es que ahora podemos escalar nuestra aplicación a lo que queramos para probar qué tan bien maneja la contención de la base de datos, los fallos y más.

Si deseas ejecutar 5 instancias de tu aplicación simultáneamente, ejecuta

```shell
docker service scale test_app=5
```

Además de ver cómo Docker amplía tu aplicación, puedes ver que se están ejecutando 5 réplicas al verificar nuevamente `docker service ls`.

Puedes ver (y seguir) los registros de tu aplicación con

```shell
docker service logs -f test_app
```

#### Desactivando los servicios de Swarn

Cuando desees desactivar tus servicios en el modo Swarm, hazlo eliminando el stack que creaste anteriormente.

```shell
docker stack rm test
```

## Despliegues de producción

Como se indicó al principio, esta guía no entrará en muchos detalles sobre el despliegue de tu aplicación dockerizada en producción porque el tema es amplio y varía mucho según el servicio de alojamiento (AWS, Azure, etc.), las herramientas (Terraform, Ansible, etc.), y la orquestación (Docker Swarm, Kubernetes, etc.).

Sin embargo, las técnicas que aprendes para ejecutar tu aplicación dockerizada localmente en tu máquina de desarrollo son en gran medida transferibles a entornos de producción. Una instancia de servidor configurada para ejecutar el demonio docker aceptará los mismos comandos.

Copia los archivos de tu proyecto a tu servidor, utiliza SSH en el servidor y ejecuta un comando `docker-compose` o `docker stack deploy` para que todo se ejecute de forma remota.

Alternativamente, configura tu variable de entorno local `DOCKER_HOST` para que apunte a tu servidor y ejecute los comandos `docker` localmente en tu máquina. Es importante tener en cuenta que, con este enfoque, no necesitas copiar ninguno de los archivos de tu proyecto al servidor, pero sí debes alojar la imagen docker en algún lugar desde donde el servidor pueda obtenerla.
