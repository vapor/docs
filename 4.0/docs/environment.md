# Environment

Vapor's Environment API helps you configure your app dynamically. By default, your app will use the `development` environment. You can define other useful environments like `production` or `staging` and change how your app is configured in each case. You can also load in variables from the process's environment or `.env` (dotenv) files depending on your needs.

To access the current environment, use `app.environment`. You can switch on this property in `configure(_:)` to execute different configuration logic. 

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Changing Environment

By default, your app will run in the `development` environment. You can change this by passing the `--env` (`-e`) flag during app boot.

```swift
vapor run serve --env production
```

Vapor includes the following environments:

|name|short|description|
|-|-|-|
|production|prod|Deployed to your users.|
|development|dev|Local development.|
|testing|test|For unit testing.|

!!! info
    The `production` environment will default to `notice` level logging unless otherwise specified. All other environments default to `info`. 

You can pass either the full or short name to the `--env` (`-e`) flag.

```swift
vapor run serve -e prod
```

## Process Variables

`Environment` offers a simple, string-based API for accessing the process's environment variables.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

In addition to `get`, `Environment` offers a dynamic member lookup API via `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

When running your app in the terminal, you can set environment variables using `export`. 

```sh
export FOO=BAR
vapor run serve
```

When running your app in Xcode, you can set environment variables by editing the `Run` scheme.

## .env (dotenv)

Dotenv files contain a list of key-value pairs to be automatically loaded into the environment. These files make it easy to configure environment variables without needing to set them manually.

Vapor will look for dotenv files in the current working directory. If you're using Xcode, make sure to set the working directory by editing the `Run` scheme.

Assume the following `.env` file placed in your projects root folder:

```sh
FOO=BAR
```

When your application boots, you will be able to access the contents of this file like other process environment variables.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Variables specified in `.env` files will not overwrite variables that already exist in the process environment. 

Alongside `.env`, Vapor will also attempt to load a dotenv file for the current environment. For example, when in the `development` environment, Vapor will load `.env.development`. Any values in the specific environment file will take precedence over the general `.env` file.

A typical pattern is for projects to include a `.env` file as a template with default values. Specific environment files are ignored with the following pattern in `.gitignore`:

```gitignore
.env.*
```

When the project is cloned to a new computer, the template `.env` file can be copied and have the correct values inserted. 

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Dotenv files with sensitive information such as passwords should not be committed to version control.

If you're having difficulty getting dotenv files to load, try enabling debug logging with `--log debug` for more information. 

## Custom Environments

To define a custom environment name, extend `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

The application's environment is usually set in `main.swift` using `Environment.detect()`.

```swift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer { app.shutdown() }
```

The `detect` method uses the process's command line arguments and parses the `--env` flag automatically. You can override this behavior by initializing a custom `Environment` struct.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

The arguments array must contain at least one argument which represents the executable name. Further arguments can be supplied to simulate passing arguments via the command line. This is especially useful for testing.
