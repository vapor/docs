---
currentMenu: fluent-query
---

# Query

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

每次与 Fluent 交互强大的地方是 `Query` 类。无论你是使用 `.find()` 获取一个 model，还是保存 model 到数据库中，都与 `Query` 有关。

## Querying Models

任何实现了 [Model](model.md) 协议的类型都有一个静态的 `.query()` 方法。

```swift
let query = try User.query()
```

这就是如何创建 `Query<User>`。

### No Database

`.query()` 方法需要使用 `try` 调用，因为如果 model 的静态属性 database 没有被设置，它将会抛出一个错误。

```swift
User.database = drop.database
```

This property is set automatically when you pass the Model as a preparation.
> 译者注： 我理解意思是： 如果你的 Model 使用 preparation，这个值将会被自动设置。

## Filter

大部分查询的类型都只包含过滤后的数据。

```swift
let smithsQuery = try User.query().filter("last_name", "Smith")
```

这是为 query 添加 `equals` 过滤条件的一个简写方式。如你所见，query 能够被级联在一起。

除了 `equals`， `Filter.Comparison` 还有许多其他的类型。

```swift
let over21 = try User.query().filter("age", .greaterThanOrEquals, 21)
```

### Scope

Filter 可以在 set 上运行。

```swift
let coolPets = try Pet.query().filter("type", .in, ["Dog", "Ferret"])
```

这里只有 Pet 类型 为 Dog _或者_ Ferret 的会被返回。与这个相反的是 `notIn`。


### Contains

部分匹配 filter 也可以被使用。

```swift
let statesWithNew = try State.query().filter("name", contains: "New")
```

## Retrieving

这里有两个方法运行 query。

### All

所有的匹配 entity 都将会被获取返回。这个将会返回 `[Model]` 数组，在我们例子中是 user。

```swift
let usersOver21 = try User.query().filter("age", .greaterThanOrEquals, 21).all()
```

### First

第一个匹配的 entity 会被获取返回。这个将会返回一个可选的（optional） `Model?`，在我们例子中是 user。

```swift
let firstSmith = try User.query().filter("last_name", "Smith").first()
```

## Union

其他模型可以连接到（joined onto）您的查询，以帮助过滤数据。这个结果仍然是创建 query 的类型的 `[Model]` 或者 `Model?`。

```swift
let usersWithCoolPets = try User.query()
	.union(Pet.self)
	.filter(Pet.self, "type", .in, ["Dog", "Ferret"])
```

这里 `User` collection 联合了 `Pet` collection。只有 `Pet` 类型中为 dog 或者 ferret 的 `User` 会返回。

### Keys

`union` 方法假设查询的 table 有一个被关联的 table 的外键。

上面例子中的 user 和 pet 假设有如下的 schema。

```
users
- id
- pet_id
pets
- id
```

可以通过重写 `union` 自定义外键。

## Raw Queries

由于 Fluent 关注在与 model 的交互，所以每个 Query 要求关联一个 model 类型。如果你想要使用不基于 model 的原始的数据库查询，你可以使用基础的 Fluent Driver 去做。

```swift
if let mysql = drop.database?.driver as? MySQLDriver {
    let version = try mysql.raw("SELECT @@version")
}
```
