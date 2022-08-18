# 模式

Fluent 的模式 API 允许你以编程方式创建和更新数据库模式。它通常与[迁移](migration.zh.md)一起使用，以准备数据库，供[模型](model.zh.md)使用。

```swift
// Fluent 模式 API 示例
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

要创建 `SchemaBuilder`，请使用数据库上的 `schema` 方法。传入要改变的表或集合的名称。如果你正在编辑模型的模式，请确保此名称与模型的 [`schema`](model.zh.md#schema) 相匹配。

## 操作 

模式 API 支持创建、更新和删除模式。每个操作都支持 API 可用方法的一个子集。

### 创建

调用 `create()` 方法在数据库中创建一个新表或集合。支持定义新字段和约束的所有方法。忽略更新或删除的方法。

```swift
// 创建模式示例。
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

如果具有所选名称的表或集合已存在，则会引发错误。要忽略这一点，请使用 `.ignoreExisting()` 方法。

### 更新

调用 `update()` 方法更新数据库中的现有表或集合。支持创建、更新和删除字段和约束的所有方法。

```swift
// 更新模式示例。
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### 删除

调用 `delete()` 方法从数据库中删除现有的表或集合。不支持其他方法。

```swift
// 删除模式示例。
database.schema("planets").delete()
```

## 字段(Field)

创建或更新模式时可以添加字段。

```swift
// 增加一个新字段。
.field("name", .string, .required)
```

第一个参数是字段的名称。这应该与关联模型属性上使用的键匹配。第二个参数是字段的[数据类型](#data-type)。最后，可以添加零个或多个[约束](#field-constraint)。

### 数据类型(Data Type)

下面列出了支持的字段数据类型。

|数据类型|Swift 类型|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (recommended)|
|`.time`|`Date` (omitting day, month, and year)|
|`.date`|`Date` (omitting time of day)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|See [dictionary](#dictionary)|
|`.array`|See [array](#array)|
|`.enum`|See [enum](#enum)|

### 字段约束(Field Constraint)

下面列出了支持的字段约束。

|字段约束|描述|
|-|-|
|`.required`|不允许 `nil` 值。|
|`.references`|要求此字段的值与引用的模式中的值匹配。参见[外键](#foreign-key)。|
|`.identifier`|表示主键。参见[标识符](#identifier)|

### 标识符(Identifier)

如果你的模型使用标准的 `@ID` 属性，你可以使用 `id()` 方法来创建它的字段。使用特殊的 `.id` 字段键和 `UUID` 值类型。

```swift
// 添加字段默认标识符。
.id()
```

对于自定义标识符类型，你需要手动指定该字段。

```swift
// 添加字段自定义标识符。
.field("id", .int, .identifier(auto: true))
```

`identifier` 约束可用于单个字段并表示主键。`auto` 标志确定数据库是否应自动生成此值。

### 更新字段

你可以使用 `updateField` 更新字段的数据类型。

```swift
// 更新字段的类型为 `double`。
.updateField("age", .double)
```

参阅[进阶](advanced.zh.md#sql)部分了解高级模式的更多信息。

### 删除字段

您可以使用 `deleteField` 方法从模式中删除字段。


```swift
// 删除 "age" 字段。
.deleteField("age")
```

## 约束

可以在创建或更新模式时添加约束。与[字段约束](#field-constraint)不同，顶级约束可以影响多个字段。
 
### 唯一(Unique)

唯一约束要求一个或多个字段中没有重复值。

```swift
// 不允许有重复的电子邮件地址。
.unique(on: "email")
```

如果约束了多个字段，则每个字段的值的特定组合必须是唯一的。

```swift
// 不允许用户有相同的全名。
.unique(on: "first_name", "last_name")
```

要删除唯一约束，使用 `deleteUnique` 方法。

```swift
// 删除重复的电子邮件约束。
.deleteUnique(on: "email")
```

### 约束名(Constraint Name)

默认情况下，Fluent 将生成唯一的约束名称。但是，你可能希望传递自定义约束名称。你可以使用 `name` 参数来实现。

```swift
// 不允许重复的电子邮件地址。
.unique(on: "email", name: "no_duplicate_emails")
```

要删除命名约束，必须使用 `deleteConstraint(name：)` 方法。

```swift
// 删除重复的电子邮件约束。
.deleteConstraint(name: "no_duplicate_emails")
```

## 外键(Foreign Key)

外键约束要求字段的值与引用字段中的值匹配。这对于防止保存无效数据很有用。外键约束可以作为字段或顶级约束添加。

要将外键约束添加到字段，请使用 `.references` 方法。

```swift
// 字段添加外键约束示例。
.field("star_id", .uuid, .required, .references("stars", "id"))
```

上述约束要求 ”star_id“ 字段中的所有值必须与 Star 的 “id” 字段中的一个值匹配。

可以使用 `foreignKey` 将相同的约束添加为顶级约束。

```swift
// 添加顶级外键约束示例。
.foreignKey("star_id", references: "stars", "id")
```

与字段约束不同，可以在模式更新中添加顶级约束。它们也可以被[命名](#Constraint-Name)。

外键约束支持可选 `onDelete` 和 `onUpdate` 操作。

|外键操作|描述|
|-|-|
|`.noAction`|防止外键违规(默认)。|
|`.restrict`|与 `.noAction` 相同。|
|`.cascade`|通过外键传播删除。|
|`.setNull`|如果引用被破坏，则将字段设置为空。|
|`.setDefault`|如果引用被破坏，则将字段设置为默认值。|

下面是使用外键操作的示例。

```swift
// 添加顶级外键约束示例。
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! 警告
    外键操作仅发生在数据库中，绕过 Fluent。这意味着模型中间件和软删除之类的东西可能无法正常工作。

## 字典(Dictionary)

字典数据类型能够存储嵌套的字典值。这包括遵循 `Codable` 协议的结构和具有 `Codable` 值的 Swift 字典。

!!! 注意
    Fluent 的 SQL 数据库驱动程序将嵌套字典存储在 JSON 列中。

采用以下 `Codable` 结构。

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

由于这个 `Pet` 遵循 `Codable` 协议，它可以存储在 `@Field` 中。

```swift
@Field(key: "pet")
var pet: Pet
```

此字段可以使用 `.dictionary(of:)` 数据类型存储。

```swift
.field("pet", .dictionary, .required)
```

由于 `Codable` 类型是异构字典，所以我们不指定 `of` 参数。

如果字典值是同类的，例如 `[String: Int]`，则 `of` 参数将指定值类型。

```swift
.field("numbers", .dictionary(of: .int), .required)
```

字典键必须始终是字符串。

## 数组(Array)

数组数据类型能够存储嵌套数组。这包括包含 `Codable` 值的 Swift 数组和使用无键容器的 `Codable` 类型。

以下面的 `@Field` 为例，它存储字符串数组。

```swift
@Field(key: "tags")
var tags: [String]
```

该字段可以使用 `.array(of：)` 数据类型存储。

```swift
.field("tags", .array(of: .string), .required)
```

由于数组是同质的，所以我们指定 `of` 参数。

可编码的 Swift `数组` 将始终具有同质的值类型。将异构值序列化为无键容器的自定义 `Codable` 类型是例外，应使用 `.array` 数据类型。

## 枚举(Enum)

枚举数据类型能够以原生地方式存储字符串支持的 Swift 枚举。数据库枚举为数据库提供了额外的类型安全层，并且可能比原始枚举的性能更好。

要定义原生数据库枚举，请使用 `Database` 的 `enum` 方法。使用 `case` 定义枚举的每种情况。

```swift
// 创建枚举示例。
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

创建枚举后，你可以使用 `read()` 方法为模式字段生成数据类型。

```swift
// 读取枚举并使用它定义新字段的示例。
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// 或者

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

要更新枚举，请调用 `update()` 方法。可以从现有枚举中删除案例。

```swift
// 更新枚举示例。
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

要删除枚举，请调用 `delete()` 方法。

```swift
// 删除枚举示例。
database.enum("planet_type").delete()
```

## 模型耦合

有目的地将模式构建与模型分离。与查询构建不同，模式构建不使用键路径，并且完全是字符串类型。这一点很重要，因为模式定义，尤其是为迁移编写的模式定义，可能需要引用不再存在的模型属性。

为了更好地理解这一点，请查看以下示例迁移。

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

让我们假设这个迁移已经被推送到生产环境中。现在假设我们需要对 User 模型进行以下更改。

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

我们可以通过以下迁移进行必要的数据库模式调整。

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("name")
            .field("first_name", .string)
            .field("last_name", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

请注意，要使此迁移起作用，我们需要能够同时引用已删除的 `name` 字段和新的 `firstName` 和 `lastName` 字段。此外，原来的 `UserMigration` 应该继续有效。这在键路径上是不可能做到的。

## 设置模型空间

要定义[模型空间](model.zh.md#database-space)，请在创建表时将空间传递给 `schema(_：space：)`。例如。

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```