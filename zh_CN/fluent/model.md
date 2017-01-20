---
currentMenu: fluent-model
---

# Model

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`Model` 是应用程序中任何 model 的基础协议，尤其是那些想要持久化的 model。


> `Model` 仅在Vapor中可用，在 Fluent 等价的是 `Entity`

## Example

让我们创建一个简单的 `User` model。

```swift
final class User {
    var name: String

    init(name: String) {
        self.name = name
    }
}
```

实现 `Model` 协议的第一步是导入 Vapor 和 Fluent。

```swift
import Vapor
import Fluent
```

然后添加协议到你的类上。

```swift
final class User: Model {
    ...
}
```

编译器将会提示你，协议中有些方法需要实现。

### ID

第一个被要求的属性是 identifier。当 model 从数据库中被获取的时候，这个属性将会包含 model 的 identifier 值。如果它为 nil，它将在 model 被保存的时候设置。

```swift
final class User: Model {
    var id: Node?
    ...
}
```

### Node Initializable

下一个要求是需要提供从持久化数据中创建 model 的方法。model 使用 `NodeInitializable` 实现它。

```swift
final class User: Model {
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }
    ...
}
```

`id` 和 `name` 两个 key 是我们希望的在数据库中命名的 column 或者 field （列或者字段）。`extract` 方法调用的时候使用了 `try`，因为如果值不存在或者是一个错误的类型，将会抛出错误。

### Node Representable

现在我们已经初始化完成了 model，我们需要展示如何保存回数据库。 model 使用 `NodeRepresentable` 实现它

```swift
final class User: Model {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name
        ])
    }
    ...
}
```

当 `User` 被保存的时候，`makeNode()` 方法将会被调用，并且返回的 `Node` 将会被存储到数据库中。`id` 和 `name` 两个 key 是我们希望的在数据库中命名的 column 或者 field （列或者字段）。

> 大多数情况下，你都不需要关注 `makeNode(context:)` 方法中的 `context` 参数。它是协议的一部分，允许在更高级或特定场景中的提高可扩展性。

## Preparations

有些数据库，例如 MySQL，需要为新的 schema 做准备。在 MySQL 这个就意味着创建一个新的 table。Preparations 也可以用于迁移，可以用于修改已经被创建的 schema。

### Prepare

我们假设使用的是 SQL 数据库。为我们的 `User` 类准备数据库，我们需要创建一个 table。如果你使用的是类似 Mongo 的数据库，你能不实现该方法。

```swift
final class User {
    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("name")
        }
    }
    ...
}
```

这里我们创建了一个 `users` 表，有一个 identifier 字段和一个叫 `name` 的字段。这个能够匹配我们的 `init(node: Node)` 和 `makeNode() -> Node` 方法。

### Revert

我们也可以创建可选的 preparation reversion。如果我们执行 `vapor run prepare --revert`，这个方法将会被调用。

```swift
final class User {
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
    ...
}
```

这里我们删除名为 `users` 的 table。

### Preparations as Migrations

如果你想在已经创建的初始化 schema 上添加一个字段 （field），你能够创建一个 struct 或者 class，实现 `Preparation` 协议：

```swift

struct AddFooToBar: Preparation {
    static func prepare(_ database: Database) throws {
        try database.modify("bars", closure: { bar in
            bar.string("foo", length: 150, optional: false, unique: false, default: nil)
        })
    }

    static func revert(_ database: Database) throws {

    }
}
```

然后，在你的 Droplet 启动的时候，添加这行代码： `drop.preparations.append(AddFooToBar.self)`。

### Droplet

要在应用程序启动的时候，执行这些 prepation， 你必须添加 Model 到你的 `Droplet` 中。

```swift
let drop = Droplet()

drop.preparations.append(User.self)
```

> 注意： Preparation 必须在 Drople 运行之前添加。

## Full Model

最终的 `User` model 如下：

```swift
import Vapor
import Fluent

final class User: Model {
    var id: Node?
    var name: String

    init(name: String) {
        self.name = name
    }


    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name
        ])
    }

    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("name")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}
```

## Interacting

现在 `User` 实现了 `Model` 协议，现在它有了一些额外的方法，例如 `find()`、 `query()`、 `makeJSON()` 等等。

### Fetch

Model 能够通过他们在数据库中的 identifier 被查找到。

```swift
let user = try User.find(42)
```

### Save

新创建的 model 可以被保存到数据库。

```swift
var user = User(name: "Vapor")
try user.save()
print(user.id) // prints the new id
```

### Delete

带有 identifier 的持久化的 model 可以被删除。

```swift
try user.delete()
```

## Model vs. Entity

Model has a couple of extra conformances that a pure Fluent entity doesn't have.

```swift
public protocol Model: Entity, JSONRepresentable, StringInitializable, ResponseRepresentable {}
```

可以看到在 protocol 中， Vapor model 可以自动转化为 `JSON`、`Response`，甚至可以被用在类型安全的路由中。

## Options

修改 table/collection 名字。
```swift
static var entity = "new_name"
```
