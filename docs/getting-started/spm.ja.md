# Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) (SPM) は、プロジェクトのソースコードと依存関係のビルドに使用されます。Vapor は SPM に大きく依存しているため、SPM の基本的な動作を理解することがおすすめです。

SPM は Cocoapods 、Ruby gems 、 NPM に似ています。SPM は、`swift build` や `swift test` などのコマンドでコマンドラインから使用することも、互換性のある IDE から使用することもできます。しかし、他のパッケージマネージャとは異なり、SPM パッケージのための中央のパッケージインデックスは存在しません。SPM は代わりに、Git リポジトリへの URL を利用し、[Git タグ](https://git-scm.com/book/en/v2/Git-Basics-Tagging)を使用して依存関係のバージョンを管理します。

## パッケージマニフェスト

SPM がプロジェクトで最初に探す場所は、パッケージマニフェストです。これは常にプロジェクトのルールディレクトリに配置され、`Package.swift` という名前でなければなりません。

以下は、パッケージマニフェストの例です。

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

以下のセクションでは、マニフェストの各部分を説明していきます。

### Tools Version

パッケージマニフェストの最初の行は、必要な Swift ツールのバージョンを示しています。これは、パッケージがサポートする Swift のバージョン間で Package description API が変更される場合があるため、この行は Swift がマニフェストをどのように解析するかを知らせるために必要ようです。

### Package Name

`Package` への最初の引数は、パッケージの名前です。パッケージが公開されている場合、Git リポジトリの URL の最後のセグメントを名前として使用する必要があります。

### Platforms

`platforms` 配列は、このパッケージがサポートするプラットフォームを指定します。
`.macOS(.v12)` を指定することで、このパッケージは macOS 12 以降が必要です。Xcode でこのプロジェクトをロードすると、利用可能な API を全て使用できるように、最小のデプロイメントバージョンが自動的に macOS 12 に設定されます。

### Dependencies

依存関係は、パッケージが依存している他の SPM パッケージです。全ての Vapor アプリケーションは Vapor パッケージに依存していますが、必要に応じて他の依存関係を追加することができます。

上の例では、[vapor/vapor](https://github.com/vapor/vapor)のバージョン 4.76.0 以降がこのパッケージの依存関係であることがわかります。パッケージに依存関係を追加すると、次にどの[ターゲット](#targets)が新しく利用可能になったモジュールに依存しているかを示す必要があります。


### Targets

ターゲットは、パッケージが含むすべてのモジュール、実行ファイル、テストです。ほとんどの Vapor アプリは 2 つのターゲットを持っていますが、コードを整理するために必要なだけ多くのターゲットを追加することができます。各ターゲットは、それが依存するモジュールを宣言します。コード内でそれらをインポートするためには、ここでモジュールの名前を追加する必要があります。ターゲットは、プロジェクト内の他のターゲットや、[主な依存関係](#dependencies)配列に追加したパッケージで公開されている任意のモジュールに依存することができます。

## フォルダ構造

以下は、SPM パッケージの典型的なフォルダ構造です。

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

各 `.target` や `.executableTarget` は、`Sources` 内のフォルダに対応しています。
各`.testTarget` は、`Tests` 内のフォルダに対応しています。

## Package.resolved

プロジェクトを初めてビルドすると、SPM は各依存関係のバージョンを保存する `Package.resolved` ファイルを作成します。次にプロジェクトをビルドするとき、新しいバージョンが利用可能であっても、これらの同じバージョンが使用されます。

依存関係を更新するには、`swift package update` を実行します。

## Xcode

もし、Xocde 11 以降を使用している場合、`Package.swift` ファイルが変更されるたびに、依存関係、ターゲット、プロダクトなどの変更が自動的に行われます。

最新の依存関係に更新するには、File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions を使用します。

また、`.swiftpm` ファイルを `.gitignore` に追加することもおすすめします。これは、Xcode がXcode project の設定を保存する場所です。
