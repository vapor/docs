# Tracing

Tracing is een krachtig hulpmiddel voor het monitoren en debuggen van gedistribueerde systemen. Vapor's tracing API stelt ontwikkelaars in staat om eenvoudig de levenscyclus van verzoeken te volgen, metadata door te geven en te integreren met populaire backends zoals OpenTelemetry.

Vapor's tracing API is gebouwd bovenop [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), wat betekent dat het compatibel is met alle [backend-implementaties](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) van swift-distributed-tracing.

Als je niet bekend bent met tracing en spans in Swift, bekijk dan de [OpenTelemetry Trace documentatie](https://opentelemetry.io/docs/concepts/signals/traces/) en de [swift-distributed-tracing documentatie](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Om automatisch een volledig geannoteerde span te maken voor elk verzoek, voeg je de `TracingMiddleware` toe aan je applicatie.

```swift
app.middleware.use(TracingMiddleware())
```

Om nauwkeurige span-metingen te krijgen en ervoor te zorgen dat tracing-identifiers correct worden doorgegeven aan andere diensten, voeg je deze middleware toe vóór andere middlewares.

## Spans Toevoegen

Wanneer je spans toevoegt aan route handlers, is het ideaal dat ze geassocieerd worden met de span van het request op het hoogste niveau. Dit wordt "span propagatie" genoemd en kan op twee verschillende manieren worden afgehandeld: automatisch of handmatig.

### Automatische Propagatie

Vapor ondersteunt het automatisch propageren van spans tussen middleware en route callbacks. Stel hiervoor tijdens de configuratie de `Application.traceAutoPropagation` eigenschap in op true.

```swift
app.traceAutoPropagation = true
```

!!! note
    Het inschakelen van auto-propagatie kan de prestaties verminderen bij API's met een hoge doorvoer en minimale tracing-behoeften, omdat de metadata van de request span moet worden hersteld voor elke route handler, ongeacht of er spans worden gemaakt.

Vervolgens kunnen spans worden gemaakt in de route closure met behulp van de gewone distributed tracing-syntax.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Handmatige Propagatie

Om de prestatie-implicaties van automatische propagatie te vermijden, kun je de span-metadata handmatig herstellen waar nodig. `TracingMiddleware` stelt automatisch een `Request.serviceContext` eigenschap in die direct kan worden gebruikt in de `context` parameter van `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Om de span-metadata te herstellen zonder een span te maken, gebruik je `ServiceContext.withValue`. Dit is waardevol als je weet dat onderliggende async-bibliotheken hun eigen tracing spans uitzenden, en die genest moeten worden onder de bovenliggende request span.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIO Overwegingen

Omdat `swift-distributed-tracing` gebruikmaakt van [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) om te propageren, moet je de context handmatig opnieuw herstellen wanneer je `NIO EventLoopFuture` grenzen oversteekt, om ervoor te zorgen dat spans correct aan elkaar worden gekoppeld. **Dit is noodzakelijk, ongeacht of automatische propagatie is ingeschakeld**.

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
