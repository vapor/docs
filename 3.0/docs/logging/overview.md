# Logging Overview

The logging package provides convenience APIs for logging information while your app is running. The [`Logger`](https://api.vapor.codes/console/latest/Logging/Protocols/Logger.html) protocol declares a common interface for logging information. A default [`PrintLogger`](https://api.vapor.codes/console/latest/Logging/Classes/PrintLogger.html) is available, but you can implement custom loggers to suit your specific needs.

## Log

First, you will want to use a `Container` to create an instance of `Logger`. Then you can use the convenience methods to log information.

```swift
let logger = try req.make(Logger.self)
logger.info("Logger created!")
```

See [`Logger`](https://api.vapor.codes/console/latest/Logging/Protocols/Logger.html) in the API docs for a list of all available methods.

Check out [Service &rarr; Services](../service/services.md#instance) for more information on how to register a custom logger.

