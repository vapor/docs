# APNS

API Vapor dla Apple Push Notification Service (APNS) ułatwia uwierzytelnianie i wysyłanie powiadomień push do urządzeń Apple. Jest zbudowane na bazie [APNSwift](https://github.com/swift-server-community/APNSwift).

## Pierwsze kroki

Zobaczmy, jak zacząć korzystać z APNS.

### Pakiet

Pierwszym krokiem do korzystania z APNS jest dodanie pakietu do zależności.

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

Jeśli edytujesz manifest bezpośrednio w Xcode, automatycznie wykryje on zmiany i pobierze nową zależność po zapisaniu pliku. W przeciwnym razie, z poziomu terminala, uruchom `swift package resolve`, aby pobrać nową zależność.

### Konfiguracja

Moduł APNS dodaje nową właściwość `apns` do `Application`. Aby wysyłać powiadomienia push, musisz ustawić właściwość `configuration` z Twoimi danymi uwierzytelniającymi.

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

Uzupełnij pola zastępcze swoimi danymi uwierzytelniającymi. Powyższy przykład pokazuje [uwierzytelnianie oparte na JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) przy użyciu klucza `.p8` uzyskanego z portalu deweloperskiego Apple. Do [uwierzytelniania opartego na TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) za pomocą certyfikatu, użyj metody uwierzytelniania `.tls`:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Wysyłanie

Gdy APNS jest już skonfigurowany, możesz wysyłać powiadomienia push za pomocą metody `apns.send` na `Application` lub `Request`.

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

Używaj `req.apns` zawsze, gdy znajdujesz się wewnątrz handlera trasy.

```swift
// Sends a push notification.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

Pierwszy parametr przyjmuje powiadomienie push (alert), a drugi parametr to token docelowego urządzenia.

## Alert

`APNSAlertNotification` to właściwe metadane powiadomienia push, które ma zostać wysłane. Więcej szczegółów na temat poszczególnych właściwości znajduje się [tutaj](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Stosują one schemat nazewnictwa jeden do jednego wymieniony w dokumentacji Apple.

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

Ten typ można przekazać bezpośrednio do metody `send`.

### Niestandardowe dane powiadomienia

Apple umożliwia programistom dodawanie niestandardowych danych ładunku (payload) do każdego powiadomienia. Aby to ułatwić, akceptujemy zgodność z `Codable` dla parametru payload we wszystkich API `send`.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Więcej informacji

Aby uzyskać więcej informacji na temat dostępnych metod, zobacz [README APNSwift](https://github.com/swift-server-community/APNSwift).
