---
currentMenu: getting-started-install-toolbox
---

# 安装 Toolbox

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Vapor 的命令行工具为一般的人物提供了捷径和帮助。

![Vapor Toolbox](https://cloud.githubusercontent.com/assets/1342803/17454691/97e549e2-5b6d-11e6-979a-f0cd6b6f1b0a.png)

> 如果你不想安装 Toolbox，可以查看 [Manual](manual.md) 快速入门。

### 安装

运行下面的脚本来安装 [Toolbox](https://github.com/vapor/toolbox)。

```sh
curl -sL toolbox.vapor.sh | bash
```

> 注意：你必须安装了合适的 Swift 3 版本。

### 验证

我们可以通过执行 help 命令，用来验证 Toolbox 安装成功。你应该能够看到打印了能够使用的命令。你能在任何 Toolboxk 命令后面加上 `--help` 来查看帮助。

```sh
vapor --help
```

### 更新

Toolbox 可以自更新。如果未来你遇到了问题，这个将会很有用。

```sh
vapor self update
```

## 创建一个项目

现在你已经安装了 Toolbox，你能按照 [Hello, World guide](hello-world.md) 创建你的第一个 Vapor 项目了。
