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
        .package(url: "https://github.com/vapor/apns.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Andere afhankelijkheden...
            .product(name: "APNS", package: "apns")
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

// Configureer APNS met JWT-authenticatie.
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
// Stuur een push notificatie.
try app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
).wait()

// Of
try await app.apns.send(
    .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
    to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
)
```

Gebruik `req.apns` wanneer je in een route handler zit.

```swift
// Stuur een push notificatie.
app.get("test-push") { req -> EventLoopFuture<HTTPStatus> in
    req.apns.send(..., to: ...)
        .map { .ok }
}

// Of
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.send(..., to: ...) 
    return .ok
}
```

De eerste parameter accepteert de push notificatie melding en de tweede parameter is het doel apparaat token. 

## Alert

`APNSwiftAlert` is de eigenlijke metadata van de te verzenden push notification alert. Meer details over de specifieke kenmerken van elke eigenschap worden [hier](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html) gegeven. Ze volgen een één-op-één naamgeving schema zoals vermeld in Apple's documentatie

```swift
let alert = APNSwiftAlert(
    title: "Hey There", 
    subtitle: "Full moon sighting", 
    body: "There was a full moon last night did you see it"
)
```

Dit type kan direct worden doorgegeven aan de `send` methode en het zal automatisch worden verpakt in een `APNSwiftPayload`.

### Payload

`APNSwiftPayload` is de metadata van de push notificatie. Dingen zoals de waarschuwing, badge count. Meer details over de specifieke kenmerken van elke eigenschap worden [hier](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html) gegeven. Ze volgen een één-op-één naamgeving schema zoals vermeld in Apple's documentatie

```swift
let alert = ...
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

Dit kan worden doorgegeven aan de `send` methode.

### Aangepaste Notification Data

Apple biedt ingenieurs de mogelijkheid om aangepaste payload data toe te voegen aan elke notificatie. Om dit mogelijk te maken hebben we de `APNSwiftNotification`.

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

Dit aangepaste notificatie type kan worden doorgegeven aan de `send` methode.

## More Information

Voor meer informatie over beschikbare methodes, zie [APNSwift's README](https://github.com/kylebrowning/APNSwift).
