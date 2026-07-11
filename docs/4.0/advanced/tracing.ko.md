# Tracing

Tracing은 분산 시스템을 모니터링하고 디버깅하는 데 강력한 도구입니다. Vapor의 tracing API를 사용하면 개발자가 요청의 생명주기를 쉽게 추적하고, 메타데이터를 전파하며, OpenTelemetry와 같은 널리 사용되는 백엔드와 통합할 수 있습니다.

Vapor의 tracing API는 [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) 위에 구축되어 있으므로, swift-distributed-tracing의 모든 [백엔드 구현체](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends)와 호환됩니다.

Swift의 tracing과 span에 익숙하지 않다면 [OpenTelemetry Trace 문서](https://opentelemetry.io/docs/concepts/signals/traces/)와 [swift-distributed-tracing 문서](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing)를 참고하세요.

## TracingMiddleware

각 요청에 대해 완전히 주석이 달린 span을 자동으로 생성하려면, 애플리케이션에 `TracingMiddleware`를 추가하세요.

```swift
app.middleware.use(TracingMiddleware())
```

정확한 span 측정값을 얻고 tracing 식별자가 다른 서비스로 올바르게 전달되도록 하려면, 이 미들웨어를 다른 미들웨어보다 먼저 추가하세요.

## Span 추가하기

라우트 핸들러에 span을 추가할 때는 최상위 요청 span과 연결되도록 하는 것이 이상적입니다. 이를 "span 전파(span propagation)"라고 하며, 자동 또는 수동의 두 가지 방식으로 처리할 수 있습니다.

### 자동 전파

Vapor는 미들웨어와 라우트 콜백 사이에서 span을 자동으로 전파하는 기능을 지원합니다. 이를 위해서는 설정 시 `Application.traceAutoPropagation` 속성을 true로 설정하세요.

```swift
app.traceAutoPropagation = true
```

!!! note
    자동 전파를 활성화하면, tracing이 거의 필요 없는 높은 처리량의 API에서 성능이 저하될 수 있습니다. span이 생성되는지 여부와 관계없이 모든 라우트 핸들러마다 요청 span 메타데이터를 복원해야 하기 때문입니다.

이렇게 하면 일반적인 distributed tracing 문법을 사용해 라우트 클로저 내에서 span을 생성할 수 있습니다.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### 수동 전파

자동 전파로 인한 성능 영향을 피하려면, 필요한 곳에서 수동으로 span 메타데이터를 복원할 수 있습니다. `TracingMiddleware`는 자동으로 `Request.serviceContext` 속성을 설정하며, 이를 `withSpan`의 `context` 매개변수에서 직접 사용할 수 있습니다.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

span을 생성하지 않고 span 메타데이터만 복원하려면 `ServiceContext.withValue`를 사용하세요. 이는 다운스트림 비동기 라이브러리가 자체적으로 tracing span을 발생시키고, 그 span들이 상위 요청 span 아래에 중첩되어야 한다는 것을 알고 있을 때 유용합니다.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIO 관련 고려사항

`swift-distributed-tracing`은 전파를 위해 [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal)를 사용하기 때문에, `NIO EventLoopFuture` 경계를 넘을 때마다 span이 올바르게 연결되도록 컨텍스트를 수동으로 다시 복원해야 합니다. **이는 자동 전파가 활성화되어 있는지 여부와 관계없이 반드시 필요합니다**.

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
