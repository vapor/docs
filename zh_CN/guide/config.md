---
currentMenu: guide-config
---

# Config

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

一个应用程序的可配置选项。一个云应用经常要求复杂的配置，以适应它们基于的不同环境。Vapor 想要提供一个灵活的、可以被用户定制的配置。

## 快速入门 （QuickStart）

对于 Vapor 程序来说，配置文件被内嵌在顶层叫做 `Config` 的目录中。这里是一个单服务器的基本配置选项的例子。

```bash
./
├── Config/
│   ├── servers.json
```

例子如下：

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 8080
  }
}
```

这个表示，我们程序会启动一个叫做 ‘http’ 的 server，并且在 `0.0.0.0` 上开发 `8080` 端口。这个代表如下的url： `http://localhost:8080`。

### Custom Keys

添加自定义的 key 到 `servers.json`文件：

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 8080,
    "custom-key": "custom value"
  }
}
```

使用如下的代码，可以在你的程序中访问你的应用程序配置。

```swift
let customValue = drop.config["server", "http", "custom-key"]?.string ?? "default"
```
> 译者注： 测试的时候发现 server 应该是 servers， 应该是跟文件名一致。

类似这样我们可以自由的添加利用这些必要的 key，使你的应用程序配置起来简单。


## 配置语法 （Config Syntax）

你能够使用后面的语法访问你的配置目录：`app.config[<#file-name#>, <#path#>, <#to#>, <#file#>]`。假设除了我们前面提到的 `servers.json` 之外，还有一个内容如下的 `keys.json` 文件：

```JSON
{
  "test-names": [
    "joe",
    "jane",
    "sara"
  ],
  "mongo": {
    "url" : "www.customMongoUrl.com"
  }
}
```

我们可以通过确保下标中的第一个参数是键来访问此文件。使用如下代码获取我们 list 中的第一个名字：

```swift
let name = drop.config["keys", "test-names", 0]?.string ?? "default"
```

或者访问 mongo url：

```swift
let mongoUrl = drop.config["keys", "mongo", "url"].?string ?? "default"
```

## 高级配置 （Advanced Configurations）

默认的 servers.js 已经很好了，但是更复杂的场景呢？例如：如果你想在生产环境和测试环境中使用不同的 host？这些复杂的场景可以通过向我们的 Config/ 目录汇总添加额外的目录结构完成。这里有个目录结构的例子，能够设置生产和开发环境。

```bash
WorkingDirectory/
├── Config/
│   ├── servers.json
│   ├── production/
│   │   └── servers.json
│   ├── development/
│   │   └── servers.json
│   └── secrets/
│       └── servers.json
```

> 你能够通过命令行使用 -env= 制定使用哪个环境。自定义环境也是可以的，默认情况下只提供了：生产，开发和测试。

```bash
vapor run --env=production
```

### 优先级 （PRIORITY）

配置文件将会按照如下的优先级被访问。

1. CLI (see below)
2. Config/secrets/
3. Config/name-of-environment/
4. Config/

这个意味着如果用户调用 `app.config["servers", "host"]`，这个 key 将会首先在 cli 中搜索，然后 secrets 目录， 然后是顶层的默认配置。

> `secrets/` 目录应该被添加到 gitignore 中。

### EXAMPLE

让我们以下面的 JSON 文件开始。

#### servers.json

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 9000
  }
}
```

#### `production/servers.json`

```JSON
{
  "http": {
    "host": "127.0.0.1",
    "port": "$PORT"
  }
}
```

> The `"$NAME"` syntax is available for all values to access environment variables.
> “$ NAME”语法可用于访问环境变量的所有值

注意在 servers.json 和 production/servers.json 都声明了相同的key：host 和 port。在我们程序中，执行如下调用：

```swift
// will load 0.0.0.0 or 127.0.0.1 based on above config
let host = drop.config["servers", "http", "host"]?.string ?? "0.0.0.0"
// will load 9000, or environment variable port.
let port = drop.config["servers", "http", "port"]?.int ?? 9000
```

## 命令行 （COMMAND LINE）

除了内嵌在 Config/ 目录中 json 文件，我们也可以通过命令行传入参数给我们的配置。默认情况下，这些值会被设置为 "cli" 文件，但更复杂的选项也可用。

#### 1. `--KEY=VALUE`

通过命令行设置的参数可以通过 "cli" 文件所访问。例如下面的 CLI 命令：

```bash
--mongo-password=$MONGO_PASSWORD
```

在你的程序中使用如下的代码就能够访问了：

```swift
let mongoPassword = drop.config["cli", "mongo-password"]?.string
```

#### 2. --CONFIG:FILE-NAME.KEY=CUSTOM-VALUE

如果你想要命令行参数被设置在 "cli" 以外，可以使用更加高级的语法。例如下面的 CLI 命令：

```bash
--config:keys.analytics=124ZH61F
```

在你的程序中使用如下的代码就能够访问了：

```swift
let analyticsKey = drop.config["keys", "analytics"]?.string
```
