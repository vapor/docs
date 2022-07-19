# Schema

Fluent's schema API allows you to create and update your database schema programatically. It is often used in conjunction with [migrations](migration.md) to prepare the database for use with [models](model.md).

```swift
// An example of Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

To create a `SchemaBuilder`, use the `schema` method on database. Pass in the name of the table or collection you want to affect. If you are editing the schema for a model, make sure this name matches the model's [`schema`](model.md#schema). 

## Actions

The schema API supports creating, updating, and deleting schemas. Each action supports a subset of the API's available methods. 

### Create

Calling `create()` creates a new table or collection in the database. All methods for defining new fields and constraints are supported. Methods for updates or deletes are ignored. 

```swift
// An example schema creation.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

If a table or collection with the chosen name already exists, an error will be thrown. To ignore this, use `.ignoreExisting()`. 

### Update

Calling `update()` updates an existing table or collection in the database. All methods for creating, updating, and deleting fields and constraints are supported.

```swift
// An example schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Delete

Calling `delete()` deletes an existing table or collection from the database. No additional methods are supported.

```swift
// An example schema deletion.
database.schema("planets").delete()
```

## Field

Fields can be added when creating or updating a schema. 

```swift
// Adds a new field
.field("name", .string, .required)
```

The first parameter is the name of the field. This should match the key used on the associated model property. The second parameter is the field's [data type](#data-type). Finally, zero or more [constraints](#field-constraint) can be added. 

### Data Type

Supported field data types are listed below.

|DataType|Swift Type|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (recommended)|
|`.time`|`Date` (omitting day, month, and year)|
|`.date`|`Date` (omitting time of day)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|See [dictionary](#dictionary)|
|`.array`|See [array](#array)|
|`.enum`|See [enum](#enum)|

### Field Constraint

Supported field constraints are listed below. 

|FieldConstraint|Description|
|-|-|
|`.required`|Disallows `nil` values.|
|`.references`|Requires that this field's value match a value in the referenced schema. See [foreign key](#foreign-key)|
|`.identifier`|Denotes the primary key. See [identifier](#identifier)|

### Identifier

If your model uses a standard `@ID` property, you can use the `id()` helper to create its field. This uses the special `.id` field key and `UUID` value type.

```swift
// Adds field for default identifier.
.id()
```

For custom identifier types, you will need to specify the field manually. 

```swift
// Adds field for custom identifier.
.field("id", .int, .identifier(auto: true))
```

The `identifier` constraint may be used on a single field and denotes the primary key. The `auto` flag determines whether or not the database should generate this value automatically. 

### Update Field

You can update a field's data type using `updateField`. 

```swift
// Updates the field to `double` data type.
.updateField("age", .double)
```

See [advanced](advanced.md#sql) for more information on advanced schema updates.

### Delete Field

You can remove a field from a schema using `deleteField`.

```swift
// Deletes the field "age".
.deleteField("age")
```

## Constraint

Constraints can be added when creating or updating a schema. Unlike [field constraints](#field-constraint), top-level constraints can affect multiple fields.

### Unique

A unique constraint requires that there are no duplicate values in one or more fields. 

```swift
// Disallow duplicate email addresses.
.unique(on: "email")
```

If multiple field are constrained, the specific combination of each field's value must be unique.

```swift
// Disallow users with the same full name.
.unique(on: "first_name", "last_name")
```

To delete a unique constraint, use `deleteUnique`. 

```swift
// Removes duplicate email constraint.
.deleteUnique(on: "email")
```

### Constraint Name

Fluent will generate unique constraint names by default. However, you may want to pass a custom constraint name. You can do this using the `name` parameter.

```swift
// Disallow duplicate email addresses.
.unique(on: "email", name: "no_duplicate_emails")
```

To delete a named constraint, you must use `deleteConstraint(name:)`. 

```swift
// Removes duplicate email constraint.
.deleteConstraint(name: "no_duplicate_emails")
```

## Foreign Key

Foreign key constraints require that a field's value match ones of the values in the referenced field. This is useful for preventing invalid data from being saved. Foreign key constraints can be added as either a field or top-level constraint. 

To add a foreign key constraint to a field, use `.references`.

```swift
// Example of adding a field foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

The above constraint requires that all values in the "star_id" field must match one of the values in Star's "id" field.

This same constraint could be added as a top-level constraint using `foreignKey`.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

Unlike field constraints, top-level constraints can be added in a schema update. They can also be [named](#constraint-name). 

Foreign key constraints support optional `onDelete` and `onUpdate` actions.

|ForeignKeyAction|Description|
|-|-|
|`.noAction`|Prevents foreign key violations (default).|
|`.restrict`|Same as `.noAction`.|
|`.cascade`|Propagates deletes through foreign keys.|
|`.setNull`|Sets field to null if reference is broken.|
|`.setDefault`|Sets field to default if reference is broken.|

Below is an example using foreign key actions.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    Foreign key actions happen solely in the database, bypassing Fluent. 
    This means things like model middleware and soft-delete may not work correctly.

## Dictionary

The dictionary data type is capable of storing nested dictionary values. This includes structs that conform to `Codable` and Swift dictionaries with a `Codable` value. 

!!! note
    Fluent's SQL database drivers store nested dictionaries in JSON columns.

Take the following `Codable` struct.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Since this `Pet` struct is `Codable`, it can be stored in a `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

This field can be stored using the `.dictionary(of:)` data type.

```swift
.field("pet", .dictionary, .required)
```

Since `Codable` types are heterogenous dictionaries, we do not specify the `of` parameter. 

If the dictionary values were homogenous, for example `[String: Int]`, the `of` parameter would specify the value type.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Dictionary keys must always be strings. 

## Array

The array data type is capable of storing nested arrays. This includes Swift arrays that contain `Codable` values and `Codable` types that use an unkeyed container.

Take the following `@Field` that stores an array of strings.

```swift
@Field(key: "tags")
var tags: [String]
```

This field can be stored using the `.array(of:)` data type.

```swift
.field("tags", .array(of: .string), .required)
```

Since the array is homogenous, we specify the `of` parameter. 

Codable Swift `Array`s will always have a homogenous value type. Custom `Codable` types that serialize heterogenous values to unkeyed containers are the exception and should use the `.array` data type.

## Enum

The enum data type is capable of storing string backed Swift enums natively. Native database enums provide an added layer of type safety to your database and may be more performant than raw enums.

To define a native database enum, use the `enum` method on `Database`. Use `case` to define each case of the enum.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Once an enum has been created, you can use the `read()` method to generate a data type for your schema field.

```swift
// An example of reading an enum and using it to define a new field.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Or

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

To update an enum, call `update()`. Cases can be deleted from existing enums.

```swift
// An example of enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

To delete an enum, call `delete()`.

```swift
// An example of enum deletion.
database.enum("planet_type").delete()
```

## Model Coupling

Schema building is purposefully decoupled from models. Unlike query building, schema building does not make use of key paths and is completely stringly typed. This is important since schema definitions, especially those written for migrations, may need to reference model properties that no longer exist.

To better understand this, take a look at the following example migration.

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

Let's assume that this migration has been has already been pushed to production. Now let's assume we need to make the following change to the User model.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

We can make the necessary database schema adjustments with the following migration.

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

Note that for this migration to work, we need to be able to reference both the removed `name` field and the new `firstName` and `lastName` fields at the same time. Furthermore, the original `UserMigration` should continue to be valid. This would not be possible to do with key paths.

## Setting Model Space

To define the [space for a model](model.md#database-space), pass the space to the `schema(_:space:)` when creating the table. E.g.

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```