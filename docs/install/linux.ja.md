# Linux にインストール

Vapor を使用するには、Swift 5.6 以上が必要です。これは、[Swift.org](https://swift.org/download/)で利用可能なツールチェーンを使用してインストールできます。

## サポートされているディストリビューションとバージョン

Vapor は、Swift 5.6 またはそれ以降のバージョンがサポートする Linux ディストリビューションのバージョンをサポートしています。

!!! 注意
    下記のサポートされているバージョンは、古くなる可能性があります。公式にサポートされているオペレーションシステムは、[Swift Releases](https://swift.org/download/#releases) のページで確認できます。


|ディストリビューション|バージョン|Swift のバージョン|
|-|-|-|
|Ubuntu|20.04|>= 5.6|
|Fedora|>= 30|>= 5.6|
|CentOS|8|>= 5.6|
|Amazon Linux|2|>= 5.6|

公式にはサポートされていない Linux ディストリビューションでも、ソースコードをコンパイルすることで、Swift を実行できるかもしれませんが、Vapor は安定性を保証できません。[Swift repo](https://github.com/apple/swift#getting-started) から Swift のコンパイル方法について詳しく学ぶことができます。

## Swift のインストール

Linux 上で Swift をインストールする方法については、Swift.org の[ダウンロードの使用](https://swift.org/download/#using-downloads)を参照してください。

### Fedora

Fedora ユーザーは、以下のコマンドを使用して Swift を簡単にインストールできます:

```sh
sudo dnf install swift-lang
```

Fedora 30 を使用している場合、Swift 5.6 またはそれ以降のバージョンを取得するには、EPEL8 を追加する必要があります。

## Docker

Swift の公式Docker イメージも使用できます。これにはコンパイラが事前にインストールされています。[Swift の Docker Hub](https://hub.docker.com/_/swift) で詳しく学ぶことができます。

## ツールボックスのインストール

Swift をインストールしたら、[Vapor Toolbox](https://github.com/vapor/toolbox) をインストールしましょう。この CLI ツールは、Vapor を使用するために必須ではありませんが、役立つユーティリティが含まれています。

Linux 上では、ソースからツールボックスをビルドする必要があります。GitHub のツールボックスの<a href="https://github.com/vapor/toolbox/releases" target="_blank">リリース</a>で最新バージョンを見つけてください。

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

## 次へ

Swift をインストールしたら、[はじめに &rarr; hello, world](../getting-started/hello-world.md) で初めてのアプリを作成してください。
