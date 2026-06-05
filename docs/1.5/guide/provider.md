---
currentMenu: guide-provider
---

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
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 1, minor: 0)
    ]
)
```

> It's important to `vapor clean` or `vapor build --clean` after adding new packages.

### Import

Once the provider has been added, you can import it using `import VaporFoo` where `Foo` is the name of the provider.

Here is what importing the MySQL provider looks like:

```swift
import Vapor
import VaporMySQL

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

// ...

drop.run()
```

Every provider comes with a class named `Provider`. Append the `Type` of this class to your `providers` array in the `Droplet`'s init method.

### Config

Some drivers may require a configuration file. For example, `VaporMySQL` requires a `Config/mysql.json` file like the following:

```json
{
	"host": "localhost",
	"user": "root",
	"password": "",
	"database": "vapor"
}
```

You will receive an error during the `Droplet`'s initialization if a configuration file is required.

## Advanced

You may choose to initialize the provider yourself. 

```swift
import Vapor
import VaporMySQL

let drop = Droplet()

let mysql = try VaporMySQL.Provider(host: "localhost", user: "root", password: "", database: "vapor")
drop.addProvider(mysql)

...

drop.run()
```

## Create a Provider

Creating a provider is easy, you just need to create a package with a class `Provider` that conforms to `Vapor.Provider`.

### Example

Here is what a provider for an example `Foo` package would look like. All the provider does is take a message, then print the message when the `Droplet` starts.

```swift
import Vapor

public final class Provider: Vapor.Provider {
	public let message: String
    public let provided: Providable

    public convenience init(config: Config) throws {
    	guard let message = config["foo", "message"].string else {
    		throw SomeError
    	}

        try self.init(message: message)
    }

    public init(message: String) throws {
		self.message = message
    }

    public func afterInit(_ drop: Droplet) {

    }

    public func beforeServe(_ drop: Droplet) {
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
