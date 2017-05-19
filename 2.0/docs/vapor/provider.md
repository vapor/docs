# Provider

The `Provider` protocol creates a simple and predictable way for adding functionality and third party packages to your Vapor project.

## Adding a Provider

Adding a provider to your application takes 2-3 steps.

### Add Package

All of Vapor's providers end with the `-provider` syntax. You can see a list of [available providers](https://github.com/vapor?utf8=✓&q=-provider) by searching on our GitHub.

To add the provider to your package, add it as a dependency in your `Package.swift` file.

```swift
let package = Package(
    name: "MyApp",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2)
    ]
)
```

!!! warning
    Always run `vapor update` or `vapor clean` after editing your `Package.swift` file.

### Import

Once the provider has been added, you can import it using `import VaporFoo` where `Foo` is the name of the provider.

Here is what importing the MySQL provider looks like:

```swift
import Vapor
import MySQLProvider
```

### Add to Droplet

Every provider comes with a class named `Provider`. Add this class to your Droplet using the `addProvider` method. 

```swift
let config = try Config()
try config.addProvider(MySQLProvider.Provider.self)

let drop = try Droplet(config)

// ...

drop.run()
```

### Configuration

Some drivers may require a configuration file. For example, `MySQLProvider` requires a `Config/mysql.json` file like the following:

```json
{
	"hostname": "localhost",
	"user": "root",
	"password": "",
	"database": "vapor"
}
```

You will receive an error during the `Droplet`'s initialization if a configuration file is required.

!!! tip
    Storing sensitive configuration files (ones that contain passwords) in the `Config/secrets` folder will prevent them from being tracked by git.

### Manual

Some providers can be configured manually by using the Provider's init method. This method can be used instead of configuration files.

```swift
let mysqlProvider = VaporMySQL.Provider(host: "localhost", user: "root", password: "", database: "vapor")
try config.addProvider(mysqlProvider)
```

## Create a Provider

Creating a provider is easy, you just need to create a package with a class `Provider` that conforms to `Vapor.Provider`.

### Example

Here is what a provider for an example `Foo` package would look like. All the provider does is take a message, then print the message when the `Droplet` starts.

```swift
import Vapor

public final class Provider: Vapor.Provider {
	public let message: String

    public convenience init(config: Config) throws {
    	guard let message = config["foo", "message"].string else {
    		throw ConfigError.missing(key: ["message"], file: "foo", desiredType: String.self)
    	}

        self.init(message: message)
    }

    public init(message: String) {
		self.message = message
    }

    public func boot(_ drop: Droplet) { }

    public func beforeRun(_ drop: Droplet) {
		drop.console.info(message)
    }
}
```

This provider wil require a `Config/foo.json` file that looks like:

```json
{
	"message": "The message to output"
}
```

The provider can also be initialized manually with the `init(message: String)` init.
