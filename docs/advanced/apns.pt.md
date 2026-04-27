# APNS

A API do Apple Push Notification Service (APNS) do Vapor facilita a autenticação e o envio de notificações push para dispositivos Apple. É construída sobre o [APNSwift](https://github.com/swift-server-community/APNSwift).

## Primeiros Passos

Vamos ver como você pode começar a usar o APNS.

### Package

O primeiro passo para usar o APNS é adicionar o pacote às suas dependências.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
         // Outras dependências...
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Outras dependências...
            .product(name: "VaporAPNS", package: "apns")
        ]),
        // Outros targets...
    ]
)
```

Se você editar o manifesto diretamente dentro do Xcode, ele automaticamente detectará as mudanças e buscará a nova dependência quando o arquivo for salvo. Caso contrário, no Terminal, execute `swift package resolve` para buscar a nova dependência.

### Configuração

O módulo APNS adiciona uma nova propriedade `apns` ao `Application`. Para enviar notificações push, você precisará definir a propriedade `configuration` com suas credenciais.

```swift
import APNS
import VaporAPNS
import APNSCore

// Configurar APNS usando autenticação JWT.
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

Preencha os placeholders com suas credenciais. O exemplo acima mostra [autenticação baseada em JWT](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) usando a chave `.p8` que você obtém do portal de desenvolvedores da Apple. Para [autenticação baseada em TLS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) com um certificado, use o método de autenticação `.tls`:

```swift
authenticationMethod: .tls(
    privateKeyPath: <#path to private key#>,
    pemPath: <#path to pem file#>,
    pemPassword: <#optional pem password#>
)
```

### Envio

Uma vez que o APNS está configurado, você pode enviar notificações push usando o método `apns.send` no `Application` ou `Request`.

```swift
// Payload Codable personalizado
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
// Criar Alert de notificação push
let dt = "70075697aa918ebddd64efb165f5b9cb92ce095f1c4c76d995b384c623a258bb"
let payload = Payload(acme1: "hey", acme2: 2)
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Olá"),
        subtitle: .raw("Este é um teste do vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#my topic#>",
    payload: payload
)
// Enviar a notificação
try! await req.apns.client.sendAlertNotification(
    alert,
    deviceToken: dt,
    deadline: .distantFuture
)
```

Use `req.apns` sempre que estiver dentro de um route handler.

```swift
// Envia uma notificação push.
app.get("test-push") { req async throws -> HTTPStatus in
    try await req.apns.client.send(...)
    return .ok
}
```

O primeiro parâmetro aceita o alert de notificação push e o segundo parâmetro é o device token de destino.

## Alert

`APNSAlertNotification` é o metadado real do alert de notificação push a ser enviado. Mais detalhes sobre as especificidades de cada propriedade são fornecidos [aqui](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). Eles seguem um esquema de nomenclatura um-para-um listado na documentação da Apple.

```swift
let alert = APNSAlertNotification(
    alert: .init(
        title: .raw("Olá"),
        subtitle: .raw("Este é um teste do vapor/apns")
    ),
    expiration: .immediately,
    priority: .immediately,
    topic: "<#my topic#>",
    payload: payload
)
```

Este tipo pode ser passado diretamente ao método `send`.

### Dados de Notificação Personalizados

A Apple fornece aos engenheiros a capacidade de adicionar dados de payload personalizados a cada notificação. Para facilitar isso, aceitamos conformidade `Codable` no parâmetro payload em todas as APIs `send`.

```swift
// Payload Codable personalizado
struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
```

## Mais Informações

Para mais informações sobre métodos disponíveis, veja o [README do APNSwift](https://github.com/swift-server-community/APNSwift).
