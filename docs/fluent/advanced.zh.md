# 进阶

Fluent 致力于创建一个通用的、与数据库无关的 API 来处理数据。无论你使用哪种数据库驱动程序，都可以轻松的学习 Fluent。创建通用 API 还可以让你在 Swift 中更轻松自在的使用数据库。

然而，你可能需要使用 Fluent 尚不支持的某个功能来驱动底层数据库。本指南涵盖了 Fluent 中仅适用于某些数据库的高级模式和 API。

## SQL

Fluent 的所有 SQL 数据库驱动程序都是建立在 [SQLKit](https://github.com/vapor/sql-kit) 之上。此通用 SQL 实现是在 Fluent 的 `FluentSQL` 模块中提供的。

### SQL 数据库

任何 Fluent `数据库` 都可以转换为 `SQLDatabase`。 这包括 `req.db`，`app.db`，传递给`迁移`的`数据库`等。

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // 底层数据库驱动程序是 SQL
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // 其它驱动
}
```

此转换仅在底层数据库驱动程序是 SQL 数据库时才有效。了解有关 `SQLDatabase` 方法的更多信息，请参阅 [SQLKit's README](https://github.com/vapor/sql-kit)。

### 指定 SQL 数据库

你还可以通过导入驱动程序转换为指定的 SQL 数据库。

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // 底层数据库驱动程序是 PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // 其它驱动
}
```

在撰写本文时，支持以下 SQL 驱动程序。

|数据库|驱动|库|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

了解更多特定数据库的 API 信息，请参阅该库的 README。 

### 自定义 SQL 

几乎所有 Fluent 的查询和模式类型都支持 `.custom` 方法。你就可以使用那些 Fluent 还未支持的数据库功能。

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // 支持 ILIKE 语句查询。
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // 不支持 ILIKE 语句的查询。
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

在 SQL 数据库中所有 `.custom` 用例都支持`字符串`和`SQL 表达式`。 `FluentSQL` 模块为常见的用例提供了方便的方法。

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // 底层数据库驱动程序是 SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // 其它驱动
}
```

下面是 `.custom` 的一个示例，通过 `.sql(raw:)` 方法与模式构建器一起使用的便利性。

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // 底层数据库驱动程序是 MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // 其它驱动
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB 是一个集成了 [Fluent](../fluent/overview.md) 和 [MongoKitten](https://github.com/OpenKitten/MongoKitten/) 的驱动程序。它利用 Swift 的强类型特性以及 Fluent 使用与 MongoDB 数据库无关的接口。

MongoDB 中最常见的标识符是 ObjectId。你可以在项目中使用 `@ID(custom: .id)` 自定义标志符。
如果需要在 SQL 中使用相同的模型，请不要使用 `ObjectId`。改为使用 `UUID`。

```swift
final class User: Model {
    // 表名或集合名
    static let schema = "users"

    // 用户标志符
    // 本例中使用 ObjectId
    // Fluent默认推荐使用 UUID，当然 ObjectId 也是支持的
    @ID(custom: .id)
    var id: ObjectId?

    // 用户邮箱
    @Field(key: "email")
    var email: String

    // 用户密码存储为 BCrypt 散列
    @Field(key: "password")
    var passwordHash: String

    // 创建一个新的空 User 实例，供 Fluent 使用
    init() { }

    // 创建用户时设置所有属性
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### 数据建模

在 MongoDB 中，模型的定义与任何其它 Fluent 环境中的定义相同。SQL 数据库和 MongoDB 的主要区别在于关系和架构。

在 SQL 环境中，为两个实体之间的关系创建连接表是很常见的。然而，在 MongoDB 中，可以使用数组来存储相关的标识符。由于 MongoDB 的设计，使用嵌套数据结构设计模型更加高效和实用。

### Flexible Data

您可以在 MongoDB 中添加灵活的数据，但此代码在 SQL 环境中不起作用。要创建分组的任意数据存储，你可以使用 `Document`。

```swift
@Field(key: "document")
var document: Document
```

Fluent 不支持对这些值进行严格的类型查询。你可以在查询中使用 .key 路径进行查询。MongoDB 中接受这样的参数，用以访问嵌套值。

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### 访问原始数据

要访问原始的 `MongoDatabase` 实例，将数据库实例转换为 `MongoDatabaseRepresentable`，如下所示：

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

接下来你可以使用所有 MongoKitten 的 API。
