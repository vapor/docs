# Linux にインストール {#install-on-linux}

Vapor を使うには、Swift 5.9 以上が必要です。これは Swift Server Workgroup が提供する CLI ツール [Swiftly](https://swiftlang.github.io/swiftly/) を使ってインストールできます（推奨）。または、[Swift.org](https://swift.org/download/) で利用可能なツールチェーンを使用してインストールできます。

## サポートされているディストリビューションとバージョン {#supported-distributions-and-versions}
Vapor は、Swift 5.9 またはそれ以上の新しいバージョンがサポートする Linux ディストリビューションと同じバージョンをサポートしています。公式にサポートされているオペレーティングシステムの最新情報については、[公式サポートページ](https://www.swift.org/platform-support/)を参照してください。


公式にはサポートされていない Linux ディストリビューションでも、ソースコードをコンパイルすることで、Swift を実行できるかもしれませんが、Vapor は安定性を保証できません。[Swift repo](https://github.com/apple/swift#getting-started) から Swift のコンパイル方法について詳しく学ぶことができます。

## Swift のインストール {#install-swift}

### Swiftly CLI ツールを使用した自動インストール (推奨) {#automated-installation-using-swiftly-cli-tool-recommended}

Linux で Swiftly と Swift をインストールする手順については、[Swiftly のウェブサイト](https://swiftlang.github.io/swiftly/)をご覧ください。その手順に従った後、次のコマンドで Swift をインストールします。

#### 基本的な使い方 {#basic-usage}

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### ツールチェーンを使用した手動インストール {#manual-installation-with-the-toolchain}

Linux 上で Swift をインストールする方法については、Swift.org の[ダウンロードの使用](https://swift.org/download/#using-downloads)を参照してください。

### Fedora

Fedora ユーザーは、以下のコマンドを使用して Swift を簡単にインストールできます:

```sh
sudo dnf install swift-lang
```

Fedora 35 を使用している場合、Swift 5.9 またはそれ以降のバージョンを取得するには、EPEL 8 を追加する必要があります。

## Docker

Swift の公式Docker イメージも使用できます。これにはコンパイラが事前にインストールされています。[Swift の Docker Hub](https://hub.docker.com/_/swift) で詳しく学ぶことができます。

## ツールボックスのインストール {#install-toolbox}

Swift をインストールしたら、[Vapor Toolbox](https://github.com/vapor/toolbox) をインストールしましょう。この CLI ツールは、Vapor を使用するために必須ではありませんが、新しい Vapor プロジェクトの作成に役立ちます。

### Homebrew

Toolbox は Homebrew 経由で配布されています。まだ Homebrew をお持ちでない場合は、<a href="https://brew.sh" target="_blank">brew.sh</a> でインストール手順をご確認ください。

```sh
brew install vapor
```

インストールが成功したかどうかを確認するためにヘルプを表示します。

```sh
vapor --help
```

利用可能なコマンドのリストが表示されるはずです。

### Makefile

必要に応じて、ソースから Toolbox をビルドすることもできます。GitHub のツールボックスの<a href="https://github.com/vapor/toolbox/releases" target="_blank">リリース</a>で最新バージョンを見つけてください。

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

インストールが成功したかどうかを確認するためにヘルプを表示します。

```sh
vapor --help
```

利用可能なコマンドのリストが表示されるはずです。

## 次へ {#next}

Swift と Vapor Toolbox をインストールしたら、[はじめに &rarr; Hello, world](../getting-started/hello-world.md) で初めてのアプリを作成してください。
