# 项目结构

现在，你已经创建并运行了第一个 Vapor 应用程序，让我们稍微花点时间熟悉一下 Vapor 的项目结构。该结构是在 [SPM](spm.zh.md) 的基础上演化而来；因此，如果你曾经使用过 SPM，应该会很熟悉。


```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

下面将详细地解释每个文件夹的作用。

## Public

如果你使用了 `FileMiddleware` 中间件，那么此文件夹包含你的应用程序提供的所有公共文件，通常是图片、`.css` 样式和浏览器脚本等。 例如，对 `localhost:8080/favicon.ico` 发起的请求将检查是否存在 `Public/favicon.ico` 图片并回应。

在 Vapor 可以提供公共文件之前，你需要在 `configure.swift` 文件中启用`FileMiddleware`，参考如下所示：

```swift
// 从 'Public/' 目录提供文件
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

此文件夹包含项目的所有 Swift 源文件。 顶级文件夹 `App` 反映了你的包的模块，如 [SwiftPM](spm.md) 清单中声明的那样。

### App

应用程序的所有核心代码都包含在这里。

#### Controllers

控制器是将应用程序的不同逻辑进行分组的优秀方案，大多数控制器都具备接受多种请求的功能，并根据需要进行响应。

#### Migrations

如果你使用 Fluent，则可以在 Migrations 文件夹中进行数据库迁移。

#### Models

models 文件夹常用于存放 `Content` 和 Fluent `Model` 的类或结构体。

#### configure.swift

这个文件包含 `configure(_:)` 函数，`entrypoint.swift` 调用这个方法用以配置新创建的 `Application` 实例。你可以在这里注册诸如路由、数据库、providers 等服务。

#### entrypoint.swift

该文件包含应用程序的 `@main` 入口点，用于设置、配置和运行 Vapor 应用程序。

#### routes.swift

这个文件包含 `routes(_:)` 方法，它会在 `configure(_:)` 结尾处被调用，用以将路由注册到你的 `Application`。

## Tests

`Sources` 文件夹中的每个不可运行的模块在 `Tests` 中都可以创建一个对应的文件夹，包含 `XCTest` 模块上构建的用例，用来测试你的代码。可以在命令行使用 `swift test`或在 Xcode 中按 `⌘+U` 来进行测试。

### AppTests

此文件夹包含 `App` 模块中代码的单元测试。

## Package.swift

最后是 [SPM](spm.zh.md) 文件，是这个项目运行所依赖的第三方库配置。


