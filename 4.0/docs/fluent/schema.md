# Schema

Fluent's schema API allows you to create and update your database schema programatically. It is often used in conjunction with [migrations](migration.md) to prepare the database for use with [models](model.md).

```swift
// An example of Fluent's schema API
database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

To create a `SchemaBuilder`, use the `schema` method on database. Pass in the name of the table or collection you want to affect. If you are editing the schema for a model, make sure this name matches the model's [`schema`](model.md#schema). 

## Actions

The schema API supports creating, updating, and deleting schemas. Each action supports a subset of the schema builders available methods. 

### Create

Calling `create()` creates a new table or collection in the database. All methods for defining new fields and constraints are supported. Methods for updates or deletes are ignored. 

If a table or collection with the chosen name already exists, an error will be thrown. To ignore this, use `ignoreExisting`. 

```swift
// An example schema creation.
database.schema("planets")
    .ignoreExisting()
    .id()
    .field("name", .string, .required)
    .create()
```

### Update

Calling `update()` updates an existing table or collection in the database. All methods for creating, updating, and deleting fields and constraints are supported.

```swift
// An example schema update.
database.schema("planets")
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

### ID

### Data Type

### Field Constraint

### Update Field

### Delete Field

## Constraint

### Unique

### Foreign Key

### Delete Constraint
