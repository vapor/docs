# APNS

 La API del Servicio de Notificaciones Push de Apple (APNS) facilita la autenticación y envío de notificaciones push a dispositivos Apple. Está construida sobre [APNSwift](https://github.com/swift-server-community/APNSwift).

## Primeros Pasos

Veamos cómo puedes empezar a usar APNS.

### Paquete

El primer paso para usar APNS es añadir el paquete a tus dependencias.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Otras dependencias...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Otras dependencias...
            .product(name: "VaporAPNS", package: "apns")
        ]),
        // Otros targets...
    ]
)
```

Si editas directamente el manifiesto desde Xcode, automáticamente tomará los cambios y obtendrá la nueva dependencia cuando se guarde el archivo. De lo contrario, desde un terminal, ejecuta `swift package resolve` para obtener la nueva dependencia.

### Configuración

El módulo APNS añade una propiedad nueva `apns` a `Application`. Para enviar notificaciones push, necesitarás establecer la propiedad `configuration` con tus credenciales.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configura APNS usando autenticación JWT.
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

Rellena los marcadores de posición con tus credenciales. El ejemplo anterior muestra [autenticación basada en JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) utilizando la clave `.p8` que se obtiene del portal para desarrolladores de Apple. Para [autenticación basada en TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) con un certificado, utiliza el método de autenticación `.tls`: 

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Enviar

Una vez que APNS está configurado, puedes enviar notificaciones push usando el método `apns.send` en `Application` o `Request`. 

```swift
// Carga útil codificable personalizada
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// Crear alerta de notificación push
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
// Enviar la notificación
try! await req.apns.client.sendAlertNotification(
    alert, 
    deviceToken: dt, 
    deadline: .distantFuture
)
```

Usa `req.apns` siempre que estés dentro de un manejador de rutas.

```swift
// Envía una notificación push.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

El primer parámetro acepta la alerta de notificación push y el segundo parámetro es el token del dispositivo de destino. 

## Alerta

`APNSAlertNotification` son los metadatos reales de la alerta de notificación push a enviar. Más detalles sobre las especificaciones de cada propiedad se proporcionan [aquí](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Siguen un esquema de nomenclatura uno a uno que figura en la documentación de Apple.

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

Este tipo se puede pasar directamente al método `send`.

### Datos de Notificación Personalizados

Apple ofrece a los ingenieros la posibilidad de agregar datos de carga (payload) personalizados a cada notificación. Para facilitar eso, aceptamos la conformidad `Codable` con el parámetro de carga (payload) en todas las apis `send`.

```swift
// Carga útil codificable personalizada
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Más Información

Para obtener más información sobre los métodos disponibles, consulte el [README de APNSwift](https://github.com/swift-server-community/APNSwift).
