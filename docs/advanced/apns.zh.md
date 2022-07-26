# APNS

在 Vapor 中使用基于 [APNSwift](https://github.com/kylebrowning/APNSwift) 构建的 API，可以轻松实现 Apple 推送通知服务(APNS) 的身份验证并将推送通知发送到 Apple 设备。

## 入门

让我们看看如何使用 APNS。

### Package

使用 APNS 的第一步是将此依赖项添加到你的 Package.swift 文件中。

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Other dependencies...
        .package(url: "https://github.com/vapor/apns.git", from: "3.0.0"),
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

如果你直接在 Xcode 中编辑清单文件，它会在文件保存时自动提取更改并获取新的依赖项。否则，从终端运行 `swift package resolve` 命令来获取新的依赖项。

### 配置

APNS 模块为 `Application` 添加了一个 `apns` 新属性。要发送推送通知，你需要设置 `configuration` 属性的认证凭证。

```swift
import APNS

// 使用 JWT 认证 配置 APNS。
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

在占位符中填写你的凭据。上面的示例显示了[基于 JWT 的认证](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)方式，使用从 Apple 开发者官网获得的 `.p8` 密钥。对于[基于 TLS 的认证](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)，请使用 `.tls` 身份验证方法：

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### 发送

配置 APNS 后，你可以使用 `apns.send` 方法在 `Application` 或 `Request` 中发送推送通知。

```swift
// 发送一条推送。
try app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
).wait()

// 或者
try await app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
)
```

每当你在路由处理内部时，使用 `req.apns` 发送推送通知。

```swift
// 发送推送通知
app.get("test-push") { req -> EventLoopFuture<HTTPStatus> in
    req.apns.send(..., to: ...)
        .map { .ok }
}

// 或者
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.send(..., to: ...) 
    return .ok
}
```

第一个参数接受推送通知的数据，第二个参数是目标设备令牌。

## Alert

`APNSwiftAlert` 是要发送的推送通知的实际元数据。[此处](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html)提供了每个属性的详细信息。它们遵循 Apple 文档中列出的一对一命名方案。

```swift
let alert = APNSwiftAlert(
    title: "Hey There", 
    subtitle: "Full moon sighting", 
    body: "There was a full moon last night did you see it"
)
```

此类型可以直接传递给 `send` 方法，它将自动包装在 `APNSwiftPayload` 中。

### Payload

`APNSwiftPayload` 是推送通知的元数据。诸如推送弹窗，徽章数之类的东西。[此处](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html)提供了每个属性的详细信息。它们遵循 Apple 文档中列出的一对一命名方案。

```swift
let alert = ...
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

这可以传递给 `send` 方法。

### 自定义通知数据

Apple 为工程师提供了为每个通知添加定制有效载荷数据的能力。为了方便操作，我们有了 `APNSwiftNotification`。

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

可将此自定义通知类型传递给该 `send` 方法。

## 更多信息

了解更多可用方法的信息，请参阅 [APNSwift](https://github.com/kylebrowning/APNSwift)。
