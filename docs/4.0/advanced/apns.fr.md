# APNS

L'API Apple Push Notification Service (APNS) de Vapor facilite l'authentification et envoi de notifications push aux appareils Apple. Elle est conçue sur [APNSwift](https://github.com/swift-server-community/APNSwift).

## Premiers pas

Voyons comment vous pouvez commencer à utiliser APNS.

### Package

La première étape consiste à ajouter le package APNS à vos dépendances.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Autres dépendances...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Autres dépendances...
            .product(name: "VaporAPNS", package: "apns")
        ]),
        // Autres targets...
    ]
)
```

Si vous éditez le manifeste directement dans Xcode, il verra automatiquement les changements et récupèrera les nouvelles dépendances à l'enregistrement du fichier. Sinon, depuis Terminal, lancez `swift package resolve` pour récupérer les nouvelles dépendances.

### Configuration

Le module APNS ajoute une nouvelle propriété `apns` à l'objet `Application`. Pour envoyer des notifications push, vous devrez définir la propriété `configuration` avec vos clés d'accès.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configure APNS avec une authentification JWT.
let apnsConfig = APNSClientConfiguration(
    authenticationMethod: .jwt(
        privateKey: try .loadFrom(string: "<#contenu de key.p8#>"),
        keyIdentifier: "<#identifiant de la clé#>",
        teamIdentifier: "<#identifiant de l'équipe#>"
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

Remplacez les valeurs par vos propres clés. L'exemple ci-dessus montre une [authentification JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) qui utilise une clé `.p8` obtenue depuis le portail développeur Apple. Pour une [authentification TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) avec certificat, utilisez la méthode d'authentification `.tls` : 

```swift
authenticationMethod: .tls(
    privateKeyPath: <#chemin vers votre clé privée#>,
    pemPath: <#chemin vers votre fichier pem#>,
    pemPassword: <#mot de passe pem facultatif#>
)
```

### Envoi

Une fois APNS configuré, vous pouvez envoyer des notifications push grâce à la méthode `apns.send` des objets `Application` ou `Request`. 

```swift
// Payload personnalisé conforme à Codable
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// Crée une notification push de type Alerte
let dt = "70075697aa918ebddd64efb165f5b9cb92ce095f1c4c76d995b384c623a258bb"
let payload = Payload(acme1: "hey", acme2: 2)
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Hello"),
        subtitle: .raw("Ceci est un test depuis vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#mon sujet#>",
    payload: payload
)
// Envoie la notification
try! await req.apns.client.sendAlertNotification(
    alert, 
    deviceToken: dt, 
    deadline: .distantFuture
)
```

Utilisez `req.apns` dès que vous êtes dans un contrôleur.

```swift
// Envoie une notification push.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

Le premier paramètre reçoit l'alerte de notification push et le second paramètre est le jeton de l'appareil cible. 

## Alerte

`APNSAlertNotification` contient les métadonnées de l'alerte de notification push à envoyer. Plus de détails sur les spécificités de chaque propriété sont disponibles [ici](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Elles suivent un nommage calqué sur la documentation Apple.

```swift
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Hello"),
        subtitle: .raw("Ceci est un test depuis vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#mon sujet#>",
    payload: payload
)
```

Vous pouvez directement passer ce type à la méthode `send`.

### Données de notification personnalisées

Apple permet aux ingénieurs d'ajouter des données personnalisées à chaque notification. Pour simplifier cela, toutes nos APIs `send` acceptent des payloads conformes au protocole `Codable`.

```swift
// Payload codable personnalisé.
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Plus d'informations

Pour plus d'informations sur les méthodes disponibles, consulter le [README de APNSwift](https://github.com/swift-server-community/APNSwift).
