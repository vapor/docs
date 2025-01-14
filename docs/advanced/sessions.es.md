# Sesiones

Las sesiones te permiten conservar los datos de un usuario entre varias solicitudes. Las sesiones funcionan creando y devolviendo una cookie única junto con la respuesta HTTP cuando se inicializa una nueva sesión. Los navegadores detectarán automáticamente esta cookie y la incluirán en futuras solicitudes. Esto permite que Vapor restaure automáticamente la sesión de un usuario específico en su controlador de solicitudes.

Las sesiones son ideales para aplicaciones web front-end creadas en Vapor que sirven HTML directamente a los navegadores web. Para APIs, recomendamos usar autenticación sin estado, [autenticación basada en tokens](../security/authentication.md) para persistir los datos del usuario entre solicitudes.

## Configuración

Para usar sesiones en una ruta, la solicitud debe pasar por `SessionsMiddleware`. La forma más fácil de lograr esto es agregando este middleware globalmente. Se recomienda que lo agregues después de declarar la fábrica de cookies. Esto se debe a que Sessions es una estructura, por lo tanto, es un tipo por valor y no un tipo por referencia. Dado que es un tipo por valor, debes establecer el valor antes de usar `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Si solo un subconjunto de tus rutas utiliza sesiones, puedes añadir `SessionsMiddleware` a un grupo de rutas.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

La cookie HTTP generada por las sesiones se puede configurar usando `app.sessions.configuration`. Puedes cambiar el nombre de la cookie y declarar una función personalizada para generar valores de las cookies.

```swift
// Cambia el nombre de la cookie a "foo".
app.sessions.configuration.cookieName = "foo"

// Configura la creación del valor de la cookie.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

De manera predeterminada, Vapor usará `vapor_session` como nombre de la cookie.

## Controladores

Los controladores de sesión son responsables de almacenar y recuperar datos de sesión por identificador. Puedes crear controladores personalizados conformando al protocolo `SessionDriver`.

!!! warning "Advertencia"
    El controlador de sesión debe configurarse _antes_ de añadir `app.sessions.middleware` a tu aplicación.
    
### En Memoria

Vapor utiliza sesiones en memoria por defecto. Las sesiones en memoria no requieren ninguna configuración y no persisten entre lanzamientos de la aplicación, lo que las hace ideales para realizar pruebas. Para habilitar en memoria las sesiones de forma manual, usa `.memory`:

```swift
app.sessions.use(.memory)
```

Para casos de uso en producción, echa un vistazo a los otros controladores de sesión que utilizan bases de datos para persistir y compartir sesiones a través de múltiples instancias de tu aplicación.

### Fluent

Fluent incluye soporte para almacenar datos de sesión en la base de datos de tu aplicación. Esta sección supone que has [configurado Fluent](../fluent/overview.md) y puedes conectarte a una base de datos. El primer paso es habilitar el controlador de sesiones de Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Esto configurará las sesiones para usar la base de datos por defecto de la aplicación. Para especificar una base de datos específica, pasa el identificador de la base de datos.

```swift
app.sessions.use(.fluent(.sqlite))
```

Por último, añade la migración de `SessionRecord` a las migraciones de tu base de datos. Esto preparará tu base de datos para almacenar datos de sesión en el esquema `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Asegúrate de ejecutar las migraciones de tu aplicación después de añadir la nueva migración. Las sesiones ahora se almacenarán en la base de datos de tu aplicación, permitiendo que se persistan entre reinicios y sean compartidas entre varias instancias de tu aplicación.

### Redis

Redis proporciona soporte para almacenar datos de sesión en tu instancia Redis configurada. Esta sección supone que has [configurado Redis](../redis/overview.md) y puedes enviar comandos a la instancia Redis.

Para usar Redis para sesiones, selecciónalo al configurar tu aplicación:

```swift
import Redis

app.sessions.use(.redis)
```

Esto configurará las sesiones para usar el controlador de sesiones Redis con el comportamiento por defecto.

!!! seealso "Ver también"
    Consulte [Redis &rarr; Sessions](../redis/sessions.md) para obtener información más detallada sobre Redis y Sessions.
    
## Datos de Sesión

Ahora que las sesiones están configuradas, estás listo para persistir datos entre solicitudes. Las nuevas sesiones se inicializan automáticamente cuando se añaden datos a `req.session`. A continuación, el controlador de ruta de ejemplo acepta un parámetro de ruta dinámica y agrega el valor a `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Utiliza la siguiente solicitud para inicializar una sesión con el nombre Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Deberías recibir una respuesta similar a la siguiente:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Observa que la cabecera `set-cookie` se ha añadido automáticamente a la respuesta después de añadir datos a `req.session`. Incluir esta cookie en solicitudes posteriores permitirá acceder a los datos de la sesión.

Añade el siguiente controlador de ruta para acceder al valor del nombre desde la sesión.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Utiliza la siguiente solicitud para acceder a esta ruta asegurándote de pasar el valor de la cookie de la respuesta anterior.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Deberías ver el nombre Vapor devuelto en la respuesta. Puedes añadir o eliminar datos de la sesión como creas conveniente. Los datos de la sesión se sincronizarán con el controlador de sesión automáticamente antes de devolver la respuesta HTTP.

Para finalizar una sesión, utiliza `req.session.destroy`. Esto eliminará los datos del controlador de sesión e invalidará la cookie de sesión.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
