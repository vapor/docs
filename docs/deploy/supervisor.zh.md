# Supervisor

[Supervisor](http://supervisord.org) 是一个进程控制系统，可让你轻松启动、停止和重启你的 Vapor 应用程序。

## 安装

Supervisor 可以通过 Linux 上的包管理器安装。

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS and Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## 配置

服务器上的每个 Vapor 应用程序都应该有自己的配置文件。例如 `Hello` 项目，配置文件位于 `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

正如我们的配置文件中所指定的， `Hello` 项目位于用户 `vapor` 的主文件夹中。确保 `directory` 指向 `Package.swift` 文件所在项目的根目录。

`--env production` 标志会禁用详细日志记录。

### 环境

你可以使用 supervisor 将变量导出到你的 Vapor 应用程序。要导出多个环境值，请将它们全部放在一行上。根据 [Supervisor 文档](http://supervisord.org/configuration.html#program-x-section-values):

> 包含非字母数字字符的值应该用引号括起来(e.g. KEY="val:123",KEY2="val,456")。否则，引用值是可选的，但是推荐使用。

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

可以在 Vapor 中使用 `Environment.get` 导出变量

```swift
let port = Environment.get("PORT")
```

## 开始

你现在可以加载并启动你的应用程序。

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "注意" 
	`add` 命令可能已经启动了你的应用程序。
