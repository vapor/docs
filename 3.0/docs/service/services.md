# Using Services

This guide will show you how to register, configure, and create your own service. In this example we will be assuming two different `Logger` implementations.

- `PrintLogger`: Prints logs.
- `FileLogger`: Saves logs to a file. Already conforms to `ServiceType`.

## Register

Let's take a look at how we can register our `PrintLogger`. First you must conform your type to `Service`. The easiest way to do this is simply adding the conformance in an extension.

```swift
extension PrintLogger: Service { }
```

It's an empty protocol so there should be no missing requirements.

### Factory

Now the service can be registered to the [`Services`](https://api.vapor.codes/service/latest/Service/Structs/Services.html) struct. This is usually done in [`configure.swift`](../getting-started/structure/#configureswift).

```swift
services.register(Logger.self) { container in
	return PrintLogger()
}
```

By registering the `PrintLogger` using a factory (closure) method, we allow the [`Container`](https://api.vapor.codes/service/latest/Service/Protocols/Container.html) to dynamically create the service once it is needed. Any [`SubContainer`](https://api.vapor.codes/service/latest/Service/Protocols/SubContainer.html)s created later can call this method again to create their own `PrintLogger`s.


### Service Type

To make registering a service easier, you can conform it to [`ServiceType`](https://api.vapor.codes/service/latest/Service/Protocols/ServiceType.html).

```swift
extension PrintLogger: ServiceType {
	/// See `ServiceType`.
    static var serviceSupports: [Any.Type] {
    	return [Logger.self]
    }

	/// See `ServiceType`.
    static func makeService(for worker: Container) throws -> PrintLogger {
    	return PrintLogger()
    }
}
```

Services conforming to [`ServiceType`](https://api.vapor.codes/service/latest/Service/Protocols/ServiceType.html) can be registered using just the type name. This will automatically conform to `Service` as well.

```swift
services.register(PrintLogger.self)
```
### Instance

You can also register pre-initialized instances to `Services`.

```swift
services.register(PrintLogger(), as: Logger.self)
```

!!! warning
	If using reference types (`class`) this method will share the _same_ object between all [`Container`](https://api.vapor.codes/service/latest/Service/Protocols/Container.html)s and [`SubContainer`](https://api.vapor.codes/service/latest/Service/Protocols/SubContainer.html)s.
	Be careful to protect against race conditions.

## Configure

If more than one service is registered for a given interface, we will need to choose which service is used.

```swift
services.register(PrintLogger.self)
services.register(FileLogger.self)
```

Assuming the above services are registered, we can use service [`Config`](https://api.vapor.codes/service/latest/Service/Structs/Config.html) to pick which one we want.

```swift
switch env {
case .production: config.prefer(FileLogger.self, for: Logger.self)
default: config.prefer(PrintLogger.self, for: Logger.self)
}
```

Here we are using the [`Environment`](https://api.vapor.codes/service/latest/Service/Structs/Environment.html) to dynamically prefer a service. This is usually done in [`configure.swift`](../getting-started/structure/#configureswift).

!!! note
	You can also dynamically _register_ services based on environment instead of using service config. 
	However, service config is required for choosing services that come from the framework or a provider.

## Create

After you have registered your services, you can use a [`Container`](https://api.vapor.codes/service/latest/Service/Protocols/Container.html) to create them.

```swift
let logger = try someContainer.make(Logger.self)
logger.log("Hello, world!")

// PrintLogger or FileLogger depending on the container's environment
print(type(of: logger)) 
```

!!! tip
	Usually the framework will create any required containers for you. You can use [`BasicContainer`](https://api.vapor.codes/service/latest/Service/Classes/BasicContainer.html) if you want to create one for testing.

