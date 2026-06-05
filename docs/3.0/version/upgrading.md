# Upgrading Versions

This document provides information about changes between version and tips for migrating your projects. 

## 2.4 to 3.0

Vapor 3 has been rewritten from the ground up to be async and event-driven. This release contains the most changes of any previous release (and most likely any future release). 

Because of this, it is recommended that to migrate your projects you start by creating a new, empty template and migrate by copy / pasting code over to the new project.

We recommend reading the [Getting Started &rarr; Hello, world!](../getting-started/hello-world.md) section for Vapor 3 to familiarize yourself with the new APIs.

### Async

The biggest change in Vapor 3 is that the framework is now completely asynchronous. When you call methods that need to perform slow work like network requests or disk access instead of blocking they will now return a `Future<T>`. 

Futures are values that may not exist yet, so you cannot interact with them directly. Instead, you must use `map`/`flatMap` to access the values.

```swift
// vapor 2
let res = try drop.client.get("http://vapor.codes")
print(res.status) // HTTPStatus
return res.status

// vapor 3
let f = try req.client().get("http://vapor.codes").map { res in
	print(res.http.status) // HTTPStatus
	return res.http.status
}
print(f) // Future<HTTPStatus>
```

See [Async &rarr; Getting Started](../async/getting-started.md) to learn more.

### Application & Services

`Droplet` has been renamed to `Application` and is now a service-container. In Vapor 2, the `Droplet` had stored properties for things you would need during development (like views, hashers, etc). In Vapor 3, this is all done via services. 

While the `Application` _is_ a service-container, you should not use it from your route closures. This is to prevent race conditions since Vapor runs on multiple threads (event loops). Instead, use the `Request` that is supplied to your route closure. This has a _copy_ of all of the application's services for you to use.

```swift
// vapor 2
return try drop.view.make("myView")

// vapor 3
return try req.make(ViewRenderer.self).render("myView")
// shorthand
return try req.view().render("myView")
```

See [Service &rarr; Getting Started](../service/getting-started.md) to learn more.

### Database Connections

In Vapor 3, database connections are no longer statically accessible. This makes doing things like transactions and connection pooling much more predictable and performant. 

In order to create a `QueryBuilder` in Fluent 3, you will need access to something `DatabaseConnectable`. Most often you can just use the incoming `Request`, but you can also create connections manually if you need. 

```swift
// vapor 2
User.makeQuery().all()

// vapor 3
User.query(on: req).all()
```

See [DatabaseKit &rarr; Getting Started](../database-kit/getting-started.md) to learn more.

### Migrating SQL Database

When migrating from Fluent 2 to 3 you may need to update your `fluent` table to support the new format. In Fluent 3, the migration log table has the following changes:

- `id` is now a `UUID`.
- `createdAt` and `updatedAt` must now be `camelCase`.

Depending on how your Fluent database was configured, your tables may already be in the correct format. If not, you can run the following queries to transfer the table data. 

Use this query if your column names were already set to `camelCase`.

```sql
ALTER TABLE fluent RENAME TO fluent_old;
CREATE TABLE fluent 
    AS (SELECT UUID() as id, name, batch, createdAt, updatedAt from fluent_old);
```

Use this query if your column names were `snake_case`.

```sql
ALTER TABLE fluent RENAME TO fluent_old;
CREATE TABLE fluent 
    AS (SELECT UUID() as id, name, batch, created_at as createdAt, updated_at as updatedAt from fluent_old);
```

After you have verified the table was transferred properly, you can drop the old fluent table.

```sql
DROP TABLE fluent_old;
```

### Work in progress

This migration guide is a work in progress. Please feel free to add any migration tips here by submitting a PR.

Join the [#upgrading-to-3](https://discordapp.com/invite/BnXmVGA) in Vapor's team chat to ask questions and get help in real time.

Also check out [Getting started with Vapor 3](https://engineering.nodesagency.com/articles/Vapor/Getting-started-with-Vapor-3/), an in-depth article about the differences between Vapor 2 and 3. This article was written by two developers from an app development company using Vapor. 
