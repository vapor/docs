# APNS

L'API APNS (Apple Push Notification Service) de Vapor permet de s'authentifier facilement et d'envoyer des notifications push aux appareils Apple. Elle est construite au-dessus d'[APNSwift](https://github.com/swift-server-community/APNSwift).

## Premiers pas

Voyons comment démarrer avec APNS.

### Package

La première étape pour utiliser APNS consiste à ajouter le package à vos dépendances.

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

Si vous éditez le manifeste directement dans Xcode, celui-ci détectera automatiquement les changements et récupérera la nouvelle dépendance dès l'enregistrement du fichier. Sinon, depuis le Terminal, exécutez `swift package resolve` pour récupérer la nouvelle dépendance.

### Configuration

Le module APNS ajoute une nouvelle propriété `apns` à `Application`. Pour envoyer des notifications push, vous devrez définir la propriété `configuration` avec vos identifiants.

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

Renseignez les emplacements réservés avec vos identifiants. L'exemple ci-dessus montre l'[authentification basée sur JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) utilisant la clé `.p8` que vous obtenez depuis le portail développeur d'Apple. Pour l'[authentification basée sur TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) avec un certificat, utilisez la méthode d'authentification `.tls` : 

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Envoyer

Une fois APNS configuré, vous pouvez envoyer des notifications push en utilisant la méthode `apns.send` sur `Application` ou `Request`. 

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

Utilisez `req.apns` chaque fois que vous êtes à l'intérieur d'un gestionnaire de route.

```swift
// Sends a push notification.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

Le premier paramètre accepte l'alerte de notification push et le second paramètre est le jeton de l'appareil ciblé. 

## Alerte

`APNSAlertNotification` représente les métadonnées réelles de l'alerte de notification push à envoyer. Plus de détails sur les spécificités de chaque propriété sont fournis [ici](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Elles suivent un schéma de nommage biunivoque avec celui listé dans la documentation d'Apple.

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

Ce type peut être transmis directement à la méthode `send`.

### Données personnalisées de notification

Apple offre aux développeurs la possibilité d'ajouter des données de payload personnalisées à chaque notification. Pour faciliter cela, nous acceptons la conformité à `Codable` pour le paramètre payload sur toutes les API `send`.

```swift
// Custom Codable Payload
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Plus d'informations

Pour plus d'informations sur les méthodes disponibles, consultez le [README d'APNSwift](https://github.com/swift-server-community/APNSwift).
