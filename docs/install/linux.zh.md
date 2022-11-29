
# 在 Linux 上面安装

你需要 Swift 5.2 或更高版本来使用 Vapor。可以通过 [Swift.org](https://swift.org/download/) 上面的工具链来安装。

## 支持的发行版和版本

Vapor 与 Swift 5.2 或者更高的版本对 Linux 的版本支持保持一致。

!!! note "注意"
    下面列出的版本可能会随时过期。你可以到 [Swift Releases](https://swift.org/download/#releases) 官方网站去确认官方支持的操作系统。

|Distribution|Version|Swift Version|
|-|-|-|
|Ubuntu|16.04, 18.04|>= 5.2|
|Ubuntu|20.04|>= 5.2.4|
|Fedora|>= 30|>= 5.2|
|CentOS|8|>= 5.2.4|
|Amazon Linux|2|>= 5.2.4|

不受官方支持的 Linux 发行版也可以通过编译源代码来运行 Swift，但是 Vapor 不能保证其稳定性。可以在 [Swift repo](https://github.com/apple/swift#getting-started) 学习更多关于编译 Swift 的信息。

## 安装 Swift

访问 Swift.org 的 [Using Downloads](https://swift.org/download/#using-downloads) 手册来学习如何在 Linux 安装 Swift。

### Fedora

Fedora 用户可以简单的通过下面的命令来安装 Swift：

```sh
sudo dnf install swift-lang
```

如果你正在使用 Fedora 30，你需要添加添加 EPEL 8 来获取 Swift 5.2 或更新的版本。


## Docker

你也可以使用预装了编译器的 Swift 官方 Docker 镜像，可以在 [Swift's Docker Hub](https://hub.docker.com/_/swift) 了解更多。

## 安装工具箱(Install Toolbox)

现在你已经安装了 Swift，让我们安装 [Vapor Toolbox](https://github.com/vapor/toolbox)。使用 Vapor 不是必须要使用此 CLI 工具，但它包含有用的实用程序。

在 Linux 系统上，你需要通过源码来编译 toolbox，在 Github 上查看 toolbox 的 <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> 来获取最新版本。

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

通过打印信息来再次确认是否已经安装成功。

```sh
vapor --help
```

你应该能看见可用命令的列表。

## 下一步

在你安装完 Swift 之后，通过 [开始 → 你好，世界](../getting-started/hello-world.md) 来学习创建你的第一个应用。
