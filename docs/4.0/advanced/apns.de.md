# APNS

Vapors Apple Push Notification Service (APNS) API macht es einfach, sich zu authentifizieren und Push-Benachrichtigungen an Apple-Geräte zu senden. Sie baut auf [APNSwift](https://github.com/swift-server-community/APNSwift) auf.

## Erste Schritte

Schauen wir uns an, wie du mit der Verwendung von APNS beginnen kannst.

### Paket

Der erste Schritt zur Verwendung von APNS besteht darin, das Paket zu deinen Abhängigkeiten hinzuzufügen.

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

Wenn du das Manifest direkt in Xcode bearbeitest, werden die Änderungen automatisch übernommen und die neue Abhängigkeit wird beim Speichern der Datei abgerufen. Andernfalls führe im Terminal `swift package resolve` aus, um die neue Abhängigkeit abzurufen.

### Konfiguration

Das APNS-Modul fügt `Application` eine neue Eigenschaft `apns` hinzu. Um Push-Benachrichtigungen zu senden, musst du die Eigenschaft `configuration` mit deinen Zugangsdaten setzen.

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

Fülle die Platzhalter mit deinen Zugangsdaten aus. Das obige Beispiel zeigt die [JWT-basierte Authentifizierung](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) mit dem `.p8`-Schlüssel, den du aus Apples Entwicklerportal erhältst. Für die [TLS-basierte Authentifizierung](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) mit einem Zertifikat verwendest du die Authentifizierungsmethode `.tls`:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Senden

Sobald APNS konfiguriert ist, kannst du mit der Methode `apns.send` auf `Application` oder `Request` Push-Benachrichtigungen senden.

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

Verwende `req.apns`, wann immer du dich innerhalb eines Route-Handlers befindest.

```swift
// Sends a push notification.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

Der erste Parameter nimmt den Push-Benachrichtigungs-Alert entgegen, der zweite Parameter ist das Ziel-Gerätetoken.

## Alert

`APNSAlertNotification` sind die eigentlichen Metadaten des zu sendenden Push-Benachrichtigungs-Alerts. Weitere Details zu den einzelnen Eigenschaften findest du [hier](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Sie folgen einem 1-zu-1-Benennungsschema, wie es in Apples Dokumentation aufgeführt ist.

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

Dieser Typ kann direkt an die Methode `send` übergeben werden.

### Benutzerdefinierte Benachrichtigungsdaten

Apple bietet Entwicklern die Möglichkeit, jeder Benachrichtigung benutzerdefinierte Payload-Daten hinzuzufügen. Um dies zu ermöglichen, akzeptieren wir für den Payload-Parameter aller `send`-APIs die Konformität zu `Codable`.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Weitere Informationen

Weitere Informationen zu den verfügbaren Methoden findest du in der [README von APNSwift](https://github.com/swift-server-community/APNSwift).
