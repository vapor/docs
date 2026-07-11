# Tracing

Tracing to potężne narzędzie do monitorowania i debugowania systemów rozproszonych. API tracingu Vapora pozwala programistom łatwo śledzić cykl życia zapytań, propagować metadane oraz integrować się z popularnymi backendami, takimi jak OpenTelemetry.

API tracingu Vapora jest zbudowane na bazie [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), co oznacza, że jest kompatybilne ze wszystkimi [implementacjami backendów](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) swift-distributed-tracing.

Jeśli nie znasz tracingu i spanów w Swifcie, zapoznaj się z [dokumentacją OpenTelemetry Trace](https://opentelemetry.io/docs/concepts/signals/traces/) oraz [dokumentacją swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Aby automatycznie tworzyć w pełni opisany span dla każdego zapytania, dodaj `TracingMiddleware` do swojej aplikacji.

```swift
app.middleware.use(TracingMiddleware())
```

Aby uzyskać dokładne pomiary spanów oraz zapewnić poprawne przekazywanie identyfikatorów tracingu do innych usług, dodaj ten middleware przed innymi middleware.

## Dodawanie spanów

Podczas dodawania spanów do handlerów tras najlepiej, aby były one powiązane z głównym spanem zapytania (top-level request span). Nazywa się to "propagacją spanów" i można to obsłużyć na dwa różne sposoby: automatycznie lub ręcznie.

### Propagacja automatyczna

Vapor obsługuje automatyczną propagację spanów pomiędzy middleware a callbackami tras. Aby to zrobić, ustaw właściwość `Application.traceAutoPropagation` na `true` podczas konfiguracji.

```swift
app.traceAutoPropagation = true
```

!!! note
    Włączenie automatycznej propagacji może obniżyć wydajność w API o wysokiej przepustowości i minimalnych potrzebach w zakresie tracingu, ponieważ metadane spanu zapytania muszą być przywracane dla każdego handlera trasy, niezależnie od tego, czy spany są tworzone.

Następnie spany mogą być tworzone w zamknięciu (closure) trasy przy użyciu zwykłej składni distributed tracing.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagacja ręczna

Aby uniknąć wpływu na wydajność związanego z automatyczną propagacją, możesz ręcznie przywracać metadane spanu tam, gdzie jest to konieczne. `TracingMiddleware` automatycznie ustawia właściwość `Request.serviceContext`, której możesz użyć bezpośrednio w parametrze `context` funkcji `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Aby przywrócić metadane spanu bez tworzenia nowego spanu, użyj `ServiceContext.withValue`. Jest to przydatne, gdy wiesz, że biblioteki asynchroniczne niższego poziomu (downstream) emitują własne spany tracingu, które powinny zostać zagnieżdżone pod nadrzędnym spanem zapytania.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Zagadnienia dotyczące NIO

Ponieważ `swift-distributed-tracing` używa [`właściwości TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) do propagacji, musisz ręcznie przywracać kontekst za każdym razem, gdy przekraczasz granice `NIO EventLoopFuture`, aby zapewnić poprawne powiązanie spanów. **Jest to konieczne niezależnie od tego, czy automatyczna propagacja jest włączona**.

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
