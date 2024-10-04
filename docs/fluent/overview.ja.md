# Fluent

Fluent は、Swift 用の [ORM](https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E9%96%A2%E4%BF%82%E3%83%9E%E3%83%83%E3%83%94%E3%83%B3%E3%82%B0) フレームワークです。Swift の強力な型システムを活用して、データベースとのインターフェースを簡単に使用できるようにします。Fluent の使用は、データベース内のデータ構造を表すモデルタイプの作成に中心を置いています。これらのモデルを使用して、生のクエリを書く代わりに、作成、読み取り、更新、および削除操作を行います。

## 設定 {#configuration}

`vapor new` を使用してプロジェクトを作成する際に、Fluent を含めるかどうかを尋ねられたら「yes」と答え、使用するデータベースドライバーを選択してください。これにより、新しいプロジェクトに依存関係が自動的に追加され、例として設定コードも含まれます。

### 既存プロジェクトへの追加 {#existing-project}

既存のプロジェクトに Fluent を追加したい場合は、[パッケージ](../getting-started/spm.md) に 2 つの依存関係を追加する必要があります：

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- 使用したいデータベースの Fluent ドライバー 1 つ以上

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

依存関係を追加したら、`configure.swift` で `app.databases` を使用してデータベースを設定します。

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

以下に Fluent ドライバーごとの、より具体的な設定手順を記しています。

### Drivers

Fluent には現在、公式にサポートされているドライバーが 4 つあります。公式およびサードパーティの Fluent データベースドライバーの完全なリストについては、GitHub で [`fluent-driver`](https://github.com/topics/fluent-driver) タグを検索してください。

#### PostgreSQL

PostgreSQL は、オープンソースで、標準 SQL に準拠したデータベースです。ほとんどのクラウドホスティングプロバイダーで簡単に設定できます。これは、Fluent の **推奨** データベースドライバーです。

PostgreSQL を使用するには、次の依存関係をパッケージに追加します。

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

依存関係を追加したら、`configure.swift` で Fluent を使用してデータベースのクレデンシャル情報を設定します。

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

データベース接続文字列からクレデンシャル情報を解析することもできます。

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite は、オープンソースの組み込み型 SQL データベースです。そのシンプルさから、プロトタイピングやテストに最適です。

SQLite を使用するには、次の依存関係をパッケージに追加します。

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

依存関係を追加したら、`configure.swift` で `app.databases` を使用してデータベースを設定します。

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

SQLite を設定して、データベースを一時的にメモリに保存することもできます。

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

メモリ内データベースを使用する場合は、`--auto-migrate` を使用して Fluent を自動的にマイグレートするよう設定するか、マイグレーションを追加した後に `app.autoMigrate()` を実行してください。

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip
    SQLite の設定では、作成されたすべての接続で外部キー制約が自動的に有効になりますが、データベース内の外部キー設定は変更されません。データベースで直接レコードを削除すると、外部キー制約やトリガーに違反する可能性があります。

#### MySQL

MySQL は、人気のあるオープンソースの SQL データベースです。多くのクラウドホスティングプロバイダーで利用可能です。このドライバーは MariaDB もサポートしています。

MySQL を使用するには、次の依存関係をパッケージに追加します。

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

依存関係を追加したら、`configure.swift` で `app.databases` を使用してデータベースのクレデンシャル情報を設定します。

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

データベース接続文字列からクレデンシャル情報を解析することもできます。

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

SSL 証明書を使用せずにローカル接続を構成する場合は、証明書の検証を無効にする必要があります。たとえば、Docker 内の MySQL 8 データベースに接続する場合などです。

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning
    本番環境では証明書の検証を無効にしないでください。検証に使用する証明書を `TLSConfiguration` に提供する必要があります。

#### MongoDB

MongoDB は、プログラマー向けに設計された人気のあるスキーマレス NoSQL データベースです。このドライバーは、バージョン 3.4 以降のすべてのクラウドホスティングプロバイダーおよびセルフホストインストールをサポートしています。

!!! note
    このドライバーは、コミュニティによって作成およびメンテナンスされている MongoDB クライアント [MongoKitten](https://github.com/OpenKitten/MongoKitten) によって動作しています。MongoDB は、公式クライアントの [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver) と、Vapor との統合 [mongodb-vapor](https://github.com/mongodb/mongodb-vapor) をメンテナンスしています。

MongoDB を使用するには、次の依存関係をパッケージに追加します。

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

依存関係を追加したら、`configure.swift` で `app.databases` を使用してデータベースのクレデンシャル情報を設定します。

接続するには、標準の MongoDB [接続 URI 形式](https://docs.mongodb.com/master/reference/connection-string/index.html) で接続文字列を渡します。

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Models

モデルは、データベース内の固定データ構造（テーブルやコレクションなど）を表します。モデルには、Codable な値を格納する 1 つ以上のフィールドがあります。すべてのモデルには一意の識別子もあります。識別子やフィールド、また後で説明するより複雑なマッピングを示すためにプロパティラッパーが使用されます。次の例では、Galaxy（銀河）を表すモデルを示しています。

```swift
final class Galaxy: Model {
    // テーブルまたはコレクションの名前
    static let schema = "galaxies"

    // Galaxy の一意の識別子
    @ID(key: .id)
    var id: UUID?

    // 銀河の名前
    @Field(key: "name")
    var name: String

    // 空の Galaxy インスタンスを作成
    init() { }

    // すべてのプロパティが設定された新しい Galaxy インスタンスを作成
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

新しいモデルを作成するには、`Model` に準拠する新しいクラスを作成します。

!!! tip
    パフォーマンスを向上させ、準拠要件を簡素化するために、モデルクラスを `final` としてマークすることをお勧めします。

`Model` プロトコルの最初の要件は、静的な文字列 `schema` です。

```swift
static let schema = "galaxies"
```

このプロパティは、モデルが対応するテーブルまたはコレクションを Fluent に示します。これは、データベース内に既に存在するテーブルであるか、[マイグレーション](#migrations) を使用して作成するテーブルです。スキーマは通常、`snake_case` であり、複数形です。

### Identifier

次の要件は、`id` という名前の識別子フィールドです。

```swift
@ID(key: .id)
var id: UUID?
```

このフィールドは、`@ID` プロパティラッパーを使用する必要があります。Fluent は、すべてのドライバーと互換性があるため、`UUID` と特別な `.id` フィールドキーを使用することをお勧めします。

キー名や型をカスタムしたい場合は、[`@ID(custom:)`](model.md#custom-identifier) オーバーロードを使用します。

### Fields

識別子を追加したら、追加情報を保存するためのフィールドを必要なだけ追加できます。この例では、追加のフィールドは銀河の名前だけです。

```swift
@Field(key: "name")
var name: String
```

単純なフィールドの場合、`@Field` プロパティラッパーが使用されます。`@ID` と同様に、`key` パラメータはデータベース内のフィールドの名前を指定します。これは、データベースのフィールド命名規則が Swift と異なる場合、たとえば `camelCase` ではなく `snake_case` を使用する場合に特に役立ちます。

次に、すべてのモデルには空の `init` が必要です。これにより、Fluent はモデルの新しいインスタンスを作成できます。

```swift
init() { }
```

最後に、モデルを便利に使用するためのすべてのプロパティを設定できる `init` を追加できます。

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

利便性用の `init` を使用しておくと、モデルに新たなプロパティを追加した場合に、`init` メソッドが変更されるとコンパイル時にエラーが発生することが特に便利です。

## Migrations

データベースが SQL データベースのように事前定義されたスキーマを使用している場合、モデルの準備をするためにマイグレーションが必要です。マイグレーションは、データベースにデータをシードするためにも役立ちます。マイグレーションを作成するには、`Migration` または `AsyncMigration` プロトコルに準拠する新しいタイプを定義します。次に、前述の `Galaxy` モデルに対応するマイグレーションを示します。

```swift
struct CreateGalaxy: AsyncMigration {
    // Galaxy モデルを格納するためのデータベースの準備
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // 必要に応じて、prepare メソッドで行った変更を元に戻します
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

`prepare` メソッドは、`Galaxy` モデルを格納するためにデータベースを準備するために使用されます。

### Schema

このメソッドでは、`database.schema(_:)` を使用して新しい `SchemaBuilder` を作成します。その後、ビルダーに 1 つ以上の `field` を追加して `create()` を呼び出してスキーマを作成します。

ビルダーに追加される各フィールドには、名前、タイプ、およびオプションの制約があります。

```swift
field(<name>, <type>, <optional constraints>)
```

Fluent の推奨デフォルトを使用して `@ID` プロパティを追加するための便利な `id()` メソッドがあります。

マイグレーションを revert すると、prepare メソッドで行った変更が元に戻されます。この場合、Galaxy のスキーマが削除されます。

マイグレーションが定義されたら、それを `configure.swift` で `app.migrations` に追加して Fluent に知らせる必要があります。

```swift
app.migrations.add(CreateGalaxy())
```

### Migrate

マイグレーションを実行するには、コマンドラインから `swift run App migrate` を実行するか、Xcode の App スキームに `migrate` を引数として追加します。


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Querying

モデルを正常に作成し、データベースをマイグレートしたので、最初のクエリを実行する準備が整いました。

### All

データベース内のすべての Galaxy の配列を返す次のルートを見てみましょう。

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

route 関数内で Galaxy を直接返すには、`Content` に準拠させます。

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` を使用して、モデルの新しいクエリビルダーを作成します。`req.db` はアプリケーションのデフォルトデータベースへの参照です。最後に、`all()` はデータベースに格納されているすべてのモデルを返します。

プロジェクトをコンパイルして実行し、`GET /galaxies` をリクエストすると、空の配列が返されるはずです。次に、新しい銀河を作成するためのルートを追加しましょう。

### Create


RESTful の慣例に従い、新しい銀河を作成するには、`POST /galaxies` エンドポイントを使用します。モデルは Codable なので、リクエストボディから Galaxy を直接デコードできます。

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    リクエストボディのデコードに関する詳細は、[コンテンツ &rarr; 概要](../basics/content.md) を参照してください。

モデルのインスタンスを取得したら、`create(on:)` を呼び出してモデルをデータベースに保存します。これにより、保存が完了したことを示す `EventLoopFuture<Void>` が返されます。保存が完了したら、`map` を使用して新しく作成されたモデルを返します。

`async`/`await` を使用している場合、次のようにコードを書くことができます。

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

この場合、async バージョンは何も返しませんが、保存が完了すると返されます。

プロジェクトをビルドして実行し、次のリクエストを送信します。

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

応答として、作成されたモデルが識別子付きで返されるはずです。

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

次に、再び `GET /galaxies` をクエリすると、新しく作成された Galaxy が配列の中に入って返されるはずです。


## Relations

銀河には星が欠かせません！ 次に、`Galaxy` と新しい `Star` モデルとの間に 1 対多のリレーションを追加することで、Fluent の強力なリレーショナル機能をざっくり見てみましょう。

```swift
final class Star: Model, Content {
    // テーブルまたはコレクションの名前
    static let schema = "stars"

    // この Star の一意の識別子
    @ID(key: .id)
    var id: UUID?

    // 星の名前
    @Field(key: "name")
    var name: String

    // この星が属する銀河への参照
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // 空の Star インスタンスを作成
    init() { }

    // すべてのプロパティが設定された新しい Star インスタンスを作成
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

新しい `Star` モデルは `Galaxy` と非常に似ていますが、新しいフィールドタイプ `@Parent` が追加されています。

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

親プロパティは、別のモデルの識別子を格納するフィールドです。参照を保持するモデルは「子」と呼ばれ、参照されるモデルは「親」と呼ばれます。この種類のリレーションは「一対多」とも呼ばれます。プロパティに渡される `key` パラメータは、データベース内で親のキーを格納するために使用されるフィールド名を指定します。

`init` メソッドでは、`$galaxy` を使用して親の識別子が設定されます。

```swift
self.$galaxy.id = galaxyID
```

親プロパティ名の前に `$` を付けることで、基になるプロパティラッパーにアクセスします。これは、実際の識別子の値を格納する内部の `@Field` にアクセスするために必要です。

!!! seealso
    プロパティラッパーに関する詳細については、Swift Evolution の提案 [[SE-0258] Property Wrappers](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) を参照してください。

次に、`Star` を処理するためのデータベースを準備するためにマイグレーションを作成します。


```swift
struct CreateStar: AsyncMigration {
    // Star モデルを格納するためのデータベースの準備
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // 必要に応じて、prepare メソッドで行った変更を元に戻します
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

これは、主に Galaxy のマイグレーションと同じですが、親の Galaxy の識別子を格納する追加のフィールドがある点が異なります。

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

このフィールドは、データベースにこのフィールドの値が「galaxies」スキーマの「id」フィールドを参照していることを伝えるオプションの制約を指定します。これは外部キーとも呼ばれ、データの整合性を確保するのに役立ちます。

マイグレーションが作成されたら、それを `CreateGalaxy` マイグレーションの後に `app.migrations` に追加します。

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

マイグレーションは順番に実行され、`CreateStar` が銀河のスキーマを参照しているため、順序が重要です。最後に、データベースを準備するために [マイグレーションを実行](#migrate) します。

新しく Star を作成するためのルートを追加します。

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

次の HTTP リクエストを使用して、先に作成した Galaxy を参照する新しい Star を作成します。

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

一意の識別子付きで新しく作成された Star が返されるはずです。

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

次に、Fluent の eager-loading 機能を活用して、`GET /galaxies` ルートで銀河の星も自動的に返す方法を見てみましょう。`Galaxy` モデルに次のプロパティを追加します。

```swift
// この Galaxy に存在するすべての Star
@Children(for: \.$galaxy)
var stars: [Star]
```

`@Children` プロパティラッパーは、`@Parent` の逆です。`for` 引数として子の `@Parent` フィールドへの key-path を受け取ります。その値は子モデルの配列で、ゼロ個以上の子モデルが存在する可能性があります。このリレーションを完了するために、Galaxy のマイグレーションに変更を加える必要はありません。

### Eager Load

リレーションが完了したら、クエリビルダーの `with` メソッドを使用して、銀河と星のリレーションを自動的にフェッチしてシリアライズできます。

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

`@Children` リレーションへの key-path が `with` に渡され、Fluent が自動的にこのリレーションをすべての結果モデルでロードするよう指示します。ビルドして実行し、再び `GET /galaxies` にリクエストを送信します。Star がレスポンスに自動的に含まれるようになっているはずです。

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Query Logging

Fluent ドライバーは、デバッグログレベルで生成された SQL を記録します。FluentPostgreSQL のような一部のドライバーでは、データベースを設定するときにこれを設定することができます。

ログレベルを設定するには、**configure.swift**（またはアプリケーションを設定する場所）で次のコードを追加します。

```swift
app.logger.logLevel = .debug
```

これにより、ログレベルがデバッグに設定されます。次にアプリをビルドして実行すると、Fluent が生成した SQL ステートメントがコンソールに記録されます。

## Next steps

おめでとうございます！ はじめてのモデルとマイグレーションを作成し、基本的な作成と読み取り操作を実行できました。これらの機能に関する詳細な情報については、Fluent ガイドの該当セクションを参照してください。