# Droplet

The `Droplet` is a service container that gives you access to many of Vapor's facilities. It is responsible for registering routes, starting the server, appending middleware, and more.

!!! tip
    Normally applications will only have one Droplet. However, for advanced use cases, it is possible to create more than one.

## Initialization

As you have probably already seen, the only thing required to create an instance of `Droplet` is to import Vapor.

```swift
import Vapor

let drop = try Droplet()

// your magic here

drop.run()
```

Creation of the `Droplet` normally happens in the `main.swift` file. 

!!! note
    For the sake of simplicity, most of the documentations sample code uses just the `main.swift` file. See the [modules](../advanced/modules.md) section in Advanced to learn more about using multiple modules.

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

!!! warning
    Debug logs can reduce the number of requests your application can handle per second. Enable production mode to silence non-critical logs.

## Working Directory

The `workDir` property contains a path to the current working directory of the application. Vapor uses this property to find the folders related to your project, such as `Resources`, `Public`, and `Config`.

```swift
print(drop.workDir) // /var/www/my-project/
```

Vapor automatically determines the working directory in most situations. However, you may need to manually set it for advanced use cases.

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

#### Supported Properties

| Property   | Type                | `droplet.json` key         | Config Initializable |
|------------|---------------------|----------------------------|----------------------|
| server     | ServerProtocol.Type | server                     | no                   |
| client     | ClientProtocol.Type | client                     | no                   |
| log        | LogProtocol         | log                        | yes                  |
| hash       | HashProtocol        | hash                       | yes                  |
| cipher     | CipherProtocol      | cipher                     | yes                  |
| middleware | Middleware          | middleware.[server,client] | no                   |
| console    | ConsoleProtocol     | console                    | yes                  |
| cache      | CacheProtocol       | cache                      | yes                  |

#### Example

Let's create a custom logger to demonstrate Vapor's configurable properties.

`AllCapsLogger.swift`
```swift
final class AllCapsLogger: LogProtocol {
    var enabled: [LogLevel] = []
    func log(_ level: LogLevel, message: String, file: String, function: String, line: Int) {
        print(message.uppercased + "!!!")
    }
}
```

Now add the logger to the Droplet using the `addConfigurable` method for logs.

`main.swift`
```swift
let drop = try Droplet()

drop.addConfigurable(log: AllCapsLogger(), name: "all-caps")
```

Whenever the `"log"` property is set to `"all-caps"` in the `droplet.json`, our new logger will be used. 

`Config/development/droplet.json`
```json
{
    "log": "all-caps"
}
```

Here we are setting our logger only in the `development` environment. All other environments will use Vapor's default logger.

#### Config Initializable

For an added layer of convenience, you can allow your custom types to be initialized from configuration files.

In our previous example, we initialized an `AllCapsLogger` before adding it to the Droplet.

Let's say we want to allow our project to configure how many exclamation points get added with each log message.

`AllCapsLogger.swift`
```swift
final class AllCapsLogger: LogProtocol {
    var enabled: [LogLevel] = []
    let exclamationCount: Int

    init(exclamationCount: Int) {
        self.exclamationCount = exclamationCount
    }

    func log(_ level: LogLevel, message: String, file: String, function: String, line: Int) {
        print(message.uppercased + String(repeating: "!", count: exclamationCount))
    }
}

extension AllCapsLogger: ConfigInitializable {
   init(config: Config) throws {
        let count = config["allCaps", "exclamationCount"]?.int ?? 3
        self.init(exclamationCount: count)
   } 
}
```

!!! note
    The first parameter to `config` is the name of the file.

Now that we have conformed our logger to `ConfigInitializable`, we can pass just the type name to `addConfigurable`.


`main.swift`
```swift
let drop = try Droplet()

drop.addConfigurable(log: AllCapsLogger.self, name: "all-caps")
```

Now if you add a file named `allCaps.json` to the `Config` folder, you can configure the logger.

`allCaps.json`
```json
{
    "exclamationCount": 5
}
```

With this configurable abstraction, you can easily change how your application functions in different environments without needing to hard code these values into your source code.

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

!!! warning
    Remember that the Droplet's properties are initialized with usable defaults. This means that if you change a property, you must be sure to change it _before_ other parts of your code use it. 


