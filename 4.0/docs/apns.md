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
        .package(url: "https://github.com/vapor/apns.git", from: "2.0.0"),
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
        key: .private(filePath: <#path to .p8#>),
        keyIdentifier: "<#key identifier#>",
        teamIdentifier: "<#team identifier#>"
    ),
    topic: "<#topic#>",
    environment: .sandbox
)
```

Fill in the placeholders with your credentials. The above example shows [JWT-based auth](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) using the `.p8` key you get from Apple's developer portal. For [TLS-based auth](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) with a certificate, use the `.tls` authentication method: 

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Send

Once APNS is configured, you can send push notifications using `apns.send` method on `Application` or `Request`. 

```swift
// Send a push notification.
try app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
).wait()

// Or
try await app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
)
```

Use `req.apns` whenever you are inside of a route handler.

```swift
// Sends a push notification.
app.get("test-push") { req -> EventLoopFuture<HTTPStatus> in
    req.apns.send(..., to: ...)
        .map { .ok }
}

// Or
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.send(..., to: ...) 
    return .ok
}
```

The first parameter accepts the push notification alert and the second parameter is the target device token. 

## Alert

`APNSwiftAlert` is the actual metadata of the push notification alert to send. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a one-to-one naming scheme listed in Apple's documentation

```swift
let alert = APNSwiftAlert(
    title: "Hey There", 
    subtitle: "Full moon sighting", 
    body: "There was a full moon last night did you see it"
)
```

This type can be passed directly to the `send` method and it will be wrapped in an `APNSwiftPayload` automatically.

### Payload

`APNSwiftPayload` is the metadata of the push notification. Things like the alert, badge count. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a one-to-one naming scheme listed in Apple's documentation

```swift
let alert = ...
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

This can be passed to the `send` method.

### Custom Notification Data

Apple provides engineers with the ability to add custom payload data to each notification. In order to facilitate this we have the `APNSwiftNotification`.

```swift
struct AcmeNotification: APNSwiftNotification {
    let acme2: [String]
    let aps: APNSwiftPayload

    init(acme2: [String], aps: APNSwiftPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let aps: APNSwiftPayload = ...
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)
```

This custom notification type can be passed to the `send` method.

## More Information

For more information on available methods, see [APNSwift's README](https://github.com/kylebrowning/APNSwift).
