# バリデーション

Vapor のバリデーション API は、データをデコードする前に、[コンテンツ](content.ja.md) API を使って入力リクエストの検証を行うのに役立ちます。

## はじめに 

Swift の型安全な `Codable` プロトコルを深く統合している Vapor は、動的型付け言語に比べてデータバリデーションについてそれほど心配する必要はありません。しかし、明示的なバリデーションを選択する理由はいくつかあります。

### 人間が読みやすいエラー

[コンテンツ](content.ja.md) API を使用して構造体をデコードする際には、データが無効である場合にエラーが発生します。しかしながら、これらのエラーメッセージは時として人間が読みやすいものではありません。例えば、次のような文字列ベースの enum を見て下さい。

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

もし、ユーザーが `Color` 型のプロパティに `"purple"` という文字列を渡そうとした場合、次のようなエラーが発生します。

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

このエラーは技術的に正しく、エンドポイントを無効な値から守るのに成功していますが、ユーザーにミスと利用可能な選択肢についてもっとよく情報を伝えることができます。バリデーション API を使用すると、次のようなエラーを生成できます。

```
favoriteColor is not red, blue, or green
```

さらに、`Codable` は最初のエラーが発生した時点で型のデコードを試みるのをやめます。つまり、リクエストに多くの無効なプロパティがあっても、ユーザーは最初のエラーしか見ることができません。バリデーション API は、一度のリクエストで全てのバリデーション失敗を報告します。

### 特定のバリデーション

`Codable` は型のバリデーションをうまく扱いますが、時にはそれ以上のことをしたい事もあります。例えば、文字列の内容を検証したり、整数のサイズを検証したりすることです。バリデーション API には、メールアドレス、文字セット、整数の範囲など、データの検証に役立つバリデータがあります。

## Validatable

リクエストをバリデーションするためには、`Validations` コレクションを生成する必要があります。これは通常、既存の型を `Validatable` に準拠させることによって行われます。

`POST /users` エンドポイントにバリデーションを追加する方法を見てみましょう。このガイドでは、既に[コンテンツ](content.ja.md) APIについて熟知していることを前提としています。

```swift
enum Color: String, Codable {
    case red, blue, green
}

struct CreateUser: Content {
    var name: String
    var username: String
    var age: Int
    var email: String
    var favoriteColor: Color?
}

app.post("users") { req -> CreateUser in
    let user = try req.content.decode(CreateUser.self)
    // Do something with user.
    return user
}
```

### バリデーションの追加

最初のステップは、この場合は `CreateUser` である、デコードする型を `Validatable` に準拠させることです。これは拡張を使って行うことができます。

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

静的メソッド `validations(_:)` は `CreateUser` がバリデーションされたときに呼び出されます。実行したいバリデーションは、提供された `Validations` コレクションに追加する必要があります。ユーザーのメールが有効であることを要求する簡単なバリデーションを追加する方法を見てみましょう。

```swift
validations.add("email", as: String.self, is: .email)
```

最初のパラメータは期待される値のキーで、この場合は `"email"` です。これは検証される型のプロパティ名と一致している必要があります。二番目のパラメータ `as` は期待される型で、この場合は `String` です。型は通常、プロパティの型と一致しますが、常にそうとは限りません。最後に、三番目のパラメータ `is` の後に一つまたは複数のバリデータを追加できます。この場合、値がメールアドレスであるかをチェックする単一のバリデータが追加されています。

### リクエストコンテンツのバリデーション

型を `Validatable` に準拠させたら、静的な `validate(content:)` 関数を使ってリクエストコンテンツをバリデーションできます。ルートハンドラの `req.content.decode(CreateUser.self)` の前に次の行を追加してください。


```swift
try CreateUser.validate(content: req)
```

これで、次のように無効なメールを含むリクエストを送信してみてください。：

```http
POST /users HTTP/1.1
Content-Length: 67
Content-Type: application/json

{
    "age": 4,
    "email": "foo",
    "favoriteColor": "green",
    "name": "Foo",
    "username": "foo"
}
```

次のようなエラーが返されるはずです。：

```
email is not a valid email address
```

### リクエストクエリのバリデーション

`Validatable` に準拠している型には、リクエストのクエリ文字列をバリデーションする `validate(query:)` もあります。ルートハンドラに次の行を追加してください。

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

これで、クエリ文字列に無効なメールを含む次のようなリクエストを送信してみてください。

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

次のようなエラーが返されるはずです。：

```
email is not a valid email address
```

### 整数のバリデーション

素晴らしい、次に `age` に対する検証を追加してみましょう。

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

年齢の検証では、年齢が `13` 歳以上であることを要求します。もし上記と同じリクエストを試したら、今度は新しいエラーが表示されるはずです。：

```
age is less than minimum of 13, email is not a valid email address
```

### 文字列のバリデーション

次に、`name` と `username` に対する検証を追加しましょう。

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

名前の検証では、!演算子を使って `.empty` 検証を反転させます。これにより、文字列が空でないことが必要です。

ユーザーネームの検証では、`&&` を使って2つのバリデーターを組み合わせます。これにより、文字列が少なくとも3文字以上であり、_かつ_ 英数字のみで構成されていることが必要です。

### Enumのバリデーション

最後に、提供された `favoriteColor` が有効かどうかをチェックする少し高度な検証を見てみましょう。



```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

無効な値から `Color` をデコードすることは不可能なため、この検証では基本型として `String` を使用しています。`.in` バリデーターを使って、値が有効なオプションであるかどうかを確認します。：赤、青、または緑です。この値はオプショナルなので、このキーがリクエストデータから欠落している場合に検証が失敗しないように、`required` はfalseに設定されます。

お気に入りの色の検証は、キーが欠落している場合には通過しますが、`null` が提供された場合には通過しません。`null` をサポートしたい場合は、検証の型を `String?` に変更し、`.nil ||`（"is nil or ..."と読みます）を使用します。

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### カスタムエラー

`Validations` や `Validator` にカスタムで人が読めるエラーを追加したい場合があります。そのためには、デフォルトのエラーを上書きする追加の `customFailureDescription` パラメータを提供するだけです。

```swift
validations.add(
	"name",
	as: String.self,
	is: !.empty,
	customFailureDescription: "Provided name is empty!"
)
validations.add(
	"username",
	as: String.self,
	is: .count(3...) && .alphanumeric,
	customFailureDescription: "Provided username is invalid!"
)
```

## バリデーター

以下は、現在サポートされているバリデーターと、それらが何をするのかの簡単な説明のリストです。

|Validation|説明|
|-|-|
|`.ascii`|ASCⅡ 文字のみを使います。|
|`.alphanumeric`|英数字のみを含みます。|
|`.characterSet(_:)`|指定された `CharacterSet` からの文字のみを含みます。|
|`.count(_:)`|コレクションのカウントが指定された範囲内です。|
|`.email`|有効なメールアドレスを含みます。|
|`.empty`|コレクションが空です。|
|`.in(_:)`|値が提供された `Collection` の中にあります。|
|`.nil`|値が `null` です。|
|`.range(_:)`|値が提供された `Range` の内です。|
|`.url`|有効な URL を含みます。|

バリデーターはまた、演算子を使用して複雑な検証を組み立てるために組み合わせることができます。

|演算子|位置|説明|
|-|-|-|
|`!`|前置|バリデーターを反転させ、反対のものを要求します。|
|`&&`|中置|2つのバリデーターを組み合わせ、両方を要求する。|
|`||`|中置|2つのバリデーターを組み合わせ、1つを要求する。|
