# APNS

VaporのApple Push Notification Service (APNS) APIを使用すると、Appleデバイスへのプッシュ通知の認証と送信が簡単になります。これは[APNSwift](https://github.com/swift-server-community/APNSwift)の上に構築されています。

## はじめに {#getting-started}

APNSの使用を開始する方法を見てみましょう。

### パッケージ {#package}

APNSを使用する最初のステップは、依存関係にパッケージを追加することです。

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

Xcode内で直接マニフェストを編集すると、ファイルが保存されたときに自動的に変更を検出し、新しい依存関係を取得します。それ以外の場合は、ターミナルから`swift package resolve`を実行して新しい依存関係を取得してください。

### 設定 {#configuration}

APNSモジュールは`Application`に新しいプロパティ`apns`を追加します。プッシュ通知を送信するには、認証情報を使用して`configuration`プロパティを設定する必要があります。

```swift
import APNS
import VaporAPNS
import APNSCore

// JWT認証を使用してAPNSを設定します。
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

プレースホルダーを認証情報で置き換えてください。上記の例は、Appleの開発者ポータルから取得した`.p8`キーを使用した[JWTベースの認証](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)を示しています。証明書を使用した[TLSベースの認証](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)の場合は、`.tls`認証方法を使用してください：

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### 送信 {#send}

APNSが設定されたら、`Application`または`Request`の`apns.send`メソッドを使用してプッシュ通知を送信できます。

```swift
// カスタムCodableペイロード
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// プッシュ通知アラートを作成
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
// 通知を送信
try! await req.apns.client.sendAlertNotification(
    alert, 
    deviceToken: dt, 
    deadline: .distantFuture
)
```

ルートハンドラー内にいる場合は、`req.apns`を使用してください。

```swift
// プッシュ通知を送信します。
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

最初のパラメータはプッシュ通知アラートを受け取り、2番目のパラメータはターゲットデバイストークンです。

## アラート {#alert}

`APNSAlertNotification`は、送信するプッシュ通知アラートの実際のメタデータです。各プロパティの詳細については[こちら](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html)で提供されています。これらはAppleのドキュメントに記載されている1対1の命名規則に従っています。

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

このタイプは`send`メソッドに直接渡すことができます。

### カスタム通知データ {#custom-notification-data}

Appleは、各通知にカスタムペイロードデータを追加する機能をエンジニアに提供しています。これを容易にするために、すべての`send` APIのペイロードパラメータに`Codable`準拠を受け入れています。

```swift
// カスタムCodableペイロード
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## 詳細情報 {#more-information}

利用可能なメソッドの詳細については、[APNSwiftのREADME](https://github.com/swift-server-community/APNSwift)を参照してください。