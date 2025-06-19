# トレーシング {#tracing}

トレーシングは、分散システムの監視とデバッグのための強力なツールです。Vaporのトレーシング APIを使用すると、開発者はリクエストのライフサイクルを簡単に追跡し、メタデータを伝播し、OpenTelemetryなどの人気のあるバックエンドと統合できます。

Vaporのトレーシング APIは[swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing)の上に構築されているため、swift-distributed-tracingのすべての[バックエンド実装](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends)と互換性があります。

Swiftでのトレーシングとスパンに馴染みがない場合は、[OpenTelemetryトレースドキュメント](https://opentelemetry.io/ja/docs/concepts/signals/traces/)と[swift-distributed-tracingドキュメント](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing)を確認してください。

## TracingMiddleware

各リクエストに対して完全に注釈付きのスパンを自動的に作成するには、アプリケーションに`TracingMiddleware`を追加します。

```swift
app.middleware.use(TracingMiddleware())
```

正確なスパン測定を取得し、トレーシング識別子が他のサービスに正しく渡されるようにするには、このミドルウェアを他のミドルウェアの前に追加してください。

## スパンの追加 {#adding-spans}

ルートハンドラーにスパンを追加する場合、それらをトップレベルのリクエストスパンに関連付けることが理想的です。これは「スパン伝播」と呼ばれ、自動または手動の2つの方法で処理できます。

### 自動伝播 {#automatic-propagation}

Vaporは、ミドルウェアとルートコールバック間でスパンを自動的に伝播する機能をサポートしています。これを行うには、設定時に`Application.traceAutoPropagation`プロパティをtrueに設定します。

```swift
app.traceAutoPropagation = true
```

!!! note
    自動伝播を有効にすると、スパンが作成されるかどうかに関係なく、すべてのルートハンドラーでリクエストスパンメタデータを復元する必要があるため、最小限のトレーシングニーズを持つ高スループットAPIではパフォーマンスが低下する可能性があります。

その後、通常の分散トレーシング構文を使用してルートクロージャでスパンを作成できます。

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### 手動伝播 {#manual-propagation}

自動伝播のパフォーマンスへの影響を避けるために、必要に応じて手動でスパンメタデータを復元できます。`TracingMiddleware`は自動的に`Request.serviceContext`プロパティを設定し、これを`withSpan`の`context`パラメータで直接使用できます。

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

スパンを作成せずにスパンメタデータを復元するには、`ServiceContext.withValue`を使用します。これは、ダウンストリームの非同期ライブラリが独自のトレーシングスパンを発行し、それらが親リクエストスパンの下にネストされるべきであることがわかっている場合に有用です。

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## NIOに関する考慮事項 {#nio-considerations}

`swift-distributed-tracing`は[`TaskLocalプロパティ`](https://developer.apple.com/documentation/swift/tasklocal)を使用して伝播するため、スパンが正しくリンクされるようにするには、`NIO EventLoopFuture`の境界を越えるたびに手動でコンテキストを再復元する必要があります。**これは自動伝播が有効かどうかに関係なく必要です**。

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