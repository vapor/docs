# Using Providers

The [`Provider`](https://api.vapor.codes/service/latest/Service/Protocols/Provider.html) protocol make it easy to integrate external services into your application. All of Vapor's official packages, like [Fluent](../fluent/getting-started.md), use the provider system to expose their services. 

Providers can:

- Register services to your [`Services`](https://api.vapor.codes/service/latest/Service/Structs/Services.html) struct.
- Hook into your [`Container`](https://api.vapor.codes/service/latest/Service/Protocols/Container.html)'s lifecycle.

## Register

Once you have added a Service-exposing [SPM dependency](../getting-started/spm/#dependencies) to your project, adding the provider is easy.

```swift
import Foo

try services.register(FooProvider())
```

This is usually done in [`configure.swift`](../getting-started/structure/#configureswift). 

!!! note
	You can search GitHub for the [`vapor-service`](https://github.com/topics/vapor-service) tag for a list of packages that expose services using this method.


## Create

Creating a custom provider can be a great way to organize your code. You will also want to create a provider if you are working on a third-party package for Vapor.

Here is what a simple provider would look like for the `Logger` examples from the [Services](services.md) section.

```swift
public final class LoggerProvider: Provider {
    /// See `Provider`.
    public func register(_ services: inout Services) throws {
		services.register(PrintLogger.self)
		services.register(FileLogger.self)
    }
    
    /// See `Provider`.
    public func didBoot(_ container: Container) throws -> Future<Void> {
    	let logger = try container.make(Logger.self)
    	logger.log("Hello from LoggerProvider!")
    	return .done(on: container)
    }
}
```

Now when someone registers the `LoggerProvider` to their `Services` struct, it will automatically register the print and file loggers. When the container boots, the success message will be printed to verify the provider was added.

See the [`Provider`](https://api.vapor.codes/service/latest/Service/Protocols/Provider.html) protocol's API docs for more information.
