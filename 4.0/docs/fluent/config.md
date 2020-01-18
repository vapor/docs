# Configuring Fluent

When creating a project using `vapor new`, answer "yes" to including Fluent and choose which database driver you want to use. This will automatically add the dependencies to your new project as well as example configuration files.

## Existing Project

If you have an existing project you want to add Fluent to, you will need to add two dependencies to your [package](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- One (or more) Fluent driver of your choice

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: ["Fluent", "Fluent<db>Driver", "Vapor"]),
```

Once the packages are added as dependencies, you can configure your databases using `app.databases` in `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Each of the Fluent drivers below has more specific instructions for configuration.

## Drivers

Fluent currently has three officially supported drivers. You can search GitHub for the tag [`fluent-driver`](https://github.com/topics/fluent-database) for a full list of official and third-party Fluent database drivers.

### PostgreSQL

PostgreSQL is an open source, standards compliant SQL database. It is easily configurable on most cloud hosting providers. This is Fluent's **recommended** database driver.

To use PostgreSQL, add the following dependencies to your package.

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
	...
    dependencies: [
    	...
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-beta"),
    ],
    targets: [
    	...
        .target(name: "App", dependencies: [
        	...
        	"Fluent", 
        	"FluentPostgresDriver", 
        ]),
    ]
)
```

Once the dependencies are added, configure the database's credentials with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(.postgres(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor"
), as: .psql)
```

You can also parse the credentials from a database connection string.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

### SQLite

SQLite is an open source, embedded SQL database. Its simplistic nature makes it a great candiate for prototyping and testing.

To use SQLite, add the following dependencies to your package.

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
	...
    dependencies: [
    	...
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0-beta"),
    ],
    targets: [
    	...
        .target(name: "App", dependencies: [
        	...
        	"Fluent", 
        	"FluentSQLiteDriver", 
        ]),
    ]
)
```

Once the dependencies are added, configure the database with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

You can also configure SQLite to store the database ephemerally in memory.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

If you use an in-memory database, make sure to set Fluent to migrate automatically using `--auto-migrate` or run `app.autoMigrate()` after adding migrations.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
```

### MySQL

MySQL is a popular open source SQL database. It is available on many cloud hosting providers. This driver also supports MariaDB.

To use MySQL, add the following dependencies to your package.

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
	...
    dependencies: [
    	...
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0-beta"),
    ],
    targets: [
    	...
        .target(name: "App", dependencies: [
        	...
        	"Fluent", 
        	"FluentMySQLDriver", 
        ]),
    ]
)
```

Once the dependencies are added, configure the database's credentials with Fluent using `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor"
), as: .mysql)
```

You can also parse the credentials from a database connection string.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .psql)
```