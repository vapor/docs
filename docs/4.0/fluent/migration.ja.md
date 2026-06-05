# マイグレーション {#migrations}

マイグレーションは、データベースのバージョン管理システムのようなものです。各マイグレーションは、データベースへの変更とその取り消し方法を定義します。マイグレーションを通じてデータベースを変更することで、時間の経過とともにデータベースを進化させる一貫性のある、テスト可能で、共有可能な方法を作成します。

```swift
// マイグレーションの例
struct MyMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // データベースに変更を加える
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
    	// `prepare`で行った変更を取り消す（可能な場合）
    }
}
```

`async`/`await`を使用している場合は、`AsyncMigration`プロトコルを実装する必要があります：

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // データベースに変更を加える
    }

    func revert(on database: any Database) async throws {
    	// `prepare`で行った変更を取り消す（可能な場合）
    }
}
```

`prepare`メソッドは、提供された`Database`に変更を加える場所です。これらは、テーブルやコレクション、フィールド、制約の追加や削除などのデータベーススキーマへの変更である可能性があります。また、新しいモデルインスタンスの作成、フィールド値の更新、クリーンアップなど、データベースの内容を変更することもできます。

`revert`メソッドは、可能であればこれらの変更を元に戻す場所です。マイグレーションを元に戻せることで、プロトタイピングとテストが容易になります。また、本番環境へのデプロイが計画通りに進まなかった場合のバックアッププランも提供します。

## 登録 {#register}

マイグレーションは`app.migrations`を使用してアプリケーションに登録されます。

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

`to`パラメータを使用して特定のデータベースにマイグレーションを追加できます。それ以外の場合は、デフォルトのデータベースが使用されます。

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

マイグレーションは依存関係の順序でリストする必要があります。例えば、`MigrationB`が`MigrationA`に依存している場合、`app.migrations`に2番目に追加する必要があります。

## マイグレート {#migrate}

データベースをマイグレートするには、`migrate`コマンドを実行します。

```sh
swift run App migrate
```

このコマンドは[Xcodeから実行](../advanced/commands.md#xcode)することもできます。migrateコマンドは、最後に実行されてから新しいマイグレーションが登録されているかデータベースをチェックします。新しいマイグレーションがある場合は、実行前に確認を求めます。

### リバート {#revert}

データベースのマイグレーションを元に戻すには、`--revert`フラグを付けて`migrate`を実行します。

```sh
swift run App migrate --revert
```

このコマンドは、最後に実行されたマイグレーションのバッチをデータベースでチェックし、それらを元に戻す前に確認を求めます。

### 自動マイグレート {#auto-migrate}

他のコマンドを実行する前にマイグレーションを自動的に実行したい場合は、`--auto-migrate`フラグを渡すことができます。

```sh
swift run App serve --auto-migrate
```

プログラムで実行することもできます。

```swift
try app.autoMigrate().wait()

// または
try await app.autoMigrate()
```

これらのオプションは両方ともリバートにも存在します：`--auto-revert`と`app.autoRevert()`。

## 次のステップ {#next-steps}

マイグレーション内に何を記述するかについての詳細は、[スキーマビルダー](schema.md)と[クエリビルダー](query.md)のガイドを参照してください。