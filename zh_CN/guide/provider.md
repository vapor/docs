---
currentMenu: guide-provider
---

# Provider

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`Provider`协议创建了一个简单和可预测的方式来添加功能和第三方包到您的Vapor项目

## 添加 Provider （Adding a Provider）

添加一个 provider 到你的应用中需要 2-3 步。

### Add Package

所有 Vapor 的 provider 都以 `-provider` 结尾。你可以在我们的 GitHub 搜索到 [可用的 providers](https://github.com/vapor?utf8=✓&q=-provider) 列表。

为了添加 provider 到你的 package，需要在你的 `Package.swift` 添加它作为依赖。

```swift
let package = Package(
    name: "MyApp",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 1, minor: 0)
    ]
)
```

> 在添加新的 package 后，执行 `vapor clean` 或 `vapor build --clean` 是很重要的。

### Import

一旦 provider 被添加，你能够使用 `import VaporFoo` 引入一个叫做 `Foo` 的provider。

Here is what importing the MySQL provider looks like:

```swift
import Vapor
import VaporMySQL

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

// ...

drop.run()
```

每个 provider 都有一个命名为 `Provider` 的类。在你的 `Droplet` 的初始化方法中，添加这个类的 `Type` 到你的 `providers` 数组。


### Config

一些 driver 可能需要配置文件。例如： `VaporMySQL` 要求一个类似如下的 `Config/mysql.json` 文件：

```json
{
	"host": "localhost",
	"user": "root",
	"password": "",
	"database": "vapor"
}
```

如果需要一个配置文件，但是没有的时候，你将在 `Droplet` 的初始化过程中收到一个错误。

## Advanced

你可以选择自己初始化这个 provider。

```swift
import Vapor
import VaporMySQL

let drop = Droplet()

let mysql = try VaporMySQL.Provider(host: "localhost", user: "root", password: "", database: "vapor")
drop.addProvider(mysql)

...

drop.run()
```

## Create a Provider

创建一个 provider 是很简单的。你仅仅需要创建一个包含实现了 `Vapor.Provider` 协议的 `Provider` 类的 package 即可。

### Example

这是一个 `Foo` package 中 provider 的样子。它获得一个 message，然后当 `Droplet` 启动的时候打印它。


```swift
import Vapor

public final class Provider: Vapor.Provider {
	public let message: String
    public let provided: Providable

    public convenience init(config: Config) throws {
    	guard let message = config["foo", "message"].string else {
    		throw SomeError
    	}

        try self.init(message: message)
    }

    public init(message: String) throws {
		self.message = message
    }

    public func afterInit(_ drop: Droplet) {

    }

    public func beforeServe(_ drop: Droplet) {
		drop.console.info(message)
    }
}
```

这个 provider 要求包含一个类似下面内容的 `Config/foo.json` 文件：

```json
{
	"message": "The message to output"
}
```

这个 provider 也可以手动使用 `init(message: String)` 方法初始化。
