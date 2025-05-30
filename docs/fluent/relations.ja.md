# リレーション {#relations}

Fluent の [model API](model.md) は、リレーションを通じてモデル間の参照を作成・管理するのに役立ちます。3 つのタイプのリレーションがサポートされています：

- [Parent](#parent) / [Child](#optional-child)（1対1）
- [Parent](#parent) / [Children](#children)（1対多）
- [Siblings](#siblings)（多対多）

## Parent {#parent}

`@Parent` リレーションは、別のモデルの `@ID` プロパティへの参照を保存します。

```swift
final class Planet: Model {
    // parent リレーションの例
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` には `id` という名前の `@Field` が含まれており、リレーションの設定と更新に使用されます。

```swift
// parent リレーション id を設定
earth.$star.id = sun.id
```

例えば、`Planet` の初期化メソッドは次のようになります：

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

`key` パラメータは、親の識別子を保存するために使用するフィールドキーを定義します。`Star` が `UUID` 識別子を持つと仮定すると、この `@Parent` リレーションは以下の [field definition](schema.md#field) と互換性があります。

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

[`.references`](schema.md#field-constraint) 制約はオプションであることに注意してください。詳細については [schema](schema.md) を参照してください。

### Optional Parent {#optional-parent}

`@OptionalParent` リレーションは、別のモデルの `@ID` プロパティへのオプショナルな参照を保存します。`@Parent` と同様に動作しますが、リレーションが `nil` になることを許可します。

```swift
final class Planet: Model {
    // optional parent リレーションの例
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

フィールド定義は `@Parent` と似ていますが、`.required` 制約を省略する必要があります。

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Parent のエンコードとデコード {#encoding-and-decoding-of-parents}

`@Parent` リレーションを扱う際に注意すべき点の1つは、それらを送受信する方法です。例えば、JSON では、`Planet` モデルの `@Parent` は次のようになるかもしれません：

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

`star` プロパティが期待される ID ではなくオブジェクトであることに注意してください。モデルを HTTP ボディとして送信する場合、デコードが機能するためにはこれに一致する必要があります。この理由から、ネットワーク経由でモデルを送信する際には、モデルを表現するための DTO を使用することを強く推奨します。例えば：

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

そして、DTO をデコードしてモデルに変換できます：

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

同じことがクライアントにモデルを返す際にも適用されます。クライアントはネストされた構造を処理できる必要があるか、返す前にモデルを DTO に変換する必要があります。DTO の詳細については、[Model ドキュメント](model.md#data-transfer-object) を参照してください。

## Optional Child {#optional-child}

`@OptionalChild` プロパティは、2つのモデル間に1対1のリレーションを作成します。ルートモデルには値を保存しません。

```swift
final class Planet: Model {
    // optional child リレーションの例
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

`for` パラメータは、ルートモデルを参照する `@Parent` または `@OptionalParent` リレーションへのキーパスを受け取ります。

`create` メソッドを使用して、新しいモデルをこのリレーションに追加できます。

```swift
// リレーションに新しいモデルを追加する例
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

これにより、子モデルの親 ID が自動的に設定されます。

このリレーションは値を保存しないため、ルートモデルのデータベーススキーマエントリは必要ありません。

リレーションの1対1の性質は、親モデルを参照するカラムに `.unique` 制約を使用して、子モデルのスキーマで強制される必要があります。

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // unique 制約の例
    .unique(on: "planet_id")
    .create()
```
!!! warning
    クライアントのスキーマから親 ID フィールドのユニーク制約を省略すると、予測できない結果につながる可能性があります。
    一意性制約がない場合、子テーブルには任意の親に対して複数の子行が含まれる可能性があります。この場合、`@OptionalChild` プロパティは一度に1つの子にしかアクセスできず、どの子が読み込まれるかを制御する方法がありません。任意の親に対して複数の子行を保存する必要がある場合は、代わりに `@Children` を使用してください。

## Children {#children}

`@Children` プロパティは、2つのモデル間に1対多のリレーションを作成します。ルートモデルには値を保存しません。

```swift
final class Star: Model {
    // children リレーションの例
    @Children(for: \.$star)
    var planets: [Planet]
}
```

`for` パラメータは、ルートモデルを参照する `@Parent` または `@OptionalParent` リレーションへのキーパスを受け取ります。この場合、前の[例](#parent)の `@Parent` リレーションを参照しています。

`create` メソッドを使用して、新しいモデルをこのリレーションに追加できます。

```swift
// リレーションに新しいモデルを追加する例
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

これにより、子モデルの親 ID が自動的に設定されます。

このリレーションは値を保存しないため、データベーススキーマエントリは必要ありません。

## Siblings {#siblings}

`@Siblings` プロパティは、2つのモデル間に多対多のリレーションを作成します。これはピボットと呼ばれる第3のモデルを通じて行われます。

`Planet` と `Tag` 間の多対多リレーションの例を見てみましょう。

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// ピボットモデルの例
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

関連付けされる各モデルに対して少なくとも2つの `@Parent` リレーションを含むモデルは、ピボットとして使用できます。モデルは ID などの追加のプロパティを含むことができ、他の `@Parent` リレーションを含むこともできます。

ピボットモデルに [unique](schema.md#unique) 制約を追加すると、重複エントリを防ぐのに役立ちます。詳細については [schema](schema.md) を参照してください。

```swift
// 重複リレーションを禁止
.unique(on: "planet_id", "tag_id")
```

ピボットが作成されたら、`@Siblings` プロパティを使用してリレーションを作成します。

```swift
final class Planet: Model {
    // siblings リレーションの例
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

`@Siblings` プロパティには3つのパラメータが必要です：

- `through`: ピボットモデルの型
- `from`: ピボットからルートモデルを参照する親リレーションへのキーパス
- `to`: ピボットから関連モデルを参照する親リレーションへのキーパス

関連モデルの逆 `@Siblings` プロパティがリレーションを完成させます。

```swift
final class Tag: Model {
    // siblings リレーションの例
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings の追加 {#siblings-attach}

`@Siblings` プロパティには、リレーションにモデルを追加または削除するメソッドがあります。

`attach()` メソッドを使用して、単一のモデルまたはモデルの配列をリレーションに追加します。ピボットモデルは必要に応じて自動的に作成および保存されます。作成された各ピボットの追加プロパティを設定するためのコールバッククロージャを指定できます：

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// モデルをリレーションに追加
try await earth.$tags.attach(inhabited, on: database)
// リレーションを確立する際にピボット属性を設定
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// 複数のモデルを属性とともにリレーションに追加
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

単一のモデルを追加する場合、`method` パラメータを使用して、保存前にリレーションをチェックするかどうかを選択できます。

```swift
// リレーションがまだ存在しない場合のみ追加
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

`detach` メソッドを使用して、リレーションからモデルを削除します。これにより、対応するピボットモデルが削除されます。

```swift
// リレーションからモデルを削除
try await earth.$tags.detach(inhabited, on: database)
```

`isAttached` メソッドを使用して、モデルが関連付けられているかどうかを確認できます。

```swift
// モデルが関連付けられているかチェック
earth.$tags.isAttached(to: inhabited)
```

## Get {#get}

`get(on:)` メソッドを使用して、リレーションの値を取得します。

```swift
// 太陽のすべての惑星を取得
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// または

let planets = try await sun.$planets.get(on: database)
print(planets)
```

`reload` パラメータを使用して、すでに読み込まれている場合にリレーションをデータベースから再取得するかどうかを選択します。

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query {#query}

リレーションで `query(on:)` メソッドを使用して、関連モデルのクエリビルダーを作成します。

```swift
// M で始まる名前を持つ太陽のすべての惑星を取得
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

詳細については [query](query.md) を参照してください。

## Eager Loading {#eager-loading}

Fluent のクエリビルダーを使用すると、モデルがデータベースから取得されるときにリレーションを事前に読み込むことができます。これは eager loading と呼ばれ、最初に [`get`](#get) を呼び出す必要なく、リレーションに同期的にアクセスできるようになります。

リレーションを eager load するには、クエリビルダーの `with` メソッドにリレーションへのキーパスを渡します。

```swift
// eager loading の例
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` は eager load されているため
        // ここで同期的にアクセス可能
        print(planet.star.name)
    }
}

// または

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` は eager load されているため
    // ここで同期的にアクセス可能
    print(planet.star.name)
}
```

上記の例では、`star` という名前の [`@Parent`](#parent) リレーションへのキーパスが `with` に渡されています。これにより、すべての惑星が読み込まれた後、クエリビルダーは関連するすべての星を取得するための追加のクエリを実行します。その後、星は `@Parent` プロパティを介して同期的にアクセスできるようになります。

eager load される各リレーションは、返されるモデルの数に関係なく、追加のクエリを1つだけ必要とします。Eager loading は、クエリビルダーの `all` と `first` メソッドでのみ可能です。

### ネストされた Eager Load {#nested-eager-load}

クエリビルダーの `with` メソッドを使用すると、クエリ対象のモデルのリレーションを eager load できます。ただし、関連モデルのリレーションも eager load できます。

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` は eager load されているため
    // ここで同期的にアクセス可能
    print(planet.star.galaxy.name)
}
```

`with` メソッドは、2番目のパラメータとしてオプションのクロージャを受け取ります。このクロージャは、選択されたリレーションの eager load ビルダーを受け取ります。eager loading のネストの深さに制限はありません。

## Lazy Eager Loading {#lazy-eager-loading}

親モデルをすでに取得していて、そのリレーションの1つを読み込みたい場合は、その目的で `get(reload:on:)` メソッドを使用できます。これにより、関連モデルがデータベース（または利用可能な場合はキャッシュ）から取得され、ローカルプロパティとしてアクセスできるようになります。

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// または

try await planet.$star.get(on: database)
print(planet.star.name)
```

受け取るデータがキャッシュから取得されないようにしたい場合は、`reload:` パラメータを使用します。

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

リレーションが読み込まれているかどうかを確認するには、`value` プロパティを使用します。

```swift
if planet.$star.value != nil {
    // リレーションが読み込まれている
    print(planet.star.name)
} else {
    // リレーションが読み込まれていない
    // planet.star にアクセスしようとすると失敗する
}
```

関連モデルがすでに変数にある場合は、上記の `value` プロパティを使用してリレーションを手動で設定できます。

```swift
planet.$star.value = star
```

これにより、追加のデータベースクエリなしで、eager load または lazy load されたかのように関連モデルが親に添付されます。