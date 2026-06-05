# 部署到 DigitalOcean

本指南将引导你将一个简单的 Hello, world Vapor 应用程序部署到 [Droplet](https://www.digitalocean.com/products/droplets/)。要遵循本指南，你需要有一个付费的 [DigitalOcean](https://www.digitalocean.com) 帐户。

## 创建服务器

让我们从在 Linux 服务器上安装 Swift 开始。 使用创建菜单创建一个新的 Droplet。

![Create Droplet](../images/digital-ocean-create-droplet.png)

在发行版下，选择 Ubuntu 22.04 LTS。以下指南将以此版本为例。

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note "注意"  
	你也可以选择 Swift 支持的其它 Linux 发行版。在撰写本文时。你可以在 [Swift Releases](https://swift.org/download/#releases) 页面上查看官方支持哪些操作系统。

选择完发行版后，选择你喜欢的套餐和数据中心所在区域。然后设置一个 SSH 密钥以在创建服务器后访问它。最后， 点击创建 Droplet 并等待新服务器启动。

新服务器准备完毕后，鼠标悬停在 Droplet 的 IP 地址上，然后单击复制。

![Droplet List](../images/digital-ocean-droplet-list.png)

## 初始化设置

打开你的终端，使用 SSH 通过 root 身份登录到服务器。

```sh
ssh root@your_server_ip
```

在 [Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04) 上初始化服务器设置，DigitalOcean 提供了深入指南。 本指南将快速介绍一些基础知识。

### 配置防火墙

允许 OpenSSH 通过防火墙并且启用它。

```sh
ufw allow OpenSSH
ufw enable
```

### 添加用户

除了 `root` 用户在创建一个新用户。本指南创建了一个 `vapor` 用户。

```sh
adduser vapor
```

允许新创建的用户使用 `sudo`。

```sh
usermod -aG sudo vapor
```

复制 root 用户的 SSH 密钥到新创建的用户。允许新用户通过 SSH 登录。

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

最后，退出当前 SSH 会话，用新创建的用户进行登录。

```sh
exit
ssh vapor@your_server_ip
```

## 安装 Swift

现在你已经创建了一个新的 Ubuntu 服务器并且通过非 root 身份登录到服务器，你可以安装 Swift。 

### 使用 Swiftly CLI 工具自动安装(推荐)

访问 [Swiftly 网站](https://swiftlang.github.io/swiftly/)获取在 Linux 上安装 Swiftly 和 Swift 的说明。之后，安装 Swift 使用如下命令：

#### 基本用法

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## 使用 Vapor 工具箱安装 Vapor

现在已经安装了 Swift，让我们 Vapor工具箱来安装 Vapor。你需要通过源码在构建工具箱。在 GitHub 上查看工具箱的[发布](https://github.com/vapor/toolbox/releases)版本，以查找最新版本。在本例中，我们使用 18.6.0 版本。

### 克隆并构建 Vapor

克隆 Vapor 工具箱仓库。

```sh
git clone https://github.com/vapor/toolbox.git
```

切换到最近的发布版本。

```sh
cd toolbox
git checkout 18.6.0
```

构建 Vapor 并将二进制文件移动到你的 path 中。

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### 创建 Vapor 项目

使用工具箱的 new 命令初始化项目。

```sh
vapor new HelloWorld -n
```

!!! tip "建议" 
	`-n` 标志表示自动回答所有问题为 no，并提供一个基础的模板。


![Vapor Splash](../images/vapor-splash.png)

命令执行完成后，切换到新创建的文件夹:

```sh
cd HelloWorld
```

### 打开 HTTP 端口

为了访问服务器上的 Vapor 程序，需要开启相应 HTTP 端口。

```sh
sudo ufw allow 8080
```

### 运行

现在 Vapor 已经设置好了，并且有了公开的端口，让我们启动它吧。

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

通过浏览器或者本地终端访问服务器的 IP， 你应该会看到 “It works!”。本例中的 IP 地址为 `134.122.126.139`。

```
$ curl http://134.122.126.139:8080
It works!
```

回到服务器上，你应该会看到测试请求的日志。

```
[ NOTICE ] Server starting on http://157.245.244.228:80
[ INFO ] GET /
```

使用 `CTRL+C` 退出服务器。可能需要一秒钟才能关闭。

恭喜你的 Vapor 应用程序运行在 DigitalOcean Droplet 上了！

## 下一步

本指南的其余部分指向的资源用于改进你的部署。

### Supervisor

Supervisor 是一个进程控制系统，可以运行和监控你的 Vapor 可执行文件。通过设置 supervisor， 服务器启动时应用程序自动启动，并在崩溃是重新启动。了解有关 [Supervisor](../deploy/supervisor.md) 的更多信息。

### Nginx

Nginx 是一个速度极快、经过实战考验并且易于配置的 HTTP 服务器和代理。虽然 Vapor 支持直接的 HTTP 请求，但 Nginx 背后的代理可以提供更高的性能、安全性和易用性。了解有关 [Nginx](../deploy/nginx.md) 的更多信息。
