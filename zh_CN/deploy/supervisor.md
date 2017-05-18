---
currentMenu: deploy-supervisor
---


# Supervisor

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

[Supervisor](http://supervisord.org) 是一个进程管理系统，它使启动、停止和重启你的 Vapor 应用变得简单。

## 安装 （Install）

```sh
sudo apt-get update
sudo apt-get install supervisor
```

## 配置 （Configure）

每一个运行在你的服务器上的 Vapor 应用，都应该有它自己的配置文件。例如 `Hello` 项目，配置文件可能是 `/etc/supervisor/conf.d/hello.conf`。

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env=production
directory=/home/vapor/hello/
user=www-data
stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log
```

正如我们的配置文件中指定的那样，`Hello` 项目位于用户 `vapor` 的主文件夹中。确保 `directory` 指向你的项目的 `Config/` 文件夹的根目录。

`--env = production` 标志将禁用详细日志（verbose logging）记录，并优先使用 `Config /production` 文件夹中的配置文件。

### Environment

你能够使用 supervisor 导出变量到你的 Vapor 应用。

```sh
environment=PORT=8123
```

导出的变量可以在 Vapor 的配置文件中通过 `$` 前缀使用。

`Config/production/servers.json `
```json
{
	"my-server": {
		"port": "$PORT"
	}
}
```

上面的配置文件，将启动一个叫 `my-server` 的服务器，并绑定到 supervisor 导出的端口上。这是控制 Vapor 如何从 supervisor 配置脚本启动的一种很好的方式。可以自由的命名 server 的名字。

## Start

现在你能加载且地洞你的应用。

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

> 注意： `add` 命令可能已经启动了你的应用。
