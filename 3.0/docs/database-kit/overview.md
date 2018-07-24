# Using Database Kit

Database Kit is a framework for configuring and working with database connections. It helps you do things like manage and pool connections, create keyed caches, and log queries. 

Many of Vapor's packages such as the Fluent drivers, Redis, and Vapor core are built on top of Database Kit. This guide will walk you through some of the common APIs you might encounter when using Database Kit.

## Config

Your first interaction with Database Kit will most likely be with the [`DatabasesConfig`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabasesConfig.html) struct. This type helps you configure one or more databases to your application and will ultimately yield a [`Databases`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/Databases.html) struct. This usually takes place in [`configure.swift`](../getting-started/structure/#configureswift).

```swift
// Create a SQLite database.
let sqliteDB = SQLiteDatabase(...)

// Create a new, empty DatabasesConfig.
var dbsConfig = DatabasesConfig()

// Register the SQLite database using '.sqlite' as an identifier.
dbsConfig.add(sqliteDB, as: .sqlite)

// Register more DBs here if you want

// Register the DatabaseConfig to services.
services.register(dbsConfig)
```

Using the [`add(...)`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabasesConfig.html) methods, you can register [`Database`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/Database.html)s to the config. You can register instances of a database, a database type, or a closure that creates a database. The latter two methods will be resolved when your container boots.

You can also configure options on your databases, such as enabling logging.

```swift
// Enable logging on the SQLite database
dbsConfig.enableLogging(for: .sqlite)
```

See the section on [logging](#logging) for more information.

### Identifier

Most database integrations will provide a default [`DatabaseIdentifier`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseIdentifier.html) to use. However, you can always create your own. This is usually done by creating a static extension.

```swift
extension DatabaseIdentifier {
    /// Test database.
    static var testing: DatabaseIdentifier<MySQLDatabase> {
        return "testing"
    }
}
```

`DatabaseIdentifier` is `ExpressibleByStringLiteral` which allows you to create one with just a `String`.

### Databases

Once you have registered a `DatabasesConfig` to your services and booted a container, you can take advantage of the convenience extensions on [`Container`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Extensions/Container.html) to start creating connections.

```swift
// Creates a new connection to `.sqlite` db
app.withNewConnection(to: .sqlite) { conn in
    return conn.query(...) // do some db query
}
```

Read more about creating and managing connections in the next section.

## Connections

Database Kit's main focus is on creating, managing, and pooling connections. Creating new connections takes a non-trivial amount of time for your application and many cloud services limit the total number of connections to a service that can be open. Because of this, it is important for high-concurrency web applications to manage their connections carefully.

### Pools

A common solution to connection management is the use of connection pools. These pools usually have a set maximum number of connections that are allowed to be open at once. Each time the pool is asked for a connection, it will first check if one is available before creating a new connection. If none are available, it will create a new one. If no connections are available and the pool is already at its maximum, the request for a new connection will _wait_ for a connection to be returned. 

The easiest way to request and release a pooled connection is the method [`withPooledConnection(...)`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Extensions/Container.html#/s:11DatabaseKit20withPooledConnectionXeXeF). 

```swift
// Requests a pooled connection to `.psql` db
req.withPooledConnection(to: .psql) { conn in
    return conn.query(...) // do some db query
}
```

This method will request a pooled connection to the identified database and call the provided closure when the connection is available. When the `Future` returned by the closure has completed, the connection will automatically be returned to the pool.

If you need access to a connection outside of a closure, you can use the related request / release methods instead.

```swift
// Request a connection from the pool and wait for it to be ready.
let conn = try app.requestPooledConnection(to: .psql).wait()

// Ensure the connection is released when we exit this scope.
defer { app.releasePooledConnection(conn, to: .psql) }
```

You can configure your connection pools using the [`DatabaseConnectionPoolConfig`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseConnectionPoolConfig.html) struct. 

```swift
// Create a new, empty pool config.
var poolConfig = DatabaseConnectionPoolConfig()

// Set max connections per pool to 8.
poolConfig.maxConnections = 8

// Register the pool config.
services.register(poolConfig)
```

To prevent race conditions, pools are never shared between event loops. There is usually one pool per database per event loop. This means that the amount of connections your application can potentially open to a given database is equal to `numThreads * maxConns`.

### New

You can always create a new connection to your databases if you need to. This will not affect your pooled connections. Creating new connections is especially useful during testing and app boot. But try not to do it in route closures since heavy traffic to your app could end up creating a lot of connections!

Similar to pooled connections, opening and closing new connections can be done using [`withNewConnection(...)`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Extensions/Container.html#/s:11DatabaseKit17withNewConnectionXeXeF). 

```swift
// Creates a new connection to `.sqlite` db
app.withNewConnection(to: .sqlite) { conn in
    return conn.query(...) // do some db query
}
```

This method will create a new connection, calling the supplied closure when the connection is open. When the `Future` returned in the closure completes, the connection will be closed automatically.

You can also simply open a new connection with [`newConnection(...)`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Extensions/Container.html#/s:11DatabaseKit13newConnectionXeXeF).

```swift
// Creates a new connection to `.sqlite` db
let conn = try app.newConnection(to: .sqlite).wait()

// Ensure the connection is closed when we exit this scope.
defer { conn.close() }
```

## Logging

Databases can opt into supporting query logging via the [`LogSupporting`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/LogSupporting.html) protocol. Databases that conform to this protocol can have loggers [configured](#config) via `DatabasesConfig`.

```swift
// Enable logging on the SQLite database
dbsConfig.enableLogging(for: .sqlite)
```

By default, a simple print logger will be used, but you can pass a custom `DatabaseLogHandler`.

```swift
// Create a custom log handler.
let myLogger: DatabaseLogHandler = ...

// Enable logging on SQLite w/ custom logger.
dbsConfig.enableLogging(for: .sqlite, logger: myLogger)
```

Log handlers will receive an instance of [`DatabaseLog`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseLog.html) for each logged query. This contains information such as the query, parameterized values, database id, and time.

## Keyed Cache

Databases can opt into supporting keyed-caching via the [`KeyedCacheSupporting`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/KeyedCacheSupporting.html) protocol. Databases that conform to this protocol can be used to create instances of [`DatabaseKeyedCache`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Classes/DatabaseKeyedCache.html).

Keyed caches are capable of getting, setting, and removing `Codable` values at keys. They are sometimes called "key value stores".

To create a keyed cache, you can use the extensions on [`Container`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Extensions/Container.html#/s:11DatabaseKit10keyedCacheXeXeF).

```swift
// Creates a DatabaseKeyedCache with .redis connection pool
let cache = try app.keyedCache(for: .redis)

// Sets "hello" = "world"
try cache.set("hello", to: "world").wait()

// Gets "hello"
let world = try cache.get("hello", as: String.self).wait()
print(world) // "world"

// Removes "hello"
try cache.remove("hello").wait()
```

See the [`KeyedCache`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/KeyedCache.html) protocol for more information.

## API Docs

Check out the [API docs](https://api.vapor.codes/database-kit/latest/DatabaseKit/index.html) for more in-depth information about DatabaseKit's APIs.
