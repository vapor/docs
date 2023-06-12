# Routing

El enrutamiento (o routing) consiste en encontrar el controlador apropiado para una petición entrante. El núcleo del routing de Vapor lo compone el router de tres nodos de alto rendimiento de [RoutingKit](https://github.com/vapor/routing-kit).

## Presentación 

Para comprender cómo funciona routing en Vapor, primero debes comprender algunos conceptos básicos sobre las peticiones HTTP (requests). Eche un vistazo a la siguiente petición de ejemplo.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Esta es una simple petición HTTP `GET` a la URL `/hello/vapor`. Este es el tipo de petición HTTP que haría tu navegador si apuntara a la siguiente URL.

```
http://vapor.codes/hello/vapor
```

### Métodos HTTP

La primera parte de la petición es el método de HTTP. `GET` es el método más común de HTTP, pero hay varios que usarás con frecuencia. Estos métodos HTTP a menudo se asocian con la semántica [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Método|CRUD|
|-|-|
|`GET`|Leer|
|`POST`|Crear|
|`PUT`|Reemplazar|
|`PATCH`|Actualizar|
|`DELETE`|Borrar|

### Ruta de Petición (Path)

Justo después del método HTTP está la URI (identificador de recursos uniforme) de la petición. Consiste en una ruta que comienza en `/` y una cadena de consulta opcional detrás de `?`. El método HTTP y la ruta son los que usa Vapor para enrutar las peticiones.

Después de la URI está la versión HTTP seguida de cero o más encabezados (headers) y finalmente el cuerpo de la respuesta (body). Dado que se trata de una petición `GET`, no hay cuerpo.

### Métodos de Router

Echemos un vistazo a cómo se podría manejar esta petición en Vapor.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

Todos los métodos comunes de HTTP están disponibles como métodos en `Application`. Aceptan uno o más argumentos de cadena que representan la ruta de la petición separados por `/`. 

Ten en cuenta que también podrías escribirlo usando `on` seguido del método.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Con esta ruta registrada, la petición HTTP de ejemplo anterior dará como resultado la siguiente respuesta HTTP.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Parámetros de Ruta

Ahora que hemos creado una petición de ruta con éxito basada en el método y ruta HTTP, intentemos hacer que la ruta sea dinámica. Ten en cuenta que el nombre "vapor" está codificado tanto en la ruta como en la respuesta. Hagámosla dinámica para que puedas visitar `/hello/<cualquier nombre>` y obtener una respuesta.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Al usar un componente de ruta con el prefijo `:`, le indicamos al router que se trata de un componente dinámico. Cualquier cadena suministrada aquí ahora coincidirá con esta ruta. Luego podemos usar `req.parameters` para acceder al valor de la cadena.

Si vuelves a ejecutar la petición de ejemplo, seguirás recibiendo una respuesta que saluda a vapor. Sin embargo, ahora puedes incluir cualquier nombre luego de `/hello/` y verlo incluido en la respuesta. Probemos `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Ahora que comprendemos los conceptos básicos, consultemos cada sección para obtener más información sobre parámetros, grupos y más.

## Rutas

Una ruta especifica un controlador de peticiones para un método HTTP y una ruta URI determinados. También puede almacenar metadatos adicionales.

### Métodos

Las rutas se pueden registrar directamente en tu `Application` utilizando varios métodos auxiliares de HTTP.

```swift
// responde a GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

Las estructuras de ruta admiten el retorno de cualquier cosa que sea `ResponseEncodable`. Esto incluye `Content`, un closure `async`, y cualquier `EventLoopFuture` donde su valor future sea `ResponseEncodable`.

Puedes especificar el tipo de retorno de una ruta usando `-> T` antes de `in`. Esto puede ser útil en situaciones en las que el compilador no puede determinar el tipo de retorno.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

Estos son los métodos de ruta auxiliares soportados:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Además de los métodos auxiliares de HTTP, existe una función `on` que acepta el método HTTP como un parámetro de entrada.

```swift
// responde a OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Componente de Ruta

Cada método de registro de ruta acepta una lista variádica de `PathComponent`. Este tipo es expresable por un string literal y consta de cuatro casos:

- Constante (`foo`)
- Parámetro (`:foo`)
- Cualquier cosa (`*`)
- Comodín (`**`)

#### Constante

Este es un componente de ruta estático. Solo permitirá peticiones con una cadena que coincida exactamente en valor y posición con la especificada en la ruta.

```swift
// responde a GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parámetro

Este es un componente de ruta dinámico. Se permitirá cualquier cadena en esta posición. Un componente de ruta de parámetro se especifica con el prefijo `:`. La cadena que sigue a `:` será el nombre del parámetro, el cual podrás usar para obtener su valor en la petición.

```swift
// responde a GET /foo/bar/baz
// responde a GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Cualquier cosa

Este es muy similar a parámetro, excepto que el valor se descarta. Este componente de ruta es especificado simplemente con un `*`.

```swift
// responde a GET /foo/bar/baz
// responde a GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Comodín

Este es un componente de ruta dinámico que coincide con uno o más componentes. Se especifica usando simplemente `**`. Cualquier cadena en esta posición o en posiciones posteriores coincidirá con la petición.

```swift
// responde a GET /foo/bar
// responde a GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Parámetros

Cuando se utiliza un componente de ruta de parámetro (con el prefijo `:`), el valor de la URI en esa posición se almacenará en `req.parameters`. Puedes utilizar el nombre del componente de ruta para acceder al valor.

```swift
// responde a GET /hello/foo
// responde a GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip "Consejo"
    Podemos estar seguros de que `req.parameters.get` nunca devolverá `nil` ya que nuestra ruta incluye `:name`. Sin embargo, si se está accediendo a parámetros de ruta en un middleware o en código activado por múltiples rutas, deberías manejar la posibilidad de un `nil`.

!!! tip "Consejo"
    Si deseas recuperar parámetros de consulta de URL (por ejemplo `/hello/?name=foo`), necesitas usar la API Content de Vapor para manejar los datos codificados del string de la URL. Consulta la referencia de [`Content`](content.md) para más detalles.

`req.parameters.get` también soporta convertir el parámetro a los tipos `LosslessStringConvertible` automáticamente.

```swift
// responde a GET /number/42
// responde a GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

Los valores de URI que coincidan con un Comodín (`**`) se guardarán en `req.parameters` como `[String]`. Puedes usar `req.parameters.getCatchall` para acceder a estos componentes.

```swift
// responde a GET /hello/foo
// responde a GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Transmisión de Body

Al registrar una ruta utilizando el método `on`, puedes especificar cómo se debe manejar la petición de Body (el cuerpo de la respuesta). Por defecto, los cuerpos de las peticiones se recopilan en memoria antes de llamar a su controlador correspondiente. Esto es útil ya que permite que la decodificación del contenido sea síncrona aunque su aplicación lea las peticiones entrantes de forma asíncrona.

Por defecto. Vapor limitará la recopilación de la transmisión del Body a un tamaño de 16KB. Puedes configurar esto usando `app.routes`.

```swift
// Aumenta el límite de recopilación de la transmisión de Body hasta 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Si una transmisión de Body que se está recopilando excede el límite configurado, se lanzará un error `413 Payload Too Large`.

Para configurar la estrategia de recopilación de Body en una ruta individual, usa el parámetro `body`.

```swift
// Recopila la transmisión de Body (hasta 1mb de tamaño) antes de llamar a esta ruta.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Administra la petición. 
}
```

Si se proporciona el `maxSize` (tamaño máximo) al realizar el `collect` (la recopilación), se sobrescribirá el valor predeterminado de la aplicación para esa ruta. Para utilizar el valor por defecto de la aplicación, omita el argumento `maxSize`.

Para peticiones grandes, como subida de archivos, recopilar el Body en un búfer puede sobrecargar la memoria del sistema. Para evitar que se recopile el Body de la petición, usa la estrategia `stream`.

```swift
// El cuerpo de la petición no se recopilará en un búfer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Cuando se transmite el cuerpo de la petición, `req.body.data` será `nil`. Debes usar `req.body.drain` para manejar cada fragmento a medida que se envía a tu ruta.

### Rutas Case Insensitive

El comportamiento por defecto para las rutas distingue (case-sensitive) y preserva (case-preserving) entre mayúsculas y minúsculas. Los componentes de ruta constantes (`Constant`) pueden manejarse alternativamente sin distinguir ni preservar entre mayúsculas y minúsculas a efectos de cada ruta; para habilitar este comportamiento, configura lo siguiente antes del inicio de la aplicación:

```swift
app.routes.caseInsensitive = true
```

No se realizarán cambios en la petición de origen; las rutas recibirán los componentes sin ninguna modificación.

### Visualizando Rutas

Puedes acceder a las rutas de tu aplicación creando el servicio `Routes` o utilizando `app.routes`.

```swift
print(app.routes.all) // [Route]
```

Vapor también posee el comando `routes` que imprime todas las rutas disponibles en una tabla con formato ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Metadata

Todos los registro de métodos de rutas retornan la ruta creada (`Route`). Esto te permite agregar metadatos al diccionario `userInfo` de la ruta. Hay algunos métodos predeterminados disponibles, como agregar una descripción a la ruta.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Grupos de Ruta

La agrupación de rutas permite crear un conjunto de rutas con un prefijo o un middleware específico. La agrupación admite una sintaxis basada en builders y closures.

Todos los métodos de agrupación devuelven un `RouteBuilder`, permitiendo mezclar, combinar y anidar infinitamente sus grupos con otros métodos de creación de rutas.

### Prefijo de Ruta

Los grupos de rutas con prefijo permiten anteponer uno o más componentes de ruta a un grupo de rutas.

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Cualquier componente de ruta que puedas pasar como `get` o `post` puede pasarse dentro de un `grouped`. También hay una sintaxis alternativa basada en closures.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

La anidación de grupos de rutas con prefijos te permite definir de manera concisa las APIs de un CRUD.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

Además de prefijar componentes de rutas, también puedes agregar un middleware a grupos de rutas.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```

Esto es especialmente útil para proteger subconjuntos de rutas con diferentes middleware de autenticación.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Redirecciones

Los redireccionamientos (redirect) son útiles en varios escenarios, como reenviar ubicaciones antiguas a nuevas para el SEO, redireccionar a un usuario no autenticado a la página de inicio de sesión o mantener la compatibilidad con versiones anteriores de su API.

Para redirigir una petición, utiliza:

```swift
req.redirect(to: "/some/new/path")
```

También puedes especificar el tipo de redirección, por ejemplo para redirigir una página de forma permanente (para que su SEO se actualice correctamente) usa:

```swift
req.redirect(to: "/some/new/path", type: .permanent)
```

Los diferentes `RedirectType` son:

* `.permanent` - devuelve una redirección **301 Moved Permanently**
* `.normal` - devuelve una redirección **303 See Other**. Este es el valor por defecto de Vapor y le dice al cliente que siga la redirección con una petición **GET**.
* `.temporary` - devuelve una redirección **307 Temporary Redirect**. Esto le dice al cliente que conserve el método HTTP utilizado en la petición.

> Para elegir el código de estado de redirección adecuado, consulte [la lista completa](https://es.wikipedia.org/wiki/Anexo:Códigos_de_estado_HTTP#3xx:_Redirecciones)
