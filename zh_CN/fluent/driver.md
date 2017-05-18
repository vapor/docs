---
currentMenu: fluent-driver
---

# Driver

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Driver 是 Fluent 强大的基石。Fluent默认带有内存 driver，并且还有许多数据库 provider，例如 MySQL, SQLite, Mongo, PostgreSQL 和更多可用的 provider。

![Drivers and Providers](https://cloud.githubusercontent.com/assets/1342803/17418823/73f1d1d2-5a68-11e6-9bed-90f42ce7781d.png)

这幅图使用 MySQL 作为例子，展示了 Driver 和 Provider 之间的关系。这个区别允许 Fluent 独立于 Vapor 单独使用。

If you want to use Fluent without Vapor, you will import Drivers into your package. If you are using Vapor, you will import Providers.
如果你想不使用 Vapor 单独使用 Fluent，你需要导入 Driver 到你的 package。如果你使用 Vapor，你导入 provider 就可以了。

在 Github 搜索:
- [Fluent Drivers](https://github.com/vapor?utf8=✓&q=-driver)
- [Vapor Providers](https://github.com/vapor?utf8=✓&q=-provider)

并不是所有的 driver 有 provider。并且并不是所有的 driver 、 provider 都随着最新的 Vapor 1.0 更新了。更新它们，这是你贡献一份力的很好的方式。

## Creating a Driver

Fluent是一个强大的数据库不可见的 package，用于持久化您的模型。它从开始就被设计成能够和 SQL 和 NoSQL 一起配合使用。

Any database that conforms to `Fluent.Driver` will be able to power the models in Fluent and Vapor.
任何实现了 `Fluent.Driver` 的 数据库，都能够用来在 Fluent 和 Vapor 中增强 model。

protocol 是箱单简单的：

```swift
public protocol Driver {
    var idKey: String { get }
    func query<T: Entity>(_ query: Query<T>) throws -> Node
    func schema(_ schema: Schema) throws
    func raw(_ raw: String, _ values: [Node]) throws -> Node
}
```

### ID Key

ID 键将用于为 `User.find()` 等功能提供功能。在 SQL 中，它经常是 `id`。在 MongoDB 中， 它是 `_id`。

### Query

这个方法将会被 Fluent 创造的每一个 query 调用。正确的理解所有的 `Query` 的属性，并且返回期望的行数据、文档或者其他能够用 `Node` 代表的数据，这些都是 driver 的工作。

### Schema

The schema method will be called before the database is expected to accept queries for a schema. For some NoSQL databases like MongoDB, this can be ignored. For SQL, this is where `CREATE` and other such commands should be called according to `Schema`.
在数据库需要接受对 schema 的查询之前，将调用模式方法。对于一些 NoSQL 数据库，例如 MongoDB，这个是忽略的。对于 SQL，`CREATE`和其他这样的命令应该根据`Schema`调用。

### Raw

This is an optional method that can be used by any Fluent driver that accepts string queries. If your database does not accept such queries, an error can be thrown.
这是一个可选的方法，能够被 Fluent driver 用来接受字符串查询。如果你的数据库不接受这样的查询，一个错误将会被抛出。

> 译者注： Schema 和 Raw 有点不是太理解，以后理解了会修改。
