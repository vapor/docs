# Tracing

Tracing ist ein mächtiges Werkzeug zur Überwachung und Fehlersuche in verteilten Systemen. Vapors Tracing-API ermöglicht es Entwicklern, den Lebenszyklus von Requests einfach nachzuverfolgen, Metadaten weiterzugeben und sich mit gängigen Backends wie OpenTelemetry zu integrieren.

Vapors Tracing-API baut auf [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) auf, wodurch sie mit allen [Backend-Implementierungen](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) von swift-distributed-tracing kompatibel ist.

Falls dir Tracing und Spans in Swift nicht vertraut sind, lies dir die [OpenTelemetry-Trace-Dokumentation](https://opentelemetry.io/docs/concepts/signals/traces/) und die [swift-distributed-tracing-Dokumentation](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing) durch.

## TracingMiddleware

Um automatisch einen vollständig annotierten Span für jeden Request zu erstellen, füge deiner Anwendung die `TracingMiddleware` hinzu.

```swift
app.middleware.use(TracingMiddleware())
```

Um präzise Span-Messungen zu erhalten und sicherzustellen, dass Tracing-Kennungen korrekt an andere Services weitergegeben werden, füge diese Middleware vor anderen Middlewares hinzu.

## Spans hinzufügen

Beim Hinzufügen von Spans zu Route-Handlern ist es ideal, wenn diese mit dem übergeordneten Request-Span verknüpft sind. Dies wird als „Span-Propagation" bezeichnet und kann auf zwei unterschiedliche Arten erfolgen: automatisch oder manuell.

### Automatische Propagation

Vapor unterstützt die automatische Propagation von Spans zwischen Middleware und Route-Callbacks. Setze dazu während der Konfiguration die Eigenschaft `Application.traceAutoPropagation` auf `true`.

```swift
app.traceAutoPropagation = true
```

!!! note
    Das Aktivieren der automatischen Propagation kann die Performance bei APIs mit hohem Durchsatz und geringem Tracing-Bedarf beeinträchtigen, da die Metadaten des Request-Spans für jeden Route-Handler wiederhergestellt werden müssen, unabhängig davon, ob Spans erstellt werden.

Spans können dann im Route-Closure mit der gewöhnlichen Syntax von distributed tracing erstellt werden.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Manuelle Propagation

Um die Performance-Auswirkungen der automatischen Propagation zu vermeiden, kannst du die Span-Metadaten bei Bedarf manuell wiederherstellen. `TracingMiddleware` setzt automatisch eine Eigenschaft `Request.serviceContext`, die direkt im `context`-Parameter von `withSpan` verwendet werden kann.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Um die Span-Metadaten wiederherzustellen, ohne einen Span zu erstellen, verwende `ServiceContext.withValue`. Dies ist nützlich, wenn du weißt, dass nachgelagerte asynchrone Bibliotheken ihre eigenen Tracing-Spans ausgeben, und diese unterhalb des übergeordneten Request-Spans verschachtelt werden sollen.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIO-Überlegungen

Da `swift-distributed-tracing` [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) zur Propagation verwendet, musst du den Kontext manuell wiederherstellen, sobald du Grenzen von `NIO EventLoopFuture` überschreitest, um sicherzustellen, dass Spans korrekt verknüpft werden. **Dies ist notwendig, unabhängig davon, ob die automatische Propagation aktiviert ist**.

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
