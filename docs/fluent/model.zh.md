# 模型

模型表示存储在数据库中的表或集合中的数据。模型有一个或多个存储可编码值的字段。所有模型都有唯一的标识符。属性包装器用于表示标识符、字段和关系。

下面示例是一个具有一个字段的简单模型。请注意，模型并不描述整个数据库模式，例如约束、索引和外键。[迁移](migration.zh.md)中有对模式的定义。模型专注于表示存储在数据库模式中的数据。

```swift
final class Planet: Model {
    // 集合或者表名。
    static let schema = "planets"

    // 行星的唯一标识符
    @ID(key: .id)
    var id: UUID?

    // 行星名称。
    @Field(key: "name")
    var name: String

    // 初始化一个空的行星。
    init() { }

    // 初始化行星并设置所有属性。
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## 模式(Schema)

所有模型都需要一个静态常量 `schema` 属性。此字符串引用此模型表示的表或集合的名称。

```swift
final class Planet: Model {
    // 表或集合名
    static let schema = "planets"
}
```

在查询该模型时，数据将从名为 `planets` 的模式中获取并存储到该模式中。

!!! 建议
    模式名称通常是复数和小写的类名称。

## 标识符

所有模型都必须有一个使用 `@ID` 属性包装器定义的 `id` 属性。该字段标识模型实例的唯一性。

```swift
final class Planet: Model {
    // 该行星的唯一标识符。
    @ID(key: .id)
    var id: UUID?
}
```

默认情况下，`@ID` 属性应使用特殊 `.id` 键，对底层数据库驱动程序来说该键会被解析为合适的键。对于 SQL 是这样 `"id"`，对于 NoSQL 是 `"_id"`。

`@ID` 的类型是 `UUID` 类型。这是所有数据库驱动程序当前支持的唯一标识符值。创建模型时 Fluent 会自动生成一个 UUID 标识符。

`@ID` 有一个可选值，因为未保存的模型可能还没有标识符。要获取标识符或引发错误，请使用 `requireID` 方法获取。

```swift
let id = try planet.requireID()
```

### Exists

`@ID` 有一个 `exists` 属性表示模型是否存在于数据库中。初始化模型时，值为 `false`。保存模型后或从数据库中获取模型时，值为 `true`。该属性是可变的。

```swift
if planet.$id.exists {
    // 数据库中已经存在该模型
}
```

### 自定义标识符(Custom Identifier)

Fluent 支持使用 `@ID(custom:)` 属性包装器自定义标识符键和类型。

```swift
final class Planet: Model {
    // 行星的唯一标识符。
    @ID(custom: "foo")
    var id: Int?
}
```

上面的示例使用带有自定义键 `"foo"` 的 `@ID` 属性且标识符类型为 `Int`。这与使用自增主键的 SQL 数据库兼容，但与 NoSQL 不兼容。

自定义 `@ID` 允许用户指定如何使用 `generatedBy` 参数生成标识符。

```swift
@ID(custom: "foo", generatedBy: .user)
```

`generatedBy` 参数支持以下情况：

|生成方式|描述|
|-|-|
|`.user`|`@ID` 属性预计在保存新模型之前设置。|
|`.random`|`@ID` 值类型必须遵循 `RandomGeneratable` 协议。|
|`.database`|数据库应在保存时生成一个值。|

如果省略了 `generatedBy` 参数，Fluent 将尝试根据 `@ID` 值类型推断出适当的情况。例如，除非另有说明，否则 `Int` 将默认生成 `.database`。

## 初始化器

模型必须有一个空的初始化方法。

```swift
final class Planet: Model {
    // 初始化一个空的行星。
    init() { }
}
```

Fluent 在内部需要此方法来初始化查询返回的模型。它也用于反射。

你可能希望添加一个便利构造器初始化时接收所有属性。

```swift
final class Planet: Model {
    // 初始化行星时设置所有属性。
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

使用便利构造器将来可以更轻松地向模型添加新属性。

## 字段

模型可以具有零个或多个 `@Field` 用于存储数据的属性。

```swift
final class Planet: Model {
    // 行星名
    @Field(key: "name")
    var name: String
}
```

字段需要明确定义数据库键。这不需要与属性名称相同。

!!! 建议
    Fluent 建议使用 `蛇形命名法` 命名数据库键和 `驼峰命名法` 命名属性名称。

字段值可以是任何遵循 `Codable` 协议类型。`@Field` 支持存储嵌套结构和数组，但过滤操作受到限制。请参阅 [@Group](#group) 替代方案。

对于包含可选值的字段，请使用 `@OptionalField`。

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! 警告
    一个非可选字段如果有一个引用其当前值的 `willSet` 属性观察者，或者一个引用其 `oldValue` 属性的 `didSet` 属性观察者，将导致致命错误。

## 关系

模型可以有零个或多个关联属性，它们引用其他模型，比如 `@Parent`，`@Children` 和 `@Siblings`。参阅[关系](relations.zh.md)了解更多信息。

## 时间戳

`@Timestamp` 是 `@Field` 的一种特殊类型，它存储 `Foundation.Date`。Fluent 根据选择的触发器自动设置时间戳。

```swift
final class Planet: Model {
    // 当创建行星时。
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // 当行星最后一次更新时。
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp` 支持以下触发器。

|触发器|描述|
|-|-|
|`.create`|在将新模型实例保存到数据库时设置。|
|`.update`|将现有模型实例保存到数据库时设置。|
|`.delete`|从数据库中删除模型时设置。请参阅[软删除](#soft-delete)。|

`@Timestamp` 的日期值是可选的，初始化新模型时应该设置为 `nil`。

### 时间戳格式化

默认情况下，`@Timestamp` 将根据数据库驱动程序使用有效的 `datetime` 编码。你可以使用 `format` 参数自定义时间戳在数据库中的存储方式。

```swift
// 存储ISO 8601格式的时间戳
// 此模型最后一次更新的时间。
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

请注意，此 `.iso8601` 示例的关联迁移需要以 `.string` 格式存储。

```swift
.field("updated_at", .string)
```

下面列出了可用的时间戳格式。

|格式化|描述|类型|
|-|-|-|
|`.default`|对特定数据库使用有效 `datetime` 的编码。	|Date|
|`.iso8601`|[ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) 字符串。支持 `withMilliseconds` 参数。|String|
|`.unix`|从 Unix 纪元开始的秒数，包括分数。|Double|

你可以使用 `timestamp` 属性直接访问原始时间戳值。

```swift
// 手动设置 ISO 8601上的时间戳值
// 格式化 @Timestamp.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### 软删除(Soft Delete)

模型中添加一个使用 `.delete` 触发器的 `@Timestamp`，将启用软删除。

```swift
final class Planet: Model {
    // 当这个行星被删除的时候。
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

软删除的模型在删除后仍然存在于数据库中，但不会在查询中返回。

!!! 建议
    你可以手动将删除时间戳设置为将来的日期。这可以用作到期日期。

要强制从数据库中删除可软删除的模型，请使用 `delete` 方法的 `force` 参数。

```swift
// 从数据库中删除，即使模型是软删除的。
model.delete(force: true, on: database)
```

要恢复软删除的模型，请使用 `restore` 方法。

```swift
// 清除软删除模型的时间戳，允许查询时返回该模型。
model.restore(on: database)
```

要在查询中包含软删除的模型，请使用 `withDeleted` 方法。

```swift
// 获取所有行星，包括软删除的行星。
Planet.query(on: database).withDeleted().all()
```

## 枚举

`@Enum` 是 `@Field` 的一种特殊类型，用于将字符串可表示类型存储为原生数据库枚举。原生数据库枚举为你的数据库提供了额外的类型安全层，可能比原始枚举性能更好。

```swift
// 动物类型遵循 String，Codable 协议。
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // 将动物类型存储为原生数据库枚举。
    @Enum(key: "type")
    var type: Animal
}
```

只有当 `RawValue` 为 `String` 时，遵循 `rawrepresentation` 协议的类型才与 `@Enum` 兼容。默认情况下，由 `String` 支持的枚举满足此要求。

使用 `@OptionalEnum`，存储可选枚举。

数据库必须准备好通过迁移处理枚举。请参阅[枚举](schema.zh.md#enum)了解更多信息。

### 原始枚举

任何由遵循 `Codable` 协议的类型支持的枚举，比如 `String` 或 `Int`，都可以存储在 `@Field` 中。它将作为原始值存储在数据库中。

## 组(Group)

`@Group` 允许你将嵌套的一组字段作为单个属性存储在模型中。与存储在 `@Field` 中的可编码结构不同，`@Group` 中的字段是可查询的。Fluent 通过将 `@Group` 作为平面结构存储在数据库中来实现这一点。

要使用 `@Group`，首先定义要使用 `Fields` 协议存储的嵌套结构。这与 `Model` 非常相似，只是不需要标识符或模式名称。你可以在这里存储许多 `Model` 支持的属性，比如 `@Field`，`@Enum`，甚至另一个 `@Group`。

```swift
// 带有名称和动物类型的宠物。
final class Pet: Fields {
    // 宠物名。
    @Field(key: "name")
    var name: String

    // 宠物类型。
    @Field(key: "type")
    var type: String

    // 创建一个空的宠物。
    init() { }
}
```

创建字段定义后，你可以将其用作 `@Group` 属性的值。

```swift
final class User: Model {
    // 用户的宠物。
    @Group(key: "pet")
    var pet: Pet
}
```

`@Group` 的字段可以通过点语法访问。

```swift
let user: User = ...
print(user.pet.name) // 字符串
```

你可以像往常一样使用属性包装器上的点语法查询嵌套字段。

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

在数据库中，`@Group` 存储为一个平面结构，键由 `_` 连接。 下面是一个关于 `User` 模型在数据库中存储样子的例子。

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

模型默认遵循 `Codable` 协议。这意味着你可以通过添加 `Content` 协议将你的模型与 Vapor 的 [content API](../basics/content.zh.md) 一起使用。

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // 返回一个包含所有行星的数组。
    try await Planet.query(on: req.db).all()
}
```

当从 `Codable` 序列化时，模型属性将使用它们的变量名而不是键。关系将序列化为嵌套结构，并将包括任何预先加载的数据。

### 数据传输对象

模型默认遵循 `Codable` 协议的一致性使它变得易于使用且原型制作更容易。然而，它并不适用于每一个用例。在某些情况下，需要使用数据传输对象 (DTO)。

!!! 建议
    DTO 是一种单独的 `Codable` 类型，表示你想要编码或解码的数据结构。

接下来的示例中，`User` 模型如下所示。

```swift
// 删节的用户模型供参考。
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

DTO 的一个常见用例是实现 `PATCH` 请求。这些请求只包含应该更新的字段的值。如果缺少任何必填的字段，尝试直接从这样的请求解码 `Model` 将会失败。在下面的示例中，你可以看到一个 DTO 用于解码请求数据和更新模型。

```swift
// PATCH 请求结构 /users/:id。
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // 解码请求数据。
    let patch = try req.content.decode(PatchUser.self)
    // 从数据库中获取所需的用户。
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // 如果提供了名字，则更新它。
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // 如果提供了新的姓氏，则更新它。
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // 保存并返回用户信息
    try await user.save(on: req.db)
    return user
}
```

DTO 的另一个常见用例是自定义 API 响应的格式。下面的示例显示了如何使用 DTO 将计算字段添加到响应中。

```swift
// GET 请求响应结构 /users。
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // 从数据库获取所有用户。
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // 将每个用户转换为 GET 返回类型。
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

即使 DTO 的结构与模型的 `Codable` 协议一致性相同，将其作为一个单独的类型也有助于保持大型项目的整洁。如果你需要修改模型属性，则不必担心破坏应用程序的公共 API。你还可以考虑将 DTO 放在一个单独的包中，该包可以与你的 API 使用者共享。

由于这些原因，我们强烈建议尽可能使用 DTO，尤其是对于大型项目。

## 别名

`ModelAlias` 协议允许你在查询中唯一地标识要多次连接的模型。请参阅 [joins](query.zh.md#join) 了解更多信息。

## 保存

要将模型保存到数据库，请使用 `save(on:)` 方法。

```swift
planet.save(on: database)
```

此方法会根据模型是否已存在于数据中在内部调用 `create` 方法或者 `update` 方法。

### 创建

你可以调用 `create` 方法将新模型保存到数据库中。

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` 也可用于模型数组。这将在单个批处理/查询中将所有模型保存到数据库中。

```swift
// 批量创建示例。
[earth, mars].create(on: database)
```

!!! 警告
    模型使用 [`@ID(custom:)`](#custom-identifier) 和 `.database` 生成器(通常是自动递增的 `Int` 型)时在批处理创建后将无法访问其新创建的标识符。对于需要访问标识符的情况，在每个模型上调用 `create` 方法。

要单独创建模型数组，请使用 `map` + `flatten`。

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

如果使用 `async`/`await` 你可以使用：

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### 更新

你可以调用 `update` 方法来保存从数据库中获取的模型。

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

要更新模型数组，请使用 `map` + `flatten`。

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TOOD
```

## 查询

模型公开了一个 `query(on:)` 静态方法返回查询构建器。

```swift
Planet.query(on: database).all()
```

了解查询相关的更多信息，请参阅[查询](query.zh.md)章节。

## 查找

模型的 `find(_:on:)` 静态方法，通过标识符查找模型实例。

```swift
Planet.find(req.parameters.get("id"), on: database)
```

如果没有找到具有该标识符的模型，则返回 `nil`。

## 生命周期

模型中间件允许你监听模型的生命周期事件。支持以下生命周期事件。

|方法|描述|
|-|-|
|`create`|在创建模型之前运行。|
|`update`|在模型更新之前运行。|
|`delete(force:)`|在删除模型之前运行。|
|`softDelete`|在模型被软删除之前运行。|
|`restore`|在模型恢复之前运行(与软删除相反)。|


模型中间件使用 `ModelMiddleware` 或 `AsyncModelMiddleware` 协议声明。所有生命周期方法都有一个默认实现，因此你只需要实现所需的方法。每个方法都接受有问题的模型、对数据库的引用以及链中的下一个操作。中间件可以选择提前返回，返回失败的 future，或者调用下一个操作正常继续。

使用这些方法，你可以在特定事件完成之前和之后执行操作。在事件完成后执行操作可以通过映射从下一个响应者返回的 future 来完成。

```swift
// 名称大写的中间件示例。
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // 在创建模型之前，可以在这里修改模型。
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            //一旦行星被创建，代码将被执行。
            print ("Planet \(model.name) was created")
        }
    }
}
```

或者如果使用 `async`/`await`：

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) async throws {
        // 在创建模型之前，可以在这里修改模型。
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        //一旦行星被创建，代码将被执行。
        print ("Planet \(model.name) was created")
    }
}
```

创建中间件后，你可以使用 `app.databases.middleware` 来启用它.

```swift
// 配置模型中间件示例。
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## 数据库空间(Database Space)

Fluent 支持为模型设置空间，这允许在 PostgreSQL 模式、MySQL 数据库和多个附加的 SQLite 数据库之间对单个 Fluent 模型进行分区。在撰写本文时，MongoDB 还不支持空间。为了将模型放置在一个非默认空间中，向模型添加一个新的静态属性:

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```
Fluent 将在构建所有数据库查询时使用它。
