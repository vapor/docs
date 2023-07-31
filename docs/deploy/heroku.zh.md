# Heroku 是什么

Heroku 是一个一站式程序托管平台，你可以通过[heroku.com](https://www.heroku.com)获取更多信息

## 注册

你需要一个 heroku 帐户，如果你还没有，请通过此链接注册：[https://signup.heroku.com/](https://signup.heroku.com/)

## 安装命令行应用

请确保你已安装 heroku 命令行工具

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### 其他安装方式

在此处查看其他安装选项: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### 登录

安装命令行工具后，使用以下命令登录:

```bash
heroku login
```

查看当前登录的 heroku 电子邮件账户:

```bash
heroku auth:whoami
```

### 创建一个应用

通过访问 heroku.com 来访问你的帐户，然后从右上角的下拉菜单中创建一个新应用程序。Heroku 会问一些问题，例如区域和应用程序名称，只需按照提示操作即可。

### Git

Heroku 使用 Git 来部署你的应用程序，因此你需要将你的项目放入 Git 存储库（如果还没有的话）。

#### 初始化 Git

如果你需要将 Git 添加到你的项目中，在终端中输入以下命令:

```bash
git init
```

#### Master

你应该选择一个分支，并坚持将其用于部署到 Heroku，比如 **main** 或 **master** 分支。确保在推送之前将所有更改都加入此分支。

通过以下命令检查你当前的分支：

```bash
git branch
```

星号表示当前分支。

```bash
* main
  commander
  other-branches
```

> **提示**：如果你没有看到任何输出并且你刚刚执行了 `git init`。 你需要先提交（commit）你的代码，然后你会看到 `git branch` 命令的输出。


如果你当前 _不在_ 正确的分支上，请输入以下命令来切换（针对 **main** 分支来说）：

```bash
git checkout main
```

#### 提交更改

如果此命令有输出，那么你有未提交的改动。

```bash
git status --porcelain
```

通过以下命令来提交

```bash
git add .
git commit -m "a description of the changes I made"
```

#### 与 Heroku 进行连接

将你的应用与 heroku 连接（替换为你的应用名称）。

```bash
$ heroku git:remote -a your-apps-name-here
```

### 设置运行包（Buildpack）

设置运行包来告知 heroku 如何处理 Vapor。

```bash
heroku buildpacks:set vapor/vapor
```

### Swift 版本文件

我们添加的运行包会查找 **.swift-version** 文件以了解要使用的 swift 版本。 （将 5.8.1 替换为你的项目需要的任何版本。）

```bash
echo "5.8.1" > .swift-version
```

这将创建 **.swift-version** ，内容为 `5.8.1`。


### Procfile

Heroku 使用 **Procfile** 来知道如何运行你的应用程序，在我们的示例中它需要这样配置：

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

我们可以使用以下终端命令来创建它

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### 提交更改

我们刚刚只是更改了这些文件，但它们没有被提交。 如果我们推送（push），heroku 将无法看到这些更改。

使用以下命令提交它们。

```bash
git add .
git commit -m "adding heroku build files"
```

### 部署到 Heroku

你已准备好开始部署，从终端运行以下命令。 构建过程可能会需要一些时间，不必担心。

```none
git push heroku main
```

### 扩展

成功构建后，你需要添加至少一台服务器，Eco 计划的价格从每月$5起（参见[定价](https://www.heroku.com/pricing#containers)），请确保在 Heroku 上配置了付款方式。然后，针对单个 web worker 执行下面命令：

```bash
heroku ps:scale web=1
```

### 继续部署

当你想更新时只需将最新的更改推入 main 分支并推送到 heroku，它就会重新部署。

## Postgres

### 添加 PostgreSQL 数据库

在 dashboard.heroku.com 上访问你的应用程序，然后转到 **Add-ons** 部分。

从这里输入`postgres`，你会看到`Heroku Postgres`的选项。 选择它。

选择每月$5的 Eco 计划（参见[定价](https://www.heroku.com/pricing#data-services)），并进行预配。剩下的交给 Heroku 处理。

完成后，你会看到数据库出现在 **Resources** 选项卡下。

### 配置数据库

我们现在必须告诉我们的应用程序如何访问数据库。 在 app 目录中运行。

```bash
heroku config
```

这会输出类似以下内容的内容：

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** 这里将代表 postgres 数据库。 请**从不** 硬编码静态 url，heroku 会变更这个 url，并破坏你的应用程序。

以下是一个示例数据库配置

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

如果你使用 Heroku Postgres 的标准计划，则需要开始未验证的 TLS。

不要忘记提交这些更改

```none
git add .
git commit -m "configured heroku database"
```

### 重置你的数据库

你可以使用 `run` 命令在 heroku 上恢复或运行其他命令。
要重置你的数据库请运行：

```bash
heroku run App -- revert --all --yes --env production
```

如要迁移请运行以下命令：

```bash
heroku run App -- migrate --env production
```
