# トランザクション {#transactions}

トランザクションを使用すると、データベースにデータを保存する前に、複数の操作が正常に完了することを保証できます。
トランザクションが開始されると、通常通りFluentクエリを実行できます。ただし、トランザクションが完了するまでデータはデータベースに保存されません。
トランザクション中のいずれかの時点でエラーがスローされた場合（あなたまたはデータベースによって）、変更は一切反映されません。

トランザクションを実行するには、データベースに接続できるものへのアクセスが必要です。これは通常、受信HTTPリクエストです。これには、`req.db.transaction(_ :)`を使用します：
```swift
req.db.transaction { database in
    // databaseを使用
}
```
トランザクションクロージャ内では、クロージャパラメータで提供されるデータベース（例では`database`という名前）を使用してクエリを実行する必要があります。

このクロージャが正常に返されると、トランザクションがコミットされます。
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
上記の例では、トランザクションを完了する前に`sun`を保存し、*その後*`sirius`を保存します。いずれかの星の保存に失敗した場合、どちらも保存されません。

トランザクションが完了すると、結果を別のfutureに変換できます。例えば、以下のように完了を示すHTTPステータスに変換できます：
```swift
return req.db.transaction { database in
    // databaseを使用してトランザクションを実行
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

`async`/`await`を使用する場合、コードを以下のようにリファクタリングできます：

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```