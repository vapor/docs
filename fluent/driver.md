---
currentMenu: fluent-driver
---

# Driver

Drivers are what power Fluent under the hood. Fluent comes with a memory driver by default and there are many providers for databases like MySQL, SQLite, Mongo, PostgreSQL, and more available as providers.

![Drivers and Providers](https://cloud.githubusercontent.com/assets/1342803/17418823/73f1d1d2-5a68-11e6-9bed-90f42ce7781d.png)

This graphic shows the relation between Drivers and Providers using MySQL as an example. This distinction allows Fluent to be used independently from Vapor.

If you want to use Fluent without Vapor, you will import Drivers into your package. If you are using Vapor, you will import Providers.

Search GitHub for:
- [Fluent Drivers](https://github.com/vapor?utf8=✓&q=-driver)
- [Vapor Providers](https://github.com/vapor?utf8=✓&q=-provider)

Not all drivers have providers yet, and not all drivers or providers are up to date with the latest Vapor 1.0. This is a great way to contribute!

## Creating a Driver

Fluent is a powerful, database agnostic package for persisting your models. It was designed from the beginning to work with both SQL and NoSQL databases alike.

Any database that conforms to `Fluent.Driver` will be able to power the models in Fluent and Vapor.

The protocol itself is fairly simple:

```swift
public protocol Driver {
    var idKey: String { get }
    func query<T: Entity>(_ query: Query<T>) throws -> Node
    func schema(_ schema: Schema) throws
    func raw(_ raw: String, _ values: [Node]) throws -> Node
}
```

### ID Key

The ID key will be used to power functionality like `User.find()`. In SQL, this is often `id`. In MongoDB, it is `_id`.

### Query

This method will be called for every query made by Fluent. It is the drivers job to properly understand all of the properties on `Query` and return the desired rows, document, or other data as represented by `Node`.

### Schema

The schema method will be called before the database is expected to accept queries for a schema. For some NoSQL databases like MongoDB, this can be ignored. For SQL, this is where `CREATE` and other such commands should be called according to `Schema`.

### Raw

This is an optional method that can be used by any Fluent driver that accepts string queries. If your database does not accept such queries, an error can be thrown.
