# Avanzado

Fluent se esfuerza por crear una API general e independiente de cualquier base de datos que te permita trabajar con tus datos. Esto facilita el proceso de aprendizaje de Fluent, sin importar el conector de base de datos que uses. Crear APIs generalizadas también puede hacer que trabajar con tu base de datos en Swift se sienta más cómodo. 

Sin embargo, puede que necesites usar una característica de tu base de datos subyacente que todavía no tenga soporte en Fluent. Esta guía cubre APIs y patrones avanzados en Fluent que solo funcionan con ciertas bases de datos.

## SQL

Todos los conectores SQL de Fluent están construidos con [SQLKit](https://github.com/vapor/sql-kit). Esta implementación general de SQL se incluye con Fluent en el módulo `FluentSQL`.

### Base de datos SQL

Cualquier `Database` de Fluent puede convertirse (cast) a una `SQLDatabase`. Esto incluye `req.db`, `app.db`, la `database` pasada a `Migration`, etc. 

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // El conector subyacente de base de datos es SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // La base de datos subyacente _no_ es SQL.
}
```

Esta conversión solo funcionará si el conector de la base de datos subyacente es una base de datos SQL. Aprende más acerca de los métodos de `SQLDatabase` en el [README de SQLKit](https://github.com/vapor/sql-kit).

### Bases de datos SQL específicas

También puedes convertir a bases de datos SQL específicas importando el conector (driver). 

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // El conector subyacente de base de datos es PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // La base de datos subyacente _no_ es PostgreSQL.
}
```

En el momento de esta redacción, están soportados los siguientes conectores SQL:

|Base de Datos|Conector|Librería|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Visita los README de la librerías para más información sobre las APIs específicas de cada base de datos.

### SQL Personalizado

Casi todos los tipos de consultas y esquemas de Fluent soportan un caso `.custom`. Esto te permite utilizar características de bases de datos que Fluent no soporta todavía.

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE soportado.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE no soportado.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

Las bases de datos SQL soportan tanto `String` como `SQLExpression` en todos los casos `.custom`. El módulo `FluentSQL` ofrece métodos de conveniencia para casos de usos comunes.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // El conector subyacente de base de datos es SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    //  La base de datos subyacente _no_ es SQL.
}
```

A continuación tienes un ejemplo de `.custom` usando la conveniencia `.sql(raw:)` con el constructor del esquema.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // El conector subyacente de base de datos es MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // La base de datos subyacente _no_ es MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB es una integración entre [Fluent](../fluent/overview.md) y el conector [MongoKitten](https://github.com/OpenKitten/MongoKitten/). Aprovecha el sistema de tipado fuerte de Swift y la interfaz no anclada a bases de datos de Fluent, usando MongoDB.

El identificador más común en MongoDB es ObjectId. Puedes usarlo para tus proyectos usando `@ID(custom: .id)`.
Si necesitas usar los mismos modelos con SQL, no uses `ObjectId`. Usa `UUID` en su lugar.

```swift
final class User: Model {
    // Nombre de la tabla o colección.
    static let schema = "users"

    // Identificador único para este User.
    // En este caso, se usa ObjectId
    // Fluent recomienda usar UUID por defecto, sin embargo ObjectId también está soportado
    @ID(custom: .id)
    var id: ObjectId?

    // La dirección email del User
    @Field(key: "email")
    var email: String

    // La contraseña de User se guarda como un hash de BCrypt
    @Field(key: "password")
    var passwordHash: String

    // Crea una nueva instancia de User vacía para el uso de Fluent
    init() { }

    // Crea un nuevo User con todas las propiedades establecidas.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Modelado de Datos

En MongoDB, los Modelos se definen de la misma manera que en cualquier otro entorno de Fluent. La principal diferencia entre bases de datos SQL y MongoDB reside en las relaciones y la arquitectura.

En entornos SQL, es muy común crear tablas de unión para relaciones entre dos entidades. En MongoDB, sin embargo, una colección (array) puede usarse para guardar identificadores relacionados. Debido al diseño de MongoDB, es más práctico y eficiente diseñar tus modelos con estructuras de datos anidadas.

### Datos Flexibles

Puedes añadir datos flexibles en MongoDB, pero este código no funcionará en entornos SQL.
Para crear un almacenamiento de datos arbitrarios agrupados puedes usar `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent no puede soportar consultas de tipos estrictos en estos valores. Puedes usar un key path con notación de punto (dot notated key path) en tus consultas.
Esto está aceptado en MongoDB para acceder a valores anidados.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### Uso de expresiones regulares

Puedes consultar a MongoDB usando el caso `.custom()`, y pasando una expresión regular. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) acepta expresiones regulares compatibles con Perl. 

Por ejemplo, puedes hacer una consulta que obvie mayúsculas y minúsculas sobre el campo `name`:

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Esto devolverá planetas que contengan 'e' y 'E'. También puedes crear otras RegEx complejas aceptadas por MongoDB.

### Raw Access

Para acceder a la instancia `MongoDatabase` en bruto, convierte (cast) la instancia de base de datos a `MongoDatabaseRepresentable` de la siguiente manera:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

A partir de aquí puedes usar todas las APIs de MongoKitten.
