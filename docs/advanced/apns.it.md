# APNS

Il servizio di notifiche push di Apple (APNS) consente di inviare notifiche push a dispositivi iOS, macOS, tvOS e watchOS. Questo pacchetto fornisce un client per inviare notifiche push ad APNS da Vapor. È basato su [APNSwift](https://github.com/swift-server-community/APNSwift).

## Inizio

Vediamo come iniziare ad usare APNS.

### Pacchetto

Il primo passo per usare APNS è aggiungere il pacchetto alle dipendenze.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Altre dipendenze...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Altre dipendenze...
            .product(name: "VaporAPNS", package: "apns")
        ]),
        // Altri target...
    ]
)
```

Se il manifesto viene modificato direttamente in Xcode, esso rileverà automaticamente le modifiche e scaricherà la nuova dipendenza quando il file viene salvato. Altrimenti, da Terminale, basta eseguire `swift package resolve` per scaricare la nuova dipendenza.

### Configurazione

Il modulo APNS aggiunge una nuova proprietà `apns` ad `Application`. Per inviare notifiche push, è necessario impostare le proprie credenziali sulla proprietà `configuration`.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configurazione di APNS utilizzando l'autenticazione tramite JWT.
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

I segnaposto dell'esempio devono essere sostituiti con le credenziali.
Questo esempio utilizza [l'autenticazione JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/) con la chiave `.p8`, ottenibile dal portale per sviluppatori di Apple. Per l'autenticazione [TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/), si può utilizzare il metodo di autenticazione `.tls`:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Invio

Una volta configurato APNS, è possibile inviare notifiche push tramite il metodo `apns.send` presente su `Application` e `Request`.

```swift
// Payload Codable personalizzato
struct Payload: Codable {
    let acme1: String
    let acme2: String
}
// Creazione di un Alert per la notifica push
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

Dall'interno di un route handler si può utilizzare `req.apns`.

```swift
// Invia una notifica push.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...) 
    return .ok
}
```

Il primo parametro contiene la notifica push mentre il secondo parametro contiene il token del dispositivo a cui inviare la notifica push.

## Alert

`APNSAlertNotification` rappresenta i metadati della notifica push da inviare. [Qui](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html) ci sono informazioni più specifiche su ogni proprietà; i nomi delle proprietà seguono lo schema di denominazione uno-a-uno elencato nella documentazione di Apple.

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

Questo tipo può essere passato come parametro al metodo `send`.

### Dati di notifica personalizzati

Apple consente di inviare dati personalizzati in ogni notifica. Per renderlo semplice in APNS basta che i dati da inviare conformino a `Codable`:

```swift
struct Payload: Codable {
    let acme1: String
    let acme2: String
}
```

## Altre informazioni

Per ulteriori informazioni su come utilizzare APNS, vedere il [README di APNSwift](https://github.com/swift-server-community/APNSwift).
