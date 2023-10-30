# *Routing* - Instradamento

Per *Routing*, in italiano *Instradamento*, si intende il procedimento che permette l'instradamento di una richiesta in arrivo verso la sua corretta gestione. La parte centrale del sistema di instradamento di Vapor è un router ad elevate prestazioni basato su [trie](https://it.wikipedia.org/wiki/Trie) presente in [RoutingKit](https://github.com/vapor/routing-kit).

## Panoramica

Per comprendere meglio l'instradamento in Vapor, è importante conoscere alcune informazioni basilari a proposito delle richieste HTTP.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Questa è una richiesta HTTP di tipo `GET` verso l'URL `/hello/vapor`. È un esempio di richiesta HTTP che il browser web invierebbe se si indicasse il seguente URL nella barra degli indirizzi.


```
http://vapor.codes/hello/vapor
```

### Metodi HTTP

La prima parte della richiesta è il metodo HTTP. `GET` è il metodo HTTP più comune, ma ne esistono altri che userai spesso. Questi metodi si ricollegano spesso alla semantica [CRUD](https://it.wikipedia.org/wiki/CRUD).

|Metodo|CRUD|Traduzione|
|-|-|-|
|`GET`|Read|Leggi|
|`POST`|Create|Crea|
|`PUT`|Replace|Sostituisci|
|`PATCH`|Update|Aggiorna|
|`DELETE`|Delete|Elimina|

### Persorso della richiesta

Subito dopo il metodo HTTP si trova l'URI della richiesta, che consiste di un percorso che inizia con `/` e una stringa di interrogazione dopo il carattere `?`. Il metodo HTTP e il percorso vengono usati da Vapor per instradare le richieste.

Dopo l'URI si trova la versione di HTTP seguita da nessuna, una o più intestazioni e infine un contenuto. In questo caso il contenuto è assente poiché si tratta di una richiesta `GET`.

### Metodi di instradamento

Guardiamo per esempio come Vapor potrebbe gestire questa richiesta.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

Tutti i metodi HTTP più frequentemente usati sono disponibili come metodi in `Application`. Essi accettano uno o più argomenti, in forma di Stringa, che rappresentano il percorso della richiesta e sono separati dal carattere `/`.

Da notare che potresti anche scrivere la stessa cosa usando `on` seguito dal metodo.

```swift
app.on(.GET, "hello", "vapor") { ... }
```
Con questo instradamento, la richiesta HTTP nell'esempio sopra darà come risultato la seguente risposta.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Parametri di instradamento

Adesso che abbiamo instradato con successo una richiesta basata su un metodo HTTP ed un percorso, proviamo a rendere variabile o dinamico il percorso. Notiamo che il nome "vapor" è fissato nel codice sia del percorso che della risposta. Rendiamolo variabile così che si possa visitare `/hello/<un nome qualunque>` ed ottenere una risposta.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Usando nel percorso un componente con prefisso `:`, indichiamo al router che questo è un componente variabile. Adesso qualunque stringa sarà accettata per seguire questo percorso. Quindi possiamo usare `req.parameters` per accedere al valore della stringa.

Se lanci di nuovo la richiesta di esempio, otterrai ancora una risposta che saluta vapor. Però adesso puoi anche includere qualunque nome dopo `/hello/` e vederlo incorporato nella risposta. Proviamo con `/hello/swift`.

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

Adesso che comprendi le basi, puoi sfogliare ogni sezione per imparare di più a proposito di parametri, gruppi e altro ancora.

## *Route* - Instradamento

Una *route* specifica un elemento che gestisce una richiesta per uno specifico metodo HTTP e un percorso URI. Può anche incorporare metadati aggiuntivi.

### Metodi

Le *Routes* possono essere registrate direttamente in `Application` utilizzando vari metodi HTTP predefiniti.

```swift
// risponde a GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

I metodi per gestire le *Routes* possono restituire in risultato qualunque cosa sia `ResponseEncodable`. Ciò include `Content`, una `async` *closure*, e qualunque `EventLoopFuture`s il cui valore promesso sarà `ResponseEncodable`.

You can specify the return type of a route using `-> T` before `in`. This can be useful in situations where the compiler cannot determine the return type.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

These are the supported route helper methods:

- `get`
- `post`
- `patch`
- `put`
- `delete`

In addition to the HTTP method helpers, there is an `on` function that accepts HTTP method as an input parameter. 

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Path Component

Each route registration method accepts a variadic list of `PathComponent`. This type is expressible by string literal and has four cases:

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`*`)
- Catchall (`**`)

#### Constant

This is a static route component. Only requests with an exactly matching string at this position will be permitted. 

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parameter

This is a dynamic route component. Any string at this position will be allowed. A parameter path component is specified with a `:` prefix. The string following the `:` will be used as the parameter's name. You can use the name to later fetch the parameters value from the request.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Anything

This is very similar to parameter except the value is discarded. This path component is specified as just `*`. 

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Catchall

This is a dynamic route component that matches one or more components. It is specified using just `**`. Any string at this position or later positions will be matched in the request. 

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Parameters

When using a parameter path component (prefixed with `:`), the value of the URI at that position will be stored in `req.parameters`. You can use the name of the path component to access the value. 

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    We can be sure that `req.parameters.get` will never return `nil` here since our route path includes `:name`. However, if you are accessing route parameters in middleware or in code triggered by multiple routes, you will want to handle the possibility of `nil`.

!!! tip
    If you want to retrieve URL query params, e.g. `/hello/?name=foo` you need to use Vapor's Content APIs to handle URL encoded data in the URL's query string. See [`Content` reference](content.md) for more details.

`req.parameters.get` also supports casting the parameter to `LosslessStringConvertible` types automatically. 

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

The values of the URI matched by Catchall (`**`) will be stored in `req.parameters` as `[String]`. You can use `req.parameters.getCatchall` to access those components. 

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

When registering a route using the `on` method, you can specify how the request body should be handled. By default, request bodies are collected into memory before calling your handler. This is useful since it allows for request content decoding to be synchronous even though your application reads incoming requests asynchronously. 

By default, Vapor will limit streaming body collection to 16KB in size. You can configure this using `app.routes`.

```swift
// Increases the streaming body collection limit to 500kb
app.routes.defaultMaxBodySize = "500kb"
```

If a streaming body being collected exceeds the configured limit, a `413 Payload Too Large` error will be thrown. 

To configure request body collection strategy for an individual route, use the `body` parameter.

```swift
// Collects streaming bodies (up to 1mb in size) before calling this route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request. 
}
```

If a `maxSize` is passed to `collect`, it will override the application's default for that route. To use the application's default, omit the `maxSize` argument. 

For large requests, like file uploads, collecting the request body in a buffer can potentially strain your system memory. To prevent the request body from being collected, use the `stream` strategy.

```swift
// Request body will not be collected into a buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

When the request body is streamed, `req.body.data` will be `nil`. You must use `req.body.drain` to handle each chunk as it is sent to your route.

### Case Insensitive Routing

Default behavior for routing is both case-sensitive and case-preserving. `Constant` path components can alternately be handled in a case-insensitive and case-preserving manner for the purposes of routing; to enable this behavior, configure prior to application startup:
```swift
app.routes.caseInsensitive = true
```
No changes are made to the originating request; route handlers will receive the request path components without modification.


### Viewing Routes

You can access your application's routes by making the `Routes` service or using `app.routes`. 

```swift
print(app.routes.all) // [Route]
```

Vapor also ships with a `routes` command that prints all available routes in an ASCII formatted table. 

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

All route registration methods return the created `Route`. This allows you to add metadata to the route's `userInfo` dictionary. There are some default methods available, like adding a description.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Route Groups

Route grouping allows you to create a set of routes with a path prefix or specific middleware. Grouping supports a builder and closure based syntax.

All grouping methods return a `RouteBuilder` meaning you can infinitely mix, match, and nest your groups with other route building methods.

### Path Prefix

Path prefixing route groups allow you to prepend one or more path components to a group of routes. 

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

Any path component you can pass into methods like `get` or `post` can be passed into `grouped`. There is an alternative, closure-based syntax as well.

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

Nesting path prefixing route groups allows you to concisely define CRUD APIs.

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

In addition to prefixing path components, you can also add middleware to route groups. 

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


This is especially useful for protecting subsets of your routes with different authentication middleware. 

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Redirections

Redirects are useful in a number of scenarios, such as forwarding old locations to new ones for SEO, redirecting an unauthenticated user to the login page or maintain backwards compatibility with the new version of your API.

To redirect a request, use:

```swift
req.redirect(to: "/some/new/path")
```

You can also specify the type of redirect, for example to redirect a page permanently (so that your SEO is updated correctly) use:

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

The different `Redirect`s are:

* `.permanent` - returns a **301 Permanent** redirect
* `.normal` - returns a **303 see other** redirect. This is the default by Vapor and tells the client to follow the redirect with a **GET** request.
* `.temporary` - returns a **307 Temporary** redirect. This tells the client to preserve the HTTP method used in the request.

> To choose the proper redirection status code check out [the full list](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
