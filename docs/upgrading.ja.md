# 4.0へのアップグレード {#upgrading-to-4.0}

このガイドでは、既存のVapor 3.xプロジェクトを4.xにアップグレードする方法を説明します。このガイドでは、Vaporの公式パッケージに加え、よく使用されるプロバイダーについても網羅します。不足している内容があれば、[Vaporのチームチャット](https://discord.gg/vapor)で質問するのがおすすめです。IssuesやPull Requestも歓迎です。

## 依存関係 {#dependencies}

Vapor 4を使用するには、Xcode 11.4およびmacOS 10.15以上が必要です。

ドキュメントのインストールセクションで依存関係のインストールについて説明しています。

## Package.swift

Vapor 4へのアップグレードの最初のステップは、パッケージの依存関係を更新することです。以下は更新されたPackage.swiftファイルの例です。更新された[テンプレートPackage.swift](https://github.com/vapor/template/blob/main/Package.swift)も確認できます。

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

Vapor 4向けにアップグレードされたすべてのパッケージは、メジャーバージョン番号が1つ増加します。

!!! warning
    Vapor 4の一部のパッケージはまだ正式にリリースされていないため、`-rc`プレリリース識別子が使用されています。

### 廃止されたパッケージ {#old-packages}

いくつかのVapor 3パッケージは非推奨となりました：

- `vapor/auth`: Vaporに含まれるようになりました。
- `vapor/core`: いくつかのモジュールに吸収されました。
- `vapor/crypto`: SwiftCryptoに置き換えられました（Vaporに含まれています）。
- `vapor/multipart`: Vaporに含まれるようになりました。
- `vapor/url-encoded-form`: Vaporに含まれるようになりました。
- `vapor-community/vapor-ext`: Vaporに含まれるようになりました。
- `vapor-community/pagination`: Fluentの一部になりました。
- `IBM-Swift/LoggerAPI`: SwiftLogに置き換えられました。

### Fluent依存関係 {#fluent-dependency}

`vapor/fluent`は、依存関係リストとターゲットに個別の依存関係として追加する必要があります。すべてのデータベース固有のパッケージには、`vapor/fluent`への依存関係を明確にするために`-driver`が付けられています。

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### プラットフォーム {#platforms}

Vaporのパッケージマニフェストは、macOS 10.15以上を明示的にサポートするようになりました。これにより、あなたのパッケージもプラットフォームサポートを指定する必要があります。

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

将来的にVaporは追加のサポートプラットフォームを追加する可能性があります。あなたのパッケージは、バージョン番号がVaporの最小バージョン要件以上である限り、これらのプラットフォームの任意のサブセットをサポートできます。

### Xcode

Vapor 4はXcode 11のネイティブSPMサポートを利用しています。これにより、`.xcodeproj`ファイルを生成する必要がなくなりました。Xcodeでプロジェクトのフォルダーを開くと、自動的にSPMが認識され、依存関係が取得されます。

`vapor xcode`または`open Package.swift`を使用して、Xcodeでプロジェクトをネイティブに開くことができます。

Package.swiftを更新したら、Xcodeを閉じてルートディレクトリから以下のフォルダーを削除する必要があるかもしれません：

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

更新されたパッケージが正常に解決されると、コンパイラエラーが表示されるはずです--おそらくかなりの数です。心配しないでください！修正方法をお見せします。

## Run

最初に行うべきことは、Runモジュールの`main.swift`ファイルを新しい形式に更新することです。

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

`main.swift`ファイルの内容はAppモジュールの`app.swift`を置き換えるため、そのファイルは削除できます。

## App

基本的なAppモジュール構造の更新方法を見てみましょう。

### configure.swift

`configure`メソッドは`Application`のインスタンスを受け入れるように変更する必要があります。

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

以下は更新されたconfigureメソッドの例です。

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// アプリケーションが初期化される前に呼び出されます。
public func configure(_ app: Application) throws {
    // `Public/`ディレクトリからファイルを提供
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // SQLiteデータベースを設定
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // マイグレーションを設定
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

ルーティング、ミドルウェア、Fluentなどの設定に関する構文の変更は以下で説明します。

### boot.swift

`boot`の内容は、アプリケーションインスタンスを受け入れるようになったため、`configure`メソッドに配置できます。

### routes.swift

`routes`メソッドは`Application`のインスタンスを受け入れるように変更する必要があります。

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

ルーティング構文の変更に関する詳細は以下で説明します。

## サービス {#services}

Vapor 4のサービスAPIは、サービスの発見と使用を容易にするために簡素化されました。サービスは`Application`と`Request`のメソッドとプロパティとして公開されるようになり、コンパイラがそれらの使用を支援できます。

これをよりよく理解するために、いくつかの例を見てみましょう。

```diff
// サーバーのデフォルトポートを8281に変更
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

`NIOServerConfig`をサービスに登録する代わりに、サーバー設定はApplicationの単純なプロパティとして公開され、オーバーライドできます。

```diff
// CORSミドルウェアを登録
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // _空の_ミドルウェア設定を作成
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

`MiddlewareConfig`を作成してサービスに登録する代わりに、ミドルウェアはApplicationのプロパティとして公開され、追加できます。

```diff
// ルートハンドラー内でリクエストを行う。
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Applicationと同様に、Requestもサービスを単純なプロパティとメソッドとして公開します。ルートクロージャ内では、常にRequest固有のサービスを使用する必要があります。

この新しいサービスパターンは、Vapor 3の`Container`、`Service`、および`Config`タイプを置き換えます。

### プロバイダー {#providers}

サードパーティパッケージを設定するためにプロバイダーは必要なくなりました。各パッケージは代わりにApplicationとRequestを新しいプロパティとメソッドで拡張して設定します。

Vapor 4でLeafがどのように設定されるか見てみましょう。

```diff
// ビューレンダリングにLeafを使用。
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Leafを設定するには、`app.leaf`プロパティを使用します。

```diff
// Leafビューキャッシュを無効化。
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### 環境 {#environment}

現在の環境（production、developmentなど）は`app.environment`でアクセスできます。

### カスタムサービス {#custom-services}

Vapor 3で`Service`プロトコルに準拠し、コンテナに登録されていたカスタムサービスは、ApplicationまたはRequestの拡張として表現できるようになりました。

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

このサービスは`make`の代わりに拡張を使用してアクセスできます。

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### カスタムプロバイダー {#custom-providers}

ほとんどのカスタムサービスは、前のセクションで示したように拡張を使用して実装できます。ただし、一部の高度なプロバイダーは、アプリケーションのライフサイクルにフックしたり、保存されたプロパティを使用したりする必要があるかもしれません。

Applicationの新しい`Lifecycle`ヘルパーを使用してライフサイクルハンドラーを登録できます。

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Applicationに値を保存するには、新しい`Storage`ヘルパーを使用できます。

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

`app.storage`へのアクセスは、簡潔なAPIを作成するために設定可能な計算プロパティでラップできます。

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4はSwiftNIOの非同期APIを直接公開するようになり、`map`や`flatMap`のようなメソッドをオーバーロードしたり、`EventLoopFuture`のようなタイプをエイリアスしたりしようとしなくなりました。Vapor 3は、SwiftNIOが存在する前にリリースされた初期ベータバージョンとの下位互換性のためにオーバーロードとエイリアスを提供していました。これらは、他のSwiftNIO互換パッケージとの混乱を減らし、SwiftNIOのベストプラクティスの推奨事項により良く従うために削除されました。

### 非同期の名前変更 {#async-naming-changes}

最も明白な変更は、`EventLoopFuture`の`Future`タイプエイリアスが削除されたことです。これは検索と置換で簡単に修正できます。

さらに、NIOはVapor 3が追加した`to:`ラベルをサポートしていません。Swift 5.2の改善された型推論により、`to:`はそれほど必要ではなくなりました。

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

`newPromise`のように`new`で始まるメソッドは、Swiftスタイルに合わせて`make`に変更されました。

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap`は利用できなくなりましたが、NIOの`mapError`や`flatMapErrorThrowing`のようなメソッドが代わりに機能します。

複数のフューチャーを組み合わせるためのVapor 3のグローバル`flatMap`メソッドは利用できなくなりました。これは、NIOの`and`メソッドを使用して多くのフューチャーを組み合わせることで置き換えることができます。

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // aとbで何かを行う。
}
```

### ByteBuffer

以前は`Data`を使用していた多くのメソッドとプロパティは、NIOの`ByteBuffer`を使用するようになりました。このタイプは、より強力で高性能なバイトストレージタイプです。APIの詳細については、[SwiftNIOのByteBufferドキュメント](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer)を参照してください。

`ByteBuffer`を`Data`に戻すには：

```swift
Data(buffer.readableBytesView)
```

### map / flatMapのスロー {#throwing-map-flatmap}

最も難しい変更は、`map`と`flatMap`がもはやスローできないことです。`map`には（やや紛らわしいことに）`flatMapThrowing`という名前のスローバージョンがあります。しかし、`flatMap`にはスローする対応物がありません。これにより、いくつかの非同期コードの再構築が必要になる場合があります。

スローしないmapは引き続き正常に動作するはずです。

```swift
// スローしないmap。
futureA.map { a in
    return b
}
```

スローするmapは`flatMapThrowing`に名前を変更する必要があります。

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

スローしないflat-mapは引き続き正常に動作するはずです。

```swift
// スローしないflatMap。
futureA.flatMap { a in
    return futureB
}
```

flat-map内でエラーをスローする代わりに、フューチャーエラーを返します。エラーが他のスローメソッドから発生する場合、エラーはdo / catchでキャッチしてフューチャーとして返すことができます。

```swift
// キャッチしたエラーをフューチャーとして返す。
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

スローメソッド呼び出しは、`flatMapThrowing`にリファクタリングし、タプルを使用してチェーンすることもできます。

```swift
// タプルチェーンを使用してflatMapThrowingにリファクタリングされたスローメソッド。
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // resultはdoSomethingの値です。
    return futureB
}
```

## ルーティング {#routing}

ルートはApplicationに直接登録されるようになりました。

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

これは、ルーターをサービスに登録する必要がなくなったことを意味します。`routes`メソッドにアプリケーションを渡してルートを追加し始めるだけです。`RoutesBuilder`で利用可能なすべてのメソッドは`Application`で利用可能です。

### 同期コンテンツ {#synchronous-content}

リクエストコンテンツのデコードは同期的になりました。

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

この動作は、`.stream`ボディコレクション戦略を使用してルートを登録することでオーバーライドできます。

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // リクエストボディは非同期になりました。
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### カンマ区切りのパス {#comma-separated-paths}

一貫性のため、パスはカンマ区切りである必要があり、`/`を含んではいけません。

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // リクエストを処理。
}
```

### ルートパラメータ {#route-parameters}

`Parameter`プロトコルは、明示的に名前付きパラメータを支持して削除されました。これにより、重複するパラメータの問題と、ミドルウェアとルートハンドラーでのパラメータの順不同の取得が防止されます。

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

モデルを使用したルートパラメータの使用については、Fluentセクションで説明します。

## ミドルウェア {#middleware}

`MiddlewareConfig`は`MiddlewareConfiguration`に名前が変更され、Applicationのプロパティになりました。`app.middleware`を使用してアプリにミドルウェアを追加できます。

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

ミドルウェアはタイプ名で登録できなくなりました。登録する前にミドルウェアを初期化してください。

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

すべてのデフォルトミドルウェアを削除するには、`app.middleware`を空の設定に設定します：

```swift
app.middleware = .init()
```

## Fluent

FluentのAPIはデータベースに依存しなくなりました。`Fluent`だけをインポートできます。

```diff
- import FluentMySQL
+ import Fluent
```

### モデル {#models}

すべてのモデルは`Model`プロトコルを使用し、クラスである必要があります。

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

すべてのフィールドは`@Field`または`@OptionalField`プロパティラッパーを使用して宣言されます。

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

モデルのIDは`@ID`プロパティラッパーを使用して定義する必要があります。

```diff
+ @ID(key: .id)
var id: UUID?
```

カスタムキーまたはタイプの識別子を使用するモデルは`@ID(custom:)`を使用する必要があります。

すべてのモデルは、テーブルまたはコレクション名を静的に定義する必要があります。

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

すべてのモデルには空のイニシャライザが必要です。すべてのプロパティがプロパティラッパーを使用するため、これは空にできます。

```diff
final class Planet: Model {
+   init() { }
}
```

モデルの`save`、`update`、`create`は、モデルインスタンスを返さなくなりました。

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

モデルはルートパスコンポーネントとして使用できなくなりました。代わりに`find`と`req.parameters.get`を使用してください。

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID`は`Model.IDValue`に名前が変更されました。

モデルのタイムスタンプは`@Timestamp`プロパティラッパーを使用して宣言されるようになりました。

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### リレーション {#relations}

リレーションはプロパティラッパーを使用して定義されるようになりました。

親リレーションは`@Parent`プロパティラッパーを使用し、フィールドプロパティを内部に含みます。`@Parent`に渡されるキーは、データベース内の識別子を格納するフィールドの名前である必要があります。

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

子リレーションは、関連する`@Parent`へのキーパスを持つ`@Children`プロパティラッパーを使用します。

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

兄弟リレーションは、ピボットモデルへのキーパスを持つ`@Siblings`プロパティラッパーを使用します。

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

ピボットは、2つの`@Parent`リレーションと0個以上の追加フィールドを持つ`Model`に準拠する通常のモデルになりました。

### クエリ {#query}

データベースコンテキストは、ルートハンドラー内で`req.db`を介してアクセスされるようになりました。

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable`は`Database`に名前が変更されました。

フィールドへのキーパスは、フィールド値の代わりにプロパティラッパーを指定するために`$`で始まるようになりました。

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### マイグレーション {#migrations}

モデルはリフレクションベースの自動マイグレーションをサポートしなくなりました。すべてのマイグレーションは手動で記述する必要があります。

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

マイグレーションは文字列型になり、モデルから切り離されて`Migration`プロトコルを使用するようになりました。

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

`prepare`および`revert`メソッドは静的ではなくなりました。

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

スキーマビルダーの作成は、`Database`のインスタンスメソッドを介して行われます。

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // ビルダーを使用。
- }
+ var builder = database.schema("Galaxy")
+ // ビルダーを使用。
```

`create`、`update`、および`delete`メソッドは、クエリビルダーと同様にスキーマビルダーで呼び出されるようになりました。

フィールド定義は文字列型になり、次のパターンに従います：

```swift
field(<name>, <type>, <constraints>)
```

以下の例を参照してください。

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

スキーマビルドはクエリビルダーのようにチェーンできるようになりました。

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent設定 {#fluent-configuration}

`DatabasesConfig`は`app.databases`に置き換えられました。

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig`は`app.migrations`に置き換えられました。

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### リポジトリ {#repositories}

Vapor 4でのサービスの動作方法が変更されたため、データベースリポジトリの実装方法も変更されました。`UserRepository`のようなプロトコルは引き続き必要ですが、そのプロトコルに準拠する`final class`を作成する代わりに、`struct`を作成する必要があります。

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

また、Vapor 4にはもはや存在しないため、`ServiceType`への準拠も削除する必要があります。
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

代わりに`UserRepositoryFactory`を作成する必要があります：
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
このファクトリーは`Request`に対して`UserRepository`を返す責任があります。

次のステップは、ファクトリーを指定するために`Application`に拡張を追加することです：
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

`Request`内で実際のリポジトリを使用するには、`Request`にこの拡張を追加します：
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

最後のステップは、`configure.swift`内でファクトリーを指定することです
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

これで、ルートハンドラー内で`req.users.all()`を使用してリポジトリにアクセスでき、テスト内でファクトリーを簡単に置き換えることができます。
テスト内でモックされたリポジトリを使用したい場合は、まず`TestUserRepository`を作成します
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

このモックされたリポジトリをテスト内で次のように使用できます：
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```