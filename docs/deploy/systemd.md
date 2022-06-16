# Systemd

Systemd is the default system and service manager on most Linux distributions. It is usually installed by default so no installation is needed on supported Swift distributions.

### Ubuntu

Default system and service manager

### CentOS and Amazon Linux

Default system and service manager

### Fedora

Default system and service manager

## Configure

Each Vapor app on your server should have its own service file. For an example `Hello` project, the configuration file would be located at `/etc/systemd/system/hello.service`

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

As specified in our configuration file the `Hello` project is located in the home folder for the user `vapor`. Make sure `WorkingDirectory` points to the root directory of your project where the `Package.swift` file is.

The `--env production` flag will disable verbose logging.

### Environment
Otherwise, quoting the values is optional but recommended.

You can export variables in two ways via systemd. Either by creating an environment file with all the variables set in it:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Or you can add them directly to the service file under `[service]`

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Exported variables can be used in Vapor using `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Start

You can now load, enable, start, stop and restart your app by running the following as root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
