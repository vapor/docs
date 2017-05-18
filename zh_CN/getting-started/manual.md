---
currentMenu: getting-started-manual
---

# Manual Quickstart

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

学习如果不使用 Toolbox，只使用 Swift 3  Swift Package Manager 创建一个 Vapor 项目。

> 如果你更想使用 Toolbox，在 [这里](install-toolbox.md) 学习如何安装。

这个文档假设你已经安装了 Swift 3 。

> 注意：如果你已经安装了 Toolbox，可以在 [这里](hello-world.md) 学习 toolbox 指南。

## 检查 （Check）

为了检查你的环境是兼容的，运行如下的脚本：

```bash
curl -sL check.vapor.sh | bash
```

## 使用 SwiftPM 创建新项目 （Make new project using SwiftPM）

打开你的终端：

> 我们的 example，我将会使用 Desktop 文件夹。

```bash
cd ~/Desktop
mkdir Hello
cd Hello
swift package init --type executable
```

你的目录结构应该像这样：

```
├── Package.swift
├── Sources
│   └── main.swift
└── Tests
```

## 编辑 `Package.swift`

打开你的 `Package.swift` 文件:

```bash
open Package.swift
```

添加 Vapor 依赖。你的文件应该像下面一样。

#### Package.swift

```swift
import PackageDescription

let package = Package(
    name: "Hello",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 1)
    ]
)
```

> 我们将会努力保持这份文档是最新的，当然你可以在 [here](https://github.com/vapor/vapor/releases) 访问最新的发布版本。

## 编辑 `main.swift`

一个简单的 hello world:

```
import Vapor

let drop = Droplet()

drop.get("/hello") { _ in
  return "Hello Vapor"
}

drop.run()
```

## Build and Run

第一个 `build` 将会花费一点时间去获取依赖。

```
swift build
.build/debug/Hello
```

> 如果你的项目名不同，替换 `Hello` 为你自己的项目名。

## View

打开你的浏览器，访问 `http://localhost:8080/hello`
