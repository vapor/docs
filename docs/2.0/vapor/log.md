Log information using `drop.log`.

```swift
drop.log.info("Informational log")
```

## Types

Below are the following methods you can call on the log protocol. Only `error` and `fatal` will be shown in `production` mode.

| Method  | Production |
|---------|------------|
| info    | No         |
| warning | No         |
| verbose | No         |
| debug   | No         |
| error   | Yes        |
| fatal   | Yes        |

## Protocol

Create your own logger by conforming to `LogProtocol`. 

```swift
/// Logger protocol. Custom loggers must conform
/// to this protocol
public protocol LogProtocol: class {
    /// Enabled log levels. Only levels in this
    /// array should be logged.
    var enabled: [LogLevel] { get set }

    /// Log the given message at the passed filter level.
    /// file, function and line of the logging call
    /// are automatically injected in the convenience function.
    func log(_ level: LogLevel, message: String, file: String, function: String, line: Int)
}
```