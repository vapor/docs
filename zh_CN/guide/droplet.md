---
currentMenu: guide-droplet
---

# Droplet

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`Droplet` 是一个 service 容器，能够让你访问许多 Vapor 的特性。它能够注册 router、启动 server、添加 middleware 等等。

## 初始化 （Initialization）

你在前面已经看到了，创建一个 `Droplet` 的实例只需要 import Vapor 就可以了。

```swift
import Vapor

let drop = Droplet()

// your magic here

drop.run()
```

在 `main.swift` 文件里创建了 `Droplet`。

## 环境 （Environment）

`environment` 属性包含了你的应用程序运行的环境。一般分为 development、testing、production。

```swift
if drop.environment == .production {
    ...
}
```

environment 会影响 [Config](config.md) 和 [Logging](log.md)。environment 默认是 `development`。我们可以传递 `--env=` 标签作为一个参数，改变它。

```sh
vapor run serve --env=production
```

如果你在 Xcode 中，你可以在 scheme 编辑器中传递参数。

> 注意：Debug logs 能够减少你的应用程序在每秒处理的请求数。使用 production 环境能够提高运行效率。

## 工作目录 （Working Directory）

`workDir` 属性包含一个应用程序应该从哪里启动的一个目录的路径。默认情况下，这个属性假设你从它的根路径启动 Droplet。

```swift
drop.workDir // "/var/www/my-project/"
```

你能够通过 `Droplet` 初始化方法覆盖工作目录，或者传入 `--workdir` 参数。

```sh
vapor run serve --workdir="/var/www/my-project"
```

## 修改属性 （Modifying Properties）

`Droplet` 的属性能够通过程序或者配置文件的方式进行修改。

### Programmatic

`Droplet` 的属性可以在初始化方法之后进行修改。

```swift
let drop = Droplet()

drop.server = MyServerType.self
```

这里将使用的 `Droplet` server 类型修改成了自定义的类型。当 `Droplet` 运营的时候，这个自定义的 server 将会代替默认的 server 启动。

### 可配置的 （Configurable）

若果你在某些特定的情况下，只是想修改 `Droplet` 的属性，你可以使用 `addConfigurable` 方法。例如你只想在生产环境中发送错误日志到你的邮箱，并不想在测试环境下收到。

```swift
let drop = Droplet()

drop.addConfigurable(log: MyEmailLogger.self, name: "email")
```

除非你修改了 `Config/droplet.json` 文件并指向了你的 email logger，否则 `Droplet` 将会继续使用默认的 logger。如果你在 `Config/production/droplet.json` 文件中修改了，你的 logger 将只会在生产环境中使用。

```json
{
    "log": "email"
}
```

## 初始化 （Initialization）

由于 `Droplet` 的大部分属性都是变量并且在初始化后能够修改，所以 `Droplet` 的 init 方法是十分简单。

Most plugins for Vapor come with a [Provider](provider.md), these take care of configuration details for you.
大部分的 Vapor 的插件都来自 [Provider](provider.md)， 下面给你一个详细的配置例子。

```swift
Droplet(
    arguments: [String]?,
    workDir workDirProvided: String?,
    config configProvided: Config?,
    localization localizationProvided: Localization?,
)
```

> 注意：记住 Droplet 的属性会被有用的默认值初始化。这就意味着如果你想修改这些属性，需要在你的代码使用它之前修改。否则你在使用的时候可能会遇到令人迷惑的结果，并且你的覆盖可能被其他地方使用。
