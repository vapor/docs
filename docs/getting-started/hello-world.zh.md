
# 你好，世界

本文将指引你逐步创建、编译并运行 Vapor 的项目。

如果尚未安装 Swift 和 Vapor Toolbox，请查看安装部分。

- [安装 → macOS](../install/macos.md)
- [安装 → Linux](../install/linux.md)

## 创建

首先，在电脑上创建 Vapor 项目。打开终端并使用以下 Toolbox 的命令行，这将会在当前目录创建一个包含 Vapor 项目的文件夹。

```sh
vapor new hello -n
```

!!! tip "建议"
	使用 `-n` 为所有的问题自动选择 no 来为您提供一个基本的模板。

!!! tip "建议"
	Vapor 以及自带的模板默认使用 `async`/`await`。如果你的系统不能更新到 macOS 12 或者想继续使用 `EventLoopFuture`。运行命令时可以添加此标志 `--branch macos10-15`。

命令完成后，切换到新创建的文件夹

```sh
cd hello
```

## 编译 & 运行

### Xcode

首先，在Xcode打开项目：

```sh
open Package.swift
```


Xcode 将自动开始下载 Swift 包管理器依赖，在第一次打开一个项目时，这可能需要一些时间，当依赖下载后，Xcode 将显示可以用的 Scheme。

在窗口的顶部，在 Play 和 Stop 按钮的右侧，单击项目名称以选择项目的 Scheme，并选择一个适当的 target ——大概率是 “My Mac”。单击 play 按钮编译并运行项目。

你应该会在 Xcode 窗口的底部看到控制台输出以下信息。

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

在 Linux 和其他操作系统上（甚至在 macOS 上如果你不想使用 Xcode），你可以在你喜欢的编辑器中编辑项目，比如 Vim 或 VSCode 。关于设置其他 IDE 的最新细节，请参阅 [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md)。

在终端运行以下命令来编译和运行你的项目。

```sh
swift run
```
它将构建并运行项目。第一次运行时，需要花费一些时间来获取和下载依赖项。一旦运行，你应该在你的控制台中看到以下内容:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## 访问 Localhost

打开你的浏览器，然后访问 <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> 或者 <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

你将看见以下页面

```html
Hello, world!
```

恭喜你创建，构建，运行了你的第一个 Vapor 应用！🎉
