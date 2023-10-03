# macOS へのインストール

Vapor を macOS で使用するには、Swift 5.6 以上が必要です。Swift とそれに関連するすべての依存関係は、Xcode にバンドルされています。

## Xcode のインストール

Mac App Store から[Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) をインストールします。

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Xcode のダウンロードが完了したら、インストールを完了するために開く必要があります。これには時間がかかる場合があります。


インストールが成功したことを確認するために、Terminal を開いて Swift のバージョンを表示してください。

```sh
swift --version
```

Swift のバージョン情報が表示されるはずです。

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4 は、Swift 5.6 以上が必要です。

## Toolbox のインストール

Swift をインストールしたので、次に [Vapor Toolbox](https://github.com/vapor/toolbox) をインストールしましょう。このCLIツールはVapor を使用するためには必須ではありませんが、新しいプロジェクトクリエイーターのような便利なユーティリティが含まれています。

Toolbox は Homebrew 経由で配布されています。まだ Homebrew をインストールしていない場合は、<a href="https://brew.sh" target="_blank">brew.sh</a> を参照してインストール手順を確認してください。

```sh
brew install vapor
```

インストールが成功したかどうかを確認するために、ヘルプを表示してください。

```sh
vapor --help
```

利用可能なコマンドのリストが表示されるはずです。

## 次へ

Swift と Vapor Toolbox をインストールしたので、 [はじめに &rarr; Hello, world](../getting-started/hello-world.md) で初めてのアプリを作成してください。
