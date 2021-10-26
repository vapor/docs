# Logging 

Vapor's logging API is built on top of [SwiftLog](https://github.com/apple/swift-log). This means Vapor is compatible with all of SwiftLog's [backend implementations](https://github.com/apple/swift-log#backends). 

## Logger

Instances of `Logger` are used for outputting log messages. Vapor provides a few easy ways to get access to a logger.

### Request

Each incoming `Request` has a unique logger that you should use for any logs specific to that request.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

The request logger includes a unique UUID identifying the incoming request to make tracking logs easier.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
	Logger metadata will only be shown in debug log level or lower.

### Application

For log messages during app boot and configuration, use `Application`'s logger.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Custom Logger

In situations where you don't have access to `Application` or `Request`, you can initialize a new `Logger`. 

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

While custom loggers will still output to your configured logging backend, they will not have important metadata attached like request UUID. Use the request or application specific loggers wherever possible. 

## Level

SwiftLog supports several different logging levels.

|name|description|
|-|-|
|trace|Appropriate for messages that contain information normally of use only when tracing the execution of a program.|
|debug|Appropriate for messages that contain information normally of use only when debugging a program.|
|info|Appropriate for informational messages.|
|notice|Appropriate for conditions that are not error conditions, but that may require special handling.|
|warning|Appropriate for messages that are not error conditions, but more severe than notice.|
|error|Appropriate for error conditions.|
|critical|Appropriate for critical error conditions that usually require immediate attention.|

When a `critical` message is logged, the logging backend is free to perform more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate debugging.

By default, Vapor will use `info` level logging. When run with the `production` environment, `notice` will be used to improve performance. 

### Changing Log Level

Regardless of environment mode, you can override the logging level to increase or decrease the amount of logs produced. 

The first method is to pass the optional `--log` flag when booting your application.

```sh
vapor run serve --log debug
```

The second method is to set the `LOG_LEVEL` environment variable.

```sh
export LOG_LEVEL=debug
vapor run serve
```

Both of these can be done in Xcode by editing the `Run` scheme.

## Configuration

SwiftLog is configured by bootstrapping the `LoggingSystem` once per process. Vapor projects typically do this in `main.swift`.

```swift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` is a helper method provided by Vapor that will configure the default log handler based on command-line arguments and environment variables. The default log handler supports outputting messages to the terminal with ANSI color support. 

### Custom Handler

You can override Vapor's default log handler and register your own.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

All of SwiftLog's supported backends will work with Vapor. However, changing the log level with command-line arguments and environment variables is only compatible with Vapor's default log handler.
