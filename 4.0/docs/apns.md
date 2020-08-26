# APNS

Vapor's Apple Push Notification Service (APNS) API makes it easy to authenticate and send push notifications to Apple devices. It's built on top of [APNSwift](https://github.com/kylebrowning/APNSwift).

## Getting Started

Let's take a look at how you can get started using APNS.

### Package

The first step to using APNS is adding the package to your dependencies.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Other dependencies...
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "APNS", package: "apns")
        ]),
        // Other targets...
    ]
)
```

If you edit the manifest directly inside Xcode, it will automatically pick up the changes and fetch the new dependency when the file is saved. Otherwise, from Terminal, run `swift package resolve` to fetch the new dependency.

### Configuration

The APNS module adds a new property `apns` to `Application`. To send push notifications, you will need to set the `configuration` property with your credentials.

```swift
import APNS

// Configure APNS using JWT authentication.
app.apns.configuration = try .init(
    authenticationMethod: .jwt(
        key: .private(pem: """
        <#private key#>
        """),
        keyIdentifier: "<#key identifier#>",
        teamIdentifier: "<#team identifier#>"
    ),
    topic: "<#topic#>",
    environment: .sandbox
)
```

Fill in the placeholders with your credentials. The private key should begin with:

```
-----BEGIN PRIVATE KEY-----
...
```

### Send

Once APNS is configured, you can send push notifications using `apns.send` method on `Application` or `Request`. 

```swift
// Send a push notification.
try app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
).wait()
```

Use `req.apns` whenever you are inside of a route handler.

```swift
// Sends a push notification.
app.get("test-push") { req -> EventLoopFuture<HTTPStatus> in
    req.apns.send(..., to: ...)
        .map { .ok }
}
```

The first parameter accepts the push notification payload and the second parameter is the target device token. For more information on available methods, see [APNSwift's README](https://github.com/kylebrowning/APNSwift).


