# Rastreamento

Rastreamento é uma ferramenta poderosa para monitorar e depurar sistemas distribuídos. A API de rastreamento do Vapor permite que desenvolvedores rastreiem facilmente ciclos de vida de requisições, propaguem metadados e integrem com backends populares como OpenTelemetry.

A API de rastreamento do Vapor é construída sobre o [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), o que significa que é compatível com todas as [implementações de backend](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) do swift-distributed-tracing.

Se você não está familiarizado com rastreamento e spans em Swift, revise a [documentação de Trace do OpenTelemetry](https://opentelemetry.io/docs/concepts/signals/traces/) e a [documentação do swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Para criar automaticamente um span totalmente anotado para cada requisição, adicione o `TracingMiddleware` à sua aplicação.

```swift
app.middleware.use(TracingMiddleware())
```

Para obter medições precisas de span e garantir que os identificadores de rastreamento sejam passados corretamente para outros serviços, adicione este middleware antes dos outros middleware.

## Adicionando Spans

Ao adicionar spans a route handlers, é ideal que eles estejam associados ao span de requisição de nível superior. Isso é chamado de "propagação de span" e pode ser tratado de duas formas diferentes: automática ou manual.

### Propagação Automática

O Vapor tem suporte para propagar automaticamente spans entre middleware e callbacks de rotas. Para isso, defina a propriedade `Application.traceAutoPropagation` como true durante a configuração.

```swift
app.traceAutoPropagation = true
```

!!! note "Nota"
    Habilitar a propagação automática pode degradar o desempenho em APIs de alto throughput com necessidades mínimas de rastreamento, já que os metadados do span de requisição devem ser restaurados para cada route handler, independentemente de os spans serem criados.

Então os spans podem ser criados na closure da rota usando a sintaxe comum de distributed tracing.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagação Manual

Para evitar as implicações de desempenho da propagação automática, você pode restaurar manualmente os metadados do span onde necessário. O `TracingMiddleware` define automaticamente uma propriedade `Request.serviceContext` que pode ser usada diretamente no parâmetro `context` do `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Para restaurar os metadados do span sem criar um span, use `ServiceContext.withValue`. Isso é valioso se você sabe que bibliotecas assíncronas downstream emitem seus próprios spans de rastreamento, e esses devem ser aninhados sob o span de requisição pai.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Considerações sobre NIO

Como o `swift-distributed-tracing` usa [`propriedades TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) para propagar, você deve restaurar manualmente o contexto sempre que cruzar fronteiras de `NIO EventLoopFuture` para garantir que os spans sejam vinculados corretamente. **Isso é necessário independentemente de a propagação automática estar habilitada**.

```swift
app.get("fetchAndProcessNIO") { req in
    withSpan("fetch", context: req.serviceContext) { span in
        fetchSomething().map { result in
            withSpan("process", context: span.context) { _ in
                process(result)
            }
        }
    }
}
```
