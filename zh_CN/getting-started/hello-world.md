---
currentMenu: getting-started-hello-world
---

# Hello, World

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

这一章节，假设你已经安装了 Swift 3 和 Vapor Toolbox， 并且已经验证过了她们能够正常的工作。

> 注意：如果你不想使用 Toolbox，请按照 [manual guide](manual.md) 操作。

## New Project

让我们通过创建一个叫 Hello, World 的项目开始。

```sh
vapor new Hello
```

如果你已经使用过其他的 web 框架，Vapor 的目录结构将会和它们很相似。

```
.
├── Sources
│   └── App
│       └── Controllers
│       └── Middleware
│       └── Models
│       └── main.swift
├── Public
├── Resources
│   └── Views
└── Package.swift
```

对于我们 Hello, World，我们将关注 `main.swift` 文件。

```
.
└── Sources
    └── App
        └── main.swift
```

注意：`vapor new` 命令创建的新项目，会包含怎样使用这个框架的例子和注释。如果你不需要，你可以删除它。

## Droplet

在 `main.swift` 文件中，你能看到如下的代码。

```swift
let drop = Droplet()
```

这里只是创建了一个 `Droplet `。`Droplet ` 类还有许多有用的方法，并且被广泛的使用。

## 路由（Routing）

创建了 `drop` 之后，添加如下的代码片段。

```swift
drop.get("hello") { request in
    return "Hello, world!"
}
```

这里创建了一个新的 route，用来匹配 `/hello` 的 `GET` 请求。

route 的闭包中将会传入 [Request](../http/request.md) 的一个实例，该实例中包含这次请求的 URI 和 发送过来的数据。

这个 route 只是简单的返回了一个字符串，但是所有的实现了 [ResponseRepresentable](../http/response-representable.md) 协议的内容都可以被返回。在 快如入门的  [Routing](../routing/basic.md) 能够了解更多。

注意：Xcode 可能自动为闭包的输入参数添加额外的类型。这个可以被删除，已保持代码清洁。如果你想要保留类型信息，在文件的头部添加 `import HTTP`。

## Running

在 main 文件的最下面，确保已经启动了 `Droplet`。

```swift
drop.run()
```

保存该文件，回到终端。

## 编译（Compiling）

使 Vapor 这么强大的一个很重要的部分就是 Swift 先进的编译器。让我们走起来。确定你在项目的根目录下，运行如下的命令。

```swift
vapor build
```

注意： `vapor build` 在后台运行 `swift build`。

Swift Package Manager 首先从 git 上下载相关的依赖。然后将它们编译并且链接到一起。

当这个过程完成后，你将看到 `Building Project [Done]`。

注意：如果你看到一个类似的输出 `unable to execute command: Killed`，你需要提高你的 swap space。如果你运行在一个有限制内存的机器上将会出现这个问题。

## Run

通过运行如下的命令启动 server。

```swift
vapor run serve
```

你应该能够看到 `Server starting...`。现在你能够在浏览器访问 `http://localhost:8080/hello`。

注意：某些端口需要超级用户权限才能够绑定。只需要简单的运行 `sudo vapor run` 就能够允许访问了。如果你使用了非 `80` 端口，你需要在浏览器访问的时候指定相关端口。

## 注意 sudo 的使用 （Note for sudo usage）

在某些基于 linux 的系统，当你使用 sudo 的时候，可能会发生错误，如果你需要在 root 下运行服务器，首先使用如下命令切换用户：

```
sudo -i
```
然后添加前面安装 swift 的路径到 root 用户的 $PATH 环境变量。

```
PATH=$PATH:/your_path_to_swift
# Example command can be like this
# PATH=$PATH:/swift-3.0/usr/bin
# In this case /swift-3.0/usr/bin is the location of my swift installation.

```


## Hello, World

你将会在你的浏览器窗口看到如下的输出。

```
Hello, world!
```
