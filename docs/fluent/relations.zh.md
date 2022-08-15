# 关系

Fluent 的[模型 API](model.zh.md) 可帮助你通过关系创建和维护模型之间的引用。支持三种类型的关系：

- [Parent](#parent) / [Child](#optional-child) (一对一)
- [Parent](#parent) / [Children](#children) (一对多) 
- [Siblings](#siblings) (多对多) 

## Parent

`@Parent` 关系存储对另一个模型 `@ID` 属性的引用。

```swift
final class Planet: Model {
    // parent 关系示例。
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` 包含一个名为 `id` 的 `@Field` 字段，用于设置和更新关系。

```swift
// 设置 parent 关系的 id 字段
earth.$star.id = sun.id
```

举个例子，`Planet` 模型初始化如下所示：

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

`key` 参数定义了用于存储父标识符的字段键。假设 `Star` 有一个 `UUID` 标识符，这个 `@Parent` 关系与下面的[字段定义](schema.zh.md#field)兼容。

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

请注意，[`.references`](schema.zh.md#field-constraint)约束是可选的。了解更多信息，请参见[模式](schema.zh.md)章节。

### Optional Parent

`@OptionalParent` 关系存储对另一个模型 `@ID` 属性的可选引用。它的工作方式类似于 `@Parent` 但允许关系为 `nil`。

```swift
final class Planet: Model {
    // 可选 parent 关系示例。
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

字段定义与 `@Parent` 类似，但 `.required` 约束应省略。

```swift
.field("star_id", .uuid, .references("star", "id"))
```

## Optional Child

`@OptionalChild` 属性在两个模型之间创建了一对一的关系。它不在根模型上存储任何值。

```swift
final class Planet: Model {
    // 可选 child 关系示例。
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

`for` 参数接受一个指向引用根模型的 `@Parent` 或 `@OptionalParent` 关系的键路径。

可以使用 `create` 方法将一个新模型添加到这个关系中。

```swift
// 添加新模型到关系中。
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

这将自动为子模型上设置父 id。

由于此关系不存储任何值，因此根模型不需要数据库模式条目。

关系的一对一性质应该在子模型的模式中使用 `.unique` 对引用父模型的列的约束来强制执行。

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // 唯一性约束示例。
    .unique(on: "planet_id")
    .create()
```

!!! 警告
    从客户端模式中省略父 ID 字段的唯一性约束可能会导致不可预知的结果。如果没有唯一性约束，则子表可能最终包含任何给定父表的多个子行；在这种情况下，`@OptionalChild` 属性一次只能访问一个子级，无法控制加载哪个子级。如果你可能需要为任何给定的父级存储多个子行，请使用 `@Children`。

## Children

`@Children` 属性在两个模型之间创建一对多关系。它不在根模型上存储任何值。

```swift
final class Star: Model {
    // children 关系示例。
    @Children(for: \.$star)
    var planets: [Planet]
}
```

`for` 参数接受引用根模型的 `@Parent` 或 `@OptionalParent` 关系的键路径。在本例中，我们引用了前面[示例](#parent)中的 `@Parent`关系。

可以使用 `create` 方法将新模型添加到此关系中

```swift
// 添加新模型到关系中。
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

这将自动为子模型上设置父 id。

由于此关系不存储任何值，因此不需要数据库模式条目。

## Siblings

`@Siblings` 属性在两个模型之间创建多对多关系。它通过称为 pivot 的三级模型来实现这一点。

让我们看一个 `Planet` 和 `Tag` 之间的多对多关系的例子。

```swift
// pivot 模型示例。
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
    }
}
```

Pivots 是包含两个 `@Parent` 关系的一般模型。一个用于每个要关联的模型。如果需要，可以将其他属性存储在 pivot 上。

向 pivot 模型添加 [unique](schema.zh.md#unique) 约束有助于防止冗余条目。请参阅[模式](schema.zh.md)了解更多信息。

```swift
// 不允许重复的关系。
.unique(on: "planet_id", "tag_id")
```

创建 pivot 后，使用该 `@Siblings` 属性创建关系。

```swift
final class Planet: Model {
    // siblings 关系示例。
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

`@Siblings` 属性需要三个参数：

- `through`：pivot 模型的类型。
- `from`：从 pivot 到引用根模型的父关系的键路径。
- `to`：从 pivot 到引用相关模型的父关系的键路径。

相关模型上的反向 `@Siblings` 属性完成了这种关系。

```swift
final class Tag: Model {
    // siblings 关系示例。
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

`@Siblings` 属性具有从关系中添加和删除模型的方法。

使用 `attach` 方法向关系添加一个模型。这将自动创建并保存 `pivot` 模型。

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// 添加模型到关系中。
try await earth.$tags.attach(inhabited, on: database)
```

附加单个模型时，你可以使用 `method` 参数选择是否在保存之前检查关系。

```swift
// 只有当关系不存在时才附加。
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

使用 `detach` 方法从关系中删除一个模型。这将删除相应的 pivot 模型。

```swift
// 从关系中删除模型。
try await earth.$tags.detach(inhabited, on: database)
```

你可以使用 `isAttached` 方法检查模型是否相关。

```swift
// 检查模型是否有关。
earth.$tags.isAttached(to: inhabited)
```

## Get

使用 `get(on:)` 方法获取关系的值。

```swift
// 获取太阳系的行星。
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// 或者

let planets = try await sun.$planets.get(on: database)
print(planets)
```

使用 `reload` 参数来选择是否应该重新从数据库中获取已经加载的关系。

```swift
try await sun.$planets.get(reload: true, on: database)
```

## 查询

在关系上使用 `query(on:)` 方法为相关模型创建查询构建器。

```swift
// 获取太阳系中的行星，且命名以 M 开头。
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

请参阅[查询](query.zh.md)了解更多信息。

## Eager Loading

当从数据库中获取模型关系时，可以使用 Fluent 的查询构建器预加载模型关系。这被称为预加载，允许你同步访问关系，而不需要首先调用[`load`](#lazy-eager-loading) 方法或者 [`get`](#get)方法。

要预加载关系，请将关系的键路径传递给查询构建器上 `with` 方法。

```swift
// 预加载示例。
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` 在这里是同步访问的
        // 因为它已经预加载了。
        print(planet.star.name)
    }
}

// 或者

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` 在这里是同步访问的
    // 因为它已经预加载了。
    print(planet.star.name)
}
```


在上面的例子中，名为 `star` 的 [`@Parent`](#parent)关系的键路径被传递给了 `with` 方法。这将导致查询构建器在所有行星加载后执行额外查询，以获取它们相关的所有恒星。然后通过 `@Parent` 属性同步访问恒星。

无论返回多少个模型，每个预加载的关系只需要一个额外的查询。只有使用查询构建器的 `all` 和 `first` 方法才能立即加载。

### Nested Eager Load

查询构建器的 `with` 方法允许你在被查询的模型上预先加载关系。但是，你也可以在相关模型上预先加载关系。

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` 在这里是同步访问的
    // 因为它已经被预加载
    print(planet.star.galaxy.name)
}
```

`with` 方法接受一个可选闭包作为第二个参数。这个闭包接受所选关系的预加载构建器。预加载嵌套深度没有限制。

## Lazy Eager Loading

如果你已经检索了父模型，并且你想加载它的一个关系，你可以使用 `load(on:)` 方法来实现这个目的。这将从数据库中获取相关的模型，并允许它作为本地属性访问。

```swift
planet.$star.load(on: database).map {
    print(planet.star.name)
}

// Or

try await planet.$star.load(on: database)
print(planet.star.name)
```

要检查是否已加载关系，请使用 `value` 属性。

```swift
if planet.$star.value != nil {
    // 关系已被加载。
    print(planet.star.name)
} else {
    // 关系还未加载。
    // 试图访问 planet.star 将会失败。
}
```

如果你已经在变量中拥有相关模型，则可以使用上述的 `value` 属性手动设置关系。

```swift
planet.$star.value = star
```

这会将相关模型附加到父模型，就好像它是预先加载或延迟加载的，而无需额外的数据库查询。
