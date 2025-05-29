# スキーマ {#schema}

Fluentのスキーマ APIを使用すると、データベーススキーマをプログラム的に作成および更新できます。[モデル](model.md)での使用に備えてデータベースを準備するために、[マイグレーション](migration.md)と組み合わせて使用されることがよくあります。

```swift
// FluentのスキーマAPIの例
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

`SchemaBuilder`を作成するには、データベースで`schema`メソッドを使用します。影響を与えたいテーブルまたはコレクションの名前を渡します。モデルのスキーマを編集する場合は、この名前がモデルの[`schema`](model.md#schema)と一致することを確認してください。

## アクション {#actions}

スキーマAPIは、スキーマの作成、更新、削除をサポートしています。各アクションは、APIで利用可能なメソッドのサブセットをサポートしています。

### 作成 {#create}

`create()`を呼び出すと、データベースに新しいテーブルまたはコレクションが作成されます。新しいフィールドと制約を定義するためのすべてのメソッドがサポートされています。更新または削除のためのメソッドは無視されます。

```swift
// スキーマ作成の例
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

選択した名前のテーブルまたはコレクションがすでに存在する場合、エラーがスローされます。これを無視するには、`.ignoreExisting()`を使用します。

### 更新 {#update}

`update()`を呼び出すと、データベース内の既存のテーブルまたはコレクションが更新されます。フィールドと制約の作成、更新、削除のためのすべてのメソッドがサポートされています。

```swift
// スキーマ更新の例
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### 削除 {#delete}

`delete()`を呼び出すと、データベースから既存のテーブルまたはコレクションが削除されます。追加のメソッドはサポートされていません。

```swift
// スキーマ削除の例
database.schema("planets").delete()
```

## フィールド {#field}

スキーマの作成または更新時にフィールドを追加できます。

```swift
// 新しいフィールドを追加
.field("name", .string, .required)
```

最初のパラメータはフィールドの名前です。これは、関連するモデルプロパティで使用されるキーと一致する必要があります。2番目のパラメータはフィールドの[データ型](#data-type)です。最後に、0個以上の[制約](#field-constraint)を追加できます。

### データ型 {#data-type}

サポートされているフィールドのデータ型は以下のとおりです。

|DataType|Swift Type|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (推奨)|
|`.date`|`Date` (時刻を省略)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|[dictionary](#dictionary)を参照|
|`.array`|[array](#array)を参照|
|`.enum`|[enum](#enum)を参照|

### フィールド制約 {#field-constraint}

サポートされているフィールド制約は以下のとおりです。

|FieldConstraint|説明|
|-|-|
|`.required`|`nil`値を許可しません。|
|`.references`|このフィールドの値が参照されているスキーマの値と一致することを要求します。[外部キー](#foreign-key)を参照。|
|`.identifier`|主キーを示します。[識別子](#identifier)を参照。|
|`.sql(SQLColumnConstraintAlgorithm)`|サポートされていない制約（例：`default`）を定義します。[SQL](#sql)と[SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/)を参照。|

### 識別子 {#identifier}

モデルが標準の`@ID`プロパティを使用している場合、`id()`ヘルパーを使用してそのフィールドを作成できます。これは特別な`.id`フィールドキーと`UUID`値型を使用します。

```swift
// デフォルト識別子のフィールドを追加
.id()
```

カスタム識別子型の場合、フィールドを手動で指定する必要があります。

```swift
// カスタム識別子のフィールドを追加
.field("id", .int, .identifier(auto: true))
```

`identifier`制約は単一のフィールドで使用でき、主キーを示します。`auto`フラグは、データベースがこの値を自動的に生成するかどうかを決定します。

### フィールドの更新 {#update-field}

`updateField`を使用してフィールドのデータ型を更新できます。

```swift
// フィールドを`double`データ型に更新
.updateField("age", .double)
```

高度なスキーマ更新の詳細については、[advanced](advanced.md#sql)を参照してください。

### フィールドの削除 {#delete-field}

`deleteField`を使用してスキーマからフィールドを削除できます。

```swift
// "age"フィールドを削除
.deleteField("age")
```

## 制約 {#constraint}

スキーマの作成または更新時に制約を追加できます。[フィールド制約](#field-constraint)とは異なり、トップレベルの制約は複数のフィールドに影響を与えることができます。

### ユニーク {#unique}

ユニーク制約は、1つ以上のフィールドに重複する値がないことを要求します。

```swift
// 重複するメールアドレスを許可しない
.unique(on: "email")
```

複数のフィールドが制約されている場合、各フィールドの値の特定の組み合わせがユニークである必要があります。

```swift
// 同じフルネームのユーザーを許可しない
.unique(on: "first_name", "last_name")
```

ユニーク制約を削除するには、`deleteUnique`を使用します。

```swift
// 重複メール制約を削除
.deleteUnique(on: "email")
```

### 制約名 {#constraint-name}

Fluentはデフォルトでユニーク制約名を生成します。ただし、カスタム制約名を渡したい場合があります。これは`name`パラメータを使用して行うことができます。

```swift
// 重複するメールアドレスを許可しない
.unique(on: "email", name: "no_duplicate_emails")
```

名前付き制約を削除するには、`deleteConstraint(name:)`を使用する必要があります。

```swift
// 重複メール制約を削除
.deleteConstraint(name: "no_duplicate_emails")
```

## 外部キー {#foreign-key}

外部キー制約は、フィールドの値が参照されているフィールドの値のいずれかと一致することを要求します。これは、無効なデータが保存されるのを防ぐのに役立ちます。外部キー制約は、フィールドまたはトップレベルの制約として追加できます。

フィールドに外部キー制約を追加するには、`.references`を使用します。

```swift
// フィールド外部キー制約を追加する例
.field("star_id", .uuid, .required, .references("stars", "id"))
```

上記の制約は、"star_id"フィールドのすべての値がStarの"id"フィールドの値のいずれかと一致する必要があることを要求します。

この同じ制約は、`foreignKey`を使用してトップレベルの制約として追加できます。

```swift
// トップレベルの外部キー制約を追加する例
.foreignKey("star_id", references: "stars", "id")
```

フィールド制約とは異なり、トップレベルの制約はスキーマ更新で追加できます。また、[名前を付ける](#constraint-name)こともできます。

外部キー制約は、オプションの`onDelete`と`onUpdate`アクションをサポートしています。

|ForeignKeyAction|説明|
|-|-|
|`.noAction`|外部キー違反を防ぎます（デフォルト）。|
|`.restrict`|`.noAction`と同じ。|
|`.cascade`|外部キーを通じて削除を伝播します。|
|`.setNull`|参照が切れた場合、フィールドをnullに設定します。|
|`.setDefault`|参照が切れた場合、フィールドをデフォルトに設定します。|

以下は外部キーアクションを使用した例です。

```swift
// トップレベルの外部キー制約を追加する例
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    外部キーアクションはデータベース内でのみ発生し、Fluentをバイパスします。
    これは、モデルミドルウェアやソフトデリートなどが正しく動作しない可能性があることを意味します。

## SQL {#sql}

`.sql`パラメータを使用すると、スキーマに任意のSQLを追加できます。これは、特定の制約やデータ型を追加するのに役立ちます。
一般的な使用例は、フィールドのデフォルト値を定義することです：

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

またはタイムスタンプのデフォルト値：

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary {#dictionary}

dictionary データ型は、ネストされた辞書値を格納できます。これには、`Codable`に準拠する構造体と、`Codable`値を持つSwift辞書が含まれます。

!!! note
    FluentのSQLデータベースドライバーは、ネストされた辞書をJSON列に格納します。

次の`Codable`構造体を考えてみましょう。

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

この`Pet`構造体は`Codable`であるため、`@Field`に格納できます。

```swift
@Field(key: "pet")
var pet: Pet
```

このフィールドは`.dictionary(of:)`データ型を使用して格納できます。

```swift
.field("pet", .dictionary, .required)
```

`Codable`型は異種辞書であるため、`of`パラメータを指定しません。

辞書の値が同種の場合、例えば`[String: Int]`の場合、`of`パラメータは値の型を指定します。

```swift
.field("numbers", .dictionary(of: .int), .required)
```

辞書のキーは常に文字列である必要があります。

## Array {#array}

array データ型は、ネストされた配列を格納できます。これには、`Codable`値を含むSwift配列と、キーなしコンテナを使用する`Codable`型が含まれます。

文字列の配列を格納する次の`@Field`を考えてみましょう。

```swift
@Field(key: "tags")
var tags: [String]
```

このフィールドは`.array(of:)`データ型を使用して格納できます。

```swift
.field("tags", .array(of: .string), .required)
```

配列は同種であるため、`of`パラメータを指定します。

Codable Swiftの`Array`は常に同種の値型を持ちます。異種の値をキーなしコンテナにシリアライズするカスタム`Codable`型は例外であり、`.array`データ型を使用する必要があります。

## Enum {#enum}

enum データ型は、文字列ベースのSwift enumをネイティブに格納できます。ネイティブデータベースenumは、データベースに型安全性の追加レイヤーを提供し、生のenumよりもパフォーマンスが高い場合があります。

ネイティブデータベースenumを定義するには、`Database`で`enum`メソッドを使用します。`case`を使用してenumの各ケースを定義します。

```swift
// enum作成の例
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

enumが作成されたら、`read()`メソッドを使用してスキーマフィールドのデータ型を生成できます。

```swift
// enumを読み取り、新しいフィールドを定義するために使用する例
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// または

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

enumを更新するには、`update()`を呼び出します。既存のenumからケースを削除できます。

```swift
// enum更新の例
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

enumを削除するには、`delete()`を呼び出します。

```swift
// enum削除の例
database.enum("planet_type").delete()
```

## モデルとの結合 {#model-coupling}

スキーマ構築は意図的にモデルから分離されています。クエリビルディングとは異なり、スキーマビルディングはキーパスを使用せず、完全に文字列型です。これは重要です。なぜなら、特にマイグレーション用に書かれたスキーマ定義は、もはや存在しないモデルプロパティを参照する必要がある場合があるからです。

これをよりよく理解するために、次のマイグレーションの例を見てみましょう。

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

このマイグレーションがすでに本番環境にプッシュされていると仮定しましょう。次に、Userモデルに次の変更を加える必要があると仮定します。

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

次のマイグレーションで必要なデータベーススキーマの調整を行うことができます。

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // 現在、カスタムSQLを使用せずにこの更新を表現することはできません。
        // また、名前を姓と名に分割する処理は行いません。
        // これにはデータベース固有の構文が必要だからです。
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

このマイグレーションが機能するためには、削除された`name`フィールドと新しい`firstName`および`lastName`フィールドの両方を同時に参照できる必要があることに注意してください。さらに、元の`UserMigration`は引き続き有効である必要があります。これはキーパスでは不可能でした。

## モデルスペースの設定 {#setting-model-space}

[モデルのスペース](model.md#database-space)を定義するには、テーブルを作成するときに`schema(_:space:)`にスペースを渡します。例：

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```