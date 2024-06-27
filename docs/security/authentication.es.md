# Autenticación

La autenticación es el acto de verificar la identidad de un usuario. Esto se hace mediante la verificación de credenciales como un nombre de usuario y contraseña o un token único. La autenticación (a veces llamada auth/c) es distinta de la autorización (auth/z), que es el acto de verificar los permisos de un usuario previamente autenticado para realizar determinadas tareas.

## Introducción

La API de autenticación de Vapor brinda soporte para autenticar a un usuario a través de la cabecera `Authorization`, usando [Basic](https://tools.ietf.org/html/rfc7617) y [Bearer](https://tools.ietf.org/html/rfc6750). También admite la autenticación de un usuario a través de los datos decodificados de la API [Content](../basics/content.md).

La autenticación se implementa mediante la creación de un `Authenticator` que contiene la lógica de verificación. Se puede utilizar un autenticador para proteger grupos de rutas individuales o una aplicación completa. Los siguientes helpers de autenticación se encuentran en Vapor:

|Protocolo|Descripción|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Autenticador base capaz de crear un middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Autentica la cabecera de autorización Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Autentica la cabecera de autorización Bearer.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Autentica una carga útil de credenciales del cuerpo de la solicitud.|

Si la autenticación es exitosa, el autenticador agrega el usuario verificado a `req.auth`. Luego se puede acceder a este usuario utilizando `req.auth.get(_:)` en rutas protegidas por el autenticador. Si la autenticación falla, el usuario no se agrega a `req.auth` y cualquier intento de acceder fallará.

## Autentificable

Para utilizar la API de autenticación, primero necesitas un tipo de usuario que se ajuste a `Authenticatable`. Puede ser un `struct`, una `class` o incluso un `Model` de Fluent. Los siguientes ejemplos asumen el struct de `User` que tiene una sola propiedad: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Cada ejemplo a continuación utilizará una instancia de un autenticador que creamos. En estos ejemplos, lo hemos llamado `UserAuthenticator`.

### Ruta

Los autenticadores son middleware y pueden usarse para proteger rutas.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` se utiliza para buscar el `User` autenticado. Si la autenticación falla, este método generará un error y protegerá la ruta.

### Middleware de Guard

También puede utilizar `GuardMiddleware` en un grupo de rutas para asegurarse de que un usuario haya sido autenticado antes de llegar a su controlador de ruta.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

El middleware del autenticador no requiere autenticación para permitir la composición de los autenticadores. Lee más sobre [composición](#composición) a continuación.

## Basic

La autenticación Basic envía un nombre de usuario y contraseña en la cabecera `Authorization`. El nombre de usuario y la contraseña están concatenados con dos puntos (por ejemplo, `test:secret`), codificados en base 64 y con el prefijo `"Basic "`. La siguiente solicitud de ejemplo codifica el nombre de usuario `test` con la contraseña `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

La autenticación Basic generalmente se usa una vez para iniciar la sesión de un usuario y generar un token. Esto minimiza la frecuencia con la que se debe enviar la contraseña confidencial del usuario. Nunca deberías enviar autorización Basic utilizando texto sin formato o en una conexión TLS no verificada.

Para implementar la autenticación Basic en su aplicación, crea un nuevo autenticador que conforme a `BasicAuthenticator`. A continuación se muestra un ejemplo de autenticador codificado para verificar la solicitud anterior.

```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

Si estás utilizando `async`/`await`, puedes usar `AsyncBasicAuthenticator` en su lugar:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

If you add this authenticator to your app, and test the route defined above, you should see the name `"Vapor"` returned for a successful login. If the credentials are not correct, you should see a `401 Unauthorized` error.



Este protocolo requiere que implementes `authenticate(basic:for:)`, que se llamará cuando una solicitud entrante contenga la cabecera `Authorization: Basic...`. Se pasa al método una estructura `BasicAuthorization` que contiene el nombre de usuario y la contraseña.

En este autenticador de prueba, el nombre de usuario y la contraseña se prueban con valores codificados. En un autenticador real, puedes compararlo con una base de datos o una API externa. Es por eso que el método `authenticate` te permite devolver un futuro.

!!! tip "Consejo"
    Las contraseñas nunca deben almacenarse en una base de datos como texto sin formato. Utiliza siempre un hash de contraseña para comparar.

Si los parámetros de autenticación son correctos, en este caso coinciden con los valores codificados, se inicia sesión un `User` llamado Vapor. Si los parámetros de autenticación no coinciden, no se inicia sesión de usuario, lo que significa que la autenticación falló.

Si agregas este autenticador a tu aplicación y pruebas la ruta definida anteriormente, deberías ver el nombre `"Vapor"` devuelto para un inicio de sesión exitoso. Si las credenciales no son correctas, deberías ver un error `401 Unauthorized`.

## Bearer

La autenticación de Bearer envía un token en la cabecera `Authorization`. El token tiene el prefijo `"Bearer "`. La siguiente solicitud de ejemplo envía el token `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

La autenticación de Bearer se usa comúnmente para la autenticación de endpoints de API. El usuario normalmente solicita un token Bearer enviando credenciales como un nombre de usuario y contraseña a un endpoint de inicio de sesión. Este token puede durar minutos o días dependiendo de las necesidades de la aplicación.

Siempre que el token sea válido, el usuario puede usarlo en lugar de sus credenciales para autenticarse en una API. Si el token deja de ser válido, se puede generar uno nuevo utilizando el endpoint de inicio de sesión.

Para implementar la autenticación de Bearer en su aplicación, crea un nuevo autenticador que conforme con `BearerAuthenticator`. A continuación se muestra un ejemplo de autenticador codificado para verificar la solicitud anterior.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

Si estás utilizando `async`/`await`, puedes usar `AsyncBearerAuthenticator` en su lugar:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

Este protocolo requiere que implementes `authenticate(bearer:for:)`, que se llamará cuando una solicitud entrante contenga la cabecera `Authorization: Bearer...`. Se pasa al método una estructura `BearerAuthorization` que contiene el token.

En este autenticador de prueba, el token se prueba con un valor codificado. En un autenticador real, puedes verificar el token comparándolo con una base de datos o utilizando medidas criptográficas, como se hace con JWT. Es por eso que el método `authenticate` te permite devolver un futuro.

!!! tip "Consejo"
    Al implementar la verificación con tokens, es importante considerar la escalabilidad horizontal. Si su aplicación necesita manejar muchos usuarios simultáneamente, la autenticación puede ser un posible cuello de botella. Considere cómo su diseño se ampliará en varias instancias de su aplicación que se ejecutan a la vez.

Si los parámetros de autenticación son correctos, en este caso coinciden con el valor codificado, se inicia sesión un `User` llamado Vapor. Si los parámetros de autenticación no coinciden, no se inicia sesión de usuario, lo que significa que la autenticación falló.

Si agrega este autenticador a su aplicación y prueba la ruta definida anteriormente, debería ver el nombre `"Vapor"` devuelto para un inicio de sesión exitoso. Si las credenciales no son correctas, debería ver un error `401 Unauthorized`.

## Composición

Se pueden componer (combinar) varios autenticadores para crear una autenticación de endpoint más compleja. Dado que un middleware de autenticación no rechazará la solicitud si falla la autenticación, se puede encadenar más de uno de estos middleware. Los autenticadores se pueden componer de dos formas clave.

### Componiendo Métodos

El primer método de composición de autenticación consiste en encadenar más de un autenticador para el mismo tipo de usuario. Tomemos el siguiente ejemplo:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Haz algo con el usuario.
}
```

Este ejemplo asume dos autenticadores `UserPasswordAuthenticator` y `UserTokenAuthenticator` que autentican al `User`. Ambos autenticadores se agregan al grupo de rutas. Finalmente, se agrega `GuardMiddleware` después de los autenticadores para exigir que el `User` se haya autenticado correctamente.

Esta composición de autenticadores da como resultado una ruta a la que se puede acceder mediante contraseña o token. Esta ruta podría permitir a un usuario iniciar sesión y generar un token, y luego continuar usando ese token para generar nuevos tokens.

### Componiendo Usuarios

El segundo método de composición de autenticación consiste en encadenar autenticadores para diferentes tipos de usuarios. Tomemos el siguiente ejemplo:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Haz algo.
}
```

Este ejemplo asume dos autenticadores `AdminAuthenticator` y `UserAuthenticator` que autentican a `Admin` y `User`, respectivamente. Ambos autenticadores se agregan al grupo de rutas. En lugar de utilizar `GuardMiddleware`, se agrega una verificación en el controlador de ruta para ver si `Admin` o `User` fueron autenticados. Si no, se genera un error.

Esta composición de autenticadores da como resultado una ruta a la que pueden acceder dos tipos diferentes de usuarios con métodos de autenticación potencialmente diferentes. Una ruta de este tipo podría permitir la autenticación normal del usuario y al mismo tiempo dar acceso a un superusuario.

## Manualmente

También puedes manejar la autenticación manualmente usando `req.auth`. Esto es especialmente útil para realizar pruebas.

Para iniciar una sesión manualmente con un usuario, utiliza `req.auth.login(_:)`. Cualquier usuario `Authenticatable` puedes pasar a este método.

```swift
req.auth.login(User(name: "Vapor"))
```

Para obtener el usuario autenticado, utiliza `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

También puedes usar `req.auth.get(_:)` si no deseas generar automáticamente un error cuando falla la autenticación.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Para anular la autenticación de un usuario, pasa el tipo de usuario a `req.auth.logout(_:)`.

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) define dos protocolos `ModelAuthenticatable` y `ModelTokenAuthenticatable` que se pueden agregar a sus modelos existentes. Adaptar sus modelos a estos protocolos permite la creación de autenticadores para proteger los endpoints.

`ModelTokenAuthenticatable` se autentica con un token Bearer. Esto es lo que utiliza para proteger la mayoría de sus endpoints. `ModelAuthenticatable` se autentica con nombre de usuario y contraseña y lo utiliza un único endpoint para generar tokens.

Esta guía asume que estás familiarizado con Fluent y que has configurado correctamente tu aplicación para usar una base de datos. Si eres nuevo en Fluent, comienza con [Presentación](../fluent/overview.md).

### Usuario

Para comenzar, necesitarás un modelo que represente al usuario que será autenticado. Para esta guía, usaremos el siguiente modelo, pero eres libre de usar un modelo ya existente.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

El modelo debe poder almacenar un nombre de usuario, en este caso un correo electrónico, y un hash de contraseña. También configuramos `email` como un campo único, para evitar usuarios duplicados. La migración correspondiente para este modelo de ejemplo está aquí:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

No olvides agregar la migración a `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

!!! tip "Consejo"
    Debido a que las direcciones de correo electrónico no distinguen entre mayúsculas y minúsculas, es posible que desees agregar un [`Middleware`](../fluent/model.md#lifecycle) que obligue a poner la dirección de correo electrónico en minúsculas antes de guardarla en la base de datos. Sin embargo, ten en cuenta que `ModelAuthenticatable` utiliza una comparación que distingue entre mayúsculas y minúsculas, por lo que si haces esto querrás asegurarte de que la entrada del usuario esté en minúsculas, ya sea con coerción entre mayúsculas y minúsculas en el cliente o con un autenticador personalizado.

Lo primero que necesitarás es un endpoint para crear nuevos usuarios. Usemos `POST /usuarios`. Crea una estructura [Content](../basics/content.md) que represente los datos que espera este endpoint.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

Si lo deseas, puedes ajustar esta estructura a [Validatable](../basics/validation.md) para agregar requisitos de validación.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Ahora puedes crear el endpoint `POST /users`.

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

Este endpoint valida la solicitud entrante, decodifica la estructura `User.Create` y verifica que las contraseñas coincidan. Luego utiliza los datos decodificados para crear un nuevo `User` y lo guarda en la base de datos. La contraseña en texto plano se codifica mediante `Bcrypt` antes de guardarla en la base de datos.

Compila y ejecuta el proyecto, asegurándote de migrar primero la base de datos y luego utiliza la siguiente solicitud para crear un nuevo usuario.

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Modelo Autentificable

Ahora que tienes un modelo de usuario y un endpoint para crear nuevos usuarios, ajustemos el modelo a `ModelAuthenticatable`. Esto permitirá autenticar el modelo mediante nombre de usuario y contraseña.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

Esta extensión conforma `User` a `ModelAuthenticatable`. Las dos primeras propiedades especifican qué campos deben usarse para almacenar el hash de nombre de usuario y contraseña, respectivamente. La notación `\` crea una ruta clave a los campos que Fluent puede usar para acceder a ellos.

El último requisito es un método para verificar las contraseñas en texto plano enviadas en la cabecera de autenticación Basic. Dado que usamos Bcrypt para codificar la contraseña durante el registro, usaremos Bcrypt para verificar que la contraseña proporcionada coincida con el hash de contraseña almacenado.

Ahora que el `User` se ajusta a `ModelAuthenticatable`, podemos crear un autenticador para proteger la ruta de inicio de sesión.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` agrega el método estático `authenticator` para crear un autenticador.

Prueba que esta ruta funciona enviando la siguiente solicitud.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Esta solicitud pasa el nombre de usuario `test@vapor.codes` y la contraseña `secret42` a través de la cabecera de autenticación Basic. Deberías ver el usuario creado anteriormente devuelto.

Si bien, en teoría, podrías utilizar la autenticación Basic para proteger todos tus endpoints, se recomienda utilizar un token independiente. Esto minimiza la frecuencia con la que debe enviar la contraseña confidencial del usuario a través de Internet. También hace que la autenticación sea mucho más rápida, ya que solo necesita realizar un hash de contraseña durante el inicio de sesión.

### Tokens de Usuario

Crea un nuevo modelo para representar tokens de usuario.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

Este modelo debe tener un campo `value` para almacenar la cadena única del token. También debe tener una [relación-padre](../fluent/overview.md#parent) con el modelo de usuario. Puedes agregar propiedades adicionales a este token como mejor te parezca, como una fecha de vencimiento.

A continuación, crea una migración para este modelo.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

Observa que esta migración hace que el campo `value` sea único. También crea una referencia de clave externa entre el campo `user_id` y la tabla de usuarios.

No olvides agregar la migración a `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Finalmente, agrega un método en `User` para generar un nuevo token. Este método se utilizará durante el inicio de sesión.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

Aquí estamos usando `[UInt8].random(count:)` para generar un valor de token aleatorio. Para este ejemplo, se utilizan 16 bytes o 128 bits de datos aleatorios. Puedes ajustar este número como mejor te parezca. Luego, los datos aleatorios se codifican en base 64 para facilitar su transmisión en cabeceras HTTP.

Ahora que puedes generar tokens de usuario, actualiza la ruta `POST /login` para crear y devolver un token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Prueba que esta ruta funcione utilizando la misma solicitud de inicio de sesión anterior. Ahora deberías obtener un token al iniciar sesión que se parece a:

```
8gtg300Jwdhc/Ffw784EXA==
```

Conserva el token que obtengas, ya que la usaremos en breve.

#### Token Autentificable en el Modelo

Conforme `UserToken` a `ModelTokenAuthenticatable`. Esto permitirá que los tokens autentiquen su modelo de `User`.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        true
    }
}
```

El primer requisito del protocolo especifica qué campo almacena el valor único del token. Este es el valor que se enviará en la cabecera de autenticación Bearer. El segundo requisito especifica la relación principal con el modelo `User`. Así es como Fluent buscará al usuario autenticado.

El requisito final es un booleano `isValid`. Si esto es `false`, el token se eliminará de la base de datos y el usuario no será autenticado. Para simplificar, haremos que los tokens sean eternal codificando esto como `true`.

Ahora que el token se ajusta a `ModelTokenAuthenticatable`, puedes crear un autenticador para proteger rutas.

Crea un nuevo endpoint `GET /me` para obtener el usuario actualmente autenticado.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Similar a `User`, `UserToken` ahora tienes un método estático `authenticator()` que puede generar un autenticador. El autenticador intentará encontrar un `UserToken` coincidente utilizando el valor proporcionado en la cabecera de autenticación Bearer. Si encuentra una coincidencia, buscará el `User` relacionado y lo autenticará.

Prueba que esta ruta funciona enviando la siguiente solicitud HTTP donde el token es el valor que guardaste de la solicitud `POST /login`.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Deberías ver devuelto el `User` autenticado.

## Session

La [API de Session](../advanced/sessions.md) de Vapor se puede utilizar para conservar automáticamente la autenticación del usuario entre solicitudes. Esto funciona almacenando un identificador único para el usuario en los datos de la sesión de la solicitud después de iniciar sesión correctamente. En solicitudes posteriores, el identificador del usuario se recupera de la sesión y se utiliza para autenticar al usuario antes de llamar a su controlador de ruta.

Las sesiones son excelentes para aplicaciones web front-end integradas en Vapor que sirven HTML directamente a los navegadores web. Para las APIs, recomendamos utilizar autenticación sin estado basada en tokens para conservar los datos del usuario entre solicitudes.

### Session Autentificable

Para utilizar la autenticación basada en sesión, necesitarás un tipo que conforme a `SessionAuthenticatable`. Para este ejemplo, usaremos un struct simple.

```swift
import Vapor

struct User {
    var email: String
}
```

Para conformar con `SessionAuthenticatable`, deberás especificar un `sessionID`. Este es el valor que se almacenará en los datos de la sesión y debes identificar al usuario de forma única.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Para nuestro tipo simple `User`, usaremos la dirección de correo electrónico como identificador de sesión único.

### Autenticador de Session

A continuación, necesitaremos un `SessionAuthenticator` para manejar la resolución de instancias de nuestro User a partir del identificador de sesión persistente.

```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

Si estás utilizando `async`/`await`, puedes usar `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Dado que toda la información que necesitamos para inicializar nuestro `User` de ejemplo está contenida en el identificador de sesión, podemos crear e iniciar sesión en el usuario de forma sincrónica. En una aplicación real, probablemente usaríamos el identificador de sesión para realizar una búsqueda en la base de datos o una solicitud a la API para recuperar el resto de los datos del usuario antes de autenticarse.

A continuación, creemos un autenticador Bearer simple para realizar la autenticación inicial.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

Este autenticador autenticará a un usuario con el correo electrónico `hello@vapor.codes` cuando se envíe el token Bearer `test`.

Finalmente, combinemos todas estas piezas en tu aplicación.

```swift
// Crea un grupo de rutas protegidas que requiera autenticación de usuario.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Agrega la ruta GET /me para leer el correo electrónico del usuario.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

Primero agreguemos `SessionsMiddleware` para habilitar la compatibilidad con sesiones en la aplicación. Puedes encontrar más información sobre la configuración de sesiones en la sección [API de Session](../advanced/sessions.md).

A continuación, agreguemos `SessionAuthenticator`. Esto maneja la autenticación del usuario si hay una sesión activa.

Si la autenticación aún no persiste en la sesión, la solicitud se reenviará al siguiente autenticador. `UserBearerAuthenticator` verificará el token Bearer y autenticará al usuario si es igual a `"test"`.

Finalmente, `User.guardMiddleware()` asegurará que `User` haya sido autenticado por uno de los middleware anteriores. Si el usuario no ha sido autenticado, se generará un error.

Para probar esta ruta, primero envía la siguiente solicitud:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Esto hará que `UserBearerAuthenticator` autentique al usuario. Una vez autenticado, `UserSessionAuthenticator` conservará el identificador del usuario en el almacenamiento de la sesión y generará una cookie. Utiliza la cookie de la respuesta en una segunda solicitud de la ruta.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Esta vez, `UserSessionAuthenticator` autenticará al usuario y debería volver a ver el correo electrónico del usuario.

### Modelo de Session Autentificable

Los modelos de Fluent pueden generar `SessionAuthenticator`s que conformen a `ModelSessionAuthenticatable`. Esto utilizará el identificador único del modelo como identificador de sesión y realizará automáticamente una búsqueda en la base de datos para restaurar el modelo desde la sesión.

```swift
import Fluent

final class User: Model { ... }

// Permitir que este modelo sea persistido en las sesiones.
extension User: ModelSessionAuthenticatable { }
```

Puedes agregar `ModelSessionAuthenticatable` a cualquier modelo existente sin hacer nada más. Una vez agregado, estará disponible un nuevo método estático para crear un `SessionAuthenticator` para ese modelo.

```swift
User.sessionAuthenticator()
```

Esto utilizará la base de datos predeterminada de la aplicación para resolver el usuario. Para especificar una base de datos, debes pasar el identificador.

```swift
User.sessionAuthenticator(.sqlite)
```

## Autenticación en el Sitio Web

Los sitios web son un caso especial de autenticación porque el uso de un navegador restringe la forma en que se pueden adjuntar credenciales al mismo. Esto lleva a dos escenarios de autenticación diferentes:

* el inicio de sesión inicial a través de un formulario
* llamadas posteriores autenticadas con una cookie de sesión

Vapor y Fluent proporcionan varias herramientas para que esto sea fácil de usar.

### Autenticación de Session

La autenticación de sesión funciona como se describió anteriormente. Debes aplicar el middleware de sesión y el autenticador de sesión a todas las rutas a las que accederá tu usuario. Estas incluyen cualquier ruta protegida, cualquier ruta que sea pública pero que aún desee acceder al usuario si ha iniciado sesión (para mostrar un botón de cuenta, por ejemplo) **y** rutas de inicio de sesión.

Puedes habilitar esto globalmente en tu aplicación en **configure.swift** así:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Estos middlewares hacen lo siguiente:

* el middleware de sesiones toma la cookie de sesión proporcionada en la solicitud y la convierte en una sesión
* el autenticador de sesión toma la sesión y ve si hay un usuario autenticado para esa sesión. Si es así, el middleware autentica la solicitud. En la respuesta, el autenticador de sesión ve si la solicitud tiene un usuario autenticado y lo guarda en la sesión para que se autentique en la siguiente llamada.

!!! note "Nota"
    La cookie de sesión no está configurada como `secure` ni `httpOnly` de forma predeterminada. Consulta la [API de Session](../advanced/sessions.md#configuration) de Vapor para obtener más información sobre cómo configurar las cookies.

### Protegiendo Rutas

When protecting routes for an API, you traditionally return an HTTP response with a status code such as **401 Unauthorized** if the request is not authenticated. However, this isn't a very good user experience for someone using a browser. Vapor provides a `RedirectMiddleware` for any `Authenticatable` type to use in this scenario:

Al proteger rutas en una API, tradicionalmente se devuelve una respuesta HTTP con un código de estado como **401 Unauthorized** si la solicitud no está autenticada. Sin embargo, esta no es una muy buena experiencia de usuario para alguien que usa un navegador. Vapor proporciona un `RedirectMiddleware` para cualquier tipo `Authenticatable` para usar en este escenario:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

The `RedirectMiddleware` object also supports passing a closure that returns the redirect path as a `String` during creation for advanced url handling. For instance, including the path redirected from as query parameter to the redirect target for state management.

El objeto `RedirectMiddleware` también admite pasar un closure que devuelve la ruta de redireccionamiento como un `String` durante la creación para un manejo avanzado de URL. Por ejemplo, incluye la ruta redirigida como parámetro de consulta al destino de redirección para la gestión del estado.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Esto funciona de manera similar a `GuardMiddleware`. Cualquier solicitud a rutas registradas en `protectedRoutes` que no estén autenticadas serán redirigidas a la ruta proporcionada. Esto te permite decirles a tus usuarios que inicien sesión, en lugar de simplemente proporcionar un **401 Unauthorized**.

Asegúrate de incluir un autenticador de sesión antes de `RedirectMiddleware` para garantizar que el usuario autenticado se cargue antes de ejecutar `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Formulario de Inicio de Sesión

Para autenticar a un usuario y solicitudes futuras con una sesión, debes iniciar sesión como un usuario. Vapor proporciona el protocolo `ModelCredentialsAuthenticatable` al que hay que conformar. Esto maneja el inicio de sesión a través de un formulario. Primero ajusta tu `User` a este protocolo:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Esto es idéntico a `ModelAuthenticatable` y si ya lo cumple, no necesitas hacer nada más. A continuación, aplica el middleware `ModelCredentialsAuthenticator` a tu solicitud POST del formulario de inicio de sesión:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Esto utiliza el autenticador de credenciales predeterminado para proteger la ruta de inicio de sesión. Debes enviar `username` y `password` en la solicitud POST. Puedes configurar tu formulario así:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

`CredentialsAuthenticator` extrae `username` y `password` del cuerpo de la solicitud, encuentra al usuario a partir del nombre de usuario y verifica la contraseña. Si la contraseña es válida, el middleware autentica la solicitud. Luego, `SessionAuthenticator` autentica la sesión para solicitudes posteriores.

## JWT

[JWT](jwt.md) proporciona `JWTAuthenticator` que se puede utilizar para autenticar tokens web JSON en solicitudes entrantes. Si eres nuevo en JWT, consulta la [descripción general de JWT](jwt.md).

Primero, crea un tipo que represente un payload de JWT.

```swift
// Ejemplo de payload de JWT.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constantes
    let expirationTime: TimeInterval = 60 * 15
    
    // Datos de Token
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

A continuación, podemos definir una representación de los datos contenidos en una respuesta de inicio de sesión exitosa. Por ahora, la respuesta solo tendrá una propiedad que es una cadena que representa un JWT firmado.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

Usando nuestro modelo para el token JWT y la respuesta, podemos usar una ruta de inicio de sesión protegida con contraseña que devuelve una `ClientTokenResponse` e incluye un `SessionToken` firmado.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Alternativamente, si no deseas utilizar un autenticador, puedes tener algo similar a lo siguiente.

```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Valida la credencial proporcionada para el usuario
    // Obtiene userId para el usuario proporcionado
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Al ajustar el payload a `Authenticatable` y `JWTPayload`, puedes generar un autenticador de ruta utilizando el método `authenticator()`. Agrega esto a un grupo de rutas para buscar y verificar automáticamente el JWT antes de llamar a su ruta.

```swift
// Crea un grupo de rutas que requiera el SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Agregar el [guard middleware](#guard-middleware) opcional requerirá que la autorización se haya realizado correctamente.

Dentro de las rutas protegidas, puedes acceder al payload JWT autenticado usando `req.auth`.

```swift
// Devuelve una respuesta ok si el token proporcionado por el usuario es válido.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
