# Fly

Fly is a hosting platform that enables running server applications and databases with a focus on edge computing. See [their website](https://fly.io/) for more information.

!!! note
    Commands specified in this document are subject to [Fly's pricing](https://fly.io/docs/about/pricing/), make sure you understand it properly before continuing.

## Signing up
If you don't have an account, you will need to [create one](https://fly.io/app/sign-up).

## Installing flyctl
The main way you interact with Fly is by using the dedicated CLI tool, `flyctl`, which you'll need to install.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Other install options
For more options and details, see [the `flyctl` installation docs](https://fly.io/docs/hands-on/install-flyctl/).

## Logging in
To log in from your terminal, run the following command:
```bash
fly auth login
```

## Configuring your Vapor project
Before deploying to Fly, you must make sure you have a Vapor project with an adequately configured Dockerfile, since it's required by Fly to build your app. In most cases, this should be very easy since the default Vapor templates already contain one.

### New Vapor project
To easiest way to create a new project is to start with a template. You can create one using GitHub templates or the Vapor toolbox. If you need a database, it is recommended to use Fluent with Postgres; Fly makes it easy to create a Postgres database to connect your apps to (see the [dedicated section](#configuring-postgres) below).

#### Using the Vapor toolbox
First, ensure you have installed the Vapor toolbox (see install the instructions for [macOS](../install/macos.md#install-toolbox) or [Linux](../install/linux.md#install-toolbox)).
Create your new app with the following command, replacing `app-name` with the app name you desire:
```bash
vapor new app-name
```

This command will display an interactive prompt that will let you configure your Vapor project, this is where you can select Fluent and Postgres if you need them.

#### Using GitHub templates
Choose the template that best suits your needs in the following list. You can either clone it locally using Git or create a GitHub project with the "Use this template" button.

- [Barebones template](https://github.com/vapor/template-bare)
- [Fluent/Postgres template](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf template](https://github.com/vapor/template-fluent-postgres-leaf)

### Existing Vapor project
If you have an existing Vapor project, make sure you have a properly configured `Dockerfile` present at the root of your directory; the [Vapor docs about using Docker](../deploy/docker.md) and [Fly docs about deploying an app via a Dockerfile](https://fly.io/docs/getting-started/dockerfile/) might come in handy.

## Launch your app on Fly
Once your Vapor project is ready, you can launch it on Fly.

First, make sure your current directory is set to the root directory of your Vapor application and run the following command:
```bash
fly launch
```

This will start an interactive prompt to configure your Fly application settings:

- **Name:** you can type one or keep it blank to get an automatically generated name.
- **Region:** the default is the one that's the closest to you. You can choose to use it or any other in the list. This is easy to change later.
- **Database:** you can ask Fly to create a database to use with your app. If you prefer, you can always do the same later with the `fly pg create` and `fly pg attach` commands (see the [Configuring Postgres section](#configuring-postgres) for more details).

The `fly launch` command automatically creates a `fly.toml` file. It contains settings such as private/public port mappings, health checks parameters, and many others. If you just created a new project from scratch using `vapor new`, the default `fly.toml` file needs no changes. If you have an existing project, chances are `fly.toml` might also be ok with no or minor changes only. You can find more information in [the `fly.toml` docs](https://fly.io/docs/reference/configuration/).

Note that if you request Fly to create a database, you will have to wait a bit for it to be created and pass health checks.

Before exiting, the `fly launch` command will ask you if you would like to deploy your app immediately. You can accept it or do it later using `fly deploy`.

!!! tip
    When your current directory is in your app's root, the fly CLI tool automatically detects the presence of a `fly.toml` file which lets Fly know which app your commands are targetting. If you want to target a specific app no matter your current directory, you can append `-a name-of-your-app` to most Fly commands.

## Deploying
You run the `fly deploy` command whenever you need to deploy new changes to Fly.

Fly reads your directory's `Dockerfile` and `fly.toml` files to determine how to build and run your Vapor project.

Once your container is built, Fly starts an instance of it. It will run various health checks, ensuring your application is running fine and your server responds to requests. The `fly deploy` command exits with an error if health checks fail.

By default, Fly will roll back to the latest working version of your app if health checks fail for the new version you attempted to deploy.

## Configuring Postgres

### Creating a Postgres database on Fly
If you didn't create a database app when you first launched your app, you can do it later using:
```bash
fly pg create
```

This command creates a Fly app that will be able to host databases available to your other apps on Fly, see the [dedicated Fly docs](https://fly.io/docs/reference/postgres/) for more details.

Once your database app is created, go to your Vapor app's root directory and run:
```bash
fly pg attach name-of-your-postgres-app
```
If you don't know the name of your Postgres app, you can find it with `fly pg list`.

The `fly pg attach` command creates a database and user destined to your app, and then exposes it to your app through the `DATABASE_URL` environment variable. 

!!! note
    The difference between `fly pg create` and `fly pg attach` is that the former allocates and configures a Fly app that will be able to host Postgres databases, while the latter creates an actual database and user destined to the app of your choice. Provided it suits your requirements, a single Postgres Fly app could host multiple databases used by various apps. When you ask Fly to create a database app in `fly launch`, it does the equivalent of calling both `fly pg create` and `fly pg attach`.

### Connecting your Vapor app to the database
Once your app is attached to your database, Fly sets the `DATABASE_URL` environment variable to the connection URL that contains your credentials (it should be treated as sensitive information).

With most common Vapor project setups, you configure your database in `configure.swift`. Here's how you might want to do this:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Handle missing DATABASE_URL here...
    //
    // Alternatively, you could also set a different config 
    // depending on wether app.environment is set to to 
    // `.development` or `.production`
}
```

At this point, your project should be ready to run migrations and use the database.

### Running migrations
With `fly.toml`'s `release_command`, you can ask Fly to run a certain command before running your main server process. Add this to `fly.toml`:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    The code snippet above assumes you are using the default Vapor Dockerfile which sets your app `ENTRYPOINT` to `./App`. Concretely, this means that when you set `release_command` to `migrate -y`, Fly will call `./App migrate -y`. If your `ENTRYPOINT` is set to a different value, you will need to adapt the value of `release_command`.

Fly will run your release command in a temporary instance that has access to your internal Fly network, secrets, and environment variables.

If your release command fails, the deployment won't continue.

### Other databases
While Fly makes it easy to create a Postgres database app, it is possible to host other types of databases as well (for instance, see ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) in the Fly Docs).

## Secrets and environment variables
### Secrets
Use secrets to set any sensitive values as environment variables.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    Keep in mind that most shells keep an history of the commands you typed. Be cautious about this when setting secrets this way. Some shells can be configured to not remember commands that are prefixed by a whitespace. See also the [`fly secrets import` command](https://fly.io/docs/flyctl/secrets-import/).

For more information, see the [documentation of `fly secrets`](https://fly.io/docs/reference/secrets/).

### Environment variables
You can set other non-sensitive [environment variables in `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), for instance:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH connection
You can connect to an app's instances using:
```bash
fly ssh console -s
```

## Checking the logs
You can check your app's live logs using:
```bash
fly logs
```

## Next steps
Now that your Vapor app is deployed, there is a lot more you can do such as scaling your apps vertically and horizontally across multiple regions, adding persistent volumes, setting up continuous deployment, or even creating distributed app clusters. The best place to learn how to do all of this and more is the [Fly docs](https://fly.io/docs/).
