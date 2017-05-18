---
currentMenu: testing-basic
---

# Basic Testing

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

测试是任何软件应用程序的重要部分，同样 Vapor 也没有什么不同。在本文档中，我们将介绍一些基本设置，以便能够测试我们的Droplet

## Displacing Droplet Creation Logic

到目前为止，我们文档中大部分都是在 `main.swift` 编写我们 `Droplet` 创建逻辑。不幸的是，当测试我们的应用程序，代码将有很大的不可访问性。第一件要做的事情，我们需要将这些拆分到 `AppLogic` module中。

这是一个启动文件的例子，我命名为 `Droplet+Setup.swift`。它可能类似下面这样：

```swift
import Vapor

func load(_ drop: Droplet) throws {
    drop.preparations.append(Todo.self)

    drop.get { _ in return "put my droplet's logic in this `load` function" }

    drop.post("form") { req in
      ...
      return Response(body: "Successfully posted form.")
    }

    // etc.
}
```

> [WARNING] Do **not** call `run()` anywhere within the `load` function as `run()` is a blocking call.

## 更新 `main.swift` （Updated `main.swift`）

既然我们已经抽出了我们的 loading 逻辑，我们需要更新我们 **在 `App` module** `main.swift`，以适应这些修改。修改后代码类似下面这样：

```swift
let drop = Droplet(...)
try load(drop)
drop.run()
```

> 由于我们是在 `load` 的范围外初始化的 `Droplet`，所以可以使用不同的方式初始化，以方便测试。我们将在以后介绍这些内容。

## 可测试的 Droplet （Testable Droplet）

第一件需要做的是在我们的 testing target 中，添加 `Droplet+Test.swift` 文件。类似如下：

```swift
@testable import Vapor

func makeTestDroplet() throws -> Droplet {
    let drop = Droplet(arguments: ["dummy/path/", "prepare"], ...)
    try load(drop)
    try drop.runCommands()
    return drop
}
```

这个看起来有点像我们在  `main.swift` 中的初始化，但是这里还有 3 处关键的不同。

### Droplet(arguments: ["dummy/path/", "prepare"], ...

在我们 `Droplet` 创建过程中的 `arguments:` 除了一些高级场景几乎很少用到，但是我们将在 testing 中使用它，保证我们的 `Droplet` 不会自动尝试服务和阻塞 （`serve` 和 block） 我们的线程。你可以使用除“”prepare“”之外的参数，但除非你对某种高级情况做特定的事情，否则这些参数应该足够了

### try drop.runCommands()

注意这里，我们使用 `runCommands()` 代替 `run()`。这允许 `Droplet` 启动之前会做的所有的通用设置，而不实际绑定到 socket 或退出。

### `@testable import Vapor`

我们需要导入 Vapor 的 testable 编译以访问 `runCommands` 函数。这个目前是不公开的，以防止线上的 app 发生意外的 bug。

## Test Our Droplet

现在所有的都已经创建了，我们准备开始测试我们的应用程序的 `Droplet`。这里展示如何进行真实的基本测试：

```swift
@testable import AppLogic

func testEndpoint() throws {
    let drop = try makeTestDroplet()
    let request = ...
    let expectedBody = ...

    let response = try drop.respond(to: request)
    XCTAssertEqual(expectedBody, response.body.bytes)
}
```

现在你可以使用 `CMD-U` 在Xcode中运行你的测试，并看到在线结果。另外，你也可以在命令行中执行 `vapor test` 进行测试。如果你选择使用 `swift build` 且在你的 app 中使用 MySQL，请确保你在调用的时候添加正确的构建标志。

祝你好运，测试愉快！
