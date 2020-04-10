# 在 macOS 上安装

要在 macOS 上使用 Vapor，您将需要 Swift 5.2 或更高版本。 Swift 及其所有依赖项都与 Xcode 捆绑。

## 安装 Xcode

从 [Mac App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) 安装 Xcode 11 或更高版本。

!!! 提示
	在撰写本文时，包含 Swift 5.2 的 Xcode 11.4 还处于测试阶段。您可以从[开发者网站](https://developer.apple.com/download/) 下载它，也可以从 [Swift.org](https://swift.org/download/) 下载最新的 Swift 5.2 工具链。

![Xcode 11](https://user-images.githubusercontent.com/1342803/66688324-2396bc80-ec54-11e9-8b96-bd8b29d0ce7c.jpg)

下载 Xcode 之后，必须将其打开以完成安装。可能还需要耐心等待一会儿。

安装后，打开 Terminal 输入以下命令打印 Swift 的版本，检查版本号以确保安装成功。

```sh
swift --version
```

您应该能够看到 Swift 的版本信息已打印。

```sh
Apple Swift version 5.2 (swiftlang-1100.0.270.13 clang-1100.0.33.7)
Target: x86_64-apple-darwin19.0.0
```

Vapor 4 需要 Swift 5.2 或更高版本。

## 安装 Toolbox

现在您已经安装了 Swift，让我们安装 [Vapor Toolbox](https://github.com/vapor/toolbox)。 使用 Vapor 不需要此 CLI 工具，但是它包含一些实用的程序，例如新项目创建者。

Toolbox 通过 Homebrew 分发。如果您还没有安装 Homebrew，请访问 <a href="https://brew.sh" target="_blank">brew.sh</a> 查看安装说明。

```sh
brew install vapor/tap/vapor-beta
```

通过输出帮助内容以确保安装成功。

```sh
vapor-beta --help
```

您应该可以看到 Vapor 包含的可用命令列表。

## 下一步

现在您已经安装了 Swift and Vapor Toolbox，在 [开始 &rarr; 世界，你好](../hello-world.md) 中创建您的第一个 Vapor 应用程序。
