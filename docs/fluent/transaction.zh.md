# 事务

事务允许你在将数据保存到数据库之前确保多个操作成功完成。事务启动后，你可以正常运行 Fluent 查询。但是，在事务完成之前，不会将任何数据保存到数据库中。如果在事务执行期间的任何时候（由你或数据库）抛出错误，则任何更改都不会生效。

为了执行事务，你需要访问可以连接到数据库的某些东西。这通常是一个传入的 HTTP 请求。为此，请使用 `req.db.transaction(_ :)`：
```swift
req.db.transaction { database in
    // use database
}
```
进入事务闭包后，必须使用闭包参数中提供的数据库（在本例中名为 `database`）执行查询。

一旦这个闭包成功返回，事务将被提交。
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
上面的例子将在完成事务之前保存 `sun` *然后*保存 `sirius`。如果任何一颗星保存失败，那两颗星都不会被保存。

一旦事务完成，结果可以转换为不同的未来，例如转换为 HTTP 状态以表明完成，如下所示:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

如果使用 `async`/`await` 你可以将代码重构为以下内容：

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
