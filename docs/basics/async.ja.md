# 非同期 {#async}

## Async Await

Swift 5.5では、`async`/`await`の形で言語に非同期性が導入されました。これにより、SwiftおよびVaporアプリケーションで非同期コードを扱うための第一級の方法が提供されます。

Vaporは、低レベルの非同期プログラミングのためのプリミティブ型を提供する[SwiftNIO](https://github.com/apple/swift-nio.git)の上に構築されています。これらは（そして依然として）`async`/`await`が到来する前のVapor全体で使用されていました。しかし、ほとんどのアプリケーションコードは、`EventLoopFuture`を使用する代わりに`async`/`await`を使用して書かれるようになりました。これにより、あなたのコードが簡素化され、その理由を理解しやすくなります。

VaporのAPIの多くは、`EventLoopFuture`と`async`/`await`の両方のバージョンを提供するようになり、どちらが最適かを選択できるようになりました。一般的には、1つのルートハンドラーにつき1つのプログラミングモデルのみを使用し、コードの中で混在させないようにすべきです。イベントループを明示的に制御する必要があるアプリケーションや、非常に高性能が求められるアプリケーションについては、カスタムエグゼキュータが実装されるまで`EventLoopFuture`を使用し続けるべきです。それ以外の人々には、読みやすさや保守性の利点が小さなパフォーマンスのペナルティをはるかに上回るため、`async`/`await`を使用すべきです。

### async/awaitへの移行 {#migrating-to-asyncawait}

async/awaitに移行するにはいくつかのステップが必要です。まず、macOSを使用している場合は、macOS 12 Monterey以降とXcode 13.1以降が必要です。他のプラットフォームでは、Swift 5.5以降を実行している必要があります。次に、すべての依存関係を更新したことを確認してください。

Package.swiftで、ファイルの先頭にあるツールバージョンを5.5に設定します：

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

次に、プラットフォームバージョンをmacOS 12 に設定します。：

```swift
    platforms: [
       .macOS(.v12)
    ],
```

最後に、`Run` ターゲットを実行可能ターゲットとしてマークを更新します。：

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Note: Linuxにデプロイする場合は、そちらのSwiftバージョンも更新してください。例えばHerokuやDockerfileで。例えばDockerfileでは、以下のように変更します：

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

これで既存のコードを移行することができます。一般的には、EventLoopFutureを返す関数は今やasyncになっています。例えば：

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

それが以下のようになります。:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### 古い API と新しい API の使用 {#working-with-old-and-new-apis}

まだ `async`/`await` バージョンを提供していない API に遭遇した場合は、`EventLoopFuture` を返す関数に `.get()` を呼び出して変換することができます。

例えば、

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

これを、

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

に変換できます。
逆にやりたい場合は、

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

を

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

に変換できます。

## `EventLoopFuture` {#eventloopfutures}

Vapor のいくつかの API が一般的な `EventLoopFuture` タイプを期待したり返したりすることに気づいたかもしれません。もしこれが futures について初めて聞いたのであれば、最初は少し混乱するかもしれません。しかし心配しないでください、このガイドは彼らの強力な API を利用する方法をお見せします。

プロミスとフューチャーは関連しているが、異なるタイプです。プロミスはフューチャーを_作成する_ために使用されます。ほとんどの場合、Vapor の API によって返されるフューチャーを扱っており、プロミスを作成することについて心配する必要はありません。

|タイプ|説明|変更可能性|
|-|-|-|
|`EventLoopFuture`|まだ利用できない可能性がある値への参照|read-only|
|`EventLoopPromise`|非同期になんらかの値を提供するという約束|read/write|

フューチャーは、コールバックベースの非同期 API への代替手段です。フューチャーは、単純なクロージャではできない方法で連鎖させたり変換したりすることができます。

## 変換 {#transforming}

Swiftのオプショナルや配列のように、フューチャーはマップやフラットマップで変換できます。これらは、フューチャーに対して行う最も一般的な操作です。

|メソッド|引数|説明|
|-|-|-|
|[`map`](#map)|`(T) -> U`|フューチャーの値を別の値にマップします。|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|フューチャーの値を別の値にマップするか、エラーを投げます。|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|フューチャーの値を別の_フューチャー_の値にマップします。|
|[`transform`](#transform)|`U`|既に利用可能な値にフューチャーをマップします。|

`Optional<T>`や`Array<T>`の`map`や`flatMap`のメソッドシグネチャを見ると、`EventLoopFuture<T>`で利用可能なメソッドと非常に似ていることが分かります。

### map

`map`メソッドを使用すると、フューチャーの値を別の値に変換できます。フューチャーの値はまだ利用可能でない可能性があるため（非同期タスクの結果である場合があります）、値を受け取るクロージャを提供する必要があります。

```swift
/// あるAPIからフューチャー文字列を取得すると仮定します
let futureString: EventLoopFuture<String> = ...

/// フューチャー文字列を整数にマップします
let futureInt = futureString.map { string in
    print(string) // 実際のString
    return Int(string) ?? 0
}

/// 今度はフューチャー整数を持っています
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

`flatMapThrowing` メソッドを使用すると、フューチャーの値を別の値に変換するか、エラーを投げることができます。

!!! info
    エラーを投げるためには内部で新しいフューチャーを作成する必要があるため、このメソッドは `flatMap` というプレフィックスが付いていますが、クロージャーはフューチャーを返す必要はありません。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

`flatMap` メソッドを使用すると、フューチャーの値を別のフューチャーの値に変換できます。これは、ネストされたフューチャー（例えば、`EventLoopFuture<EventLoopFuture<T>>`）を作成するのを避けることができるため、"flat" map と呼ばれます。つまり、ジェネリックをフラットに保つのに役立ちます。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ...

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    上記の例で `map` を使用した場合、結果は `EventLoopFuture<EventLoopFuture<ClientResponse>>` になります。

`flatMap` 内でエラーを投げるメソッドを呼び出す場合は、Swiftの `do` / `catch` キーワードを使用し、[completed future](#makefuture) を作成します。

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```

### transform

`transform` メソッドを使用すると、既存の値を無視してフューチャーの値を変更できます。これは、フューチャーの実際の値が重要でない `EventLoopFuture<Void>` の結果を変換する場合に特に便利です。

!!! tip
    `EventLoopFuture<Void>` は、時にシグナルと呼ばれ、その唯一の目的は、非同期操作の完了または失敗を通知することです。

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```

`transform` に既に利用可能な値を提供しているとしても、これはまだ_変換_です。前のフューチャーが完了する（または失敗する）まで、フューチャーは完了しません。

### チェーン {#chaining}

フューチャーの変換の素晴らしい点は、それらがチェーンできることです。これにより、多くの変換やサブタスクを簡単に表現できます。

上記の例を変更して、チェーンを利用する方法を見てみましょう。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ...

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

最初の map 呼び出しの後、一時的な `EventLoopFuture<URL>` が作成されます。このフューチャーはすぐに `EventLoopFuture<Response>` にフラットマップされます。

## Future

`EventLoopFuture<T>` を使用する他の方法について見てみましょう。

### makeFuture

イベントループを使用して、値またはエラーを持つ事前に完了したフューチャーを作成できます。

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

`whenComplete` を使用して、フューチャーが成功または失敗したときに実行されるコールバックを追加できます。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    Future には、好きなだけコールバックを追加できます。

### Get

API に並行性ベースの代替手段がない場合は、`try await future.get()` を使用して Future の値を待つことができます。

```swift
/// 何らかの API から Future 文字列を取得すると仮定します
let futureString: EventLoopFuture<String> = ...

/// 文字列が準備できるまで待ちます
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! warning
    `wait()` 関数は廃止されました。推奨されるアプローチについては [`Get`](#get) を参照してください。

`.wait()`を使用して、フューチャーが完了するまで同期的に待つことができます。フューチャーが失敗する可能性があるため、この呼び出しは投げられます。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` は、バックグラウンドスレッドまたはメインスレッド、つまり `configure.swift` で使用できます。イベントループスレッド、つまりルートクロージャで使用することは_できません_。

!!! warning
    イベントループスレッドで `wait()` を呼び出そうとすると、アサーションエラーが発生します。


## Promise

ほとんどの場合、Vapor の API からの呼び出しによって返されるフューチャーを変換します。しかし、ある時点で自分自身の約束を作成する必要があるかもしれません。

約束を作成するには、`EventLoop` へのアクセスが必要です。`Application` または `Request` からコンテキストに応じてイベントループにアクセスできます。

```swift
let eventLoop: EventLoop

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    約束は一度だけ完了できます。その後の完了は無視されます。

約束はどのスレッドからでも完了（`succeed` / `fail`）できます。これが、初期化にイベントループが必要な理由です。約束は、完了アクションがそのイベントループに戻されて実行されることを保証します。

## イベントループ {#event-loop}

アプリケーションが起動すると、通常は実行中の CPU の各コアに対して1つのイベントループが作成されます。各イベントループには1つのスレッドがあります。Node.js からのイベントループに精通している場合、Vapor のものは似ています。主な違いは、Swift がマルチスレッディングをサポートしているため、Vapor は 1 つのプロセスで複数のイベントループを実行できることです。

クライアントがサーバーに接続するたびに、そのイベントループの 1 つに割り当てられます。その時点から、サーバーとそのクライアントとの間のすべての通信は、同じイベントループ（および関連するイベントループのスレッド）で行われます。

イベントループは、接続された各クライアントの状態を追跡する責任があります。クライアントからのリクエストが読み取りを待っている場合、イベントループは読み取り通知をトリガーし、データが読み取られます。リクエスト全体が読み取られると、そのリクエストのデータを待っている任意のフューチャーが完了します。

ルートクロージャで、`Request` 経由で現在のイベントループにアクセスできます。

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor はルートクロージャが `req.eventLoop` に留まることを期待しています。スレッドを移動する場合、`Request` と最終的な応答フューチャーへのアクセスがすべてリクエストのイベントループ上で行われることを確認する必要があります。

ルートクロージャの外では、`Application` を介して利用可能なイベントループの1つを取得できます。

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

`hop` を使用して、フューチャーのイベントループを変更できます。

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

イベントループスレッドでブロッキングコードを呼び出すと、アプリケーションがタイムリーに受信リクエストに応答することができなくなる可能性があります。ブロッキングコールの例としては、`libc.sleep(_:)` のようなものがあります。

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)

    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` は指定された秒数だけ現在のスレッドをブロックするコマンドです。イベントループで直接このようなブロッキング作業を行うと、その作業の期間、イベントループはそれに割り当てられた他のクライアントに応答することができなくなります。言い換えると、イベントループで `sleep(5)` を行うと、そのイベントループに接続されている他のクライアント（数百または数千）が少なくとも5秒遅れることになります。

ブロッキング作業は背景で実行し、この作業がブロッキングしない方法で完了したときにイベントループに通知するためにプロミスを使用してください。

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)

        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

すべてのブロッキングコールが `sleep(_:)` ほど明白ではありません。使用している呼び出しがブロッキングかどうか疑わしい場合は、そのメソッド自体を調査するか、誰かに尋ねてください。以下のセクションでは、メソッドがどのようにブロッキングする可能性があるかについて、詳しく説明します。

### I/O バウンド {#io-bound}

I/O バウンドのブロッキングとは、ネットワークやハードディスクなど、CPU よりも桁違いに遅いリソースを待つことを意味します。これらのリソースを待っている間に CPU をブロックすると、時間が無駄になります。

!!! danger
    イベントループで直接ブロッキングI/Oバウンドコールを行わないでください。

Vapor のすべてのパッケージは SwiftNIO に基づいており、ノンブロッキング I/O を使用しています。しかし、ブロッキング I/O を使用する Swift のパッケージや C ライブラリが多く存在します。関数がディスクやネットワーク IO を行っており、同期 API（コールバックやフューチャーがない）を使用している場合、ブロッキングしている可能性が高いです。

### CPU バウンド {#cpu-bound}

リクエスト中のほとんどの時間は、データベースのクエリやネットワークリクエストなどの外部リソースを待っているために費やされます。Vapor と SwiftNIO はノンブロッキングなので、このダウンタイムは他の受信リクエストを満たすために使用できます。しかし、アプリケーションのいくつかのルートは、リクエストの結果として重い CPU バウンド作業を行う必要があるかもしれません。

イベントループが CPU バウンド作業を処理している間、他の受信リクエストに応答することができません。これは通常問題ありません。CPU は高速であり、Web アプリケーションが行うほとんどの CPU 作業は軽量です。しかし、長時間実行される CPU 作業のルートが、他のルートへの迅速な応答を妨げる場合、問題になる可能性があります。

アプリ内の長時間実行される CPU 作業を特定し、それをバックグラウンドスレッドに移動することで、サービスの信頼性と応答性を向上させることができます。CPU バウンド作業は I/O バウンド作業よりもグレーエリアであり、線を引く場所を決定するのは最終的にはあなた次第です。

重い CPU バウンド作業の一般的な例は、ユーザーのサインアップとログイン時の Bcrypt ハッシュ化です。Bcrypt はセキュリティ上の理由から意図的に非常に遅く、CPU を集中的に使用します。これは、シンプルな Web アプリケーションが実際に行う作業の中で最も CPU 集中的な作業かもしれません。ハッシングをバックグラウンドスレッドに移動すると、CPU はイベントループの作業とハッシュの計算を交互に行うことができ、結果として高い並行性が実現されます。
