# Cliente

La API cliente de Vapor te permite hacer llamadas HTTP a recursos externos. Está hecha en [async-http-client](https://github.com/swift-server/async-http-client) y se integra con la API [content](content.md).

## Descripción

Puedes acceder al cliente por defecto mediante `Application`, o en un controlador de rutas mediante `Request`.

```swift
app.client // Cliente

app.get("test") { req in
	req.client // Cliente
}
```

El cliente de la aplicación es útil para realizar peticiones HTTP durante la configuración. Si realizas las peticiones HTTP en un controlador de rutas, usa siempre el cliente de la petición (request).

### Métodos

Para realizar una petición `GET`, proporciona la URL deseada al método de conveniencia `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Existen métodos para cada acción HTTP, como `get`, `post`, y `delete`. La respuesta del cliente es devuelta como un futuro y contiene el estado (status) HTTP, las cabeceras y el cuerpo de la petición.

### Content

La API [content](content.md) de Vapor está disponible para el manejo de datos en las peticiones y respuestas del cliente. Para codificar contenido, parámetros de petición o añadir cabeceras a la petición, usa el closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Codifica la cadena de consulta (query) a la petición URL.
	try req.query.encode(["q": "test"])

	// Codifica un JSON en el cuerpo de la petición.
    try req.content.encode(["hello": "world"])
    
    // Añade una cabecera de autenticación a la petición.
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Controla la respuesta.
```

También puedes decodificar el cuerpo de la respuesta usando `Content` de manera similar:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Si estás utilizando futuros, puedes usar `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Usa JSON aquí
}
```

## Configuración

Puedes configurar el cliente HTTP subyacente mediante la aplicación.

```swift
// Desactiva el seguimiento de redireccionado automático.
app.http.client.configuration.redirectConfiguration = .disallow
```

Ten en cuenta que debes configurar el cliente por defecto _antes_ de usarlo por primera vez.

