# 在 Ubuntu 上安装

要在 Ubuntu 上使用 Vapor，您将需要 Swift 5.2 或更高版本。可以使用 [Swift.org](https://swift.org/download/) 上提供的工具链进行安装。

## 支持版本

Vapor 支持的 Ubuntu 版本与 Swift 5.2 相同。

| 版本 | 代号          |
|---------|-------------------|
| 18.04   | Bionic Beaver     |
| 16.04   | Xenial Xerus      |

## 安装

请访问 Swift.org [使用下载](https://swift.org/download/#using-downloads) 指南，以获取有关如何在 Linux上 安装 Swift 的说明。

## Docker

您还可以使用预装编译器的 Swift 官方 Docker 映像。在 [Swift Docker Hub](https://hub.docker.com/_/swift) 上了解更多信息。

## 安装 Toolbox

现在您已经安装了Swift，让我们安装 [Vapor Toolbox](https://github.com/vapor/toolbox)。使用 Vapor 不需要此CLI工具，但它包含一些实用程序。

在 Linux 上，您需要从源代码构建 Toolbox，在 GitHub 上查看 <a href="https://github.com/vapor/toolbox/releases" target="_blank">Toolbox </a>，以找到最新版本。

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
swift build -c release --disable-sandbox
mv .build/release/vapor /usr/local/bin
```

通过输出帮助内容以确保安装成功。

```sh
vapor --help
```

您应该可以看到 Vapor 包含的可用命令列表。

## 下一步

安装Swift之后，请在 [开始 &rarr; 世界，你好](../hello-world.md) 中创建您的第一个 Vapor 应用程序。
