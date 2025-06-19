# パスワード {#passwords}

Vaporには、パスワードを安全に保存・検証するためのパスワードハッシュAPIが含まれています。このAPIは環境に基づいて設定可能で、非同期ハッシュ化をサポートしています。

## 設定 {#configuration}

アプリケーションのパスワードハッシャーを設定するには、`app.passwords`を使用します。

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

パスワードハッシュ化にVaporの[Bcrypt API](crypto.md#bcrypt)を使用するには、`.bcrypt`を指定します。これがデフォルトです。

```swift
app.passwords.use(.bcrypt)
```

Bcryptは、特に指定しない限りコスト12を使用します。`cost`パラメータを渡すことで、これを設定できます。

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vaporには、パスワードを平文として保存・検証する安全でないパスワードハッシャーが含まれています。これは本番環境では使用すべきではありませんが、テストには便利です。

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## ハッシュ化 {#hashing}

パスワードをハッシュ化するには、`Request`で利用可能な`password`ヘルパーを使用します。

```swift
let digest = try req.password.hash("vapor")
```

パスワードダイジェストは、`verify`メソッドを使用して平文パスワードと照合できます。

```swift
let bool = try req.password.verify("vapor", created: digest)
```

同じAPIは、起動時に使用するために`Application`でも利用可能です。

```swift
let digest = try app.password.hash("vapor")
```

### Async 

パスワードハッシュアルゴリズムは、遅くCPU集約的になるように設計されています。このため、パスワードをハッシュ化する際にイベントループをブロックしないようにしたい場合があります。Vaporは、ハッシュ化をバックグラウンドスレッドプールにディスパッチする非同期パスワードハッシュAPIを提供します。非同期APIを使用するには、パスワードハッシャーの`async`プロパティを使用します。

```swift
req.password.async.hash("vapor").map { digest in
    // ダイジェストを処理
}

// または

let digest = try await req.password.async.hash("vapor")
```

ダイジェストの検証も同様に機能します：

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // 結果を処理
}

// または

let result = try await req.password.async.verify("vapor", created: digest)
```

バックグラウンドスレッドでハッシュを計算することで、アプリケーションのイベントループを解放し、より多くの受信リクエストを処理できるようになります。
