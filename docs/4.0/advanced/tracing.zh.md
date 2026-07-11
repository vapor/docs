# 追踪

追踪（Tracing）是监控和调试分布式系统的强大工具。Vapor 的追踪 API 让开发者可以轻松地追踪请求的生命周期、传播元数据，并与 OpenTelemetry 等主流后端集成。

Vapor 的追踪 API 构建于 [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) 之上，这意味着它与 swift-distributed-tracing 的所有[后端实现](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends)兼容。

如果你不熟悉 Swift 中的追踪和 span，请查阅 [OpenTelemetry Trace 文档](https://opentelemetry.io/docs/concepts/signals/traces/)和 [swift-distributed-tracing 文档](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing)。

## TracingMiddleware

要为每个请求自动创建一个带有完整注解的 span，请将 `TracingMiddleware` 添加到你的应用程序中。

```swift
app.middleware.use(TracingMiddleware())
```

为了获得准确的 span 度量，并确保追踪标识符能被正确传递给其他服务，请将此中间件添加在其他中间件之前。

## 添加 Span

在路由处理程序中添加 span 时，最好将它们与顶层的请求 span 相关联。这被称为“span 传播”，可以通过两种不同的方式来处理：自动或手动。

### 自动传播

Vapor 支持在中间件和路由回调之间自动传播 span。要启用此功能，请在配置期间将 `Application.traceAutoPropagation` 属性设置为 true。

```swift
app.traceAutoPropagation = true
```

!!! note
    在高吞吐量且追踪需求较小的 API 上启用自动传播可能会降低性能，因为无论是否创建了 span，都必须为每个路由处理程序恢复请求的 span 元数据。

然后就可以在路由闭包中使用普通的分布式追踪语法来创建 span 了。

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### 手动传播

为了避免自动传播带来的性能影响，你可以在必要时手动恢复 span 元数据。`TracingMiddleware` 会自动设置一个 `Request.serviceContext` 属性，你可以直接在 `withSpan` 的 `context` 参数中使用它。

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

要在不创建 span 的情况下恢复 span 元数据，可以使用 `ServiceContext.withValue`。如果你知道下游的异步库会自行发出追踪 span，并且这些 span 应嵌套在父级请求 span 之下，这将非常有用。

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIO 相关注意事项

由于 `swift-distributed-tracing` 使用 [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) 来传播，因此每当跨越 `NIO EventLoopFuture` 边界时，你都必须手动重新恢复上下文，以确保 span 能正确关联。**无论是否启用了自动传播，这一点都是必要的**。

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
