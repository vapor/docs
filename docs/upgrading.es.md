# Actualizar a 4.0

Esta guía muestra cómo actualizar un proyecto existente de Vapor 3.x a 4.x. Esta guía intenta cubrir todos los paquetes oficiales de Vapor, así como algunos providers de uso común. Si nota que falta algo, el [chat del equipo de Vapor](https://discord.gg/vapor) es un excelente lugar para pedir ayuda. También se agradecen issues y pull request.

## Dependencias

Para usar Vapor 4, necesitarás Xcode 11.4 y macOS 10.15 o superior.

La sección Instalación de los documentos analiza la instalación de dependencias.

## Package.swift

El primer paso para actualizar a Vapor 4 es actualizar las dependencias de su proyecto. A continuación se muestra un ejemplo de un archivo Package.swift actualizado. También puedes consultar la [plantilla Package.swift](https://github.com/vapor/template/blob/main/Package.swift) actualizada.

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

Todos los paquetes que se hayan actualizado para Vapor 4 tendrán su número de versión principal incrementado en uno.

!!! warning "Advertencia"
    El identificador de prelanzamiento `-rc` se utiliza ya que algunos paquetes de Vapor 4 aún no se han actualizado oficialmente.

### Paquetes Antiguos

Algunos paquetes de Vapor 3 han quedado obsoletos, como por ejemplo:

- `vapor/auth`: Ahora incluido en Vapor.
- `vapor/core`: Absorbido en varios módulos.
- `vapor/crypto`: Reemplazado por SwiftCrypto (Ahora incluido en Vapor).
- `vapor/multipart`: Ahora incluido en Vapor.
- `vapor/url-encoded-form`: Ahora incluido en Vapor.
- `vapor-community/vapor-ext`: Ahora incluido en Vapor.
- `vapor-community/pagination`: Ahora parte de Fluent.
- `IBM-Swift/LoggerAPI`: Reemplazado por SwiftLog.

### Dependencia Fluent

`vapor/fluent` ahora debe agregarse como una dependencia separada a su lista de dependencias y targets. Todos los paquetes específicos de bases de datos tienen el sufijo `-driver` para aclarar el requisito de `vapor/fluent`.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### Plataformas

Los manifiestos del paquete de Vapor ahora son explícitamente compatibles con macOS 10.15 y superiores. Esto significa que tu paquete también deberá especificar la compatibilidad con la plataforma.

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor puede agregar plataformas compatibles adicionales en el futuro. Tu paquete puede admitir cualquier subconjunto de estas plataformas siempre que el número de versión sea igual o mayor a los requisitos mínimos de versión de Vapor.

### Xcode

Vapor 4 utiliza SPM nativo de Xcode 11. Esto significa que ya no necesitarás generar archivos `.xcodeproj`. Al abrir la carpeta de tu proyecto en Xcode, se reconocerá automáticamente SPM y se incorporarán las dependencias.

Puedes abrir tu proyecto de forma nativa en Xcode usando `vapor xcode` o `open Package.swift`.

Una vez que hayas actualizado Package.swift, es posible que debas cerrar Xcode y borrar las siguientes carpetas del directorio raíz:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Una vez que tus paquetes actualizados se hayan resuelto exitosamente, deberías ver errores del compilador, probablemente bastantes. ¡No te preocupes! Te mostraremos cómo solucionarlos.

## Run

Lo primero que debemos hacer es actualizar el archivo `main.swift` de tu módulo Run al nuevo formato.

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

El contenido del archivo `main.swift` reemplaza al `app.swift` del módulo de aplicación, por lo que puedes eliminar ese archivo.

## Aplicación

Echemos un vistazo a cómo actualizar la estructura básica del módulo de la aplicación.

### configure.swift

El método `configure` debe cambiarse para aceptar una instancia de `Application`.

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

A continuación se muestra un ejemplo de un método de configuración actualizado.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Llamado antes de que se inicialice su aplicación.
public func configure(_ app: Application) throws {
    // Sirve archivos del directorio `Public/`
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configura la base de datos SQLite
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configura migraciones
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

A continuación se mencionan los cambios de sintaxis para configurar cosas como routing, middleware, fluent y más.

### boot.swift

El contenido de `boot` se puede colocar en el método `configure` ya que ahora acepta la instancia de la aplicación.

### routes.swift

El método `routes` debe cambiarse para aceptar una instancia de `Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

A continuación se menciona más información sobre los cambios en la sintaxis de routing.

## Servicios

Las APIs de servicios de Vapor 4 se han simplificado para que resulte más fácil descubrirlos y utilizarlos. Los servicios ahora están expuestos como métodos y propiedades en `Application` y `Request`, lo que permite al compilador ayudarte en su uso.

Para entender esto mejor, echemos un vistazo a algunos ejemplos.

```diff
// Cambiar el puerto predeterminado del servidor a 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

En lugar de registrar un `NIOServerConfig` en los servicios, la configuración del servidor ahora se expone como propiedades simples en Application que se pueden anular.

```diff
// Registrar middleware cors
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Create _empty_ middleware config
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

En lugar de crear y registrar un `MiddlewareConfig` para los servicios, el middleware ahora se expone como una propiedad de Application a la que se puede agregar.

```diff
// Realizar una solicitud en un controlador de ruta.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Al igual que Application, Request también expone los servicios como propiedades y métodos simples. Los servicios específicos de Request siempre deben usarse cuando se encuentre dentro de un closure de ruta.

Este nuevo patrón de servicio reemplaza los tipos `Container`, `Service` y `Config` de Vapor 3.

### Providers

Ya no se requiere que los providers configuren paquetes de terceros. En cambio, cada paquete amplía Application y Request con nuevas propiedades y métodos de configuración.

Echa un vistazo a cómo está configurado Leaf en Vapor 4.

```diff
// Utilizar Leaf para renderizar vistas.
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Para configurar Leaf, usa la propiedad `app.leaf`.

```diff
// Deshabilitar el caché de vista de Leaf.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Entorno

Se puede acceder al entorno actual (producción, desarrollo, etc.) a través de `app.environment`.

### Servicios Personalizados

Los servicios personalizados que cumplen con el protocolo `Service` y están registrados en el contenedor en Vapor 3 ahora se pueden expresar como extensiones de Application o Request.

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

Luego se puede acceder a este servicio utilizando la extensión en lugar de `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Providers Personalizados

La mayoría de los servicios personalizados se pueden implementar mediante extensiones como se muestra en la sección anterior. Sin embargo, es posible que algunos providers avanzados necesiten conectarse al ciclo de vida de la aplicación o utilizar propiedades almacenadas.

El nuevo helper `Lifecycle` de la aplicación se puede utilizar para registrar controladores de ciclo de vida.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Para almacenar valores en Application, utilice el nuevo helper `Storage`.

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

El acceso a `app.storage` se puede incluir en una propiedad calculada configurable para crear una API concisa.

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4 ahora expone las APIs asíncronas de SwiftNIO directamente y no intenta sobrecargar métodos como `map` y` flatMap` o tipos de alias como `EventLoopFuture`. Vapor 3 proporcionó sobrecargas y alias para compatibilidad con versiones beta anteriores que se lanzaron antes de que existiera SwiftNIO. Estos se han eliminado para reducir la confusión con otros paquetes compatibles con SwiftNIO y seguir las recomendaciones de mejores prácticas de SwiftNIO.

### Cambios de nombres asíncronos

El cambio más obvio es la eliminación del alias de tipo `Future` para `EventLoopFuture`. Esto se puede solucionar con bastante facilidad buscando y reemplazando.

Además, NIO no admite las etiquetas `to:` que agregó Vapor 3. Dada la inferencia de tipos mejorada de Swift 5.2, `to:` ahora es menos necesario de todos modos.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Los métodos con el prefijo `new`, como `newPromise`, se han cambiado a `make` para adaptarse mejor al estilo de Swift.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` ya no está disponible, pero los métodos de NIO como `mapError` y` flatMapErrorThrowing` funcionarán en su lugar.

El método global `flatMap` de Vapor 3 para combinar múltiples futuros ya no está disponible. Esto se puede reemplazar utilizando el método `and` de NIO para combinar muchos futuros.

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

Muchos métodos y propiedades que anteriormente usaban `Data` ahora usan `ByteBuffer` de NIO. Este tipo es un tipo de almacenamiento de bytes más potente y eficaz. Puedes leer más sobre su API en la [documentación de ByteBuffer de SwiftNIO](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Para convertir un `ByteBuffer` nuevamente en `Data`, usa:

```swift
Data(buffer.readableBytesView)
```

### Throwing map / flatMap

El cambio más difícil es que `map` y `flatMap` ya no lanzan errores (throw). `map` tiene una versión throw llamada (de manera algo confusa) `flatMapThrowing`. Sin embargo, `flatMap` no tiene contrapartida throw. Esto puede requerir que tengas que reestructurar algo de código asincrónico.

Los maps que _no_ hacen throw deberían seguir funcionando bien.

```swift
// map que no devuelve throw.
futureA.map { a in
    return b
}
```

Los maps que _si_ hacen throw deben cambiarse de nombre a `flatMapThrowing`.

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

Los flatMap que _no_ hacen throw deberían seguir funcionando bien.

```swift
// flatMap que no devuelve throw.
futureA.flatMap { a in
    return futureB
}
```

En lugar de generar un error dentro de un flatMap, devuelva un error futuro. Si el error se origina en otro método throw, el error puede detectarse utilizando do / catch y devolverse como futuro.

```swift
// Devolver un error atrapado como futuro.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Las llamadas a métodos que devuelven throw también se pueden refactorizar en un `flatMapThrowing` y encadenarlas usando tuplas.

```swift
// Método de throw refactorizado en flatMapThrowing con encadenamiento de tuplas.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result es el valor de doShomething.
    return futureB
}
```

## Routing

Las rutas ahora se registran directamente en Application.

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

Esto significa que ya no necesitas registrar un router en los servicios. Simplemente pasa tu aplicación a tu método `routes` y comienza a agregar rutas. Todos los métodos disponibles en `RoutesBuilder` están disponibles en `Application`.

### Contenido Sincrónico

El contenido de la solicitud de decodificación ahora es sincrónico.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

Este comportamiento puede ser anulado por rutas de registro utilizando la estrategia de recopilación de body `.stream`.

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // El body de la solicitud ahora es asíncrono.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Rutas separadas por comas

Las rutas ahora deben estar separadas por comas y no contener `/` para mantener la coherencia.

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### Parámetros de ruta

El protocolo `Parameter` se ha eliminado en favor de parámetros nombrados explícitamente. Esto evita problemas con parámetros duplicados y recuperación desordenada de parámetros en middleware y controladores de ruta.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

El uso de parámetros de ruta con modelos se menciona en la sección de Fluent.

## Middleware

`MiddlewareConfig` pasó a llamarse `MiddlewareConfiguration` y ahora es una propiedad de Application. Puedes agregar middleware a tu aplicación usando `app.middleware`.

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

El middleware ya no se puede registrar por nombre de tipo. Primero debes inicializar el middleware antes de registrarlo.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Para eliminar todo el middleware predeterminado, establece `app.middleware` en una configuración vacía usando:

```swift
app.middleware = .init()
```

## Fluent

La API de Fluent ahora es independiente de la base de datos. Puedes importar solo `Fluent`.

```diff
- import FluentMySQL
+ import Fluent
```

### Modelos

Todos los modelos ahora usan el protocolo `Model` y deben ser clases.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Todos los campos se declaran utilizando los property wrappers `@Field` o `@OptionalField`.

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

El ID de un modelo debe definirse utilizando el property wrapper `@ID`.

```diff
+ @ID(key: .id)
var id: UUID?
```

Los modelos que usan un identificador con una clave o tipo personalizado deben usar `@ID(custom:)`.

Todos los modelos deben tener su tabla o nombre de colección definido estáticamente.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

Todos los modelos ahora deben tener un inicializador vacío. Dado que todas las propiedades usan property wrappers, puede estar vacío.

```diff
final class Planet: Model {
+   init() { }
}
```

Los métodos `save`, `update`, y `create` del modelo ya no devuelven la instancia del modelo.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Los modelos ya no se pueden utilizar como componentes de ruta. Utiliza `find` y `req.parameters.get` en su lugar.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` ha sido renombrado a `Model.IDValue`.

Los timestamps del modelo ahora se declaran usando el property wrapper `@Timestamp`.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relaciones

Las relaciones ahora se definen mediante property wrappers.

Las relaciones padres utilizan el property wrapper `@Parent` y contienen la propiedad del campo internamente. La clave pasada a `@Parent` debe ser el nombre del campo que almacena el identificador en la base de datos.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Las relaciones hijas utilizan el property wrapper `@Children` con una ruta clave al `@Parent` relacionado.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Las relaciones entre hermanos utilizan el property wrapper `@Siblings` con rutas clave al modelo de pivote.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Los pivotes ahora son modelos normales que se ajustan a `Model` con dos relaciones `@Parent` y cero o más campos adicionales.

### Consultas

Ahora se accede al contexto de la base de datos a través de `req.db` en los controladores de ruta.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

Se ha cambiado el nombre de `DatabaseConnectable` a `Database`.

Las rutas clave a los campos ahora tienen el prefijo `$` para especificar el contenedor de propiedad en lugar del valor del campo.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migraciones

Los modelos ya no admiten migraciones automáticas basadas en reflection. Todas las migraciones deben escribirse manualmente.

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Las migraciones ahora se escriben de forma estricta, están desacopladas de los modelos y utilizan el protocolo `Migration`.

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

Los métodos `prepare` y `revert` ya no son estáticos.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

La creación de un schema builder se realiza mediante un método de instancia `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

Los métodos `create`, `update`, y `delete` ahora se llaman en el schema builder de manera similar a como funciona el query builder.

Las definiciones de los campos ahora están escritas en formato de cadena y siguen el siguiente patrón:

```swift
field(<name>, <type>, <constraints>)
```

Mira el ejemplo a continuación.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

El schema building ahora se puede encadenar como un query builder.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Configuración de Fluent

`DatabasesConfig` ha sido reemplazado por `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` ha sido reemplazado por `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repositorios

Como la forma en que funcionan los servicios en Vapor 4 ha cambiado, la manera de hacer repositorios de bases de datos también. Aún necesitas un protocolo como `UserRepository`, pero en lugar de hacer que una `final class` se ajuste a ese protocolo, debes crear una `struct`.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

También debes eliminar la conformidad de `ServiceType`, ya que ya no existe en Vapor 4.

```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

En su lugar, deberías crear un `UserRepositoryFactory`:

```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```

Esta factory es responsable de devolver un `UserRepository` para un `Request`.

El siguiente paso es agregar una extensión a `Application` para especificar su factory:

```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

Para usar el repositorio creado dentro de una `Request`, agrega esta extensión a la `Request`:

```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

El último paso es especificar el factory dentro de `configure.swift`

```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Ahora puedes acceder a tu repositorio en tus controladores de ruta con: `req.users.all()` y reemplazar fácilmente los tests internos del factory.

Si deseas utilizar un repositorio simulado dentro de los tests, primero crea un `TestUserRepository`

```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

Ahora puedes usar este repositorio simulado dentro de tus tests de la siguiente manera:

```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
