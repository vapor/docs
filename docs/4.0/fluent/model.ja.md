# モデル {#models}

モデルは、データベースのテーブルやコレクションに格納されたデータを表現します。モデルは、コード化可能な値を格納する1つ以上のフィールドを持ちます。すべてのモデルには一意の識別子があります。プロパティラッパーは、識別子、フィールド、リレーションを示すために使用されます。

以下は、1つのフィールドを持つシンプルなモデルの例です。モデルは、制約、インデックス、外部キーなどのデータベーススキーマ全体を記述するものではないことに注意してください。スキーマは[マイグレーション](migration.md)で定義されます。モデルは、データベーススキーマに格納されているデータの表現に焦点を当てています。

```swift
final class Planet: Model {
    // テーブルまたはコレクションの名前
    static let schema = "planets"

    // このPlanetの一意の識別子
    @ID(key: .id)
    var id: UUID?

    // Planetの名前
    @Field(key: "name")
    var name: String

    // 新しい空のPlanetを作成
    init() { }

    // すべてのプロパティが設定された新しいPlanetを作成
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## スキーマ {#schema}

すべてのモデルには、静的なgetオンリーの`schema`プロパティが必要です。この文字列は、このモデルが表すテーブルまたはコレクションの名前を参照します。

```swift
final class Planet: Model {
    // テーブルまたはコレクションの名前
    static let schema = "planets"
}
```

このモデルをクエリする際、データは`"planets"`という名前のスキーマから取得され、格納されます。

!!! tip
    スキーマ名は通常、クラス名を複数形にして小文字にしたものです。

## 識別子 {#identifier}

すべてのモデルには、`@ID`プロパティラッパーを使用して定義された`id`プロパティが必要です。このフィールドは、モデルのインスタンスを一意に識別します。

```swift
final class Planet: Model {
    // このPlanetの一意の識別子
    @ID(key: .id)
    var id: UUID?
}
```

デフォルトでは、`@ID`プロパティは特別な`.id`キーを使用する必要があります。これは、基礎となるデータベースドライバーに適したキーに解決されます。SQLの場合は`"id"`、NoSQLの場合は`"_id"`です。

`@ID`は`UUID`型である必要があります。これは現在、すべてのデータベースドライバーでサポートされている唯一の識別子値です。Fluentは、モデルが作成されるときに新しいUUID識別子を自動的に生成します。

`@ID`は、保存されていないモデルにはまだ識別子がない可能性があるため、オプショナル値です。識別子を取得するか、エラーをスローするには、`requireID`を使用します。

```swift
let id = try planet.requireID()
```

### 存在確認 {#exists}

`@ID`には、モデルがデータベースに存在するかどうかを表す`exists`プロパティがあります。モデルを初期化すると、値は`false`です。モデルを保存した後、またはデータベースからモデルをフェッチしたときは、値は`true`になります。このプロパティは変更可能です。

```swift
if planet.$id.exists {
    // このモデルはデータベースに存在します
}
```

### カスタム識別子 {#custom-identifier}

Fluentは、`@ID(custom:)`オーバーロードを使用して、カスタム識別子キーと型をサポートします。

```swift
final class Planet: Model {
    // このPlanetの一意の識別子
    @ID(custom: "foo")
    var id: Int?
}
```

上記の例では、カスタムキー`"foo"`と識別子型`Int`を持つ`@ID`を使用しています。これは自動インクリメントのプライマリキーを使用するSQLデータベースと互換性がありますが、NoSQLとは互換性がありません。

カスタム`@ID`では、`generatedBy`パラメータを使用して識別子の生成方法を指定できます。

```swift
@ID(custom: "foo", generatedBy: .user)
```

`generatedBy`パラメータは以下のケースをサポートします：

|生成方法|説明|
|-|-|
|`.user`|新しいモデルを保存する前に`@ID`プロパティが設定されることが期待される|
|`.random`|`@ID`値型は`RandomGeneratable`に準拠する必要がある|
|`.database`|データベースが保存時に値を生成することが期待される|

`generatedBy`パラメータが省略された場合、Fluentは`@ID`値型に基づいて適切なケースを推測しようとします。例えば、`Int`は特に指定されない限り、デフォルトで`.database`生成になります。

## イニシャライザ {#initializer}

モデルには空のイニシャライザメソッドが必要です。

```swift
final class Planet: Model {
    // 新しい空のPlanetを作成
    init() { }
}
```

Fluentは、クエリによって返されたモデルを初期化するために、内部的にこのメソッドを必要とします。また、リフレクションにも使用されます。

すべてのプロパティを受け入れるコンビニエンスイニシャライザをモデルに追加することもできます。

```swift
final class Planet: Model {
    // すべてのプロパティが設定された新しいPlanetを作成
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

コンビニエンスイニシャライザを使用すると、将来モデルに新しいプロパティを追加しやすくなります。

## フィールド {#field}

モデルは、データを格納するために0個以上の`@Field`プロパティを持つことができます。

```swift
final class Planet: Model {
    // Planetの名前
    @Field(key: "name")
    var name: String
}
```

フィールドには、データベースキーを明示的に定義する必要があります。これはプロパティ名と同じである必要はありません。

!!! tip
    Fluentでは、データベースキーには`snake_case`を、プロパティ名には`camelCase`を使用することを推奨しています。

フィールド値は、`Codable`に準拠する任意の型にできます。ネストされた構造体や配列を`@Field`に格納することはサポートされていますが、フィルタリング操作は制限されます。代替案については[`@Group`](#group)を参照してください。

オプショナル値を含むフィールドには、`@OptionalField`を使用します。

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! warning
    現在の値を参照する`willSet`プロパティオブザーバー、または`oldValue`を参照する`didSet`プロパティオブザーバーを持つ非オプショナルフィールドは、致命的なエラーを引き起こします。

## リレーション {#relations}

モデルは、`@Parent`、`@Children`、`@Siblings`など、他のモデルを参照する0個以上のリレーションプロパティを持つことができます。リレーションの詳細については、[リレーション](relations.md)セクションを参照してください。

## タイムスタンプ {#timestamp}

`@Timestamp`は、`Foundation.Date`を格納する特別な種類の`@Field`です。タイムスタンプは、選択されたトリガーに応じてFluentによって自動的に設定されます。

```swift
final class Planet: Model {
    // このPlanetが作成されたとき
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // このPlanetが最後に更新されたとき
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp`は以下のトリガーをサポートします。

|トリガー|説明|
|-|-|
|`.create`|新しいモデルインスタンスがデータベースに保存されるときに設定される|
|`.update`|既存のモデルインスタンスがデータベースに保存されるときに設定される|
|`.delete`|モデルがデータベースから削除されるときに設定される。[論理削除](#soft-delete)を参照|

`@Timestamp`の日付値はオプショナルで、新しいモデルを初期化するときは`nil`に設定する必要があります。

### タイムスタンプフォーマット {#timestamp-format}

デフォルトでは、`@Timestamp`はデータベースドライバーに基づいた効率的な`datetime`エンコーディングを使用します。`format`パラメータを使用して、タイムスタンプがデータベースに格納される方法をカスタマイズできます。

```swift
// このモデルが最後に更新されたときを表す
// ISO 8601形式のタイムスタンプを格納
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

この`.iso8601`の例に関連するマイグレーションでは、`.string`形式でのストレージが必要になることに注意してください。

```swift
.field("updated_at", .string)
```

利用可能なタイムスタンプフォーマットを以下に示します。

|フォーマット|説明|型|
|-|-|-|
|`.default`|特定のデータベース用の効率的な`datetime`エンコーディングを使用|Date|
|`.iso8601`|[ISO 8601](https://en.wikipedia.org/wiki/ISO_8601)文字列。`withMilliseconds`パラメータをサポート|String|
|`.unix`|小数部を含むUnixエポックからの秒数|Double|

`timestamp`プロパティを使用して、生のタイムスタンプ値に直接アクセスできます。

```swift
// このISO 8601形式の@Timestampに
// タイムスタンプ値を手動で設定
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### 論理削除 {#soft-delete}

`.delete`トリガーを使用する`@Timestamp`をモデルに追加すると、論理削除が有効になります。

```swift
final class Planet: Model {
    // このPlanetが削除されたとき
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

論理削除されたモデルは削除後もデータベースに存在しますが、クエリでは返されません。

!!! tip
    削除時のタイムスタンプを将来の日付に手動で設定できます。これは有効期限として使用できます。

論理削除可能なモデルをデータベースから強制的に削除するには、`delete`の`force`パラメータを使用します。

```swift
// モデルが論理削除可能であっても
// データベースから削除する
model.delete(force: true, on: database)
```

論理削除されたモデルを復元するには、`restore`メソッドを使用します。

```swift
// 削除時のタイムスタンプをクリアして、
// このモデルがクエリで返されるようにする
model.restore(on: database)
```

クエリに論理削除されたモデルを含めるには、`withDeleted`を使用します。

```swift
// 論理削除されたものを含むすべての惑星を取得
Planet.query(on: database).withDeleted().all()
```

## Enum

`@Enum`は、文字列表現可能な型をネイティブデータベース列挙型として格納する特別な種類の`@Field`です。ネイティブデータベース列挙型は、データベースに型安全性の追加レイヤーを提供し、生の列挙型よりもパフォーマンスが向上する可能性があります。

```swift
// 動物の種類を表す文字列表現可能なCodable列挙型
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // 動物の種類をネイティブデータベース列挙型として格納
    @Enum(key: "type")
    var type: Animal
}
```

`RawValue`が`String`である`RawRepresentable`に準拠する型のみが`@Enum`と互換性があります。`String`バックの列挙型はデフォルトでこの要件を満たしています。

オプショナルの列挙型を格納するには、`@OptionalEnum`を使用します。

データベースは、マイグレーションを介して列挙型を処理する準備が必要です。詳細については[Enum](schema.md#enum)を参照してください。

### 生の列挙型 {#raw-enums}

`String`や`Int`などの`Codable`型でバックされた列挙型は、`@Field`に格納できます。データベースには生の値として格納されます。

## グループ {#group}

`@Group`を使用すると、ネストされたフィールドのグループをモデルの単一のプロパティとして格納できます。`@Field`に格納されたCodable構造体とは異なり、`@Group`のフィールドはクエリ可能です。Fluentは、`@Group`をデータベースにフラットな構造として格納することでこれを実現しています。

`@Group`を使用するには、まず`Fields`プロトコルを使用して格納したいネストされた構造を定義します。これは`Model`に非常に似ていますが、識別子やスキーマ名は必要ありません。ここでは、`@Field`、`@Enum`、さらには別の`@Group`など、`Model`がサポートする多くのプロパティを格納できます。

```swift
// 名前と動物の種類を持つペット
final class Pet: Fields {
    // ペットの名前
    @Field(key: "name")
    var name: String

    // ペットの種類
    @Field(key: "type")
    var type: String

    // 新しい空のPetを作成
    init() { }
}
```

フィールド定義を作成したら、それを`@Group`プロパティの値として使用できます。

```swift
final class User: Model {
    // ユーザーのネストされたペット
    @Group(key: "pet")
    var pet: Pet
}
```

`@Group`のフィールドはドット構文でアクセスできます。

```swift
let user: User = ...
print(user.pet.name) // String
```

プロパティラッパーのドット構文を使用して、通常どおりネストされたフィールドをクエリできます。

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

データベースでは、`@Group`は`_`で結合されたキーを持つフラットな構造として格納されます。以下は、`User`がデータベースでどのように見えるかの例です。

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

モデルはデフォルトで`Codable`に準拠しています。つまり、`Content`プロトコルへの準拠を追加することで、モデルをVaporの[コンテンツAPI](../basics/content.md)で使用できます。

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // すべての惑星の配列を返す
    try await Planet.query(on: req.db).all()
}
```

`Codable`にシリアライズ/デシリアライズする際、モデルプロパティはキーの代わりに変数名を使用します。リレーションはネストされた構造としてシリアライズされ、イーガーロードされたデータが含まれます。

!!! info
    ほぼすべてのケースで、APIレスポンスとリクエストボディにはモデルの代わりにDTOを使用することをお勧めします。詳細については[データ転送オブジェクト](#data-transfer-object)を参照してください。

### データ転送オブジェクト {#data-transfer-object}

モデルのデフォルトの`Codable`準拠により、簡単な使用とプロトタイピングが容易になります。ただし、これは基礎となるデータベース情報をAPIに公開します。これは通常、セキュリティの観点（ユーザーのパスワードハッシュなどの機密フィールドを返すのは良くない）と使いやすさの観点の両方から望ましくありません。APIを破壊せずにデータベーススキーマを変更したり、異なる形式でデータを受け入れたり返したり、APIからフィールドを追加または削除したりすることが困難になります。

ほとんどの場合、モデルの代わりにDTO（データ転送オブジェクト）を使用する必要があります（これはドメイン転送オブジェクトとも呼ばれます）。DTOは、エンコードまたはデコードしたいデータ構造を表す別個の`Codable`型です。これらはAPIをデータベーススキーマから分離し、アプリの公開APIを破壊することなくモデルに変更を加えたり、異なるバージョンを持ったり、クライアントにとってAPIをより使いやすくしたりできます。

次の例では、以下の`User`モデルを想定しています。

```swift
// 参照用の省略されたUserモデル
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

DTOの一般的な使用例の1つは、`PATCH`リクエストの実装です。これらのリクエストには、更新する必要があるフィールドの値のみが含まれています。必要なフィールドが不足している場合、そのようなリクエストから`Model`を直接デコードしようとすると失敗します。以下の例では、DTOを使用してリクエストデータをデコードし、モデルを更新しています。

```swift
// PATCH /users/:idリクエストの構造
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // リクエストデータをデコード
    let patch = try req.content.decode(PatchUser.self)
    // データベースから目的のユーザーを取得
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // 名が提供された場合、更新する
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // 新しい姓が提供された場合、更新する
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // ユーザーを保存して返す
    try await user.save(on: req.db)
    return user
}
```

DTOのもう1つの一般的な使用例は、APIレスポンスの形式をカスタマイズすることです。以下の例は、DTOを使用してレスポンスに計算フィールドを追加する方法を示しています。

```swift
// GET /usersレスポンスの構造
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // データベースからすべてのユーザーを取得
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // 各ユーザーをGET戻り値型に変換
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

もう1つの一般的な使用例は、親リレーションや子リレーションなどのリレーションを扱う場合です。`@Parent`リレーションを持つモデルを簡単にデコードするためのDTOの使用例については、[Parentドキュメント](relations.md##encoding-and-decoding-of-parents)を参照してください。

DTOの構造がモデルの`Codable`準拠と同じであっても、別の型として持つことで大規模なプロジェクトを整理できます。モデルのプロパティに変更を加える必要がある場合でも、アプリの公開APIを破壊する心配はありません。また、DTOをAPIの利用者と共有できる別のパッケージに配置し、VaporアプリでContent準拠を追加することも検討できます。

## エイリアス {#alias}

`ModelAlias`プロトコルを使用すると、クエリで複数回結合されるモデルを一意に識別できます。詳細については、[Join](query.md#join)を参照してください。

## Save

モデルをデータベースに保存するには、`save(on:)`メソッドを使用します。

```swift
planet.save(on: database)
```

このメソッドは、モデルがすでにデータベースに存在するかどうかに応じて、内部的に`create`または`update`を呼び出します。

### Create

新しいモデルをデータベースに保存するには、`create`メソッドを呼び出します。

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create`はモデルの配列でも利用可能です。これにより、すべてのモデルが単一のバッチ/クエリでデータベースに保存されます。

```swift
// バッチ作成の例
[earth, mars].create(on: database)
```

!!! warning
    `.database`ジェネレーター（通常は自動インクリメントの`Int`）を使用する[`@ID(custom:)`](#custom-identifier)を使用するモデルは、バッチ作成後に新しく作成された識別子にアクセスできません。識別子にアクセスする必要がある状況では、各モデルで`create`を呼び出してください。

モデルの配列を個別に作成するには、`map` + `flatten`を使用します。

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

`async`/`await`を使用している場合は、以下を使用できます：

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### Update

データベースから取得したモデルを保存するには、`update`メソッドを呼び出します。

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

モデルの配列を更新するには、`map` + `flatten`を使用します。

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TOOD
```

## クエリ {#query}

モデルは、クエリビルダーを返す静的メソッド`query(on:)`を公開します。

```swift
Planet.query(on: database).all()
```

クエリの詳細については、[クエリ](query.md)セクションを参照してください。

## Find

モデルには、識別子でモデルインスタンスを検索するための静的`find(_:on:)`メソッドがあります。

```swift
Planet.find(req.parameters.get("id"), on: database)
```

その識別子を持つモデルが見つからない場合、このメソッドは`nil`を返します。

## ライフサイクル {#lifecycle}

モデルミドルウェアを使用すると、モデルのライフサイクルイベントにフックできます。以下のライフサイクルイベントがサポートされています。

|メソッド|説明|
|-|-|
|`create`|モデルが作成される前に実行される|
|`update`|モデルが更新される前に実行される|
|`delete(force:)`|モデルが削除される前に実行される|
|`softDelete`|モデルが論理削除される前に実行される|
|`restore`|モデルが復元される前に実行される（論理削除の反対）|

モデルミドルウェアは、`ModelMiddleware`または`AsyncModelMiddleware`プロトコルを使用して宣言されます。すべてのライフサイクルメソッドにはデフォルトの実装があるため、必要なメソッドのみを実装する必要があります。各メソッドは、対象のモデル、データベースへの参照、チェーン内の次のアクションを受け入れます。ミドルウェアは、早期に返す、失敗したfutureを返す、または次のアクションを呼び出して通常どおり続行することを選択できます。

これらのメソッドを使用すると、特定のイベントが完了する前と後の両方でアクションを実行できます。イベント完了後のアクションの実行は、次のレスポンダーから返されたfutureをマップすることで実行できます。

```swift
// 名前を大文字化するミドルウェアの例
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // モデルは作成される前にここで変更できます
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // 惑星が作成されたら、ここのコードが実行されます
            print ("Planet \(model.name) was created")
        }
    }
}
```

または`async`/`await`を使用する場合：

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyAsyncModelResponder) async throws {
        // モデルは作成される前にここで変更できます
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // 惑星が作成されたら、ここのコードが実行されます
        print ("Planet \(model.name) was created")
    }
}
```

ミドルウェアを作成したら、`app.databases.middleware`を使用して有効にできます。

```swift
// モデルミドルウェアの設定例
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## データベース空間 {#database-space}

Fluentは、モデルの空間の設定をサポートしており、個々のFluentモデルをPostgreSQLスキーマ、MySQLデータベース、および複数の添付されたSQLiteデータベース間で分割できます。MongoDBは現時点では空間をサポートしていません。モデルをデフォルト以外の空間に配置するには、モデルに新しい静的プロパティを追加します：

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

Fluentは、すべてのデータベースクエリを構築する際にこれを使用します。