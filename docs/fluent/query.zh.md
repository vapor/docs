# 查询

Fluent 的查询 API 允许你从数据库中创建、读取、更新和删除模型。它支持过滤结果、连接、分块、聚合等。

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

查询构建器与单个模型类型相关联，可以使用静态 [`query`](model.zh.md#query) 方法创建。也可以通过将模型类型传递给数据库对象上的 `query` 方法来创建它们。

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! 笔记
    你必须在你的查询文件中 `import Fluent`，这样编译器就可以看到 Fluent 的辅助函数。

## All

`all()` 方法返回一个模型数组。

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

`all` 方法还支持从结果集中仅获取单个字段。

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

`first()` 方法返回单个可选模型。如果查询结果有多个模型，则仅返回第一个模型。如果没有查询到结果，则返回 `nil`。

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! 建议
    如果使用`EventLoopFuture`，此方法可以与 [`unwrap(or:)`](../basics/errors.zh.md#abort) 组合使用以返回非可选模型或抛出错误。

## Filter

`filter` 方法允许你约束结果集中包含的模型。此方法有几个重载方法。

### 值过滤

最常用的 `filter` 方法接受带有值的运算符表达式。

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

这些运算符表达式接受左侧的字段键路径和右侧的值。所提供的值必须与字段的预期值类型相匹配，并绑定到结果查询。过滤表达式是强类型的，允许使用前导点语法。

以下是所有受支持的值运算符的列表。

|运算符|描述|
|-|-|
|`==`|相等。|
|`!=`|不相等。|
|`>=`|大于或等于。|
|`>`|大于。|
|`<`|小于。|
|`<=`|小于或等于。|

### 字段过滤

`filter` 方法支持比较两个字段。

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

字段过滤器支持与[值过滤](#value-filter)相同的运算符。

### 子集过滤

`filter` 方法支持检查字段的值是否存在于给定的一组值中。

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

提供的值集可以是任何 Swift 的 `Collection`，其 `Element` 类型与字段的值类型相匹配。

以下是所有受支持的子集运算符的列表。

|运算符|描述|
|-|-|
|`~~`|值在集中。|
|`!~`|值不在集中。|

### 包含过滤

`filter` 方法支持检查字符串字段的值是否包含给定的子字符串。

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

这些运算符仅适用于具有字符串值的字段。

下面是所有受支持的包含运算符的列表。

|运算符|描述|
|-|-|
|`~~`|包含子字符串。|
|`!~`|不包含子字符串。|
|`=~`|匹配前缀。|
|`!=~`|不匹配前缀。|
|`~=`|配后后缀。|
|`!~=`|不匹配后缀。|

### 组

默认情况下，添加到查询中的所有过滤器都必须匹配。查询构建器支持创建一组过滤器且有一个过滤器必须匹配。

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

`group` 方法支持通过 `and` 或 `or` 逻辑组合过滤器。这些组可以无限嵌套。顶级过滤器可以被认为是在一个 `and` 组中。

## 聚合

查询构建器支持多种方法来对一组值执行计算，例如计数或平均值。

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

除了 `count` 之外，所有聚合方法都需要传递一个指向字段的键路径。

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

下面是所有可用聚合方法的列表。

|聚合|描述|
|-|-|
|`count`|结果计数。|
|`sum`|结果求和。|
|`average`|结果求平均数。|
|`min`|结果中最小值。|
|`max`|结果中最大值。|

除 `count` 外，所有聚合方法都将返回字段的值类型作为结果。`count` 总是返回一个整数。

## Chunk

查询构建器支持将结果集作为单独的块返回。这有助于你在处理大型数据库读取时控制内存使用。

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

根据结果的总数，所提供的闭包将被调用零次或多次。返回的每个项都是一个 `Result`，其中包含模型或试图解码数据库条目时返回的错误。

## Field

默认情况下，查询将从数据库中读取模型的所有字段。你可以选择使用 `field` 方法仅选择模型字段的子集。

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

在查询期间未选择的任何模型字段都将处于未初始化状态。尝试直接访问未初始化的字段将导致致命错误。要检查是否设置了模型的字段值，请使用 `value` 属性。

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

查询构建器的 `unique` 方法只返回不同的结果（去重）。

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` 在获取带有 `all` 的单个字段时特别有用。但是，你也可以使用 [`field`](#field) 方法选择多个字段。由于模型标识符总是唯一的，所以在使用 `unique` 时应避免选择它们。

## Range

查询构建器的 `range` 方法允许你使用 Swift ranges 选择结果的子集。

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

范围值是从零开始的无符号整数。了解有关 [Swift ranges](https://developer.apple.com/documentation/swift/range) 的更多信息。

```swift
// Skip the first 2 results.
.range(2...)
```

## Join

查询构建器的 `join` 方法允许你在结果集中包含另一个模型的字段。可以将多个模型加入到你的查询中。

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

`on` 参数接受两个字段之间的相等表达式。其中一个字段必须已经存在于当前结果集中。另一个字段必须存在于被连接的模型上。这些字段必须具有相同的值类型。

大多数查询构建器方法，如 `filter` 和 `sort` 都支持连接模型。如果一个方法支持连接模型，它将接受连接模型类型作为第一个参数。

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

使用连接的查询仍将返回基本模型的数组。要访问连接模型，请使用 `joined` 方法。

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### 模型别名

模型别名允许你多次将同一模型加入查询。要声明模型别名，请创建一个或多个遵循 `ModelAlias`协议的类型。

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

这些类型引用通过 `model` 属性别名的模型。创建之后，就可以像在查询构建器中使用普通模型一样使用模型别名。

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

所有模型字段都可以通过 `@dynamicMemberLookup` 通过模型别名类型访问。

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

查询构建器支持使用 `update` 方法一次更新多个模型。

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` 支持 `set`、`filter` 和 `range` 方法。

## Delete

查询构建器支持使用 `delete` 方法一次删除多个模型。

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` 支持 `filter` 方法。

## Paginate

Fluent 的查询 API 支持使用 `paginate` 方法进行自动结果分页。

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

`paginate(for:)` 方法将使用请求 URI 中可用的 `page` 和 `per` 参数来返回所需的结果集。关于当前页面和结果总数的元数据包含在 `metadata` 键中。

```http
GET /planets?page=2&per=5 HTTP/1.1
```

上述请求将产生如下结构的响应。

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

页码从`1`开始。你也可以手动请求页面。

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

查询结果可以使用 `sort` 方法按字段值排序。

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

如果出现并列相等，可以添加额外的排序作为后备。回退将按照它们添加到查询构建器的顺序使用。

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
