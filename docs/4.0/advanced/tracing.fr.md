# Traçage

Le traçage est un outil puissant de surveillance et débogage pour systèmes distribués. L'API Tracing de Vapor permet aux développeurs de suivre facilement le cycle de vie d'une requête, de propager des méta-données, et de s'intégrer à des plateformes populaires comme OpenTelemetry.

L'API Tracing de Vapor est basée sur [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), ce qui la rend compatible avec toutes les [implémentations backend](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) de swift-distributed-tracing.

Si vous n'êtes pas familiarisé avec le traçage et la notion de portée en Swift, lisez la [documentation sur les Traces OpenTelemetry](https://opentelemetry.io/docs/concepts/signals/traces/) et la [documentation de swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Pour créer automatiquement un span entièrement renseigné pour chaque requête, ajoutez le `TracingMiddleware` à votre application.

```swift
app.middleware.use(TracingMiddleware())
```

Pour obtenir des mesures de span précises et s'assurer que les identifiants de traces sont bien transmis aux autres services, ajoutez ce middleware avant tout autre middlewares.

## Ajout de Spans

Lorsque vous ajoutez des spans dans vos routes, il faut idéalement les associer avec le span racine de la requête. Cela s'appelle la "propagation de span" et peut être fait de deux manières différentes : automatiquement ou manuellement.

### Propagation automatique

Vapor permet la propagation automatique de spans entre middleware et routes. Pour l'activer, définissez la valeur de la propriété `Application.traceAutoPropagation` à true dans votre configuration.

```swift
app.traceAutoPropagation = true
```

!!! Note
    Activer l'auto-propagation peut causer une dégradation de performances sur des APIs fortement sollicitées dont les besoins de traçage sont minimes, car les méta-données du span de la requête doivent être restaurées pour chaque route, que des spans y soient créés ou non.

Des spans peuvent ensuite être créés dans la route en utilisant la syntaxe classique de traçage distribué.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagation manuelle

Pour éviter les implications de performance de la propagation automatique, vous pouvez restaurer manuellement les méta-données de span là ou ce sera nécessaire. Le `TracingMiddleware` définit automatiquement une propriété `Request.serviceContext` que l'on peut directement utiliser dans le paramètre `context` de `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Pour restaurer les méta-données de span sans créer un nouveau span, utilisez `ServiceContext.withValue`. Cela vous servira si vous savez que des librairies asynchrones en aval émettent leurs propres spans de traçage, qui devraient être encapsulés dans le span de la requête parente.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Considérations relatives à NIO

Étant donné que `swift-distributed-tracing` utilise des propriétés de type [`TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) pour la propagation, vous devez manuellement restaurer à nouveau le contexte dès que vous franchissez les frontières d'un `EventLoopFuture NIO` pour vous assurer que les spans sont correctement liés. **Cette étape est nécessaire même si la propagation automatique est activée**.

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
