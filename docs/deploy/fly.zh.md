# Fly

Fly 是一个托管平台，支持运行服务器应用程序和数据库，专注于边缘计算。更多信息请参阅[官网](https://fly.io/)。

!!! note "注意"
    本文档指定的命令受 [Fly 价格](https://fly.io/docs/about/pricing/)约束，继续之前确保你已经了解它。

## 注册
如果你没有账号，你需要[注册](https://fly.io/app/sign-up)一个。

## 安装 flyctl
你与 Fly 的主要交互方式是使用专用的 CLI 工具 `flyctl`，你需要安装该工具。

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### 其它安装选项
有关更多选项和详细信息，请参阅 [flyctl 文档](https://fly.io/docs/hands-on/install-flyctl/)。

## 登录
通过终端登录，运行如下命令：
```bash
fly auth login
```

## 配置你的 Vapor 项目
在部署到 Fly 之前，确保你的 Vapor 项目包含一个配置好的 Dockerfile 文件。因为 Fly 需要使用它来构建你的应用程序。在大多数情况下，这很容易，因为默认的 Vapor 模板已经包含了一个 Dockerfile 文件 。

### 创建新的 Vapor 项目
创建新项目的最简单方式是使用模板。你可以使用 GitHub 模板或 Vapor 工具箱创建模板。如果你需要一个数据库，推荐使用 Fluent 和 Postgres；Fly 可以轻松创建一个 Postgres 数据库，以便连接你的应用程序（请参阅下面的[具体章节](#postgres)）。

#### 使用 Vapor 工具箱
首先，确保你已安装了 Vapor 工具箱（请参见 [macOS](../install/macos.zh.md#install-toolbox) 或 [Linux](../install/linux.zh.md#install-toolbox) 的安装说明）。使用以下命令创建新应用程序，替换 `app-name` 为所需的应用程序名称：
```bash
vapor new app-name
```

该命令将显示一个交互式提示，让你配置 Vapor 项目，如果需要，你可以在此选择 Fluent 和 Postgres 。

#### 使用 GitHub 模板
在以下列表中选择最适合你需求的模板。你可以使用 Git 将其克隆到本地，也可以使用“使用此模板”按钮创建一个 GitHub 项目。

- [Barebones template](https://github.com/vapor/template-bare)
- [Fluent/Postgres template](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf template](https://github.com/vapor/template-fluent-postgres-leaf)

### 已有的 Vapor 项目
如果你有一个现有的 Vapor 项目，请确保项目的根目录中有一个正确配置的 `Dockerfile` 文件；[Vapor 文档中关于使用 Docker](../deploy/docker.zh.md) 和 [Fly 文档中关于通过 Dockerfile 部署应用程序](https://fly.io/docs/getting-started/dockerfile/)可能会对你有所帮助。

## 在 Fly 上启动应用
一旦你的 Vapor 项目准备就绪，就可以在 Fly 上启动它。

首先，确保你的当前目录设置为 Vapor 应用程序的根目录，并运行以下命令：
```bash
fly launch
```

这将启动一个交互式提示，以配置你的 Fly 应用程序设置：

- **Name:** 你可以输入一个名称，或保留空白以获取自动生成的名称。
- **Region:** 默认情况下，为用户当前所在区域。你可以选择使用它或列表中的任何其他区域。后期可以更改。
- **Database:** 你可以要求 Fly 创建一个数据库与应用程序一起使用。如果你愿意，你始终可以使用 `fly pg create` 和 `fly pg attach` 命令进行相同的操作（详细信息，请参阅[配置 Postgres 部分](#postgres)。

`fly launch` 命令会自动创建一个 `fly.toml` 文件。它包含私有/公共端口映射、健康检查参数等设置。如果你刚刚使用 `vapor new` 从头开始创建了一个新项目，则默认的 `fly.toml` 文件不需要更改。如果你有一个现有的项目，则 `fly.toml` 可能只需要进行轻微的更改。你可以在 [fly.toml 文档](https://fly.io/docs/reference/configuration/)中找到更多信息。

请注意，如果你请求 Fly 创建一个数据库，则必须等待一段时间才能创建并通过健康检查。

在退出之前，`fly launch` 命令将询问你是否要立即部署应用程序。你可以接受或稍后使用 `fly deploy` 进行部署。

!!! tip "建议"
    当前目录在你的应用程序根目录中时，fly CLI 工具会自动检测到 `fly.toml` 文件的存在，从而让 Fly 知道命令作用于哪个应用程序。如果你想无论在哪个目录都能针对特定的应用程序，请在大多数 Fly 命令后面附加 `-a 你的应用程序名称`。

## 部署
每当你部署新更改到 Fly 时，运行 `fly deploy` 命令。

Fly 会读取你的目录中的 `Dockerfile` 和 `fly.toml` 文件来确定如何构建和运行你的 Vapor 项目。

一旦你的容器构建完成，Fly 会启动一个实例。它将运行各种健康检查，确保你的应用程序正常运行并且你的服务器响应请求。如果健康检查失败，`fly deploy` 命令将退出并显示错误消息。

默认情况下，如果新版本健康检查失败，Fly 会回滚到最新的可用版本。

## 配置 Postgres

### 在 Fly 上创建一个 Postgres 数据库
如果你在第一次启动应用时没有创建数据库应用，你可以使用以下命令创建：
```bash
fly pg create
```

这个命令创建了一个 Fly 应用程序，可以为其他 Fly 上的应用程序提供数据库服务，详情请参阅 [Fly 文档](https://fly.io/docs/reference/postgres/)。

创建完数据库应用之后，进入你的 Vapor 应用程序的根目录，运行以下命令：
```bash
fly pg attach name-of-your-postgres-app
```

如果你不知道你的 Postgres 应用程序的名称，可以使用 `fly pg list` 命令查找。

`fly pg attach` 命令创建了一个数据库和一个专门针对你的应用程序的用户，然后通过 `DATABASE_URL` 环境变量将其暴露给你的应用程序。

!!! note "注意"
    `fly pg create` 和 `fly pg attach` 的区别在于前者分配和配置了一个能够托管 Postgres 数据库的 Fly 应用程序，而后者则创建了一个实际的数据库和用户，以供你选择的应用程序使用。只要符合你的要求，单个 Postgres Fly 应用程序就可以托管多个由不同应用程序使用的数据库。当你在 `fly launch` 中请求 Fly 创建一个数据库应用程序时，Fly 会执行相当于调用 `fly pg create` 和 `fly pg attach` 两个命令的操作。

### 连接 Vapor 应用程序到数据库
一旦你的应用程序已连接到数据库，Fly 会将 `DATABASE_URL` 环境变量设置为包含你的凭据的连接 URL（它应该被视为敏感信息）。

对于大多数常见的 Vapor 项目设置，你可以在 `configure.swift` 文件中配置你的数据库。下面是你可能想要执行的操作：

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // 在这里处理缺少 DATABASE_URL 的情况...
    //
    // 或者，你也可以根据 app.environment 是否设置为 .development 或 .production 来设置不同的配置
}
```

此时，你的项目应该已准备好运行迁移并使用数据库了。

### 运行迁移
使用 `fly.toml` 的 `release_command`，可以要求 Fly 在运行主服务器进程之前运行某个命令。将其添加到 `fly.toml` 中：
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note "注意"
    上面的代码片段假设你正在使用默认的 Vapor Dockerfile，该文件将你的应用程序 `ENTRYPOINT` 设置为 `./Run`。具体来说，这意味着当你将 `release_command` 设置为 `migrate -y` 时，Fly 将调用 `./Run migrate -y`。如果你的 `ENTRYPOINT` 设置为其他值，则需要调整 `release_command` 的值。

Fly 将在具有访问 Fly 内部网络、密钥和环境变量的临时实例中运行你的发布命令。

如果你的发布命令失败，部署将无法继续。

### 其他数据库
虽然 Fly 使创建 Postgres 数据库应用程序变得容易，但也可以托管其他类型的数据库（例如，请参阅 Fly 文档中的 [”使用 MySQL 数据库“](https://fly.io/docs/app-guides/mysql-on-fly/)）。


## 密钥和环境变量
### 密钥
使用密钥将任何敏感值设置为环境变量。
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning "警告"
    请注意，大多数 shell 都会保留你输入的命令历史记录。在使用此方式设置密钥时要注意。某些 shell 可以配置为不记录以空格为前缀的命令。请参阅 [`fly secrets import` 命令](https://fly.io/docs/flyctl/secrets-import/)的文档。

更多信息，请参阅 [`fly secrets` 文档](https://fly.io/docs/reference/secrets/) 。

### 环境变量
你可以在 [`fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section) 中设置其他非敏感的环境变量，例如：

```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH连接
你可以使用以下方式连接到应用实例：
```bash
fly ssh console -s
```

## 查看日志
你可以使用以下命令查看应用程序的实时日志：
```bash
fly logs
```

## 下一步
现在，你的 Vapor 应用已经部署完成，你可以进行更多操作，例如在多个区域垂直和水平扩展你的应用程序、添加持久卷、设置持续部署，甚至创建分布式应用程序集群。学习如何执行这些操作的最好地方是查看 [Fly 文档](https://fly.io/docs/)。

