# Requisição

O objeto [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) é passado para cada [route handler](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Ele é a janela principal para o restante da funcionalidade do Vapor. Contém APIs para o [corpo da requisição](../basics/content.md), [parâmetros de query](../basics/content.md#query), [logger](../basics/logging.md), [cliente HTTP](../basics/client.md), [Authenticator](../security/authentication.md) e mais. Acessar essa funcionalidade através da requisição mantém a computação no event loop correto e permite que seja mockado para testes. Você também pode adicionar seus próprios [serviços](../advanced/services.md) ao `Request` com extensions.

A documentação completa da API para `Request` pode ser encontrada [aqui](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

A propriedade `Request.application` contém uma referência ao [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Este objeto contém toda a configuração e funcionalidade principal da aplicação. A maioria deve ser configurada apenas em `configure.swift`, antes da aplicação iniciar completamente, e muitas das APIs de baixo nível não serão necessárias na maioria das aplicações. Uma das propriedades mais úteis é `Application.eventLoopGroup`, que pode ser usado para obter um `EventLoop` para processos que precisam de um novo através do método `any()`. Também contém o [`Environment`](../basics/environment.md).

## Body

Se você quiser acesso direto ao corpo da requisição como um `ByteBuffer`, pode usar `Request.body.data`. Isso pode ser usado para fazer streaming de dados do corpo da requisição para um arquivo (embora você deva usar a propriedade [`fileio`](../advanced/files.md) na requisição para isso) ou para outro cliente HTTP.

## Cookies

Embora a aplicação mais útil de cookies seja através das [sessões](../advanced/sessions.md#configuration) integradas, você também pode acessar cookies diretamente via `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

Um objeto `HTTPHeaders` pode ser acessado em `Request.headers`. Ele contém todos os headers enviados com a requisição. Pode ser usado para acessar o header `Content-Type`, por exemplo.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Veja documentação adicional para `HTTPHeaders` [aqui](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). O Vapor também adiciona várias extensões ao `HTTPHeaders` para facilitar o trabalho com os headers mais comumente usados; uma lista está disponível [aqui](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)

## Endereço IP

O `SocketAddress` representando o cliente pode ser acessado via `Request.remoteAddress`, que pode ser útil para logging ou rate limiting usando a representação em string `Request.remoteAddress.ipAddress`. Pode não representar com precisão o endereço IP do cliente se a aplicação estiver atrás de um proxy reverso.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Veja documentação adicional para `SocketAddress` [aqui](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
