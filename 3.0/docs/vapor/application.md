# Application

Every application in Vapor starts as an `Application`. Application is a open class, meaning it _can_ be subclassed to add extra properties, but that's usually not necessary.

Application is [`Extendable`](../core/extend.md), has a [`Config`](../service/config.md) and [`Services`](../service/services.md).

Application may behave differently depending on it's [`Environment`](../service/environment.md).

## Creating a basic application

Creating and running an application is only 2 lines of code.

```swift
let application = Application()

// Set up your routes etc..

try application.run()
```

If not overridden, `Application` comes with it's own set of default services.

You can override the default config, environment and services like so:

```swift
let config: Config = ...
let environment = Environment.production
let services = Services()

// configure services, otherwise there's no Server and Router
```

## Application routing services

In order to add routes to an `Application` you need to get a router first. The default services set up for `Application` support [`AsyncRouter`](../routing/async.md) and [`SyncRouter`](../routing/sync.md)

```swift
let async = try app.make(AsyncRouter.self)
let sync = try app.make(SyncRouter.self)
```
