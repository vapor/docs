# Xcode

このページでは、Xcode の使用に関するいくつかのヒントとテクニックを紹介します。異なる開発環境を使用している場合、このセクションはスキップしてもよいです。

## カスタムワーキングディレクトリ

デフォルトでは、Xcode はあなたのプロジェクトを _DerivedData_ フォルダから実行します。このフォルダは、プロジェクトのルートフォルダ ( _Package.swift_ ファイルがある場所) とは異なります。これは、 Vapor が _.env_ や _Public_ のようなファイルやフォルダを見つけることができないことを意味します。

アプリを実行するときに以下の警告が表示される場合、この問題が発生していることがわかります。

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

これを修正するには、プロジェクトの Xcode スキームでカスタムワーキングディレクトリを設定します。

まず、プレイボタンとストップボタンの隣にあるスキームセレクタをクリックして、プロジェクトのスキームを編集します。

![Xcode Scheme Area](../images/xcode-scheme-area.png)

ドロップダウンから _Edit Scheme..._ を選択します。

![Xcode Scheme Menu](../images/xcode-scheme-menu.png)

スキームエディタで、_App_ アクションと _Options_ タブを選択します。_Use custom working directory_ をチェックし、プロジェクトのルートフォルダへのパスを入力します。

![Xcode Scheme Options](../images/xcode-scheme-options.png)

プロジェクトのルートへのフルパスは、その場所で開いたターミナルウィンドウから `pwd` を実行することで取得できます。

```sh
# get path to this folder
pwd
```

以下のような出力が表示されるはずです。

```
/path/to/project
```
