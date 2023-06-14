# Fluent

Fluent es un framework [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) para Swift. Aprovecha el sólido sistema de tipado de Swift para proporcionar una interfaz fácil de usar para el manejo de bases de datos. El uso de Fluent se centra en la creación de tipos de modelo que representan estructuras de datos en la base de datos. Estos modelos se utilizan para realizar operaciones de creación, lectura, actualización y eliminación en lugar de escribir consultas directas a la base de datos.

## Configuración

Al crear un nuevo proyecto, habiendo utilizando el comando `vapor new`, responder "sí" para incluir Fluent y elegir qué controlador de base de datos se va a utilizar. Esto agregará automáticamente las dependencias al nuevo proyecto, así como código de ejemplo para realizar la configuración.

### Proyecto Existente

Si ya se dispone de un proyecto al que se quiere agregar Fluent, se deberán de agregar dos dependencias al paquete [package](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Uno (o más) controladores de Fluent que se deseen seleccionar

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

Una vez agregados los paquetes como dependencias, las bases de datos se configuran usando `app.databases` en  `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

A continuación, se detallan uno por uno y de forma más específica los detalles de configuración de cada uno de los controladores de Fluent.

### Controladores

Fluent actualmente tiene cuatro controladores oficialmente compatibles. Si se desea obtener una lista completa, tanto de controladores oficiales como de terceros de base de datos Fluent, se debe buscar en GitHub la etiqueta [`fluent-driver`](https://github.com/topics/fluent-driver).

#### PostgreSQL

PostgreSQL es una base de datos de código abierto que cumple con los estándares SQL. Es fácilmente configurable en la mayoría de los proveedores de alojamiento en la nube. Este es el controlador de base de datos  **recommendado** para Fluent.

Para usar PostgreSQL, agregar las siguientes dependencias al paquete.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Una vez agregadas las dependencias, configura la base de datos con Fluent utilizando `app.databases.use` en `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(.postgres(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .psql)
```

También se pueden expecificar las credenciales mediante una cadena de texto que defina la conexión a la base de datos.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite es una base de datos SQL integrada de código abierto. Su naturaleza simplista lo convierte en una excelente opción para prototipos y pruebas.

Para usar SQLite, se deben de agregar las siguientes dependencias al paquete.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Una vez agregadas las dependencias, configura la base de datos con Fluent utilizando `app.databases.use` en `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

También es posible configurar SQLite para que el almacenamiento de la base de datos tan solo se realice en memoria.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Si se utiliza una base de datos en memoria, asegurar que la configuración de Fluent se realiza mediante la migración automática usando `--auto-migrate` o ejecutando  `app.autoMigrate()` después de agregar las migraciones.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip "Consejo"
    La configuración de SQLite habilita automáticamente las restricciones de clave foranea en todas las conexiones creadas, pero no modifica las configuraciones de clave foranea en la base de datos en sí. La eliminación directa de registros en la base de datos podría violar las restricciones y desencadenar errores de clave foranea.

#### MySQL

MySQL es una popular base de datos SQL de código abierto. Está disponible en muchos proveedores de alojamiento en la nube. Añadir que este controlador también es compatible con MariaDB.

Para usar MySQL, se deben de agregar las siguientes dependencias al paquete.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Una vez que se hayan agregado las dependencias, configurar la base de datos con Fluent utilizando `app.databases.use` en `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

También se pueden expecificar las credenciales mediante una cadena de texto que defina la conexión a la base de datos.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Para configurar una conexión local sin un certificado SSL, se debe deshabilitar la verificación del certificado. Por ejemplo, es posible que esto sea necesario si se está conectando a una base de datos MySQL 8 mediante Docker.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning "Advertencia"
    Nunca deshabilitar la verificación del certificado en producción. Se deberá de proporcionar un certificado a la configuración de `TLSConfiguration` para su verificación.

#### MongoDB

MongoDB es una base de datos popular NoSQL y sin esquemas diseñada para los programadores. El controlador es compatible con todos los proveedores de alojamiento en la nube y con las instalaciones en un hospedaje propio a partir de la versión 3.4 y en adelante.

!!! note Nota
    Este controlador está impulsado por un cliente de MongoDB creado y mantenido por la comunidad llamado [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB mantiene un cliente oficial, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), junto con una integración de Vapor, mongodb-vapor.

Para usar MongoDB, se deben de agregar las siguientes dependencias al paquete.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Una vez que se hayan agregado las dependencias, configurar la base de datos con Fluent utilizando `app.databases.use` en `configure.swift`.

Para conectarse, se debe de usar una cadena de texto el formato de [conexión estándar URI](https://docs.mongodb.com/master/reference/connection-string/index.html) de MongoDB.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Modelos

Los modelos representan estructuras de datos fijas en la base de datos, como tablas o colecciones. Los modelos tienen uno o más campos que almacenan valores codificables. Todos los modelos también tienen un identificador único. Los Property Wrappers se utilizan para denotar identificadores y campos, así como mapeos más complejos mencionados posteriormente. El modelo de ejemplo a continuación representa una galaxia.

```swift
final class Galaxy: Model {
    // Nombre de la tabla o colección.
    static let schema = "galaxies"

    // Identificador único de esta Galaxia.
    @ID(key: .id)
    var id: UUID?

    // El nombre de la galaxia.
    @Field(key: "name")
    var name: String

    // Crea una nueva Galaxia vacía.
    init() { }

    // Crea una nueva Galaxia con todas las propiedades establecidas.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Para crear un nuevo modelo, crea una nueva clase que conforme a `Model`.

!!! tip Consejo
    Se recomienda marcar las clases de modelos como `final` para mejorar el rendimiento y simplificar los requisitos de conformidad.

El primer requisito del protocolo `Model` es la cadena estática `schema`.

```swift
static let schema = "galaxies"
```

Esta propiedad le indica a Fluent a qué tabla o colección corresponde el modelo. Esto puede ser una tabla que ya existe en la base de datos o una que creará con una [migración](#migrations). El esquema suele ser `snake_case` y en plural.

### Identificador

El siguiente requisito es un campo de identificador llamado `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Este campo debe usar el property wrapper `@ID`. Fluent recomienda usar `UUID` y el campo especial `.id` ya que esto es compatible con todos los controladores de Fluent.

Si se desea utilizar una clave o tipo de ID personalizado, se debe de usar la sobrecarga de [`@ID(custom:)`](model.md#custom-identifier).

### Campos

Después de agregar el identificador, se pueden agregar tantos campos como se deseen para almacenar información adicional. En este ejemplo, el único campo adicional es el nombre de la galaxia.

```swift
@Field(key: "name")
var name: String
```

Para campos simples, se utiliza el property wrapper `@Field`. Al igual que con `@ID`, el parámetro `key` especifica el nombre del campo en la base de datos. Esto es especialmente útil en casos en los que la convención de nomenclatura de campos de la base de datos puede ser diferente a la de Swift, por ejemplo, usando `snake_case` en lugar de `camelCase`.

A continuación, todos los modelos requieren un init vacío. Esto permite que Fluent cree nuevas instancias del modelo.

```swift
init() { }
```

Por último, se puede agregar un inicializador de conveniencia para que se puedan establecer todas las propiedades en el modelo.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

El uso de inicializadores de conveniencia es especialmente útil si se agregan nuevas propiedades al modelo, ya que se pueden obtener errores en tiempo de compilación si se cambia el método de inicialización.

## Migraciones

Si las base de datos utiliza esquemas predefinidos, como las bases de datos SQL, se necesita una migración para preparar la base de datos para el modelo. Las migraciones también son útiles para poblar las bases de datos con datos. Para crear una migración, define un nuevo tipo que se ajuste al protocolo `Migration` o `AsyncMigration`. Esta sería la siguiente migración para el modelo de Galaxia previamente definido.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepara la base de datos para almacenar modelos de Galaxia.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Opcionalmente revierte los cambios realizados en el método prepare.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

El método `prepare` se utiliza para preparar la base de datos para almacenar modelos de `Galaxy`.

### Esquema

En este método, se utiliza `database.schema(_:)` para crear un nuevo `SchemaBuilder`. Luego se agregan uno o más `field`s al constructor antes de llamar a `create()` para crear el esquema.

Cada campo agregado al constructor tiene un nombre, un tipo y restricciones opcionales.

```swift
field(<name>, <type>, <optional constraints>)
```

Hay un método `id()` de conveniencia para agregar propiedades  `@ID` utilizando los valores predeterminados recomendados de Fluent.

El `revert` en la migración deshace cualquier cambio realizado en el método `prepare`. En este caso, eso significa eliminar el esquema de Galaxia.

Una vez que se define la migración, se debe de informar a Fluent sobre ella agregándola a `app.migrations` en `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrar

Para realizar migraciones, ejecuta `swift run App migrate` desde la línea de comandos o agrega `migrate` como argumento al esquema de la aplicación en Xcode.

```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Consultando

Ahora que el modelo ha sido creado exitosamente y migrado a la base de datos, es el momento de hacer la primera consulta.

### All

La siguiente ruta devolverá una colección de todas las galaxias en la base de datos.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Para que la Galaxia pueda ser devuelta en un ruta de consulta es necesario agregar la conformidad con `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` se utiliza para crear un nuevo generador de consultas para el modelo.  `req.db` es una referencia a la base de datos predeterminada de la aplicación. Por último, `all()` devuelve todos los modelos almacenados en la base de datos.

Si tras compilar y ejecutar el proyecto, se realiza una solicitud de tipo `GET /galaxies`, se devolverá una colección vacía. Por lo tanto, se tendrá que agregar una ruta para crear una nueva galaxia.

### Creación

Siguiendo la convención RESTful, se utilizará el punto de entrada `POST /galaxies` para crear una nueva galaxia. Dado que los modelos son decodificables (codables), se puede decodificar una galaxia directamente desde el cuerpo de la solicitud.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso Ver también
    Consulta [Content &rarr; Overview](../basics/content.md) para obtener más información sobre la decodificación de los cuerpos de las solicitudes.

Una vez se tiene una instancia del modelo, llamar a `create(on:)` guarda el modelo en la base de datos. Esto devuelve un `EventLoopFuture<Void>` que indica que el guardado se ha completado. Una vez que se completa el guardado, devuelve el modelo recién creado utilizando `map`.

Si se está utilizando `async`/`await`, el código se puede escribir de la siguiente manera:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

En este caso, la operación async no tiene valor de retorno. La instancia se devolverá una vez que se complete el guardado.

Compilar, ejecutar el proyecto y envíar la siguiente solicitud.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Devolverá el modelo creado con un identificador como respuesta.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Ahora, si se consulta otra vez `GET /galaxies`, se debería de ver la galaxia recién creada devuelta en la colección.

## Relaciones

¡Las galaxias no son nada sin estrellas! Echemos un vistazo rápido a las potentes características de relaciones de Fluent mediante la adición de una relación uno a muchos entre `Galaxy` y un nuevo modelo `Star`.

```swift
final class Star: Model, Content {
    // Nombre de la tabla o colección.
    static let schema = "stars"

    // Identificador único para esta Estrella.
    @ID(key: .id)
    var id: UUID?

    // Nombre de la Estrella.
    @Field(key: "name")
    var name: String

    // Referencia a la Galaxia en la que se encuentra esta Estrella.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Crea una nueva Estrella vacía.
    init() { }

    // Crea una nueva Estrella con todas las propiedades establecidas.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Padre

El nuevo modelo de `Star` es muy similar a la `Galaxy`, excepto por un nuevo tipo de campo: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

La propiedad `parent` es un campo que almacena el identificador de otro modelo. El modelo que contiene la referencia se llama "hijo" y el modelo referenciado se llama "padre". Este tipo de relación también se conoce como "uno a muchos". El parámetro clave de la propiedad especifica el nombre del campo que se debe usar para almacenar la clave del padre en la base de datos.

En el método init, se establece el identificador del padre utilizando `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

Al anteponer el nombre de la propiedad padre con `$`, se accede al envoltorio de propiedad subyacente. Esto es necesario para acceder al `@Field` interno que almacena el valor real del identificador.

!!! seealso Ver También
    Consultar la propuesta de Evolución de Swift sobre envoltorios de propiedad, para obtener más información: [[SE-0258] Property Wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)

A continuación, crear una migración para preparar la base de datos para manejar las `Star`.

```swift
struct CreateStar: AsyncMigration {
    // Prepara la base de datos para almacenar los modelos de Estrella.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Opcionalmente revierte los cambios realizados en el método prepare.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Esto es casi igual a la migración de la Galaxia, excepto por el campo adicional para almacenar el identificador de la galaxia padre.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Este campo especifica una restricción opcional que indica a la base de datos que el valor del campo hace referencia al campo "id" en el esquema "galaxies". Esto también se conoce como una clave externa y ayuda a garantizar la integridad de los datos.

Una vez que se crea la migración, hay que añadirlo a las migraciones de `app.migrations` después de la migración `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Dado que las migraciones se ejecutan en orden y `CreateStar` hace referencia al esquema "galaxies", el orden es importante. Por último, [ejecuta las migraciones](#migrate) para preparar la base de datos.

Agregar una ruta para crear nuevas estrellas.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Crear una nueva estrella haciendo referencia a la galaxia previamente creada utilizando la siguiente petición HTTP.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

Debería devolver la creación de la nueva estrella con un identificador único.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Hijos

Ahora veamos cómo puedes utilizar la función de carga anticipada de Fluent para devolver automáticamente las estrellas de una galaxia en la ruta `GET /galaxies`. Agregar la siguiente propiedad al modelo `Galaxy`.

```swift
// Todas las estrellas en esta galaxia.
@Children(for: \.$galaxy)
var stars: [Star]
```

El envoltorio de propiedad `@Children` es el inverso de `@Parent`. Toma un camino de clave al campo `@Parent` del hijo como argumento para el parámetro `for`. Su valor es una matriz de hijos, ya que puede existir cero o más modelos hijo. No se necesitan cambios en la migración de la galaxia, ya que toda la información necesaria para esta relación se almacena en `Star`.

### Carga forzada

Ahora que la relación está completa, se puede usar el método `with` en el generador de consultas para buscar y serializar automáticamente la relación entre galaxia y estrella.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Se pasa un `key-path` `@Children` a `with` para indicarle a Fluent que cargue automáticamente esta relación en todos los modelos resultantes. Compilar y ejecutar la aplicación y envíar otra solicitud a `GET /galaxies`. Ahora se debería de ver que las estrellas se incluyen automáticamente en la respuesta.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Registro de consultas

Los controladores de Fluent registran el SQL generado en el nivel de registro de depuración. Algunos controladores, como FluentPostgreSQL, permiten configurar esto al configurar la base de datos.

Para establecer el nivel de registro, en **configure.swift** (o donde se esté configurando la aplicación), agregar:

```swift
app.logger.logLevel = .debug
```

Esto le indica a la aplicación que el nivel de registro es **depuración**. Para que los cambios se apliquen, requiere que se compile y se vuelva a ejecutar la aplicación. Las declaraciones SQL generadas por Fluent se registrarán en la consola.

## Siguentes pasos

Felicitaciones por crear los primeros modelos, migraciones y realizar operaciones básicas de creación y lectura. Para obtener información más detallada sobre todas estas características, consultar las secciones correspondientes en la guía de Fluent.
