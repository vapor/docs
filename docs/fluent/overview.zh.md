# Fluent

Fluent 是服务于 Swift 的 [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) 框架，它利用 Swift 的强类型特性为你的数据库操作提供简易使用的接口。使用 Fluent 的核心是创建用于表示数据库中数据结构的模型，然后通过这些模型来执行创建、读取、更新和删除等操作，而不必编写原始的 SQL 查询语句。

## 配置

当在终端使用 `vapor new` 命令来创建项目时，对于包含询问 Fluent 的问答选项，请选择 'Yes'，并选择要使用的数据库驱动程序，之后将自动生成依赖项添加到你的新项目以及配置示例代码。

### 现有项目

如果你想为现有项目添加 Fluent，你需要在 [package](../getting-started/spm.zh.md) 中添加两个依赖项：

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- 你选择的一个（或多个）Fluent 驱动程序

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

一旦这些包被添加为依赖项，你就可以在 `configure.swift` 中使用 `app.databases` 配置你的数据库。

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

下面的每个 Fluent 驱动程序都有更具体的配置说明。

### 驱动

Fluent 目前有四个官方支持的驱动程序。你可以在 GitHub 上搜索标签 [`fluent-driver`](https://github.com/topics/fluent-driver) 来获取官方和第三方 Fluent 数据库驱动程序的完整列表。

#### PostgreSQL

PostgreSQL 是一个开源的、符合标准的 SQL 数据库。 它很容易在大多数云托管提供商上进行配置。这是 Fluent **推荐**的数据库驱动程序。

要使用 PostgreSQL，请将以下依赖项添加到 package 中。

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

添加依赖项后，在 `configure.swift` 中使用 `app.databases.use` 配置数据库的凭证。 

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(.postgres(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .psql)
```

还可以从数据库连接字符串解析凭证。

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite 是一种开源的，嵌入式 SQL 数据库。它的简单性使其成为原型设计和测试的理想选择。

要使用 SQLite，请将以下依赖项添加到 package 中。

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

添加依赖项后，在 `configure.swift` 中使用 `app.databases.use` 配置数据库的凭证。 

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

你还可以配置 SQLite 将数据库临时存储在内存中。

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

如果使用内存中的数据库，请确保使用 `--auto-migrate` 将 Fluent 设置为自动迁移，或者在添加迁移后运行 `app.autoMigrate()`。

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! 提示
    SQLite 配置自动对所有创建的连接启用外键约束，但不会更改数据库本身的外键配置。直接删除数据库中的记录可能会违反外键约束和触发器。

#### MySQL

MySQL 是一种流行的开源 SQL 数据库。许多云托管服务提供商都提供它。该驱动程序还支持 MariaDB。

要使用 MySQL，请将以下依赖项添加到你的 package 中。

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

添加依赖项后，在 `configure.swift` 中使用 `app.databases.use` 配置数据库的凭证。

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

你还可以从数据库连接字符串中解析凭证。

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

要配置不涉及 SSL 证书的本地连接，你应该禁用证书验证。例如，如果连接到 Docker 中的 MySQL 8 数据库，你可能需要这样做。

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! 警告
    不要在生产中禁用证书验证。你应该向 `TLSConfiguration` 提供一个证书以进行验证。

#### MongoDB

MongoDB 是一种流行的无模式 NoSQL 数据库，专为程序员设计。该驱动程序支持 3.4 及更高版本的所有云托管提供商和自托管安装。

!!! 注意
    该驱动程序由一个名为 [MongoKitten](https://github.com/OpenKitten/MongoKitten) 的社区创建和维护的 MongoDB 客户端提供支持。MongoDB 维护着一个官方客户端，[mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver) 以及 Vapor 集成的 [mongodb-vapor](https://github.com/mongodb/mongodb-vapor)。

要使用 MongoDB，请将以下依赖项添加到你的 package 中。

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

添加依赖项后，在 `configure.swift` 中使用 `app.databases.use` 配置数据库的凭证。

要进行连接，请传递标准 MongoDB [连接 URI 格式](https://docs.mongodb.com/master/reference/connection-string/index.html)的连接字符串。


```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Models

模型表示数据库中固定的数据结构，如表或集合。模型有一个或多个存储可编码值的字段。所有模型都有一个唯一的标识符。属性包装器用于表示标识符和字段以及后面提到的更复杂的映射。看看下面这个代表星系的模型。

```swift
final class Galaxy: Model {
    // 表或集合名。
    static let schema = "galaxies"

    // 星系唯一标识符。
    @ID(key: .id)
    var id: UUID?

    // 星系名称。
    @Field(key: "name")
    var name: String

    // 创建一个空的星系。
    init() { }

    // 创建一个新的星系并设置所有属性。
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

要创建一个新的模型，请创建一个遵循 `Model` 协议的类。

!!! 建议
    建议将模型类标记为 `final`，以提高性能并简化一致性要求。

`Model` 协议第一个要求是静态字符串 `schema`。

```swift
static let schema = "galaxies"
```

此属性告诉 Fluent 模型对应于哪个表或集合。这可以是数据库中已经存在的表，也可以是你将通过 [migration](#migrations) 创建的表。schema 通常是 `snake_case` 复数形式.

### Identifier

下一个要求是一个名为 `id` 的标识符字段。

```swift
@ID(key: .id)
var id: UUID?
```

该字段必须使用 `@ID` 属性包装器。Fluent 建议使用 `UUID` 和 特殊 `.id` 字段键，因为它兼容 Fluent 的所有驱动程序。

如果要使用自定义 ID 键或类型， 请使用 [`@ID(custom:)`](model.zh.md#custom-identifier) 重载。

### Fields

添加标识符之后，你可以添加任意多的字段来存储额外的信息。在本例中，唯一的附加字段是星系的名称。

```swift
@Field(key: "name")
var name: String
```

对于简单字段，使用 `@Field` 属性包装器。 与 `@ID` 一样，`key` 参数指定数据库中字段的名称。这在数据库字段命名约定可能与 Swift 不同的情况下特别有用，例如，使用 `snake_case` 而不是 `camelCase`。

接下来，所有模型都需要一个空的 init。这允许 Fluent 创建模型的新实例。

```swift
init() { }
```

最后，你可以为模型添加一个方便的 init 来设置其所有属性。

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

如果你向模型添加新属性，则使用便捷的 inits 尤其有用，因为如果 init 方法发生更改，你可能会收到编译时错误。

## Migrations

如果数据库使用预定义的模式，如 SQL 数据库，则需要进行迁移，以便为模型准备数据库。迁移对于用数据填充数据库也很有用。要创建一个迁移，定义一个符合 `migration` 或 `AsyncMigration` 协议的新类型。看看下面对之前定义的 `Galaxy` 模型的迁移。

```swift
struct CreateGalaxy: AsyncMigration {
    // 为存储 Galaxy 模型准备数据库。
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // 可选地恢复 prepare 方法中所做的更改。
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

该 `prepare` 方法用于准备数据库以存储 `Galaxy` 模型。

### Schema

在此方法中，`database.schema(_:)` 用来创建一个新的 `schembuilder`。然后，在调用 `create()` 创建模式之前，将一个或多个 `字段` 添加到构建器中。

添加到构建器的每个字段都有一个名称、类型和可选约束。

```swift
field(<name>, <type>, <optional constraints>)
```

使用 Fluent 推荐的默认值，有一个方便的 `id()` 方法可以添加 `@ID` 属性。

恢复迁移会撤消在 prepare 方法中所做的任何更改。在这种情况下，这意味着删除 Galaxy 的模式。

一旦定义了迁移，你必须将迁移添加到 `configure.swift` 中的 `app.migrations` 来告知 Fluent 。

```swift
app.migrations.add(CreateGalaxy())
```

### Migrate

要运行迁移，在命令行中调用 `vapor run migrate` 或者添加 `migrate` 参数到 Xcode 的运行方案中。


```
$ vapor run migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Querying

现在你已经成功地创建了一个模型并迁移了你的数据库，你可以进行第一次查询了。

### All

看看下面的路由，它将返回一个包含数据库中所有星系的数组。

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

为了在路由闭包中直接返回 Galaxy，添加遵循 `Content` 协议

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` 用于为模型创建新的查询构建器。`req.db` 是对你的应用程序的默认数据库的引用。 最后， `all()` 返回存储在数据库中的所有模型。

如果你编译并运行项目并请求 `GET /galaxies`， 你会看到返回一个空数组。 让我们添加一个创建新星系的路由。

### Create


根据 RESTful 约定，使用 `POST /galaxies` 端点创建新星系。 由于模型是可编码的，因此你可以直接从请求正文中解码星系。

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! 也可以看看
    有关解码请求正文的更多信息，请参阅 [内容 → 概述](../basics/content.zh.md)。

一旦有了模型的实例，调用 `create(on:)` 就会将模型保存到数据库中。这将返回一个 `EventLoopFuture<Void>` 表示保存已完成的信号。保存完成后，使用 `map` 返回新创建的模型。

如果你正在使用 `async/await` 你可以这样编写代码：

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

在这种情况下，异步版本不会返回任何内容，但会在保存完成后返回。

构建并运行项目并发送以下请求。

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

你应该以标识符作为响应来取回创建的模型。

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

现在，如果你 `GET /galaxies` 再次查询，你应该会看到数组中返回了新创建的星系。


## Relations

没有恒星的星系算什么! 让我们通过在 `Galaxy` 和新的 `Star` 模型之间添加一对多关系来快速了解一下 `Fluent` 强大的关系特性。

```swift
final class Star: Model, Content {
    // 表或集合名。
    static let schema = "stars"

    // Star 唯一标识符。
    @ID(key: .id)
    var id: UUID?

    // Star 名称
    @Field(key: "name")
    var name: String

    // 引用这颗恒星所在的星系。
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // 创建一个空的 Star。
    init() { }

    // 创建一个新的 Star，设置所有属性。
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

除了 `@Parent` 新字段类型，新的 `Star` 模型与 `Galaxy` 非常相似。

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

parent 属性是存储另一个模型标识符的字段。持有引用的模型称为`子`，被引用的模型称为`父`。这种类型的关系也称为“一对多”。该 `key` 参数指定了用于在数据库中存储父键的字段名称。

在 init 方法中，父标识符使用 `$galaxy`。

```swift
self.$galaxy.id = galaxyID
```

通过为父属性的名称添加前缀 `$`，你可以访问底层属性包装器。这是访问 `@Field` 存储实际标识符值的内部所必需的。

!!! 也可以看看
    查看 Swift Evolution 关于属性包装器的提案以获得更多信息:[[SE-0258] Property Wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)

接下来，创建一个迁移以准备数据库来处理 `Star`。

```swift
struct CreateStar: AsyncMigration {
    // 为存储 Star 模型准备数据库。
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // 可选地恢复 prepare 方法中所做的更改。
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

这与星系的迁移基本相同，除了存储父星系标识符的额外字段。

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

该字段指定了一个可选的约束，告诉数据库该字段的值引用了 “galaxies” 模式中的字段 “id”。这也称为外键，有助于确保数据完整性。

一旦迁移创建完成，将其添加到 `app.migrations` 中的 `CreateGalaxy`之后。

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

因为迁移是按顺序运行的，而且 `CreateStar` 引用了星系模式，所以顺序是很重要的。最后，[运行迁移](#migrate)准备数据库。

添加创建新恒星的路由。

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```
使用下面的HTTP请求创建一个引用之前创建的星系的新星。

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

你应该看到新创建的星星返回一个惟一标识符。

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

现在让我们看看如何利用 Fluent 的预加载功能自动返回 `GET /galaxies` 路由中的星系恒星。将以下属性添加到 `Galaxy`模型中。

```swift
// 这个星系的所有恒星。
@Children(for: \.$galaxy)
var stars: [Star]
```

`@Children` 属性包装器与 `@Parent`相反。它采用子 `@Parent` 字段的键路径作为 `for`参数。它的值是一个子模型数组，因为可能存在零个或多个子模型。星系的迁移不需要改变，因为这种关系所需的所有信息都存储在`恒星`上。


### Eager Load

现在关系已经完成，你可以在查询构建器上使用 `with` 方法来自动获取和序列化星系-星型关系。

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

一个指向 `@Children` 关系的键路径被传递给 `with`，告诉 Fluent 在所有结果模型中自动加载这个关系。创建并运行另一个请求到 `GET /galaxies`。你现在应该看到响应中自动包含星星。

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## 查询日志

Fluent 驱动程序在日志级别为 debug 时会记录生成的 SQL 语句。一些驱动程序，如 FluentPostgreSQL，允许在配置数据库时进行配置。

要设置日志级别，请在 **configure.swift**（或你设置应用程序的位置）文件中添加：

```swift
app.logger.logLevel = .debug
```

这会将日志级别设置为 debug。下次构建和运行应用程序时，Fluent 生成的 SQL 语句会在控制台输出。

## 下一步

祝贺你创建了第一个模型和迁移，并执行了基本的创建和读取操作。要了解更多关于所有这些特性的深入信息，请查看 Fluent 指南中的相应部分。