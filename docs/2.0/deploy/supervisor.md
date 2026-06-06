# Supervisor

[Supervisor](http://supervisord.org) is a process control system that makes it easy to start, stop, and restart your Vapor app.

## Install

```sh
sudo apt-get update
sudo apt-get install supervisor
```

## Configure

Each Vapor app on your server should have its own configuration file. For an example `Hello` project, the configuration file would be located at `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/Run serve --env=production
directory=/home/vapor/hello/
user=www-data
stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log
```

As specified in our configuration file the `Hello` project is located in the home folder for the user `vapor`. Make sure `directory` points to the root directory of your project where the `Config/` folder is.

The `--env=production` flag will disable verbose logging and prioritize the `Config/production` sub folder of your configuration files.

### Environment

You can export variables to your Vapor app with supervisor.

```sh
environment=PORT=8123
```

Exported variables can be used in Vapor's configuration files with the `$` prefix.

`Config/production/servers.json `
```json
{
	"port": "$PORT"
}
```

The above config file will start a server named `my-server` on the port number exported by supervisor. This is a great way to control how Vapor starts from the supervisor config scripts. Feel free to name the server whatever you like.

## Start

You can now load and start your app.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
	The `add` command may have already started your app.
