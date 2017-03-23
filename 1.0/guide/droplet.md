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

drop.run()
```

Creation of the `Droplet` normally happens in the `main.swift` file.

## Environment

The `environment` property contains the current environment your application is running in. Usually development, testing, or production.

```swift
if drop.environment == .production {
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

## Modifying Properties

The `Droplet`'s properties can be changed programmatically or through configuration.

### Programmatic 

Properties on the `Droplet` can be changed after it is initialized.

```swift
let drop = Droplet()

drop.server = MyServerType.self
```

Here the type of server the `Droplet` uses is changed to a custom type. When the `Droplet` is run, this custom server type will be booted instead of the default server.

### Configurable

If you want to modify a property of the `Droplet` only in certain cases, you can use `addConfigurable`. Say for example you want to email error logs to yourself in production, but you don't want to spam your inbox while developing.

```swift
let drop = Droplet()

drop.addConfigurable(log: MyEmailLogger.self, name: "email")
```

The `Droplet` will continue to use the default logger until you modify the `Config/droplet.json` file to point to your email logger. If this is done in `Config/production/droplet.json`, then your logger will only be used in production.

```json
{
    "log": "email"
}
```

## Initialization

The `Droplet` init method is fairly simple since most properties are variable and can be changed after initialization.

Most plugins for Vapor come with a [Provider](provider.md), these take care of configuration details for you.

```swift
Droplet(
    arguments: [String]?,
    workDir workDirProvided: String?,
    config configProvided: Config?,
    localization localizationProvided: Localization?,
)
```

> Note: Remember that the Droplet's properties are initialized with usable defaults. This means that if you change a property, you must be sure to change it _before_ other parts of your code use it. Otherwise, you may end up with confusing results as the defaults are used sometimes, and your overrides are used other times.

