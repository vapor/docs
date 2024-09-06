# APNS

Vapor's Apple Push Notification Service (APNS) API maakt het eenvoudig om te authenticeren en push-notificaties te verzenden naar Apple-apparaten. Het is gebouwd op de top van [APNSwift](https://github.com/kylebrowning/APNSwift).

## Aan De Slag

Laten we eens kijken hoe u aan de slag kunt met APNS.

### Package

De eerste stap om APNS te gebruiken is het toevoegen van het pakket aan uw dependencies.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Andere afhankelijkheden...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Andere afhankelijkheden...
            .product(name: "VaporAPNS", package: "apns")
        ]),
        // Andere targets...
    ]
)
```

Als u het manifest direct in Xcode bewerkt, zal het automatisch de wijzigingen oppikken en de nieuwe dependency ophalen wanneer het bestand wordt opgeslagen. Anders, voer `swift package resolve` uit vanuit Terminal om de nieuwe dependency op te halen.

### Configuratie

De APNS module voegt een nieuwe eigenschap `apns` toe aan `Application`. Om push notificaties te versturen, moet je de `configuration` eigenschap instellen met je credentials.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configureer APNS met JWT-authenticatie.
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

Vul de plaatsaanduidingen in met uw referenties. Het bovenstaande voorbeeld toont [JWT-gebaseerde auth](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) met behulp van de `.p8` sleutel die je krijgt van Apple's ontwikkelaarsportaal. Voor [TLS-gebaseerde auth](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) met een certificaat, gebruik de `.tls` authenticatie methode:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Verzenden

Zodra APNS is geconfigureerd, kunt u push notificaties versturen met `apns.send` methode op `Application` of `Request`.

```swift
// Aangepaste codeerbare lading
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// Maak een pushmeldingswaarschuwing
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
// Verzend de melding
try! await req.apns.client.sendAlertNotification(
    alert,
    deviceToken: dt,
    deadline: .distantFuture
)
```

Gebruik `req.apns` wanneer je in een route handler zit.

```swift
// Stuur een push notificatie.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

De eerste parameter accepteert de push notificatie melding en de tweede parameter is het doel apparaat token.

## Alert

`APNSAlertNotification` is de eigenlijke metadata van de te verzenden push notification alert. Meer details over de specifieke kenmerken van elke eigenschap worden [hier](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html) gegeven. Ze volgen een één-op-één naamgeving schema zoals vermeld in Apple's documentatie

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

Dit type kan direct worden doorgegeven aan de `send` methode en het zal automatisch worden verpakt in een `APNSwiftPayload`.

### Aangepaste Notification Data

Apple biedt ontwikkelaars de mogelijkheid om aangepaste payload data toe te voegen aan elke notificatie. Om dit te vergemakkelijken accepteren we `Codable`-conformiteit met de payload-parameter op alle `send`-apis.

```swift
// Aangepaste codeerbare lading
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## More Information

Voor meer informatie over beschikbare methodes, zie [APNSwift's README](https://github.com/swift-server-community/APNSwift).
