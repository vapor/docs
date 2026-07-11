# Tracing

Le tracing est un outil puissant pour surveiller et déboguer des systèmes distribués. L'API de tracing de Vapor permet aux développeurs de suivre facilement le cycle de vie des requêtes, de propager des métadonnées et de s'intégrer avec des backends populaires comme OpenTelemetry.

L'API de tracing de Vapor est construite au-dessus de [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), ce qui signifie qu'elle est compatible avec toutes les [implémentations de backend](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) de swift-distributed-tracing.

Si vous n'êtes pas familier avec le tracing et les spans en Swift, consultez la [documentation OpenTelemetry Trace](https://opentelemetry.io/docs/concepts/signals/traces/) et la [documentation swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Pour créer automatiquement un span entièrement annoté pour chaque requête, ajoutez `TracingMiddleware` à votre application.

```swift
app.middleware.use(TracingMiddleware())
```

Pour obtenir des mesures de span précises et garantir que les identifiants de tracing sont correctement transmis aux autres services, ajoutez ce middleware avant les autres middlewares.

## Ajout de spans

Lors de l'ajout de spans aux gestionnaires de route, il est idéal qu'ils soient associés au span de requête de premier niveau. C'est ce qu'on appelle la « propagation de span » et cela peut être géré de deux manières différentes : automatique ou manuelle.

### Propagation automatique

Vapor prend en charge la propagation automatique des spans entre les middlewares et les callbacks de route. Pour ce faire, définissez la propriété `Application.traceAutoPropagation` sur true lors de la configuration.

```swift
app.traceAutoPropagation = true
```

!!! note
    L'activation de la propagation automatique peut dégrader les performances des API à haut débit ayant des besoins de tracing minimes, car les métadonnées du span de requête doivent être restaurées pour chaque gestionnaire de route, que des spans soient créés ou non.

Les spans peuvent alors être créés dans la closure de route en utilisant la syntaxe habituelle de distributed tracing.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagation manuelle

Pour éviter les implications sur les performances de la propagation automatique, vous pouvez restaurer manuellement les métadonnées du span où cela est nécessaire. `TracingMiddleware` définit automatiquement une propriété `Request.serviceContext` qui peut être utilisée directement dans le paramètre `context` de `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Pour restaurer les métadonnées du span sans créer de span, utilisez `ServiceContext.withValue`. Cela est utile si vous savez que des bibliothèques asynchrones en aval émettent leurs propres spans de tracing, et que ceux-ci doivent être imbriqués sous le span de requête parent.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Considérations relatives à NIO

Étant donné que `swift-distributed-tracing` utilise les [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) pour la propagation, vous devez restaurer manuellement le contexte chaque fois que vous traversez des frontières `NIO EventLoopFuture` afin de garantir que les spans sont correctement liés. **Cela est nécessaire que la propagation automatique soit activée ou non**.

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
