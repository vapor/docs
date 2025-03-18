# Xcode

这篇将介绍一些使用 Xcode 的提示和技巧。如果你使用不同的开发环境，你可以跳过此篇。

## 自定义工作目录(Working directory)

Xcode 将默认在 _DerivedData_ 目录运行项目。这与项目的根目录（你的 _Package.swift_ 文件所在的目录）不在同一个目录，这意味着 Vapor 将找不到像 _.env_ 或者 _Public_ 等一些文件和目录。

如果在运行应用程序时看到以下警告，你就可以知道这正在发生。

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

要解决这个问题，你可以在 Xcode scheme 中为你的项目设置一个自定义的工作目录。

首先，编辑项目的 scheme。

![Xcode Scheme Area](../images/xcode-scheme-area.png)

在下拉框中选择 _Edit Scheme..._ 

![Xcode Scheme Menu](../images/xcode-scheme-menu.png)

在 scheme 编辑器中，选择 _App_ action 以及 _Options_ tab 页。选中 _Use custom working directory_ 然后输入你项目根目录。

![Xcode Scheme Options](../images/xcode-scheme-options.png)

你可以在终端中运行 `pwd` 来获取你项目根目录的绝对目录。

```sh
# 获取当前目录的路径
pwd
```

你应该能看见类似下面的输出。

```
/path/to/project
```
