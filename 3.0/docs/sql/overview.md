# Using SQL

The SQL library helps you build and serialize SQL queries in Swift. It has an extensible, protocol-based design and supports DQL, DML, and DDL:

- **DQL**: Data Query Language (`SELECT`)
- **DML**: Data Manpulation Language (`INSERT`, `DELETE`, etc)
- **DDL**: Data Definition Language (`CREATE`, `ALTER`, etc)

This library's goal is to help you build SQL queries in a type-safe, consistent way. It can be used by ORMs to serialize their data types into SQL. It can also be used to generate SQL in a more Swifty way. The rest of this guide will give you an overview into using the SQL library manually.

## Data Query

DQL (data query language) is used to fetch data from one or more tables. This is done via the `SELECT` statement. Let's take a look how we would serialize the following SQL query.

```sql
SELECT * FROM users WHERE name = ?
```

This query selects all rows from the table `users` where the name is equal to a parameterized value. You can serialize literal values into data queries as well, but parameterization is highly recommended.

Let's build this query in Swift.

```swift
// Create a new data query for the table.
var users = DataQuery(table: "users")

// Create the "name = ?" predicate.
let name = DataPredicate(column: "name", comparison: .equal, value: .placeholder)

// Add the predicate as a single item (not group) to the query.
users.predicates.append(.predicate(name))

// Serialize the query.
let sql = GeneralSQLSerializer.shared.serialize(query: users)
print(sql) // "SELECT * FROM `users` WHERE (`name` = ?)"
```

Here we are using the shared [`GeneralSQLSerializer`](#fixme) to serialize the query. You can also implement [custom serializers](#serializer).

## Data Manipulation

DML (data manipulation language) is used to mutate data in a table. This is done via statements like `INSERT`, `UPDATE`, and `DELETE`. Let's take a look how we would serialize the following SQL query.

```sql
INSERT INTO users (name) VALUES (?)
```

This query inserts a new row into the table `users` where the name is equal to a parameterized value. You can serialize literal values into data manipulation queries as well, but parameterization is highly recommended.

Let's build this query in Swift.

```swift
// Create a new data manipulation query for the table.
var users = DataManipulationQuery(statement: .insert, table: "users")

// Create the column + value.
let name = DataManipulationColumn(column: "name", value: .placeholder)

// Add the column + value to the query.
users.columns.append(name)

// Serialize the query.
let sql = GeneralSQLSerializer.shared.serialize(query: user)
print(sql) // "INSERT INTO `users` (`name`) VALUES (?)"
```

That's all it takes to generate an `INSERT` query. Let's take a look at how this query would serialize if we use the [`.update`](#fixme) statement instead.

```swift
// Change the statement type
users.statement = .update

// Serialize the query.
let sql = GeneralSQLSerializer.shared.serialize(query: user)
print(sql) // "UPDATE `users` SET `name` = ?"
```

You can see that SQL has generated an equivalent `UPDATE` query with the appropriate syntax.

## Data Definition

DDL (data definition language) is used to create, update, and delete schemas in the database. This is done via statements like `CREATE TABLE`, `DROP TABLE`, etc. Let's take a look at how we would serialize the following SQL query.

```sql
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)
```

This example is using SQLite-like syntax, but that is not required. Let's generate this query in Swift.

```swift
// Create a new data definition query for the table.
var users = DataDefinitionQuery(statement: .create, table: "users")

// Create and append the id column.
let id = DataDefinitionColumn(name: "id", dataType: "INTEGER", attributes: ["PRIMARY KEY"])
users.addColumns.append(id)

// Create and append the name column.
let name = DataDefinitionColumn(name: "name", dataType: "TEXT")
users.addColumns.append(name)

// Serialize the query.
let sql = GeneralSQLSerializer.shared.serialize(query: user)
print(sql) // "CREATE TABLE `users` (`id` INTEGER PRIMARY KEY, `name` TEXT)"
```

That's all it takes to generate a `CREATE` query.

## Serializer

The default [`GeneralSQLSerializer`](#fixme) that comes with this library generates a fairly "standard" SQL syntax. However, each flavor of SQL (SQLite, MySQL, PostgreSQL, etc) all have specific rules for their syntax. 

To deal with this, all serializers are backed by the [`SQLSerializer`](#fixme) protocol. All serialization methods are defined on this protocol and come with a default implementation. Custom serializers can conform to this protocol and implement only the methods they need to customize. 

Let's take a look at how we would implement a `PostgreSQLSerializer` that uses `$x` placeholders instead of `?`.

```swift
/// Postgres-flavor SQL serializer.
final class PostgreSQLSerializer: SQLSerializer {
    /// Keeps track of the current placeholder count.
    var count: Int

    /// Creates a new `PostgreSQLSerializer`.
    init() {
        self.count = 1
    }

    /// See `SQLSerializer`.
    func makePlaceholder() -> String {
        defer { count += 1 }
        return "$\(count)"
    }
}
```

Here we've implemented `PostgreSQLSerializer` and overriden one method from `SQLSerializer`, `makePlaceholder()`.

Now let's use this serializer to serialize the [data query](#data-query) from a previous example.

```swift
// Data query from previous example
let users: DataQuery = ... 

// Serialize the query.
let sql = PostgreSQLSerializer().serialize(query: users)
print(sql) // "SELECT * FROM `users` WHERE (`name` = $1)"
```

That's it, congratulations on implementing a custom serializer.

## API Docs

Check out the [API docs](https://api.vapor.codes/sql/latest/SQL/index.html) for more in-depth information about SQL's APIs.