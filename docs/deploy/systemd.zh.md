# Systemd

Systemd 是大多数 Linux 发行版中默认的系统和服务管理器。它通常是默认安装的，所以在支持 Swift 的发行版上无需安装。

## 配置

服务器上的每个 Vapor 应用程序都应该有自己的服务文件。对于 `Hello` 示例项目，配置文件位于 `/etc/systemd/system/hello.service`. 该文件如下所示：

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/Run serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

正如我们的配置文件中所指定的，`Hello` 项目位于用户 `vapor` 的主文件夹中。确保 `WorkingDirectory` 指向 `Package.swift` 文件所在项目的根目录。

`--env production` 标志将禁用详细日志记录。

### 环境

此外，以下部分是可选配置，但建议使用。

你可以通过 systemd 以下面其中一种方式导出变量，或通过创建一个包含所有环境变量的文件：

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```

或者你可以直接将它们添加到服务文件 `[service]` 下：

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```

在 Vapor 中可以用使用 `Environment.get` 导出变量。

```swift
let port = Environment.get("PORT")
```

## 启动

你现在可以通过 `root` 身份运行以下命令来加载、启用、启动、停止和重启你的应用程序了。

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
