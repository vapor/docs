# コマンド {#commands}

VaporのCommand APIを使用すると、カスタムコマンドライン関数を構築し、ターミナルと対話できます。これは、`serve`、`routes`、`migrate`などのVaporのデフォルトコマンドが構築されている基盤です。

## デフォルトコマンド {#default-commands}

`--help`オプションを使用して、Vaporのデフォルトコマンドについて詳しく学ぶことができます。

```sh
swift run App --help
```

特定のコマンドに`--help`を使用すると、そのコマンドが受け入れる引数とオプションを確認できます。

```sh
swift run App serve --help
```

### Xcode

Xcodeでコマンドを実行するには、`App`スキームに引数を追加します。これを行うには、次の手順に従います：

- `App`スキームを選択（再生/停止ボタンの右側）
- 「Edit Scheme」をクリック
- 「App」プロダクトを選択
- 「Arguments」タブを選択
- 「Arguments Passed On Launch」にコマンド名を追加（例：`serve`）

## カスタムコマンド {#custom-commands}

`AsyncCommand`に準拠する型を作成することで、独自のコマンドを作成できます。

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

カスタムコマンドを`app.asyncCommands`に追加すると、`swift run`経由で利用可能になります。

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

`AsyncCommand`に準拠するには、`run`メソッドを実装する必要があります。これには`Signature`の宣言が必要です。また、デフォルトのヘルプテキストも提供する必要があります。

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Hello, world!")
    }
}
```

このシンプルなコマンドの例には引数やオプションがないため、シグネチャは空のままにします。

提供されたコンテキストを介して現在のコンソールにアクセスできます。コンソールには、ユーザー入力のプロンプト、出力のフォーマットなど、多くの便利なメソッドがあります。

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

次のコマンドを実行してコマンドをテストします：

```sh
swift run App hello
```

### Cowsay

`@Argument`と`@Option`の使用例として、有名な[`cowsay`](https://en.wikipedia.org/wiki/Cowsay)コマンドの再現を見てみましょう。

```swift
import Vapor

struct Cowsay: AsyncCommand {
    struct Signature: CommandSignature {
        @Argument(name: "message")
        var message: String

        @Option(name: "eyes", short: "e")
        var eyes: String?

        @Option(name: "tongue", short: "t")
        var tongue: String?
    }

    var help: String {
        "Generates ASCII picture of a cow with a message."
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let eyes = signature.eyes ?? "oo"
        let tongue = signature.tongue ?? "  "
        let cow = #"""
          < $M >
                  \   ^__^
                   \  ($E)\_______
                      (__)\       )\/\
                       $T ||----w |
                          ||     ||
        """#.replacingOccurrences(of: "$M", with: signature.message)
            .replacingOccurrences(of: "$E", with: eyes)
            .replacingOccurrences(of: "$T", with: tongue)
        context.console.print(cow)
    }
}
```

これをアプリケーションに追加して実行してみてください。

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```