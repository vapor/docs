# Using Database Kit

Database Kit is a framework for configuring and working with database connections. It helps you do things like manage and pool connections, create simple keyed caches, and log queries. 

Many of Vapor's packages such as the Fluent drivers, Redis, and Vapor core are built on top of Database Kit. This guide will walk you through some of the common APIs you might encounter when using Database Kit.

## Config

Your first interaction with Database Kit will most likely be with the [`DatabasesConfig`](#fixme) struct. This type helps you configure one or more databases to your application and will ultimately yield a [`Databases`](#fixme) struct. This usually takes place in [`configure.swift`](../getting-started/structure/#configureswift).

```swift
// Create a SQLite database.
let sqliteDB = SQLiteDatabase(...)

// Create a new, empty DatabasesConfig.
var dbsConfig = DatabasesConfig()

// Register the SQLite database using '.sqlite' as an identifier.
dbsConfig.add(sqliteDB, as: .sqlite)

// Register the DatabaseConfig to services.
services.register(dbsConfig)
```

Using the [`add(...)`](#fixme) methods, you can register [`Database`](#fixme)s to the config. You can register instances of a database, a database type, or a closure that creates a database. The latter two methods will be resolved when your container boots.

You can also configure options on your databases, such as enabling logging.

```swift
// Enable logging on the SQLite database
dbsConfig.enableLogging(for: .sqlite)
```

Once you have registered a `DatabasesConfig` to your services and booted a container, you can take advantage of the convenience extensions on [`Container`](#fixme) to start creating connections.

```swift
// Creates a new connection to `.sqlite` db
app.withNewConnection(to: .sqlite) { conn in
    return conn.query(...) // do some db query
}
```

Read more about creating and managing connections in the next section.

## Connections

Database Kit's main focus is on creating, managing, and pooling connections. Creating new connections takes a non-trivial amount of time for your application and many cloud services will limit the total number of connections to a service that can be created. Because of this, it is important for high-concurrency web applications to manage their connections carefully.

### Pools

A common solution to connection management is the use of connection pools. These pools usually have a set maximum number of connections that are allowed to be open at once. Each time the pool is asked for a connection, it will first check if one is available before creating a new connection. If none are available, it will create a new one. If no connections are available and the pool is already at its maximum, the request for a new connection will _wait_ for a connection to be returned. 

The easiest way to request and release a pooled connection is the method [`withPooledConnection(...)`](#fixme). 

```swift
// Requests a pooled connection to `.psql` db
req.withPooledConnection(to: .psql) { conn in
    return conn.query(...) // do some db query
}
```

This method will requested a pooled connection to the identified database and call the provided closure when the connection is available. When the `Future` returned by the closure has completed, the connection will automatically be returned to the pool.

If you need access to a connection outside of a closure, you can use the related request / release methods instead.

```swift
let conn = try app.requestPooledConnection(to: .psql).wait()
defer { app.releasePooledConnection(conn, to: .psql) }
```

### New

You can always create a new connection to your databases if you need to. This will not affect your pooled connections. Creating new connections is especially useful during testing and app boot. But try not to do it in route closures since heavy traffic to your app could end up creating a lot of connections!

Similar to pooled connections, opening and closing new connections can be done using [`withNewConnection(...)`](#fixme). 

```swift
// Creates a new connection to `.sqlite` db
app.withNewConnection(to: .sqlite) { conn in
    return conn.query(...) // do some db query
}
```

This method will create a new connection, calling the supplied closure when the connection is open. When the `Future` returned in the closure completes, the connection will be closed automatically.

## Logging

Coming soon.

## Keyed Cache

Coming soon.

## API Docs

Check out the [API docs](https://api.vapor.codes/database-kit/latest/DatabaseKit/index.html) for more in-depth information about DatabaseKit's APIs.
