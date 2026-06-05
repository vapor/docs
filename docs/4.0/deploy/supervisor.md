# Supervisor

[Supervisor](http://supervisord.org) is a process control system that makes it easy to start, stop, and restart your Vapor app.

## Install

Supervisor can be installed through package managers on Linux.

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

## Configure

Each Vapor app on your server should have its own configuration file. For an example `Hello` project, the configuration file would be located at `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

As specified in our configuration file the `Hello` project is located in the home folder for the user `vapor`. Make sure `directory` points to the root directory of your project where the `Package.swift` file is.

The `--env production` flag will disable verbose logging.

### Environment

You can export variables to your Vapor app with supervisor. For exporting multiple environment values, put them all on one line. Per [Supervisor documentation](http://supervisord.org/configuration.html#program-x-section-values):

> Values containing non-alphanumeric characters should be quoted (e.g. KEY="val:123",KEY2="val,456"). Otherwise, quoting the values is optional but recommended.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Exported variables can be used in Vapor using `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Start

You can now load and start your app.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
	The `add` command may have already started your app.
