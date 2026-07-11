# 在 macOS 上安装

要在 macOS 上使用 Vapor，你将需要 Swift 5.9 或更高版本。 Swift 及其所有依赖项都与 Xcode 捆绑。

## 安装 Xcode

从 Mac App Store 安装 [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)。

![Mac App Store 中的 Xcode](../images/xcode-mac-app-store.png)

下载 Xcode 之后，必须将其打开以完成安装。可能还需要耐心等待一会儿。

安装后，打开 Terminal 输入以下命令打印 Swift 的版本，检查版本号以确保安装成功。

```sh
swift --version
```

你应该能够看到 Swift 的版本信息已打印。

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4 需要 Swift 5.9 或更高版本。

## 安装工具箱(Install Toolbox)

现在你已经安装了 Swift，让我们安装 [Vapor Toolbox](https://github.com/vapor/toolbox)。使用 Vapor 不需要此 CLI 工具，但它有助于创建新的 Vapor 项目。

### Homebrew

Toolbox 通过 Homebrew 分发。如果你还没有安装 Homebrew，请访问 <a href="https://brew.sh" target="_blank">brew.sh</a> 查看安装说明。

```sh
brew install vapor
```

通过输出帮助内容以确保安装成功。

```sh
vapor --help
```

你应该可以看到可用命令列表。

### Makefile

如果你愿意，也可以从源代码构建 Toolbox。在 GitHub 上查看 Toolbox 的 <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> 以找到最新版本。

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

通过输出帮助内容以确保安装成功。

```sh
vapor --help
```

你应该可以看到可用命令列表。

## 下一步

现在你已经安装了 Swift 和 Vapor Toolbox，在 [开始 → 你好，世界](../getting-started/hello-world.md) 中创建你的第一个 Vapor 应用程序。
