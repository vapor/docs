# Hello, world

このガイドは、新しい Vapor プロジェクトを作成、ビルド、サーバーを実行する手順を説明します。

まだ、Swift や Vapor ツールボックスをインストールしていない場合は、インストールセクションを参照してください。

- [Install &rarr; macOS](../install/macos.ja.md)
- [Install &rarr; Linux](../install/linux.ja.md)

!!! tip
	Vapor ツールボックスで使用されるテンプレートには Swift 6.0 以降が必要です

## 新規プロジェクト

最初のステップは、コンピュータに新しい Vapor プロジェクトを作成することです。ターミナルを開き、ツールボックスの新規プロジェクトコマンドを使用してください。これにより、現在のディレクトリにプロジェクトを含む新しいフォルダが作成されます。

```sh
vapor new hello -n
```

!!! tip
	`-n` フラグは、すべての質問に自動的に「いいえ」と答えることで、ベアボーンのテンプレートを提供します。

!!! tip
		Vapor ツールボックスを使用せずに GitHub [テンプレートリポジトリ](https://github.com/vapor/template-bare)をクローンして最新のテンプレートを取得することもできます。

!!! tip
	Vapor とテンプレートは、デフォルトで `async`/`await` を使用します。
	macOS 12 にアップデートできない、または `EventLoopFuture` を継続して使用する必要がある場合は、
	`--branch macos10-15` フラグを使います。

コマンドが完了したら、新しく作成されたフォルダに移動します。


```sh
cd hello
```

## ビルド & 実行

### Xcode

まず、Xcode でプロジェクトを開きます：

```sh
open Package.swift
```

自動的に Swift Package Manager の依存関係をダウンロードし始めます。プロジェクトを初めて開くとき、時間がかかることがあります。依存関係の解決が完了すると、Xcode は利用可能なスキームを表示します。

ウィンドウの上部に、再生ボタンと停止ボタンの右側にあるプロジェクト名をクリックして、プロジェクトのスキームを選択します。適切な実行ターゲットを選択してください。おそらく、"My Mac" が適しているでしょう。プレイボタンをクリックして、プロジェクトをビルドして実行します。

Xcode のウィンドウの下部に、コンソールが表示されるはずです。

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Linux やその他 OS (または　Xcode を使用したくない場合の macOS も含む)では、 Vim や VScode のようなお好きなエディタでプロジェクトを編集できます。他の IDE の設定に関する最新の詳細は、[Swift Server ガイド](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md)を参照してください。

!!! tip
    VSCode をコードエディタとして使用している場合は、公式の Vapor 拡張機能をインストールすることをお勧めします: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode)

プロジェクトをビルドして実行するには、ターミナルで以下のコマンドを実行します:

```sh
swift run
```

これにより、プロジェクトがビルドされて実行されます。初めてこれを実行すると、依存関係を取得および解決するのに時間がかかります。実行が開始されると、コンソールに以下の内容が表示されるはずです:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Localhost へのアクセス

ウェブブラウザを開き、<a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> または <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a> にアクセスしてください。

次のページが表示されるはずです。


```html
Hello, world!
```

おめでとうございます！ Vapor アプリの作成、ビルド、実行することに成功しました！ 🎉
