# クエリ {#query}

Fluentのクエリ APIを使用すると、データベースからモデルの作成、読み取り、更新、削除を行うことができます。結果のフィルタリング、結合、チャンク処理、集約などをサポートしています。

```swift
// Fluentのクエリ APIの例
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

クエリビルダーは単一のモデルタイプに紐付けられており、静的な[`query`](model.md#query)メソッドを使用して作成できます。また、データベースオブジェクトの`query`メソッドにモデルタイプを渡すことでも作成できます。

```swift
// こちらもクエリビルダーを作成します
database.query(Planet.self)
```

!!! note
    クエリを含むファイルで`import Fluent`を行う必要があります。これにより、コンパイラがFluentのヘルパー関数を認識できるようになります。

## All {#all}

`all()`メソッドはモデルの配列を返します。

```swift
// すべての惑星を取得
let planets = try await Planet.query(on: database).all()
```

`all`メソッドは、結果セットから単一のフィールドのみを取得することもサポートしています。

```swift
// すべての惑星名を取得
let names = try await Planet.query(on: database).all(\.$name)
```

### First {#first}

`first()`メソッドは、単一のオプショナルなモデルを返します。クエリが複数のモデルを返す場合、最初のものだけが返されます。クエリ結果がない場合は、`nil`が返されます。

```swift
// Earthという名前の最初の惑星を取得
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    `EventLoopFuture`を使用している場合、このメソッドは[`unwrap(or:)`](../basics/errors.md#abort)と組み合わせて、非オプショナルなモデルを返すか、エラーをスローすることができます。

## フィルター {#filter}

`filter`メソッドを使用すると、結果セットに含まれるモデルを制限できます。このメソッドにはいくつかのオーバーロードがあります。

### 値フィルター {#value-filter}

最もよく使用される`filter`メソッドは、値を含む演算子式を受け入れます。

```swift
// フィールド値フィルタリングの例
Planet.query(on: database).filter(\.$type == .gasGiant)
```

これらの演算子式は、左側にフィールドのキーパスを、右側に値を受け取ります。提供される値はフィールドの期待される値型と一致する必要があり、結果のクエリにバインドされます。フィルター式は強く型付けされているため、先頭ドット構文を使用できます。

以下は、サポートされているすべての値演算子のリストです。

|演算子|説明|
|-|-|
|`==`|等しい|
|`!=`|等しくない|
|`>=`|以上|
|`>`|より大きい|
|`<`|より小さい|
|`<=`|以下|

### フィールドフィルター {#field-filter}

`filter`メソッドは、2つのフィールドの比較をサポートしています。

```swift
// 名と姓が同じすべてのユーザー
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

フィールドフィルターは[値フィルター](#value-filter)と同じ演算子をサポートしています。

### サブセットフィルター {#subset-filter}

`filter`メソッドは、フィールドの値が指定された値のセットに存在するかどうかをチェックすることをサポートしています。

```swift
// ガス巨星または小岩石型のいずれかのタイプを持つすべての惑星
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

提供される値のセットは、`Element`型がフィールドの値型と一致する任意のSwiftの`Collection`にすることができます。

以下は、サポートされているすべてのサブセット演算子のリストです。

|演算子|説明|
|-|-|
|`~~`|セット内の値|
|`!~`|セット内にない値|

### 含有フィルター {#contains-filter}

`filter`メソッドは、文字列フィールドの値が指定された部分文字列を含むかどうかをチェックすることをサポートしています。

```swift
// 名前がMで始まるすべての惑星
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

これらの演算子は、文字列値を持つフィールドでのみ使用できます。

以下は、サポートされているすべての含有演算子のリストです。

|演算子|説明|
|-|-|
|`~~`|部分文字列を含む|
|`!~`|部分文字列を含まない|
|`=~`|プレフィックスに一致|
|`!=~`|プレフィックスに一致しない|
|`~=`|サフィックスに一致|
|`!~=`|サフィックスに一致しない|

### グループ {#group}

デフォルトでは、クエリに追加されたすべてのフィルターが一致する必要があります。クエリビルダーは、1つのフィルターのみが一致する必要があるフィルターのグループを作成することをサポートしています。

```swift
// 名前がEarthまたはMarsのすべての惑星
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

`group`メソッドは、`and`または`or`ロジックによるフィルターの組み合わせをサポートしています。これらのグループは無限にネストできます。トップレベルのフィルターは`and`グループ内にあると考えることができます。

## 集約 {#aggregate}

クエリビルダーは、カウントや平均などの値のセットに対する計算を実行するためのいくつかのメソッドをサポートしています。

```swift
// データベース内の惑星数
Planet.query(on: database).count()
```

`count`以外のすべての集約メソッドには、フィールドへのキーパスを渡す必要があります。

```swift
// アルファベット順で最も低い名前
Planet.query(on: database).min(\.$name)
```

以下は、利用可能なすべての集約メソッドのリストです。

|集約|説明|
|-|-|
|`count`|結果数|
|`sum`|結果値の合計|
|`average`|結果値の平均|
|`min`|最小結果値|
|`max`|最大結果値|

`count`を除くすべての集約メソッドは、結果としてフィールドの値型を返します。`count`は常に整数を返します。

## チャンク {#chunk}

クエリビルダーは、結果セットを別々のチャンクとして返すことをサポートしています。これにより、大規模なデータベース読み取りを処理する際のメモリ使用量を制御できます。

```swift
// 一度に最大64個ずつ、すべての惑星をチャンクで取得
Planet.query(on: self.database).chunk(max: 64) { planets in
    // 惑星のチャンクを処理
}
```

提供されたクロージャは、結果の総数に応じて0回以上呼び出されます。返される各アイテムは、モデルまたはデータベースエントリのデコードを試みて返されたエラーのいずれかを含む`Result`です。

## フィールド {#field}

デフォルトでは、モデルのすべてのフィールドがクエリによってデータベースから読み取られます。`field`メソッドを使用して、モデルのフィールドのサブセットのみを選択できます。

```swift
// 惑星のidとnameフィールドのみを選択
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

クエリ中に選択されなかったモデルフィールドは、初期化されていない状態になります。初期化されていないフィールドに直接アクセスしようとすると、致命的なエラーが発生します。モデルのフィールド値が設定されているかどうかを確認するには、`value`プロパティを使用します。

```swift
if let name = planet.$name.value {
    // Nameが取得されました
} else {
    // Nameは取得されませんでした
    // `planet.name`へのアクセスは失敗します
}
```

## ユニーク {#unique}

クエリビルダーの`unique`メソッドは、一意の結果（重複なし）のみが返されるようにします。

```swift
// すべての一意のユーザーの名を返します
User.query(on: database).unique().all(\.$firstName)
```

`unique`は、`all`で単一のフィールドを取得する場合に特に便利です。ただし、[`field`](#field)メソッドを使用して複数のフィールドを選択することもできます。モデル識別子は常に一意であるため、`unique`を使用する場合は選択を避けるべきです。

## 範囲 {#range}

クエリビルダーの`range`メソッドを使用すると、Swift範囲を使用して結果のサブセットを選択できます。

```swift
// 最初の5つの惑星を取得
Planet.query(on: self.database)
    .range(..<5)
```

範囲値は、ゼロから始まる符号なし整数です。[Swift範囲](https://developer.apple.com/documentation/swift/range)の詳細について学びましょう。

```swift
// 最初の2つの結果をスキップ
.range(2...)
```

## 結合 {#join}

クエリビルダーの`join`メソッドを使用すると、結果セットに別のモデルのフィールドを含めることができます。クエリに複数のモデルを結合できます。

```swift
// Sunという名前の星を持つすべての惑星を取得
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

`on`パラメータは、2つのフィールド間の等価式を受け入れます。フィールドの1つは現在の結果セットに既に存在している必要があります。もう1つのフィールドは、結合されるモデルに存在する必要があります。これらのフィールドは同じ値型を持つ必要があります。

`filter`や`sort`などのほとんどのクエリビルダーメソッドは、結合されたモデルをサポートしています。メソッドが結合されたモデルをサポートしている場合、最初のパラメータとして結合されたモデルタイプを受け入れます。

```swift
// Starモデルの結合されたフィールド「name」でソート
.sort(Star.self, \.$name)
```

結合を使用するクエリは、依然としてベースモデルの配列を返します。結合されたモデルにアクセスするには、`joined`メソッドを使用します。

```swift
// クエリ結果から結合されたモデルへのアクセス
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### モデルエイリアス {#model-alias}

モデルエイリアスを使用すると、同じモデルをクエリに複数回結合できます。モデルエイリアスを宣言するには、`ModelAlias`に準拠する1つ以上の型を作成します。

```swift
// モデルエイリアスの例
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

これらの型は、`model`プロパティを介してエイリアスされるモデルを参照します。作成されると、クエリビルダーで通常のモデルのようにモデルエイリアスを使用できます。

```swift
// ホームチームの名前がVaporで、
// アウェイチームの名前でソートされたすべての試合を取得
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

すべてのモデルフィールドは、`@dynamicMemberLookup`を介してモデルエイリアスタイプを通じてアクセスできます。

```swift
// 結果から結合されたモデルにアクセス
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## 更新 {#update}

クエリビルダーは、`update`メソッドを使用して一度に複数のモデルを更新することをサポートしています。

```swift
// 「Pluto」という名前のすべての惑星を更新
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update`は`set`、`filter`、`range`メソッドをサポートしています。

## 削除 {#delete}

クエリビルダーは、`delete`メソッドを使用して一度に複数のモデルを削除することをサポートしています。

```swift
// 「Vulcan」という名前のすべての惑星を削除
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete`は`filter`メソッドをサポートしています。

## ページネーション {#paginate}

Fluentのクエリ APIは、`paginate`メソッドを使用した自動結果ページネーションをサポートしています。

```swift
// リクエストベースのページネーションの例
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

`paginate(for:)`メソッドは、リクエストURIで利用可能な`page`と`per`パラメータを使用して、目的の結果セットを返します。現在のページと結果の総数に関するメタデータは、`metadata`キーに含まれます。

```http
GET /planets?page=2&per=5 HTTP/1.1
```

上記のリクエストは、以下のような構造のレスポンスを生成します。

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

ページ番号は`1`から始まります。手動でページリクエストを作成することもできます。

```swift
// 手動ページネーションの例
.paginate(PageRequest(page: 1, per: 2))
```

## ソート {#sort}

クエリ結果は、`sort`メソッドを使用してフィールド値でソートできます。

```swift
// 名前でソートされた惑星を取得
Planet.query(on: database).sort(\.$name)
```

同点の場合のフォールバックとして、追加のソートを追加できます。フォールバックは、クエリビルダーに追加された順序で使用されます。

```swift
// 名前でソートされたユーザーを取得。2人のユーザーが同じ名前の場合、年齢でソート
User.query(on: database).sort(\.$name).sort(\.$age)
```