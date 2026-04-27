# Cliente

A API de client do Vapor permite que você faça chamadas HTTP para recursos externos. Ela é construída sobre o [async-http-client](https://github.com/swift-server/async-http-client) e integra com a API de [conteúdo](content.md).

## Visão Geral

Você pode obter acesso ao client padrão via `Application` ou em um handler de rota via `Request`.

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

O client da aplicação é útil para fazer requisições HTTP durante o tempo de configuração. Se você estiver fazendo requisições HTTP em um handler de rota, sempre use o client da requisição.

### Métodos

Para fazer uma requisição `GET`, passe a URL desejada para o método de conveniência `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Existem métodos para cada um dos verbos HTTP como `get`, `post` e `delete`. A resposta do client é retornada como um future e contém o status HTTP, headers e body.

### Conteúdo

A API de [conteúdo](content.md) do Vapor está disponível para manipular dados em requisições e respostas do client. Para codificar conteúdo, parâmetros de query ou adicionar headers à requisição, use a closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Codifica a query string na URL da requisição.
	try req.query.encode(["q": "test"])

	// Codifica JSON no body da requisição.
    try req.content.encode(["hello": "world"])

    // Adiciona header de auth à requisição
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Manipula a resposta.
```

Você também pode decodificar o body da resposta usando `Content` de maneira similar:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Se você estiver usando futures, pode usar `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Use o JSON aqui
}
```

## Configuração

Você pode configurar o client HTTP subjacente através da aplicação.

```swift
// Desabilita o redirecionamento automático.
app.http.client.configuration.redirectConfiguration = .disallow
```

Note que você deve configurar o client padrão _antes_ de usá-lo pela primeira vez.

