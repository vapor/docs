# Leaf

Leaf 是一种强大的模板语言，其语法受 Swift 启发。你可以使用它为前端网站生成动态 HTML 页面或生成内容丰富的电子邮件并通过 API 发送。

## Package

使用 Leaf 的第一步是将其作为依赖项添加到你项目的 SPM 清单文件中。

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## 配置

将包添加到项目后，通常在 [`configure.swift`](../getting-started/folder-structure.md#configureswift) 中进行配置，这样 Vapor 就可以使用它了。

```swift
import Leaf

app.views.use(.leaf)
```

当你调用 `req.view` 时，就是在告诉 Vapor 需要使用 `LeafRenderer` 渲染页面。

!!! 注意 
    Leaf 有一个用于渲染页面的内部缓存。当 `Application` 的运行环境设置为 `.development` 时，此缓存被禁用，因此对模板的更改会立即生效。在 `.production` 环境和所有的其它环境中，默认启用缓存；应用重启之前，对模板所做的任何更改都不会生效。

!!! 警告 
    从 Xcode 运行项目时为了 Leaf 能够找到模板，你必须为你的 Xcode 工作区设置[自定义工作目录](../getting-started/xcode.md#working-directory)。

## 目录结构

一旦你配置了 Leaf，你需要确保有一个 `Views` 文件夹来存储 `.leaf` 文件。默认情况下，Leaf 期望文件夹位于相对于项目根目录的 `./Resources/Views` 中。

例如，如果你计划提供 Javascript 和 CSS 文件，你可能还希望启用 Vapor 的 [`FileMiddleware`](https://api.vapor.codes/vapor/main/Vapor/FileMiddleware/) 服务来提供 `/Public` 文件夹中的文件。

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## 渲染视图

现在已经配置了 Leaf，让我们渲染你的第一个模板。在 `Resources/Views` 文件夹中，创建一个新文件，命名为 `hello.leaf`，其内容如下：

```leaf
Hello, #(name)!
```

然后，注册一个路由（通常在 `routes.swift` 中或一个控制器中完成注册）来渲染视图。

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

使用 `Request` 上的通用 `view` 属性，而不是直接调用 Leaf。这允许你在测试中切换到不同的渲染器。

打开浏览器并访问 `/hello` 路径。你应该看到 `Hello, Leaf!`。恭喜你成功渲染了你的第一个 Leaf 视图！

