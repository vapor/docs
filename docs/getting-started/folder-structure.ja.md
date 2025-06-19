# フォルダ構造 {#folder-structure}

あなたの初めての Vapor アプリを作成し、ビルドし、実行したので、Vapor のフォルダ構造に慣れるための時間を取りましょう。この構造は、[SPM](spm.ja.md) のフォルダ構造に基づいていますので、以前に SPM を使ったことがあれば、見慣れているはずです。

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│
├── Tests
│   └── AppTests
└── Package.swift
```

以下のセクションでは、フォルダ構造の各部分について詳しく説明します。

## Public

このフォルダには、`FileMiddleware` が有効になっている場合にアプリによって提供される公開ファイルが含まれます。これは通常、画像やスタイルシート、ブラウザスクリプトです。例えば、`localhost:8080/favicon.ico` へのリクエストは、`Public/favicon.ico` が存在するかどうかを確認し、それを返します。

Vapor が公開ファイルを提供できるようにする前に、`configure.swift` ファイルで `FileMiddleware` を有効にする必要があります。

```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

このフォルダには、プロジェクトのすべての Swift ソースファイルが含まれています。
トップレベルのフォルダ、`App` は、[SwiftPM](spm.ja.md) のマニフェストで宣言されたパッケージのモジュールを反映しています。

### App

ここには、アプリケーションの全てのロジックが入ります。

#### Controllers

Controllers は、アプリケーションのロジックをまとめるのに適しています。ほとんどのコントローラには、リクエストを受け取り、何らかの形でレスポンスを返す多くの関数があります。

#### Migrations

Migrations フォルダは、Fluent を使用している場合、データベースの移行を格納する場所です。

#### Models

Models フォルダは、`Content` 構造体や Fluent の `Model` を保存するのに適しています。

#### configure.swift {#configureswift}

このファイルには、`configure(_:)` 関数が含まれています。このメソッドは、新しく作成された `Application` を設定するために `entrypoint.swift` から呼び出されます。ここで、ルート、データベース、プロバイダなどのサービスの登録をする必要があります。

#### entrypoint.swift {#entrypointswift}

このファイルには、Vapor アプリケーションの設定と実行を行うアプリケーションの `@main` エントリーポイントが含まれています。

#### routes.swift {#routesswift}

このファイルには、`routes(_:)` 関数が含まれています。このメソッドは、`Application` へのルートを登録するために、`configure(_:)` の終わり近くで呼び出されます。

## Tests

`Sources` フォルダ内の各非実行可能モジュールには、`Tests` の対応するフォルダがあります。これには、パッケージのテストのために `XCTest` モジュールに基づいてビルドされたコードが含まれています。テストは、コマンドラインで `swift test` を使用するか、Xcode で ⌘+U を押すと実行できます。

### AppTests

このフォルダには、`App` モジュールのコードの単体テストが含まれています。

## Package.swift {#packageswift}

最後に、[SPM](spm.ja.md) のパッケージマニフェストがあります。
