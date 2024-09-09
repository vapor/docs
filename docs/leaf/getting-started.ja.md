# Leaf

Leaf は、Swift にインスパイアされた構文を持つ強力なテンプレート言語です。これを使って、フロントエンドのウェブサイト向けに動的な HTML ページを生成したり、API から送信するリッチなメールを生成したりできます。

## Package

Leaf を使用する最初のステップは、プロジェクトの SPM パッケージマニフェストファイルに依存関係として追加することです。

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## 設定

パッケージをプロジェクトに追加したら、Vapor を設定してそれを使用するように構成します。これは通常、[`configure.swift`](../getting-started/folder-structure.md#configureswift) で行います。

```swift
import Leaf

app.views.use(.leaf)
```

これにより、コード内で `req.view` を呼び出すと、Vapor が `LeafRenderer` を使用するように指示します。

!!! note 
    Leaf には、ページをレンダリングするための内部キャッシュがあります。`Application` の環境が `.development` に設定されている場合、このキャッシュは無効になり、テンプレートへの変更が即座に反映されます。`.production` やその他の環境では、キャッシュがデフォルトで有効になっており、テンプレートに加えた変更はアプリケーションを再起動するまで反映されません。

!!! warning 
    Xcode から実行する際に Leaf がテンプレートを見つけられるようにするためには、 Xcode ワークスペースの [custom working directory](../getting-started/xcode.md#_1) を設定する必要があります。
## フォルダ構成

Leaf を設定したら、`.leaf` ファイルを格納するための `Views` フォルダを用意する必要があります。デフォルトでは、Leaf はプロジェクトのルートに対して `./Resources/Views` というフォルダを要求します。

JavaScript や CSS ファイルを提供する予定がある場合は、Vapor の [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) を有効にして、 `/Public` フォルダからファイルを提供できるようにすることも可能です。

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## Viewのレンダリング

Leaf が設定できたので、最初のテンプレートをレンダリングしてみましょう。`Resources/Views` フォルダ内に、次の内容で `hello.leaf` という新しいファイルを作成します。

```leaf
Hello, #(name)!
```

!!! tip
    もし、コードエディタとして VSCode を使用している場合、シンタックスハイライトを有効にするために、Leaf 拡張機能をインストールすることをお勧めします：[Leaf HTML](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf)

次に、View をレンダリングするルートを登録します。(通常は、`routes.swift` やコントローラで行います)

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

ここでは、Leaf を直接呼び出すのではなく、`Request` の汎用 `view` プロパティを使用します。これにより、テスト時に別のレンダラーに切り替えることができます。

ブラウザを開き、`/hello` にアクセスしてください。 `Hello, Leaf!` と表示されているはずです。これで最初の Leaf ビューのレンダリングが完了です！
