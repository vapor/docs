# Schema

La API de schema de Fluent te permite crear y actualizar el esquema de tu base de datos programáticamente. Normalmente se usa junto a las [migraciones](migration.md) para preparar la base de datos para su uso con [modelos](model.md).

```swift
// Un ejemplo de la API schema de Fluent
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Para crear un `SchemaBuilder`, usa el método `schema` en "database". Pásale el nombre de la tabla o colección que quieras afectar. Si estás editando el esquema para un modelo, asegúrate de que este nombre coincida con el [`schema`](model.md#schema) del modelo. 

## Acciones

La API de schema soporta crear, actualizar y borrar esquemas. Cada acción soporta un subconjunto de los métodos de la API disponibles. 

### Crear

Llamar a `create()` crea una nueva tabla o colección en la base de datos. Todos los métodos para definir nuevos campos y restricciones (constraints) están soportados. Los métodos para actualizaciones y borrados se ignoran. 

```swift
// Un ejemplo de creación de esquema.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Si ya existe una tabla o colección con el nombre elegido, se lanzará un error. Para ignorarlo, usa `.ignoreExisting()`. 

### Actualizar

Llamar a `update()` actualizará una tabla o colección ya existente en la base de datos. Todos los métodos para crear, actualizar y borrar campos y restricciones están soportados.

```swift
// Un ejemplo de actualización de esquema.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Borrar

Llamar a `delete()` borrará una tabla o colección ya existente de la base de datos. Ningún método adicional está soportado.

```swift
// Un ejemplo de borrado de esquema.
database.schema("planets").delete()
```

## Campo

Pueden añadirse campos cuando se crea o actualiza un esquema. 

```swift
// Añade un campo nuevo
.field("name", .string, .required)
```

El primer parámetro es el nombre del campo. Este nombre debería coincidir con la clave usada en la propiedad del modelo. El segundo parámetro es el [tipo de dato](#tipos-de-datos) del campo. Por último, puedes añadir cero o más [restricciones](#restricciones-de-campo). 

### Tipos de Datos

Debajo hay un listado con los tipos de datos soportados.

|DataType|Tipo de Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (recomendado)|
|`.time`|`Date` (omitiendo día, mes y año)|
|`.date`|`Date` (omitiendo hora y minutos del día)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Ver [diccionario](#diccionario)|
|`.array`|Ver [array](#array)|
|`.enum`|Ver [enum](#enum)|

### Restricciones de Campo

Debajo hay un listado con las restricciones de campo (field constraints) soportadas. 

|FieldConstraint|Descripción|
|-|-|
|`.required`|No permite valores `nil`.|
|`.references`|Requiere que el valor del campo coincida con un valor del esquema referenciado. Ver [clave externa](#clave-externa)|
|`.identifier`|Denota la clave primaria. Ver [identificador](#identificador)|

### Identificador

Si tu modelo usa una propiedad `@ID` estándar, puedes usar el helper `id()` para crear su campo correspondiente. Esto usa la clave de campo especial `.id` y el tipo de valor `UUID`.

```swift
// Añade campo para identificador por defecto.
.id()
```

Para tipos de identificador personalizados, necesitarás especificar el campo manualmente. 

```swift
// Añade campo para identificador personalizado.
.field("id", .int, .identifier(auto: true))
```

La restricción `identifier` debe usarse en un único campo, y denote la clave primaria. La marca (flag) `auto` determina si la base de datos deberá generar el valor automáticamente o no. 

### Actualizar Campo

Puedes actualizar el tipo de dato de un campo usando `updateField`. 

```swift
// Actualiza el campo al tipo de dato `double`.
.updateField("age", .double)
```

Ve a [avanzado](advanced.md#sql) para más información sobre actualizaciones avanzadas del esquema.

### Borrar Campo

Puedes borrar un campo de un esquema usando `deleteField`.

```swift
// Borra el campo "age".
.deleteField("age")
```

## Restricciones

Las restricciones (constraints) pueden añadirse al crear o actualizar un esquema. A diferencia de las [restricciones de campo](#restricciones-de-campo), las restricciones de nivel superior (top-level constraints) pueden afectar a varios campos.

### Unique

Una restricción "unique" requiere que no existan valores duplicados en uno o más campos. 

```swift
// No permite direcciones de email duplicadas.
.unique(on: "email")
```

Si varios campos son restringidos, la combinación de los valores de cada campo debe ser única.

```swift
// No permite usuarios con el mismo nombre completo.
.unique(on: "first_name", "last_name")
```

Para borrar una restricción "unique", usa `deleteUnique`. 

```swift
// Elimina la restricción de email duplicado.
.deleteUnique(on: "email")
```

### Nombre de Constraint

Fluent generará nombres de restricción únicos por defecto. Sin embargo, puedes querer proporcionar un nombre de restricción personalizado. Puedes hacerlo mediante el parámetro `name`.

```swift
// No permite direcciones de email duplicadas.
.unique(on: "email", name: "no_duplicate_emails")
```

Para borrar una restricción con nombre, debes usar `deleteConstraint(name:)`. 

```swift
// Elimina la restricción de email duplicado.
.deleteConstraint(name: "no_duplicate_emails")
```

## Clave Externa

Las restricciones de clave externa requieren que el valor de un campo coincida con uno de los valores del campo referenciado. Esto es útil para prevenir el guardado de datos no válidos. Las restricciones de clave externa pueden añadirse como restricciones de campo o de nivel superior. 

Para añadir una restricción de clave externa a un campo, usa `.references`.

```swift
// Ejemplo de añadir una restricción de clave externa de campo.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

La restricción de arriba requiere que todos los valores en el campo "star_id" deban coincidir con uno de los valores en el campo "id" de "Star".

Esta misma restricción podría añadirse como una de nivel superior usando `foreignKey`.

```swift
// Ejemplo de añadir una restricción de clave externa de nivel superior.
.foreignKey("star_id", references: "stars", "id")
```

A diferencia de las restricciones de campo, las de nivel superior pueden añadirse en una actualización del esquema. También pueden [nombrarse](#nombre-de-constraint). 

Las restricciones de clave externa soportan las acciones opcionales `onDelete` y `onUpdate`.

|ForeignKeyAction|Descripción|
|-|-|
|`.noAction`|Previene violaciones de clave externa (por defecto).|
|`.restrict`|Igual que `.noAction`.|
|`.cascade`|Propaga los borrados por las claves externas.|
|`.setNull`|Establece el campo a "null" si la referencia se rompe.|
|`.setDefault`|Establece el campo a su valor por defecto si la referencia se rompe.|

Debajo hay un ejemplo del uso de acciones de clave externa.

```swift
// Ejemplo de añadir una restricción de clave externa de nivel superior.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning "Advertencia"
    Las acciones de clave externa ocurren únicamente en la base de datos, evitando a Fluent. 
    Esto significa que cosas como el middleware de modelo o el borrado no permanente (soft-delete) pueden no funcionar correctamente.

## SQL

El parámetro `.sql` te permite añadir SQL arbitrario a tu esquema. Esto es útil para añadir restricciones o tipos de datos específicos.
Un caso de uso habitual es definir un valor por defecto para un campo:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

o inclusive un valor por defecto para una marca de tiempo (timestamp):

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Diccionario

El tipo de dato diccionario es capaz de guardar valores de diccionario anidados. Esto inclute structs conformadas con `Codable` y diccionarios de Swift con un valor `Codable`. 

!!! note "Nota"
    Los conectores de bases de datos SQL de Fluent guardan diccionarios anidados en columnas JSON.

Toma el struct `Codable` a continuación.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Como este struct `Pet` es `Codable`, puede guardarse en un `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

Este campo puede guardarse usando el tipo de dato `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Como los tipos `Codable` son diccionarios heterogéneos, no especificamos el parámetro `of`. 

Si los valores del diccionario fueran homogéneos, por ejemplo `[String: Int]`, el parámetro `of` especificaría el tipo del valor.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Las claves de los diccionarios deben ser siempre cadenas (strings). 

## Array

El tipo de dato array es capaz de guardar arrays anidados. Esto incluye arrays de Swiftque contengan valores `Codable` y tipos `Codable` que usen un contenedor sin clave.

Toma el siguiente `@Field` que guarda un array de cadenas.

```swift
@Field(key: "tags")
var tags: [String]
```

Este campo puede guardarse usando el tipo de dato `.array(of:)`.

```swift
.field("tags", .array(of: .string), .required)
```

Como el array es homogéneo, especificamos el parámetro `of`. 

Los `Array`s de Swift que puedan codificarse siempre tendrán un tipo de valor homogéneo. Los tipos `Codable` personalizados que serializan valores heterogéneos a contenedores sin clave son una excepción y deberían usar el tipo de dato `.array`.

## Enum

El tipo de dato enum es capaz de guardar enumeraciones de Swift con representación en cadenas (string backed) de forma nativa. Los enums nativos de bases de datos proporcionan una capa extra de seguridad de tipos a tu base de datos y pueden llegar a ser más eficientes que los enums normales (raw enums).

Para definir un enum nativo de base de datos, usa el método `enum` en `Database`. Usa `case` para definir cada caso del enum.

```swift
// Un ejemplo de creación de enums.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Una vez se ha creado el enum, puedes usar el método `read()` para generar un tipo de dato para el campo de tu esquema.

```swift
// Un ejemplo de leer un enum y usarlo para definir un campo nuevo.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// O

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Para actualizar un enum, llama a `update()`. Pueden borrarse los casos de un enum ya existente.

```swift
// Un ejemplo de actualización de un enum.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Para borrar un enum, llama a `delete()`.

```swift
// Un ejemplo de borrado de un enum.
database.enum("planet_type").delete()
```

## Acoplamiento de Modelos

La construcción de esquemas está desacoplada de los modelos a propósito. A diferencia de la construcción de consultas, la de esquemas no usa keypaths y está escrita totalmente en cadenas. Esto es importante dado que las definiciones de esquemas, especialmente las escritas para migraciones, pueden necesitar referenciar propiedades de modelos que ya no existen.

Para entender esto mejor, examina la migración de ejemplo a continuación.

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Asumamos que esta migración ya se ha subido a producción. Ahora asumamos que necesitamos hacer el siguiente cambio al modelo de User.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Podemos hacer los ajustes necesarios del esquema de la base de datos con la siguiente migración.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("name")
            .field("first_name", .string)
            .field("last_name", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Cabe destacar que para que esta migración funcione, necesitamos poder referenciar tanto el campo `name` eliminado como los nuevos campos `firstName` y `lastName` al mismo tiempo. Es más, la migración `UserMigration` original debería continuar siendo válida. Esto no sería posible de hacer mediante keypaths.

## Configurando el Espacio del Modelo

Para definir el [espacio para un modelo](model.md#database-space), pasa el espacio al `schema(_:space:)` cuando vayas a crear la tabla. Por ejemplo:

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
