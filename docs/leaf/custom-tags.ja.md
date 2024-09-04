# カスタムタグ

[`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag) プロトコルを使用して、カスタム Leaf タグを作成することができます。

これを実際に試してみるために、現在のタイムスタンプを表示するカスタムタグ `#now` を作成してみましょう。このタグは、日付形式を指定するためのオプションのパラメータもサポートします。

!!! tip
	もしカスタムタグが HTML をレンダリングする場合は、HTML がエスケープされないように、`UnsafeUnescapedLeafTag` に準拠させる必要があります。ユーザー入力のチェックやサニタイズを忘れないようにしましょう。

## `LeafTag`

まず、`NowTag` というクラスを作成し、`LeafTag` に準拠させます。

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

次に、`render(_:)` メソッドを実装します。このメソッドに渡される `LeafContext` は、必要なすべての情報を持っています。

```swift
enum NowTagError: Error {
    case invalidFormatParameter
    case tooManyParameters
}

struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let formatter = DateFormatter()
        switch ctx.parameters.count {
        case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        case 1:
            guard let string = ctx.parameters[0].string else {
                throw NowTagError.invalidFormatParameter
            }

            formatter.dateFormat = string
        default:
            throw NowTagError.tooManyParameters
	    }
    
        let dateAsString = formatter.string(from: Date())
        return LeafData.string(dateAsString)
    }
}
```

## タグの設定

`NowTag` を実装したので、Leaf にそれを伝えるだけです。このようにして、たとえ別のパッケージで定義されたタグでも追加することができます。通常、これを `configure.swift` で行います：

```swift
app.leaf.tags["now"] = NowTag()
```

これで完了です！Leaf でカスタムタグを使用できるようになりました。

```leaf
The time is #now()
```

## コンテキストプロパティ

`LeafContext` には、重要なプロパティが 2 つあります。それが `parameters` と `data` です。この 2 つで必要な情報はすべて揃っています。

- `parameters`: タグのパラメータを含む配列です
- `data`: コンテキストとして `render(_:_:)` に渡されたビューのデータを含む辞書です

### Hello タグによる実例

これを理解するために、両方のプロパティを使ったシンプルな hello タグを実装してみましょう。

#### parameters の使用

nameの値が提供される、1つ目のパラメータにアクセスできます

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### data の使用

data プロパティの中の "name" キーを使って名前の値にアクセスします。

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello()
```

_Controller_:

```swift
return try await req.view.render("home", ["name": "John"])
```
