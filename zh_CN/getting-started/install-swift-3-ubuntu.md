---
currentMenu: getting-started-install-swift-3-ubuntu
---

# Install Swift 3: Ubuntu

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

在 Ubuntu 上安装 Swift 3 只需要一点点的时间。

## 快速安装

不想输入？运行下面的脚本，快速安装 Swift 3.0。  

```sh
curl -sL swift.vapor.sh/ubuntu | bash
```

> 注意：这个安装脚本自动将 Swift 添加到你的 `~/.bashrc` 文件中。

## 手动安装

### 依赖

根据你的 Ubuntu 版本的不同，你需要一些额外的用于编译的工具。我们将会在安全的范围内犯错，最终会安装你需要的所有东西

```sh
sudo apt-get update
sudo apt-get install clang libicu-dev binutils git
```

### 下载

针对你的 Ubuntu 版本下载对应的 Swift 3 toolchain。

```sh
# Ubuntu 14.04
wget https://swift.org/builds/swift-3.0-release/ubuntu1404/swift-3.0-RELEASE/swift-3.0-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 15.10
wget https://swift.org/builds/swift-3.0-release/ubuntu1510/swift-3.0-RELEASE/swift-3.0-RELEASE-ubuntu15.10.tar.gz
```

### 解压

<!-- After Swift 3 has downloaded, decompress it. -->
下载完成后，解压它。

```sh
# Ubuntu 14.04
tar zxf swift-3.0-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 15.10
tar zxf swift-3.0-RELEASE-ubuntu15.10.tar.gz
```

### 安装

在你的电脑上将 Swift 3.0 移动到一个安全的、不变的位置。我们将使用 `/swift-3.0`，但是你可以自有选择你喜欢的名字。

```sh
# Ubuntu 14.04
mv swift-3.0-RELEASE-ubuntu14.04 /swift-3.0

# Ubuntu 15.10
mv swift-3.0-RELEASE-ubuntu15.10 /swift-3.0
```

> 注意：你可能需要使用`sudo`

### Export

使用你的编辑器编辑你的 bash profile。

```sh
vim ~/.bashrc
```

添加如下的一行内容：

```sh
export PATH=/swift-3.0/usr/bin:"${PATH}"
```

> 注意：如果你移动 Swift 3.0 到的目录不是 `/swift-3.0`，你的路径将会是不同的。

## 检查

通过如下命令再次检测是否安装成功：

```sh
curl -sL check.vapor.sh | bash
```

## Toolbox

现在你可以继续 [Install Toolbox](install-toolbox.md)。

## Swift.org

如果你想了解更详细的安装 Swift 3.0 的指令，请查看 [Swift.org](https://swift.org) 的更多指南。
