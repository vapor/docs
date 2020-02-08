# Supervisor

[Supervisor](http://supervisord.org) is a process control system that makes it easy to start, stop, and restart your Vapor app.

## Install

```sh
sudo apt-get update
sudo apt-get install supervisor
```

Supervisor can currently only run as the `root` user. You can exit and login as root, or create a new group and add `vapor` to it.

```sh
groupadd supervisor
usermod -a vapor -G supervisor
```

Log out, log back in, and edit the the supervisord configuration file (/etc/supervisor/supervisor.conf) unix_http_server section:

```sh
[unix_http_server]
file=/var/run/supervisor.sock ; (the path to the socket file)
chmod=0770 ; socket file mode (default 0700)
chown=root:supervisor
```

Finally, restart Supervisor:

```sh
supervisorctl reload
```

## Configure

Each Vapor app on your server should have its own configuration file. For an example `Hello` project, the configuration file would be located at `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/Run serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log
```

As specified in our configuration file the `Hello` project is located in the home folder for the user `vapor`. Make sure `directory` points to the root directory of your project where the `Package.swift` file is.

The `--env production` flag will disable verbose logging.

### Environment

You can export variables to your Vapor app with supervisor.

```sh
environment=PORT=8123
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
