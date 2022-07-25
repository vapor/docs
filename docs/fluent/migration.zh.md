# 迁移

迁移就像数据库的版本控制系统。每次迁移都定义了对数据库的更改以及如何撤消更改。通过迁移修改数据库，你可以创建一种一致的、可测试的和可共享的方式来随着时间演进数据库。

```swift
// An example migration.
struct MyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // Make a change to the database.
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

如果你使用 `async`/`await`，则应该实现 `AsyncMigration` 协议：

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Make a change to the database.
    }

    func revert(on database: Database) async throws {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

`prepare` 方法是对提供的 `数据库` 进行更改的地方。这些可能是对数据库模式的更改，如添加或删除表或集合、字段或约束。他们还可以修改数据库内容，比如创建新的模型实例、更新字段值或进行清理。

如果可能的话，`revert` 方法是撤消这些更改的地方。能够撤消迁移可以使原型设计和测试更加容易。如果部署到生产环境的工作没有按计划进行，它们还会为你提供备份计划。

## 注册

迁移请使用 `app.migrations` 方法注册到你的应用程序。

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

你可以使用 `to` 参数指定要迁移的数据库，否则将使用默认的数据库。

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

迁移应按依赖关系顺序列出。例如，如果 `MigrationB` 依赖 `MigrationA`，则在添加完 `MigrationA` 之后，通过 `app.migrations` 方法添加 `MigrationB`。

## 迁移
 
要迁移你的数据库，请在终端运行 `migrate` 命令。

```sh
vapor run migrate
```

你也可以[通过 Xcode 运行这个命令](../advanced/commands.md#xcode)。migrate 命令将检查数据库，查看自上次运行以来是否注册了新的迁移。如果有新的迁移，运行它之前会要求确认。

### 撤销

要撤消数据库上的迁移，终端运行 `migrate` 命令时添加 `--revert` 标志。

```sh
vapor run migrate --revert
```

该命令将检查数据库以查看上次运行的迁移是哪一批，并在恢复之前要求确认。

### 自动迁移

如果你希望在运行其他命令之前自动运行迁移，可以添加 `--auto-migrate` 标志。

```sh
vapor run serve --auto-migrate
```

你也可以通过编程来实现。

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

`--auto-revert` 和 `app.autoRevert()`，这两种方式皆可用于撤销迁移。

## 下一步

请查看[schema builder](schema.md) 和 [query builder](query.md) 指南，以了解更多迁移相关的信息。


