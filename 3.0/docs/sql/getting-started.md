# Getting Started with SQL

SQL ([vapor/sql](https://github.com/vapor/sql)) is a library for building and serializing SQL queries in Swift. It has an extensible, protocol-based design and supports DQL, DML, and DDL.

!!! tip
    If you use Fluent, you will usually not need to build SQL queries manually.

## Choosing a Driver

Vapor's SQL database packages are built on top of this library. 

|database|repo|version|dbid|notes|
|-|-|-|-|-|
|[PostgreSQL](../postgresql/getting-started.md)|[postgresql](https://github.com/vapor/postgresql.git)|1.0.0|`psql`|**Recommended**. Open source, standards compliant SQL database. Available on most cloud hosting providers.|
|[MySQL](../mysql/getting-started.md)|[mysql](https://github.com/vapor/mysql)|3.0.0|`mysql`|Popular open source SQL database. Available on most cloud hosting providers. This driver also supports MariaDB.|
|[SQLite](../sqlite/getting-started.md)|[sqlite](https://github.com/vapor/sqlite)|3.0.0|`sqlite`|Open source, embedded SQL database. Its simplistic nature makes it a great candiate for prototyping and testing.|

Once you have selected a driver and added it to your `Package.swift` file, you can continue following this guide.
