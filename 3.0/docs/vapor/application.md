# Application

Every application in Vapor starts as an `Application`. Application is a open class, meaning it _can_ be subclassed to add extra properties, but that's usually not necessary.

Application has a [`Config`](../service/config.md) and [`Services`](../service/services.md).

Application may behave differently depending on it's [`Environment`](../service/environment.md).

## Creating a basic application

If not overridden, `Application` comes with it's own set of default services. This makes setting up an empty (basic) application extremely simple.

```swift
import Vapor

let application = Application()

// Set up your routes etc..

try application.run()
```

You can override the default config, environment and services like so:

```swift
let config: Config = ...
let environment = Environment.production
var services = Services.default()

// configure services, otherwise there's no Server and Router
```

## Application routing services

In order to add routes to an `Application` you need to get a router first.

```swift
let router = try app.make(Router.self)
```

From here you can start writing [your application's routes](routing.md).
