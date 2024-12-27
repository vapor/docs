# Tracing

Tracing is a powerful tool for monitoring and debugging distributed systems. Vapor's tracing API allows developers to easily track request lifecycles, propagate metadata, and integrate with popular backends like OpenTelemetry.

Vapor's tracing API is built on top of [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), which means it is compatible with all of swift-distributed-tracing's [backend implementations](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends).

If you are unfamiliar with tracing and spans in Swift, review the [OpenTelemetry Trace documentation](https://opentelemetry.io/docs/concepts/signals/traces/) and [swift-distributed-tracing documentation](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

To automatically create a fully annotated span for each request, add the `TracingMiddleware` to your application.

```swift
app.middleware.use(TracingMiddleware())
```

To ensure that tracing identifiers are passed along correctly, this should be added before any middleware that calls tracing APIs or connects to external services.

## Adding Spans

When adding spans to route handlers, it's ideal for them to be associated with the top-level request span. This is referred to as "span propagation" and can be handled in two different ways: automatic or manual.

### Automatic Propagation

Vapor has support to automatically propagate spans between middleware and route callbacks. To do so, set the `Application.traceAutoPropagation` property to true during configuration.

```swift
app.traceAutoPropagation = true
```

!!! note
    Enabling auto-propagation may degrade performance on high-throughput APIs with minimal tracing needs, since request span metadata must be restored for every route handler regardless of whether spans are created.

Then spans may be created in the route closure using the ordinary distributed tracing syntax.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Manual Propagation

To avoid the performance implications of automatic propagation, you may manually restore span metadata where necessary. `TracingMiddleware` automatically sets a `Request.serviceContext` property which may be used directly in `withSpan`'s `context` parameter.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

To restore the span metadata without creating a span, use `ServiceContext.withValue`. This is valuable if you know that downstream async libraries emit their own tracing spans, and those should be nested underneath the parent request span.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIO Considerations

Because `swift-distributed-tracing` uses [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) to propagate, you must manually re-restore the context whenever you cross `NIO EventLoopFuture` boundaries to ensure spans are linked correctly. **This is necessary regardless of whether automatic propagation is enabled**.

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
