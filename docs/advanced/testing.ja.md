# テスト {#testing}

## VaporTesting {#vaportesting}

Vaporには`VaporTesting`というモジュールが含まれており、`Swift Testing`をベースとしたテストヘルパーを提供しています。これらのテストヘルパーを使用すると、Vaporアプリケーションにプログラムでテストリクエストを送信したり、HTTPサーバー経由で実行したりできます。

!!! note
    新しいプロジェクトやSwift並行処理を採用しているチームには、`XCTest`よりも`Swift Testing`を強く推奨します。

### はじめに {#getting-started}

`VaporTesting`モジュールを使用するには、パッケージのテストターゲットに追加されていることを確認してください。

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning
    対応するテストモジュールを使用することを確認してください。そうしないと、Vaporのテスト失敗が適切に報告されない可能性があります。

次に、テストファイルの先頭に`import VaporTesting`と`import Testing`を追加します。テストケースを記述するために`@Suite`名を持つ構造体を作成します。

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
    	// ここでテストします。
    }
}
```

`@Test`でマークされた各関数は、アプリがテストされるときに自動的に実行されます。

テストがシリアル化された方法で実行されることを確実にするには（例：データベースでテストする場合）、テストスイート宣言に`.serialized`オプションを含めます：

```swift
@Suite("App Tests with DB", .serialized)
```

### テスト可能なアプリケーション {#testable-application}

テストのセットアップとティアダウンを効率化し標準化するために、プライベートメソッド関数`withApp`を定義します。このメソッドは`Application`インスタンスのライフサイクル管理をカプセル化し、各テストでアプリケーションが適切に初期化、設定、シャットダウンされることを保証します。

特に、起動時にアプリケーションが要求するスレッドを解放することが重要です。各単体テスト後にアプリで`asyncShutdown()`を呼び出さない場合、`Application`の新しいインスタンスのスレッドを割り当てる際に、precondition失敗でテストスイートがクラッシュする可能性があります。

```swift
private func withApp(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await test(app)
    }
    catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

設定を適用するために、`Application`をパッケージの`configure(_:)`メソッドに渡します。その後、`test()`メソッドを呼び出してアプリケーションをテストします。テスト専用の設定も適用できます。

#### リクエストの送信 {#send-request}

アプリケーションにテストリクエストを送信するには、`withApp`プライベートメソッドを使用し、その中で`app.testing().test()`メソッドを使用します：

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

最初の2つのパラメータは、HTTPメソッドとリクエストするURLです。末尾のクロージャは、`#expect`マクロを使用して検証できるHTTPレスポンスを受け取ります。

より複雑なリクエストの場合、`beforeRequest`クロージャを提供してヘッダーを変更したり、コンテンツをエンコードしたりできます。Vaporの[Content API](../basics/content.md)は、テストリクエストとレスポンスの両方で利用できます。

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### テストメソッド {#testing-method}

Vaporのテスト用APIは、プログラムでのテストリクエスト送信と、ライブHTTPサーバー経由での送信の両方をサポートしています。`testing`メソッドを通じて使用したい方法を指定できます。

```swift
// プログラムによるテストを使用。
app.testing(method: .inMemory).test(...)

// ライブHTTPサーバー経由でテストを実行。
app.testing(method: .running).test(...)
```

デフォルトでは`inMemory`オプションが使用されます。

`running`オプションは、使用する特定のポートを渡すことをサポートしています。デフォルトでは`8080`が使用されます。

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### データベース統合テスト {#database-integration-tests}

テスト中にライブデータベースが使用されないように、テスト専用にデータベースを設定します。

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

その後、`autoMigrate()`と`autoRevert()`を使用してテスト中のデータベーススキーマとデータライフサイクルを管理することで、テストを強化できます：

これらのメソッドを組み合わせることで、各テストが新しく一貫したデータベース状態で開始されることを保証し、テストをより信頼性の高いものにし、残存データによる偽陽性や偽陰性の可能性を減らすことができます。

更新された設定を含む`withApp`関数は次のようになります：

```swift
private func withApp(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

## XCTVapor {#xctvapor}

Vaporには`XCTVapor`というモジュールが含まれており、`XCTest`をベースとしたテストヘルパーを提供しています。これらのテストヘルパーを使用すると、Vaporアプリケーションにプログラムでテストリクエストを送信したり、HTTPサーバー経由で実行したりできます。

### はじめに {#getting-started-1}

`XCTVapor`モジュールを使用するには、パッケージのテストターゲットに追加されていることを確認してください。

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

次に、テストファイルの先頭に`import XCTVapor`を追加します。テストケースを記述するために`XCTestCase`を拡張するクラスを作成します。

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // ここでテストします。
    }
}
```

`test`で始まる各関数は、アプリがテストされるときに自動的に実行されます。

### テスト可能なアプリケーション {#testable-application-1}

`.testing`環境を使用して`Application`のインスタンスを初期化します。このアプリケーションがdeinitializeされる前に`app.shutdown()`を呼び出す必要があります。

シャットダウンは、アプリが要求したリソースの解放を助けるために必要です。特に、起動時にアプリケーションが要求するスレッドを解放することが重要です。各単体テスト後にアプリで`shutdown()`を呼び出さない場合、`Application`の新しいインスタンスのスレッドを割り当てる際に、precondition失敗でテストスイートがクラッシュする可能性があります。

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

設定を適用するために、`Application`をパッケージの`configure(_:)`メソッドに渡します。テスト専用の設定は後で適用できます。

#### リクエストの送信 {#send-request-1}

アプリケーションにテストリクエストを送信するには、`test`メソッドを使用します。

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

最初の2つのパラメータは、HTTPメソッドとリクエストするURLです。末尾のクロージャは、`XCTAssert`メソッドを使用して検証できるHTTPレスポンスを受け取ります。

より複雑なリクエストの場合、`beforeRequest`クロージャを提供してヘッダーを変更したり、コンテンツをエンコードしたりできます。Vaporの[Content API](../basics/content.md)は、テストリクエストとレスポンスの両方で利用できます。

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### テスト可能なメソッド {#testable-method}

Vaporのテスト用APIは、プログラムでのテストリクエスト送信と、ライブHTTPサーバー経由での送信の両方をサポートしています。`testable`メソッドを使用して、使用したい方法を指定できます。

```swift
// プログラムによるテストを使用。
app.testable(method: .inMemory).test(...)

// ライブHTTPサーバー経由でテストを実行。
app.testable(method: .running).test(...)
```

デフォルトでは`inMemory`オプションが使用されます。

`running`オプションは、使用する特定のポートを渡すことをサポートしています。デフォルトでは`8080`が使用されます。

```swift
.running(port: 8123)
```