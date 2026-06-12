# 高度な使い方 {#advanced}

Fluentは、データを扱うための汎用的でデータベースに依存しないAPIの作成を目指しています。これにより、どのデータベースドライバーを使用しているかに関わらず、Fluentを学習しやすくなります。汎用的なAPIを作成することで、Swiftでデータベースを扱う際により自然に感じられるようになります。

しかし、Fluentでまだサポートされていない基礎となるデータベースドライバーの機能を使用する必要がある場合があります。このガイドでは、特定のデータベースでのみ動作するFluentの高度なパターンとAPIについて説明します。

## SQL {#sql}

Fluentのすべての SQLデータベースドライバーは[SQLKit](https://github.com/vapor/sql-kit)上に構築されています。この汎用SQL実装は、`FluentSQL`モジュールでFluentと共に提供されています。

### SQLデータベース {#sql-database}

任意のFluent `Database`は`SQLDatabase`にキャストできます。これには`req.db`、`app.db`、`Migration`に渡される`database`などが含まれます。

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // 基礎となるデータベースドライバーはSQLです。
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // 基礎となるデータベースドライバーはSQLではありません。
}
```

このキャストは、基礎となるデータベースドライバーがSQLデータベースである場合にのみ機能します。`SQLDatabase`のメソッドについては、[SQLKitのREADME](https://github.com/vapor/sql-kit)で詳しく学べます。

### 特定のSQLデータベース {#specific-sql-database}

ドライバーをインポートすることで、特定のSQLデータベースにキャストすることもできます。

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // 基礎となるデータベースドライバーはPostgreSQLです。
    let planets = try await postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // 基礎となるデータベースはPostgreSQLではありません。
}
```

執筆時点で、以下のSQLドライバーがサポートされています。

|データベース|ドライバー|ライブラリ|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

データベース固有のAPIについての詳細は、各ライブラリのREADMEをご覧ください。

### SQLカスタム {#sql-custom}

Fluentのクエリとスキーマタイプのほぼすべてが`.custom`ケースをサポートしています。これにより、Fluentがまだサポートしていないデータベース機能を利用できます。

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKEがサポートされています。
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKEはサポートされていません。
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

SQLデータベースは、すべての`.custom`ケースで`String`と`SQLExpression`の両方をサポートしています。`FluentSQL`モジュールは、一般的な使用例のための便利なメソッドを提供しています。

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // 基礎となるデータベースドライバーはSQLです。
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // 基礎となるデータベースドライバーはSQLではありません。
}
```

以下は、スキーマビルダーで`.sql(raw:)`の便利な機能を介して`.custom`を使用する例です。

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // 基礎となるデータベースドライバーはMySQLです。
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // 基礎となるデータベースドライバーはMySQLではありません。
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB {#mongodb}

Fluent MongoDBは、[Fluent](../fluent/overview.md)と[MongoKitten](https://github.com/OpenKitten/MongoKitten/)ドライバー間の統合です。Swiftの強力な型システムとFluentのデータベース非依存インターフェースをMongoDBで活用します。

MongoDBで最も一般的な識別子はObjectIdです。`@ID(custom: .id)`を使用してプロジェクトでこれを使用できます。
SQLで同じモデルを使用する必要がある場合は、`ObjectId`を使用しないでください。代わりに`UUID`を使用してください。

```swift
final class User: Model {
    // テーブルまたはコレクションの名前。
    static let schema = "users"

    // このUserの一意識別子。
    // この場合、ObjectIdが使用されています
    // Fluentはデフォルトで UUID の使用を推奨しますが、ObjectIdもサポートされています
    @ID(custom: .id)
    var id: ObjectId?

    // ユーザーのメールアドレス
    @Field(key: "email")
    var email: String

    // BCryptハッシュとして保存されるユーザーのパスワード
    @Field(key: "password")
    var passwordHash: String

    // Fluentが使用するための新しい空のUserインスタンスを作成します
    init() { }

    // すべてのプロパティが設定された新しいUserを作成します。
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### データモデリング {#data-modelling}

MongoDBでは、モデルは他のFluent環境と同じように定義されます。SQLデータベースとMongoDBの主な違いは、リレーションシップとアーキテクチャにあります。

SQL環境では、2つのエンティティ間の関係のために結合テーブルを作成することが非常に一般的です。しかし、MongoDBでは、配列を使用して関連する識別子を保存できます。MongoDBの設計により、ネストされたデータ構造でモデルを設計する方がより効率的で実用的です。

### 柔軟なデータ {#flexible-data}

MongoDBでは柔軟なデータを追加できますが、このコードはSQL環境では動作しません。
グループ化された任意のデータストレージを作成するには、`Document`を使用できます。

```swift
@Field(key: "document")
var document: Document
```

Fluentはこれらの値に対する厳密に型付けされたクエリをサポートできません。クエリでドット記法のキーパスを使用できます。
これは、ネストされた値にアクセスするためにMongoDBで受け入れられています。

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### 正規表現の使用 {#use-of-regular-expressions}

`.custom()`ケースを使用し、正規表現を渡してMongoDBをクエリできます。[MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/)はPerl互換の正規表現を受け入れます。

例えば、`name`フィールドで大文字と小文字を区別しない文字をクエリできます：

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

これは'e'と'E'を含む惑星を返します。MongoDBが受け入れる他の複雑な正規表現も作成できます。

### 生のアクセス {#raw-access}

生の`MongoDatabase`インスタンスにアクセスするには、データベースインスタンスを`MongoDatabaseRepresentable`にキャストします：

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

ここから、すべてのMongoKitten APIを使用できます。