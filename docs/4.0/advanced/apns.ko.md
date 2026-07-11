# APNS

Vapor의 Apple Push Notification Service(APNS) API를 사용하면 Apple 기기에 대한 인증과 푸시 알림 전송을 손쉽게 처리할 수 있습니다. 이 API는 [APNSwift](https://github.com/swift-server-community/APNSwift) 위에 구축되었습니다.

## 시작하기

APNS를 어떻게 사용하기 시작하는지 살펴보겠습니다.

### 패키지

APNS를 사용하기 위한 첫 번째 단계는 종속성에 패키지를 추가하는 것입니다.

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

Xcode 내부에서 매니페스트를 직접 수정하면, 파일이 저장될 때 변경 사항을 자동으로 인식하고 새로운 종속성을 가져옵니다. 그렇지 않다면, 터미널에서 `swift package resolve`를 실행해서 새로운 종속성을 가져오세요.

### 설정

APNS 모듈은 `Application`에 새로운 프로퍼티인 `apns`를 추가합니다. 푸시 알림을 보내려면, 여러분의 자격 증명으로 `configuration` 프로퍼티를 설정해야 합니다.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configure APNS using JWT authentication.
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

자리 표시자(placeholder)에 여러분의 자격 증명을 채워 넣으세요. 위 예제는 Apple 개발자 포털에서 얻은 `.p8` 키를 사용하는 [JWT 기반 인증](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)을 보여줍니다. 인증서를 사용하는 [TLS 기반 인증](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)의 경우, `.tls` 인증 메서드를 사용하세요.

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### 전송

APNS가 설정되면, `Application` 또는 `Request`의 `apns.send` 메서드를 사용해서 푸시 알림을 보낼 수 있습니다.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// Create push notification Alert
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
// Send the notification
try! await req.apns.client.sendAlertNotification(
    alert, 
    deviceToken: dt, 
    deadline: .distantFuture
)
```

라우트 핸들러 내부에 있을 때는 언제나 `req.apns`를 사용하세요.

```swift
// Sends a push notification.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

첫 번째 매개변수는 푸시 알림 Alert를 받고, 두 번째 매개변수는 대상 기기 토큰입니다.

## Alert

`APNSAlertNotification`은 보낼 푸시 알림 Alert의 실제 메타데이터입니다. 각 프로퍼티의 세부 사항에 대한 자세한 내용은 [여기](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html)에서 확인할 수 있습니다. 이 프로퍼티들은 Apple 문서에 나열된 명명 체계를 일대일로 따릅니다.

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

이 타입은 `send` 메서드에 직접 전달할 수 있습니다.

### 사용자 정의 알림 데이터

Apple은 개발자가 각 알림에 사용자 정의 payload 데이터를 추가할 수 있도록 지원합니다. 이를 지원하기 위해 모든 `send` API의 payload 매개변수에서 `Codable` 준수를 허용합니다.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## 추가 정보

사용 가능한 메서드에 대한 자세한 내용은 [APNSwift의 README](https://github.com/swift-server-community/APNSwift)를 참조하세요.
