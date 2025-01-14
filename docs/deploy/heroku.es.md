# ¿Qué es Heroku?

Heroku es una solución de alojamiento todo en uno muy popular. Puedes encontrar más información en [heroku.com](https://www.heroku.com)

## Registrarse

Necesitarás una cuenta de Heroku. Si no tienes una, regístrate aquí: [https://signup.heroku.com/](https://signup.heroku.com/)

## Instalar CLI

Asegúrate de haber instalado la herramienta CLI de Heroku.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Otras Opciones de Instalación

Consulta las opciones de instalación alternativas aquí: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Iniciar sesión

Una vez que hayas instalado la CLI, inicia sesión con el siguiente comando:

```bash
heroku login
```

Verifica que el correo electrónico correcto esté conectado con:

```bash
heroku auth:whoami
```

### Crear una aplicación

Visita dashboard.heroku.com para acceder a tu cuenta, y crea una aplicación nueva desde el menú desplegable en la esquina superior derecha. Heroku te hará algunas preguntas, como la región y el nombre de la aplicación, tan solo sigue las indicaciones.

### Git

Heroku usa Git para desplegar tu aplicación, por lo que deberás colocar tu proyecto en un repositorio de Git, si aún no lo está.

#### Inicializar Git

Si necesitas agregar Git a tu proyecto, ingresa el siguiente comando en Terminal:

```bash
git init
```

#### Master

Debes decidirte por una rama y ceñirte a ella para desplegar en Heroku, como la rama **main** o **master**. Asegúrate de que todos los cambios se hayan registrado en esta rama antes de hacer push.

Comprueba tu rama actual con:

```bash
git branch
```

El asterisco indica la rama actual.

```bash
* main
  commander
  other-branches
```

!!! note "Nota"
    Si no ves ningún resultado y acabas de ejecutar `git init`, primero deberás hacer un commit de tu código y luego verás el resultado del comando `git branch`.

Si actualmente no estás en la rama correcta, cambia a ella escribiendo (para el caso de **main**):

```bash
git checkout main
```

#### Commit de cambios

Si este comando produce resultados, entonces tienes cambios sin confirmar.

```bash
git status --porcelain
```

Confirmalos con lo siguiente

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Conectar con Heroku

Conecta tu aplicación con heroku (reemplaza con el nombre de tu aplicación).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Establecer Buildpack

Establece el buildpack para enseñar a heroku cómo tratar con vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Archivo de versión de Swift

El buildpack que agregamos busca un archivo **.swift-version** para saber qué versión de Swift usar. (Reemplace 5.8.1 con la versión que requiera su proyecto).

```bash
echo "5.8.1" > .swift-version
```

Esto crea **.swift-version** con `5.8.1` como su contenido.

### Procfile

Heroku usa el **Procfile** para saber cómo ejecutar tu aplicación, en nuestro caso debe verse así:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Podemos crear esto con el siguiente comando de terminal

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Confirmar cambios

Acabamos de agregar estos archivos, pero no están confirmados. Si hacemos push, heroku no los encontrará.

Confírmarlos con lo siguiente.

```bash
git add .
git commit -m "adding heroku build files"
```

### Despliegue en Heroku

Estás listo para desplegar, ejecuta esto desde la terminal. Puede que la compilación tarde un poco de tiempo, esto es normal.

```bash
git push heroku main
```

### Escalabilidad

Una vez que hayas construido con éxito, debes agregar al menos un servidor. Los precios comienzan en $5/mes para el plan Eco (consulta [precios](https://www.heroku.com/pricing#containers)), asegúrate de tener configurado el pago en Heroku. Luego, para un solo trabajador web:

```bash
heroku ps:scale web=1
```

### Despliegue continuo

Cada vez que quieras actualizar, solo tienes que obtener los últimos cambios en main y enviarlos a heroku y se volverá a desplegar.

## Postgres

### Agregar base de datos PostgreSQL

Visita tu aplicación en dashboard.heroku.com y ve a la sección **Add-ons**.

Desde aquí entra en `postgres` y verás una opción para `Heroku Postgres`. Selecciónala.

Elige el plan Eco por $5/mes (consulta [precios](https://www.heroku.com/pricing#data-services)) y realiza la instalación. Heroku hará el resto.

Una vez que termines, verás que la base de datos aparece en la pestaña **Resources**.

### Configura la base de datos

Ahora tenemos que indicarle a nuestra aplicación cómo acceder a la base de datos. En el directorio de nuestra aplicación, ejecutémosla.

```bash
heroku config
```

Esto generará una salida similar a esta

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

Aquí **DATABASE_URL** representará nuestra base de datos postgres. **NUNCA** codifiques de manera estática la URL desde aquí, heroku la rotará y romperá tu aplicación. Además, es una mala práctica. En su lugar, lee la variable de entorno en tiempo de ejecución.

El complemento Heroku Postgres [requiere](https://devcenter.heroku.com/changelog-items/2035) que todas las conexiones sean cifradas. Los certificados que utilizan los servidores Postgres son internos a Heroku, por lo que se debe configurar una conexión TLS **no verificada**.

El siguiente fragmento muestra cómo lograr ambas cosas:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```
No olvide confirmar estos cambios

```none
git add .
git commit -m "configured heroku database"
```

### Revertir tu base de datos

Puedes revertir o ejecutar otros comandos en heroku con el comando `run`.

Para revertir tu base de datos:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Para migrar:

```bash
heroku run App -- migrate --env production
```
