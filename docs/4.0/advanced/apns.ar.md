# APNS

تُسهّل واجهة خدمة الإشعارات الفورية من Apple (Apple Push Notification Service، أو APNS) في Vapor المصادقة وإرسال الإشعارات الفورية إلى أجهزة Apple. وهي مبنية على [APNSwift](https://github.com/swift-server-community/APNSwift).

## البدء

لنلقِ نظرة على كيفية البدء باستخدام APNS.

### الحزمة

الخطوة الأولى لاستخدام APNS هي إضافة الحزمة إلى اعتمادياتك (dependencies).

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

إذا حرّرت الملف الوصفي (manifest) مباشرة داخل Xcode، فسيلتقط التغييرات تلقائيًا ويجلب الاعتمادية الجديدة عند حفظ الملف. وإلا، من الطرفية (Terminal)، شغّل `swift package resolve` لجلب الاعتمادية الجديدة.

### الإعداد

تضيف وحدة APNS خاصية جديدة `apns` إلى `Application`. لإرسال الإشعارات الفورية، ستحتاج إلى ضبط الخاصية `configuration` ببيانات اعتمادك.

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

املأ العناصر النائبة (placeholders) ببيانات اعتمادك. يُظهر المثال أعلاه [المصادقة القائمة على JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) باستخدام مفتاح `.p8` الذي تحصل عليه من بوابة مطوّري Apple. أما [المصادقة القائمة على TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) باستخدام شهادة، فاستخدم طريقة المصادقة `.tls`:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### الإرسال

بمجرد إعداد APNS، يمكنك إرسال الإشعارات الفورية باستخدام الطريقة `apns.send` على `Application` أو `Request`.

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

استخدم `req.apns` كلما كنت داخل معالج مسار.

```swift
// Sends a push notification.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

يقبل المُعامِل الأول تنبيه الإشعار الفوري (push notification alert)، والمُعامِل الثاني هو رمز الجهاز الهدف (device token).

## Alert

`APNSAlertNotification` هي البيانات الوصفية (metadata) الفعلية لتنبيه الإشعار الفوري المراد إرساله. تتوفّر تفاصيل أكثر حول تفاصيل كل خاصية [هنا](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). وهي تتبع مخطّط تسمية واحد لواحد مذكورًا في وثائق Apple.

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

يمكن تمرير هذا النوع مباشرة إلى الطريقة `send`.

### بيانات الإشعار المخصّصة

توفّر Apple للمهندسين القدرة على إضافة بيانات حمولة (payload) مخصّصة إلى كل إشعار. لتيسير ذلك، نقبل توافق `Codable` لمُعامِل الحمولة على جميع واجهات `send`.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## مزيد من المعلومات

لمزيد من المعلومات حول الطرق المتاحة، راجع [ملف README الخاص بـ APNSwift](https://github.com/swift-server-community/APNSwift).
