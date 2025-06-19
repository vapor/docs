# 環境 {#environment}

VaporのEnvironment APIは、アプリの動的な設定を支援します。デフォルトでは、あなたのアプリは`development`環境を使用します。`production`や`staging`のような他の有用な環境を定義し、各ケースでアプリがどのように設定されるかを変更できます。また、プロセスの環境や`.env`（dotenv）ファイルから変数を読み込むことも、ニーズに応じて可能です。

現在の環境にアクセスするには、`app.environment`を使用します。`configure(_:)`内でこのプロパティにスイッチして、異なる設定ロジックを実行できます。

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## 環境の変化 {#changing-environment}

デフォルトでは、アプリは `development` 環境で実行されます。アプリ起動時に `--env`（`-e`）フラグを渡すことで、これを変更できます。

```swift
swift run App serve --env production
```

Vapor は以下の環境を含みます。:

|名前|略称|説明|
|-|-|-|
|production|prod|ユーザーにデプロイされた状態|
|development|dev|ローカル開発|
|testing|test|ユニットテスト用|

!!! info
    `production` 環境は、特に指定されていない場合、デフォルトで `notice` レベルのログになります。他の環境はデフォルトでinfoです。


`--env`（`-e`）フラグには、フルネームか略称のどちらかを渡すことができます。

```swift
swift run App serve -e prod
```

## プロセス変数 {#process-variables}

`Environment` は、プロセスの環境変数にアクセスするためのシンプルな文字列ベースの API を提供します。

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

`get` に加えて、`Environment` は `process` 経由で動的メンバールックアップ API を提供します。

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

ターミナルでアプリを実行する際は、`export` を使って環境変数を設定できます。

```sh
export FOO=BAR
swift run App serve
```

Xcode でアプリを実行する場合は、`App` スキームを編集して環境変数を設定できます。

## .env (dotenv) {#env-dotenv}

Dotenv ファイルには、環境に自動的にロードされるキーと値のペアのリストが含まれています。これらのファイルは、手動で設定することなく環境変数を設定するのを容易にします。

Vapor は、現在の作業ディレクトリにある dotenv ファイルを探します。Xcode を使用している場合は、`App` スキームを編集して作業ディレクトリを設定してください。

以下の `.env` ファイルがプロジェクトのルートフォルダに配置されているとします：

```sh
FOO=BAR
```

アプリケーションが起動すると、このファイルの内容に他のプロセス環境変数のようにアクセスできます。

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    `.env` ファイルで指定された変数は、プロセス環境に既に存在する変数を上書きしません。


`.env` と並行して、Vapor は現在の環境の dotenv ファイルも読み込もうとします。例えば、`development` 環境では、`.env.development` がロードされます。特定の環境ファイルにある値は、一般的な `.env` ファイルより優先されます。

一般的なパターンとして、プロジェクトはデフォルト値を含む `.env` ファイルをテンプレートとして含めます。特定の環境ファイルは、以下のパターンで `.gitignore` に含まれます：

```gitignore
.env.*
```

プロジェクトが新しいコンピュータにクローンされたとき、テンプレートの `.env` ファイルをコピーして正しい値を挿入できます。

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    パスワードなどの機密情報を含む dotenv ファイルは、バージョン管理にコミットしてはいけません。

dotenv ファイルの読み込みに問題がある場合は、`--log debug` を使用してデバッグログを有効にすると、より多くの情報が得られます。

## カスタム環境 {#custom-environments}

カスタム環境を定義するには、`Environment`を拡張します。

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

アプリケーションの環境は通常、`entrypoint.swift` で `Environment.detect()` を使って設定されます。

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)
        defer { 
            app.shutdown() 
        }

        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

`detect` メソッドはプロセスのコマンドライン引数を使用し、`--env` フラグを自動的に解析します。カスタム `Environment` 構造体を初期化することで、この動作をオーバーライドできます。

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

引数配列には、実行可能な名前を表す少なくとも1つの引数が含まれている必要があります。コマンドライン経由で引数を渡すのをシミュレートするために、さらに引数を供給できます。これは特にテストに役立ちます。
