# Leaf 概要

Leaf は、Swift にインスパイアされた構文を持つ強力なテンプレート言語です。これを使って、フロントエンドのウェブサイト向けに動的な HTML ページを生成したり、API から送信するリッチなメールを生成したりできます。

このガイドでは、Leaf の構文と使用可能なタグについての概要を説明します。

## テンプレート構文

ここに、基本的な Leaf タグの使用例を示します。

```leaf
There are #count(users) users.
```

Leaf タグは、以下の 4 つの要素で構成されています：

- トークン `#` : Leaf パーサーがタグの開始を検出するためのシグナルです
- 名前 `count` : タグを識別するための名前です
- パラメータリスト `(users)` : 0個以上の引数を受け取ることができます
- ボディ：一部のタグには、コロンと閉じタグを使用して任意のボディを追加できるタグもあります

これらの4つの要素は、タグの実装に応じて様々な使い方ができます。 Leaf の標準タグがどのように使われるか、いくつかの例をみてみましょう。

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf は、Swift でお馴染みの多くの式もサポートしています。

- `+`
- `%`
- `>`
- `==`
- `||`
- etc.

```leaf
#if(1 + 1 == 2):
    Hello!
#endif

#if(index % 2 == 0):
    This is even index.
#else:
    This is odd index.
#endif
```

## Context

[Getting Started](getting-started.ja.md) の例では、 `[String: String]` 辞書を使って Leaf にデータを渡しましたが、`Encodable` に準拠する任意のデータを渡すことができます。実際、`[String: Any]` はサポートされていないため、`Encodable` な構造体を使用する方が推奨されます。つまり、配列を直接渡すことは*できず*、代わりに構造体にラップする必要があります：

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

これにより、`title` と `numbers` が Leaf テンプレートに公開され、タグ内で使用できるようになります。例：

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## 使用例

以下は、Leaf の一般的な使用例です。

### 条件

Leaf は、`#if` タグを使用してさまざまな条件を評価できます。例えば、変数を提供すると、その変数がコンテキストに存在するかチェックします：

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

また、比較を行うこともできます。例：

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

別のタグを条件の一部として使用したい場合は、内側のタグの `#` を省略する必要があります。例：

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

また、`#elseif` ステートメントを使用することもできます：

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### ループ

アイテムの配列を提供すると、Leaf はそれをループし、 `#for` タグを使用して各アイテムを個別に操作できます。

例えば、Swift コードを更新して、惑星のリストを提供することができます：

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

その後、Leaf で次のようにループを行うことができます：

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

これにより、次のようなビューがレンダリングされます：

```
Planets:
- Venus
- Earth
- Mars
```

### テンプレートの拡張

Leaf の `#extend` タグを使用すると、あるテンプレートの内容を別のテンプレートにコピーすることができます。このタグを使用する場合、テンプレートファイルの拡張子 .leaf を省略することが奨励されます。

拡張は、複数のページで共有される標準的なコンテンツ、例えばフッターや広告コード、テーブルなどをコピーするのに便利です：

```leaf
#extend("footer")
```

このタグは、あるテンプレートを別のテンプレートの上に構築する場合にも便利です。例えば、レイアウト用の layout.leaf ファイルを作成し、ウェブサイトの HTML 構造、CSS、JavaScript など、ページごとに異なるコンテンツを配置する場所を開けておくことができます。

この方法を使用すると、独自のコンテンツを入力し、それを適切に配置する親テンプレートを拡張する子テンプレートを構築することができます。このため、`#export` および `#import` タグを使用して、コンテンツをコンテキストに保存し、後でそれを取得することができます。

例えば、次のような `child.leaf` テンプレートを作成できます：

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

ここでは、`#export` を使用して HTML を保存し、現在拡張しているテンプレートで利用できるようにしています。その後、`master.leaf` をレンダリングし、Swift から渡された他のコンテキスト変数と共にエクスポートされたデータを使用します。例えば、`master.leaf` は次のようになります：

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

ここでは、`#import` を使用して、`#extend` タグに渡されたコンテンツを取得しています。Swift から `["title": "Hi there!"]` が渡されると、`child.leaf` は次のようにレンダリングされます：

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### その他のタグ

#### `#count`

`#count` タグは、配列内のアイテム数を返します。例：

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

`#lowercased` タグは、文字列内のすべての文字を小文字に変換します。

```leaf
#lowercased(name)
```

#### `#uppercased`

`#uppercased` タグは、文字列内のすべての文字を大文字に変換します。

```leaf
#uppercased(name)
```

#### `#capitalized`

`#capitalized` タグは、文字列の各単語の最初の文字を大文字にし、他の文字を小文字に変換します。詳細は [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized)をご覧ください。

```leaf
#capitalized(name)
```

#### `#contains`

`#contains` タグは、配列と値を2つのパラメータとして受け取り、パラメータ1の配列にパラメータ2の値が含まれているかどうかを返します。

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

`#date` タグは、日付を読みやすい文字列にフォーマットします。デフォルトでは ISO8601 フォーマットを使用します。

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

カスタム日付フォーマット文字列を2番目の引数として渡すこともできます。詳細は Swift の [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) をご覧ください。

```leaf
The date is #date(now, "yyyy-MM-dd")
```

日付フォーマッターのタイムゾーン ID を3番目の引数として渡すこともできます。詳細は Swift の [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) または [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) をご覧ください。

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

`#unsafeHTML` タグは、変数タグ(例: `#(variable)`) のように動作します。しかし、`variable` が含む可能性のある HTML はエスケープしません。

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note
    このタグを使用する際は、提供する変数がユーザーを XSS 攻撃に晒さないように注意する必要があります。

#### `#dumpContext`

`dumpContext` タグは、コンテキスト全体を人間が読める形式でレンダリングします。このタグを使用して、現在のレンダリングに提供されているコンテキストをデバッグします。

```leaf
Hello, world!
#dumpContext
```