# Using MySQL

This section outlines how to import the MySQL package both with or without a Vapor project.

## Install MySQL

To use MySQL, you need to have the C MySQL library installed on your computer.

```sh
# macOS

brew install vapor/tap/cmysql
```

> Note for Ubuntu
> * [Add Vapor's APT repo to get access to all of Vapor's system packages.](https://docs.vapor.codes/2.0/getting-started/install-on-ubuntu/#apt-repo)

```sh
# Ubuntu

sudo apt-get install cmysql
```

## With Vapor + Fluent

The easiest way to use MySQL with Vapor is to include the MySQL provider.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

The MySQL provider package adds MySQL to your project and adds some additional, Vapor-specific conveniences like `drop.mysql()`.

Using `import MySQLProvider` will import both Fluent and Fluent's Vapor-specific APIs.

## With Fluent

Fluent is a powerful, pure-Swift ORM that can be used with any Server-Side Swift framework. The MySQL driver allows you to use a MySQL database to power your models and queries.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/mysql-driver.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import MySQLDriver` to access the `MySQLDriver` class which you can use to initialize a Fluent `Database`.

## Just MySQL

At the core of the MySQL provider and MySQL driver is a Swift wrapper around the C MySQL client. This package can be used by itself to send raw, parameterized queries to your MySQL database.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/mysql.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import MySQL` to access the `MySQL.Database` class.
