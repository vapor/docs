# Tracing

Il tracing è uno strumento potente per monitorare e fare debug di sistemi distribuiti. L'API tracing di Vapor consente agli sviluppatori di tracciare facilmente il ciclo di vita delle richieste, propagare i metadati e integrarsi con backend popolari come OpenTelemetry.

L'API tracing di Vapor è costruita sopra [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), il che significa che è compatibile con tutte le [implementazioni backend](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) di swift-distributed-tracing.

Se non hai familiarità con il tracing e gli span in Swift, consulta la [documentazione OpenTelemetry Trace](https://opentelemetry.io/docs/concepts/signals/traces/) e la [documentazione swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Per creare automaticamente uno span completamente annotato per ogni richiesta, aggiungi il `TracingMiddleware` alla tua applicazione.

```swift
app.middleware.use(TracingMiddleware())
```

Per ottenere misurazioni accurate degli span e garantire che gli identificatori di tracing vengano passati correttamente ad altri servizi, aggiungi questo middleware prima degli altri middleware.

## Aggiungere Span

Quando aggiungi span ai gestori di route, è ideale che siano associati allo span della richiesta di primo livello. Questo è noto come "propagazione degli span" e può essere gestito in due modi diversi: automatico o manuale.

### Propagazione Automatica

Vapor ha supporto per propagare automaticamente gli span tra middleware e callback di route. Per farlo, imposta la proprietà `Application.traceAutoPropagation` su true durante la configurazione.

```swift
app.traceAutoPropagation = true
```

!!! note "Nota"
    Abilitare la propagazione automatica potrebbe degradare le prestazioni su API ad alto throughput con esigenze minime di tracing, poiché i metadati degli span delle richieste devono essere ripristinati per ogni gestore di route indipendentemente dal fatto che vengano creati span.

Poi gli span possono essere creati nelle chiusure delle routes usando la sintassi ordinaria di distributed tracing.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagazione Manuale

Per evitare le implicazioni sulle prestazioni della propagazione automatica, puoi ripristinare manualmente i metadati degli span dove necessario. `TracingMiddleware` imposta automaticamente una proprietà `Request.serviceContext` che può essere usata direttamente nel parametro `context` di `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Per ripristinare i metadati degli span senza creare uno span, usa `ServiceContext.withValue`. Questo è utile se sai che le librerie async a valle emettono i propri span di tracing, e questi dovrebbero essere annidati sotto lo span della richiesta padre.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Considerazioni su NIO

Poiché `swift-distributed-tracing` usa le [`proprietà TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) per la propagazione, devi ripristinare manualmente il contesto ogni volta che attraversi i confini di `NIO EventLoopFuture` per assicurarti che gli span siano collegati correttamente. **Questo è necessario indipendentemente dal fatto che la propagazione automatica sia abilitata**.

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
