# APNS

在 Vapor 中使用基于 [APNSwift](https://github.com/swift-server-community/APNSwift) 构建的 API，可以轻松实现 Apple 推送通知服务(APNS) 的身份验证并将推送通知发送到 Apple 设备。

## 入门

让我们看看如何使用 APNS。

### Package

使用 APNS 的第一步是将此依赖项添加到你的 Package.swift 文件中。

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Other dependencies...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "VaporAPNS", package: "apns")
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
import VaporAPNS
import APNSCore

// 使用 JWT 认证 配置 APNS。
let apnsConfig = APNSClientConfiguration(
    authenticationMethod: .jwt(
        privateKey: try .loadFrom(string: "<#key.p8 content#>"),
        keyIdentifier: "<#key identifier#>",
        teamIdentifier: "<#team identifier#>"
    ),
    environment: .development
)
app.apns.containers.use(
    apnsConfig,
    eventLoopGroupProvider: .shared(app.eventLoopGroup),
    responseDecoder: JSONDecoder(),
    requestEncoder: JSONEncoder(),
    as: .default
)
```

在占位符中填写你的凭证。

上面的示例显示了[基于 JWT 的认证](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)方式，使用从 Apple 开发者官网获得的 `.p8` 密钥。

对于[基于 TLS 的认证](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)，请使用 `.tls` 身份验证方法：

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### 发送通知

配置 APNS 后，你可以使用 `apns.client.sendAlertNotification` 方法在 `Application` 或 `Request` 中发送通知。

```swift
// 自定义遵循 `Codable` 协议的 Payload
struct Payload: Codable {
     let acme1: String
     let acme2: Int
}
// 创建推送
let dt = "70075697aa918ebddd64efb165f5b9cb92ce095f1c4c76d995b384c623a258bb"
let payload = Payload(acme1: "hey", acme2: 2)
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Hello"),
        subtitle: .raw("This is a test from vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#my topic#>",
    payload: payload
)
// 发送通知
try! await req.apns.client.sendAlertNotification(
    alert, 
    deviceToken: dt, 
    deadline: .distantFuture
)
```

当你在路由内部处理时，使用 `req.apns` 发送推送通知。

```swift
// 发送通知
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...) 
    return .ok
}
```

第一个参数接受推送通知的数据，第二个参数是目标设备的 token。

## Alert

`APNSAlertNotification` 是要发送的推送通知的实际元数据。[此处](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html)提供了每个属性的详细信息。它们遵循 Apple 文档中列出的一对一命名方案。

```swift
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Hello"),
        subtitle: .raw("This is a test from vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#my topic#>",
    payload: payload
)
```

此类型可以直接传递给 `send` 方法。

### 自定义通知数据

Apple 为工程师提供了为每个通知添加定制有效载荷数据的能力。为了方便操作，我们有了 `APNSwiftNotification`。
Apple 为工程师提供了向每个通知添加自定义 Payload 的能力，为了方便使用，对于 `send` api，我们接受所有遵循 `Codable` 协议的 Payload。

```swift
// 自定义遵循 `Codable` 协议的 Payload
 struct Payload: Codable {
     let acme1: String
     let acme2: Int
```

## 更多信息

了解更多可用方法的信息，请参阅 [APNSwift](https://github.com/swift-server-community/APNSwift)。
