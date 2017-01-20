---
currentMenu: guide-controllers
---

# Controllers

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Controller 帮助你组织相关的功能聚集在一个地方。它们能够被用来创建 RESTful 资源及请求。

## Basic

一个基本的 controller 看起来像下面这样：

```swift
final class HelloController {
	func sayHello(_ req: Request) throws -> ResponseRepresentable {
		guard let name = req.data["name"] else {
			throw Abort.badRequest
		}
		return "Hello, \(name)"
	}
}
```

简单的 controller 不需要实现任何的协议，你可以按照你的想法自由的设计它们。

### 注册 （Registering）

唯一需要的结构是 controller 中每个方法的签名。为了能够将方法注册到 router 中，方法名必须类似 `(Request) throws -> ResponseRepresentable`。`Request` 和 `ResponseRepresentable` 可以通过引入 `HTTP` 模块获得。

```swift
let hc = HelloController()
drop.get("hello", handler: hc.sayHello)
```

由于我们的 `sayHello` 方法的签名和 `drop.get` 方法的闭包中的参数签名匹配，所以我们能够直接将其传入。

### 类型安全 （Type Safe）

您还可以使用带有类型安全路由的控制器方法

```swift
final class HelloController {
	...

	func sayHelloAlternate(_ req: Request, _ name: String) -> ResponseRepresentable {
		return "Hello, \(name)"
	}
}
```

我们给 `HelloController` 添加了一个新的叫 `sayHelloAlternate` 的方法，它能够接受第二个参数 `name: String`。

```swift
let hc = HelloController()
drop.get("hello", String.self, handler: hc.sayHelloAlternate)
```

由于类型安全的 `drop.get` 可以接受 `(Request, String) throws -> ResponseRepresentable` 签名，我们的方法现在可以被用在我们的 router 的闭包。

## Resources

实现了 `ResourceRepresentable` Controller 能够很容易的作为 ESTful resource 被注册到 router 中。让我们看一个 `UserController` 的例子：

```swift
final class UserController {
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try User.all().makeNode().converted(to: JSON.self)
    }

    func show(_ request: Request, _ user: User) -> ResponseRepresentable {
        return user
    }
}
```

这是一个典型的带有 `index` 和 `show` router 的 controller。`index` 返回所有用户列表的 JSON， `show` 返回单个用户的 JSON 数据。

我们 _能够_ 像下面这样注册这个 controller：

```swift
let users = UserController()
drop.get("users", handler: users.index)
drop.get("users", User.self, handler: users.show)
```

`ResourceRepresentable` 使这种标准的 RESTful 结构使用起来很简单。

```swift
extension UserController: ResourceRepresentable {
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            show: show
        )
    }
}
```

使 `UserController` 实现 `ResourceRepresentable` 协议，要求 `index` 和 `show` 的方法签名需要与期望的 `Resource<User>` 相匹配。

这里窥探​​ `Resource` 类：


```swift
final class Resource<Model: StringInitializable> {
    typealias Multiple = (Request) throws -> ResponseRepresentable
    typealias Item = (Request, Model) throws -> ResponseRepresentable

    var index: Multiple?
    var store: Multiple?
    var show: Item?
    var replace: Item?
    var modify: Item?
    var destroy: Item?
    var clear: Multiple?
    var aboutItem: Item?
    var aboutMultiple: Multiple?

    ...
}
```

现在 `UserController` 实现了 `ResourceRepresentable` 协议，注册这个 router 就简单了。

```swift
let users = UserController()
drop.resource("users", users)
```

  `drop.resource` 将负责注册那些通过调用 `makeResource（）` 提供的 route。在这个例子中，只有 `index` 和 `show` route 被提供了。

> Note: `drop.resource` also adds useful defaults for OPTIONS requests. These can be overriden.  

## Folder

Controller 能够在你应用程序的任何地方，但是我们一般会把它们放在 `Controllers/*` 目录。

### Modules

如果你正在创建一个大型的工程，你可能想要在一个单独的 module 中创建你的 controller。这个允许你对你的 controller 执行单元测试。更多关于创建 module 信息，查看这个文档 [Swift Package Manager](https://swift.org/package-manager/)
