# Queues

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) は、タスクの責任をサイドワーカーに譲渡することができる、純粋な Swift のキューシステムです。

このパッケージが適しているタスクの例:

- メインのリクエストスレッド外でのメール送信
- 複雑または長時間かかるデータベース操作の実行
- ジョブの整合性と耐障害性の確保
- 非クリティカルな処理を遅らせることによる応答時間の短縮
- 特定の時間にジョブをスケジュール

このパッケージは [Ruby Sidekiq](https://github.com/mperham/sidekiq) に似ており、以下の機能を提供します:

- シャットダウン、再起動、または新しいデプロイを示すためにホスティングプロバイダーから送信される `SIGTERM` および `SIGINT` シグナルの安全な処理。
- 異なる優先度が付いたキュー。例えば、メールキューで実行するジョブとデータ処理キューで実行するジョブの優先度を指定できます。
- 予期しない障害に対処するための信頼性の高いキュープロセスの実装。
- 指定された回数までジョブを成功するまで繰り返す `maxRetryCount` 機能を含む。
- NIO を使用して、利用可能なすべてのコアと EventLoop をジョブに活用。
- 定期実行処理をスケジュールする機能を提供。

Queues には、メインプロトコルとインターフェースする正式にサポートされているドライバが 1 つあります:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

また、コミュニティベースのドライバもあります:
- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/m-barthelemy/vapor-queues-fluent-driver)

!!! tip
    `vapor/queues` パッケージは、ドライバを新規に構築している場合を除き、直接依存パッケージに追加しないでください。代わりにドライバパッケージのいずれかを追加してください。

## はじめに {#getting-started}

Queues の使用を開始する方法を見てみましょう。

### Package

Queues を使用するための最初のステップは、SwiftPM パッケージのマニフェストファイルに依存関係としてドライバの 1 つを追加することです。この例では、Redis ドライバを使用します。

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// 他の依存関係...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // 他の依存関係
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Xcode 内でマニフェストを直接編集した場合、ファイルを保存すると自動的に変更を検出し、新しい依存関係を取得します。それ以外の場合は、ターミナルから `swift package resolve` を実行して新しい依存関係を取得します。

### 設定 {#config}

次のステップは、`configure.swift` で Queues を設定することです。ここでは、Redis ライブラリを例として使用します:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### `Job` の登録 {#registering-a-job}

ジョブをモデリングした後、次のように configuration セクションに追加する必要があります:

```swift
// ジョブを登録
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### プロセスとしてワーカーを実行 {#running-workers-as-processes}

新しいキューワーカーを開始するには、`swift run App queues` を実行します。特定の種類のワーカーを実行する場合は、`swift run App queues --queue emails` と指定することもできます。

!!! tip
    ワーカーは本番環境で実行し続ける必要があります。長時間実行するプロセスを維持する方法については、ホスティングプロバイダーに従ってください。例えば、Heroku では、Procfile に `worker: Run queues` のように "worker" dyno を指定できます。これを設定すると、ダッシュボードのリソースタブや `heroku ps:scale worker=1`（または任意の dyno 数）でワーカーを開始できます。

### プロセス内でワーカーを実行 {#running-workers-in-process}

アプリケーションと同じプロセスでワーカーを実行するには（別のサーバーを起動して処理する代わりに）、`Application` の便利なメソッドを呼び出します:

```swift
try app.queues.startInProcessJobs(on: .default)
```

スケジュールされたジョブをプロセス内で実行するには、次のメソッドを呼び出します:

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    キューワーカーをコマンドラインまたはプロセス内ワーカー経由で起動しない場合、ジョブはディスパッチされません。

## `Job` プロトコル {#the-job-protocol}

ジョブは `Job` または `AsyncJob` プロトコルで定義されます。

### `Job` オブジェクトのモデリング {#modeling-a-job-object}

```swift
import Vapor 
import Foundation 
import Queues 

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // ここでメールを送信します
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // エラーを処理しない場合は単に future を返すことができます。また、この関数を完全に省略することもできます。
        return context.eventLoop.future()
    }
}
```

`async`/`await` を使用する場合は、`AsyncJob` を使用します:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // ここでメールを送信します
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // エラーを処理しない場合は単に return します。また、この関数を完全に省略することもできます。
    }
}
```
!!! info
    `Payload` 型が `Codable` プロトコルを実装していることを確認してください。
!!! tip
    **Getting Started** の指示に従って、このジョブを設定ファイルに追加することを忘れないでください。

## ジョブのディスパッチ {#dispatching-jobs}

キュージョブをディスパッチするには、`Application` または `Request` のインスタンスにアクセスする必要があります。ジョブをディスパッチするのは主にルートハンドラー内になるでしょう:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

`Request` オブジェクトが利用できないコンテキスト（例えば `Command` 内）でジョブをディスパッチする必要がある場合は、`Application` オブジェクト内の `queues` プロパティを使用する必要があります。次のようにします:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "message")
            )
    }
}
```


### `maxRetryCount` の設定 {#setting-maxretrycount}

`maxRetryCount` を指定した場合、エラーが発生するとジョブは自動的に再試行されます。例えば:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### 遅延の指定 {#specifying-a-delay}

ジョブを指定した `Date` が経過してからのみ実行するように設定できます。遅延を指定するには、`dispatch` の `delayUntil` パラメータに `Date` を渡します:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 日後
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

ジョブが `delay` パラメータの前にデキューされた場合、ドライバによってジョブが再キューされます。

### 優先度の指定 {#specify-a-priority}

ジョブは必要に応じて異なるキュータイプ/プライオリティに分類できます。例えば、`email` キューと `background-processing` キューを開いてジョブを分類したい場合があります。

まず `QueueName` を拡張します:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

次に、`jobs` オブジェクトを取得する際にキュータイプを指定します:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 日後
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 日後
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

`Application` オブジェクト内からアクセスする場合は、次のようにします:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```



キューを指定しない場合、ジョブは `default` キューで実行されます。各キュータイプのワーカーを起動する手順については、**Getting Started** の指示に従ってください。

## ジョブのスケジューリング {#scheduling-jobs}

Queues パッケージは、ジョブを特定の時点にスケジュールすることもできます。

!!! warning
    スケジュールされたジョブは、アプリケーションの起動前に `configure.swift` などで設定する必要があります。ルートハンドラー内では動作しません。

### スケジューラワーカーの起動 {#starting-the-scheduler-worker}
スケジューラには、キューワーカーと同様に、別のワーカープロセスが必要です。このコマンドを実行してワーカーを起動できます:

```sh
swift run App queues --scheduled
```

!!! tip
    ワーカーは本番環境で実行し続ける必要があります。長時間実行するプロセスを維持する方法については、ホスティングプロバイダーに従ってください。例えば、Heroku では、Procfile に `worker: App queues --scheduled` と指定することで「worker」 dyno を指定できます。

### `ScheduledJob` の作成 {#creating-a-scheduledjob}

まず、新しい `ScheduledJob` または `AsyncScheduledJob` を作成します:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // 追加のサービスが必要な場合は、依存性注入を使用してここに追加します。

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // ここで何か作業を行い、別のジョブをキューに入れるなどします。
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // 追加のサービスが必要な場合は、依存性注入を使用してここに追加します。

    func run(context: QueueContext) async throws {
        // ここで何か作業を行い、別のジョブをキューに入れるなどします。
    }
}
```

次に、設定コード内でスケジュールされたジョブを登録します:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

上記の例では、ジョブは毎年 5 月 23 日の 12:00 PM に実行されます。

!!! tip
    スケジューラはサーバーのタイムゾーンを考慮します。

### 利用可能なビルダーメソッド {#available-builder-methods}
スケジューラには 5 つの主なメソッドがあり、それぞれがさらにヘルパーメソッドを含むビルダーオブジェクトを作成します。コンパイラが未使用の結果に関する警告を出さなくなるまで、スケジューラオブジェクトを構築し続けます。利用可能なすべてのメソッドは以下のとおりです:

| ヘルパー関数       | 利用可能な修飾子                                                     | 説明                                        |
|--------------|--------------------------------------------------------------|-------------------------------------------|
| `yearly()`   | `in(_ month: Month) -> Monthly`                              | ジョブを実行する月。さらに構築するための `Monthly` オブジェクトを返します。 |
| `monthly()`  | `on(_ day: Day) -> Daily`                                    | ジョブを実行する日。さらに構築するための `Daily` オブジェクトを返します。   |
| `weekly()`   | `on(_ weekday: Weekday) -> Daily`                            | ジョブを実行する曜日。`Daily` オブジェクトを返します。            |
| `daily()`    | `at(_ time: Time)`                                           | ジョブを実行する時間。チェーンの最終メソッド。                   |
|              | `at(_ hour: Hour24, _ minute: Minute)`                       | ジョブを実行する時間と分。チェーンの最終メソッド。                 |
|              | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | 実行する時間、分、時間帯。チェーンの最終メソッド。                 |
| `hourly()`   | `at(_ minute: Minute)`                                       | 実行する分。チェーンの最終メソッド。                        |
| `minutely()` | `at(_ second: Second)`                                       | 実行する秒。チェーンの最終メソッド。                        |

### 利用可能なヘルパー {#available-helpers}
Queues には、スケジューリングを容易にするためのいくつかのヘルパー enum が付属しています:

| ヘルパー関数      | 利用可能なヘルパー enum                        |
|-------------|--------------------------------------|
| `yearly()`  | `.january`,`.february`,`.march`, ... |
| `monthly()` | `.first`,`.last`,`.exact(1)`         |
| `weekly()`  | `.sunday`,`.monday`,`.tuesday`, ...  |
| `daily()`   | `.midnight`,`.noon`                  |

ヘルパー enum を使用するには、ヘルパー関数の適切な修飾子を呼び出し、値を渡します。例えば:

```swift
// 毎年 1 月 
.yearly().in(.january)

// 毎月 1 日 
.monthly().on(.first)

// 毎週日曜日 
.weekly().on(.sunday)

// 毎日深夜
.daily().at(.midnight)
```

## イベントデリゲート {#event-delegates}
Queues パッケージでは、ワーカーがジョブに対してアクションを取ったときに通知を受け取る `JobEventDelegate` オブジェクトを指定することができます。これは、モニタリング、インサイトの表示、またはアラートの目的で使用できます。

始めるには、オブジェクトを `JobEventDelegate` に準拠させ、必要なメソッドを実装します:

```swift
struct MyEventDelegate: JobEventDelegate {
    /// ジョブがルートからキューワーカーにディスパッチされたときに呼び出されます
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// ジョブが処理キューに置かれ、作業が開始されたときに呼び出されます
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// ジョブが処理を完了し、キューから削除されたときに呼び出されます
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// ジョブが処理を完了したがエラーが発生したときに呼び出されます
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

次に、設定ファイルに追加します:

```swift
app.queues.add(MyEventDelegate())
```

キューワーカーに関する追加のインサイトを提供するために、デリゲート機能を使用するサードパーティパッケージがいくつかあります:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)
