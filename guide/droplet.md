---
currentMenu: guide-droplet
---

# Droplet

The `Droplet` is a service container that gives you access to many of Vapor's facilities. It is responsible for registering routes, starting the server, appending middleware, and more.

## Initialization

As you have probably already seen, the only thing required to create an instance of `Droplet` is to import Vapor.

```swift
import Vapor

let drop = Droplet()

// your magic here

drop.start()
```

Creation of the `Droplet` normally happens in the `main.swift` file.

## Environment

The `environment` property contains the current environment your application is running in. Usually development, testing, or production.

```swift
if drop.config.environment == .production {
    ...
}
```

The environment affects [Config](config.md) and [Logging](log.md). The environment is `development` by default. To change it, pass the `--env=` flag as an argument.

```sh
vapor run serve --env=production
```

If you are in Xcode, you can pass arguments through the scheme editor.

> Note: Debug logs can reduce the number of requests your application can handle per second. Enabling the production environment can improve performance.

## Working Directory

The `workDir` property contains a path to the current working directory of the application relative to where it was started. By default, this property assumes you started the Droplet from its root directory.

```swift
drop.workDir // "/var/www/my-project/"
```

You can override the working directory through the `Droplet`'s initializer, or by passing the `--workdir` argument.

```sh
vapor run serve --workdir="/var/www/my-project"
```

## Initialization

The `Droplet` has several customizable properties.

Most plugins for Vapor come with a [Provider](providers.md), these take care of configuration details for you.

```swift
Droplet(
    arguments: [String]?,
    workDir workDirProvided: String?,
    config configProvided: Config?,
    localization localizationProvided: Localization?,
    server: ServerProtocol.Type?,
    sessions: Sessions?,
    hash: Hash?,
    console: ConsoleProtocol?,
    log: Log?,
    client: ClientProtocol.Type?,
    database: Database?,
    preparations: [Preparation.Type],
    providers: [Provider.Type],
    initializedProviders: [Provider]
)
```
