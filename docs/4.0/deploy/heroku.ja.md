# Herokuとは {#what-is-heroku}

Herokuは人気のオールインワンホスティングソリューションです。詳細は[heroku.com](https://www.heroku.com)をご覧ください。

## サインアップ {#signing-up}

Herokuアカウントが必要です。まだお持ちでない場合は、こちらからサインアップしてください：[https://signup.heroku.com/](https://signup.heroku.com/)

## CLIのインストール {#installing-cli}

Heroku CLIツールがインストールされていることを確認してください。

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### その他のインストールオプション {#other-install-options}

代替のインストールオプションはこちらをご覧ください：[https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install)。

### ログイン {#logging-in}

CLIをインストールしたら、次のコマンドでログインします：

```bash
heroku login
```

正しいメールアドレスでログインしていることを確認します：

```bash
heroku auth:whoami
```

### アプリケーションの作成 {#create-an-application}

dashboard.heroku.comにアクセスしてアカウントにログインし、右上のドロップダウンから新しいアプリケーションを作成します。Herokuはリージョンやアプリケーション名などいくつかの質問をしますので、プロンプトに従ってください。

### Git

HerokuはGitを使用してアプリをデプロイするため、プロジェクトをGitリポジトリに配置する必要があります（まだの場合）。

#### Gitの初期化 {#initialize-git}

プロジェクトにGitを追加する必要がある場合は、ターミナルで次のコマンドを入力します：

```bash
git init
```

#### マスターブランチ {#main}

Herokuへのデプロイには、**main**または**master**ブランチのような一つのブランチを決めて、それを使い続ける必要があります。プッシュする前に、すべての変更がこのブランチにチェックインされていることを確認してください。

現在のブランチを確認します：

```bash
git branch
```

アスタリスクが現在のブランチを示しています。

```bash
* main
  commander
  other-branches
```

!!! note 
    `git init`を実行したばかりで出力が表示されない場合、最初にコードをコミットする必要があります。その後、`git branch`コマンドから出力が表示されます。

正しいブランチにいない場合は、次のコマンドで切り替えます（**main**の場合）：

```bash
git checkout main
```

#### 変更のコミット {#commit-changes}

このコマンドが出力を生成する場合、コミットされていない変更があります。

```bash
git status --porcelain
```

次のコマンドでコミットします：

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Herokuとの接続 {#connect-with-heroku}

アプリをHerokuと接続します（アプリの名前に置き換えてください）。

```bash
$ heroku git:remote -a your-apps-name-here
```

### ビルドパックの設定 {#set-buildpack}

HerokuにVaporの扱い方を教えるためにビルドパックを設定します。

```bash
heroku buildpacks:set vapor/vapor
```

### Swiftバージョンファイル {#swift-version-file}

追加したビルドパックは、使用するSwiftのバージョンを知るために**.swift-version**ファイルを探します。（5.8.1をプロジェクトが必要とするバージョンに置き換えてください。）

```bash
echo "5.8.1" > .swift-version
```

これにより、`5.8.1`を内容とする**.swift-version**が作成されます。

### Procfile

Herokuはアプリの実行方法を知るために**Procfile**を使用します。私たちの場合、次のようになります：

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

次のターミナルコマンドでこれを作成できます：

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### 変更のコミット {#commit-changes_1}

これらのファイルを追加しましたが、まだコミットされていません。プッシュしてもHerokuはそれらを見つけられません。

次のコマンドでコミットします。

```bash
git add .
git commit -m "adding heroku build files"
```

### Herokuへのデプロイ {#deploying-to-heroku}

デプロイの準備ができました。ターミナルからこれを実行します。ビルドに時間がかかることがありますが、これは正常です。

```bash
git push heroku main
```

### スケールアップ {#scale-up}

ビルドが成功したら、少なくとも1つのサーバーを追加する必要があります。価格はEcoプランで月額$5から始まります（[価格](https://www.heroku.com/pricing#containers)を参照）。Herokuで支払い設定が完了していることを確認してください。次に、単一のWebワーカーの場合：

```bash
heroku ps:scale web=1
```

### 継続的デプロイ {#continued-deployment}

更新したい場合は、最新の変更をmainに取り込んでHerokuにプッシュするだけで、再デプロイされます。

## Postgres

### PostgreSQLデータベースの追加 {#add-postgresql-database}

dashboard.heroku.comでアプリケーションにアクセスし、**Add-ons**セクションに移動します。

ここで`postgres`と入力すると、`Heroku Postgres`のオプションが表示されます。それを選択します。

Essential 0プランを月額$5で選択し（[価格](https://www.heroku.com/pricing#data-services)を参照）、プロビジョニングします。Herokuが残りの作業を行います。

完了すると、**Resources**タブの下にデータベースが表示されます。

### データベースの設定 {#configure-the-database}

次に、アプリがデータベースにアクセスする方法を指定する必要があります。アプリディレクトリで実行します。

```bash
heroku config
```

これにより、次のような出力が生成されます：

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

ここでの**DATABASE_URL**はPostgresデータベースを表します。この静的URLを**決して**ハードコードしないでください。Herokuはそれをローテーションし、アプリケーションが壊れます。また、これは悪い習慣です。代わりに、実行時に環境変数を読み取ります。

Heroku Postgresアドオンは、すべての接続を暗号化することを[要求](https://devcenter.heroku.com/changelog-items/2035)します。Postgresサーバーが使用する証明書はHeroku内部のものであるため、**未検証**のTLS接続を設定する必要があります。

次のスニペットは、両方を達成する方法を示しています：

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

これらの変更をコミットすることを忘れないでください：

```bash
git add .
git commit -m "configured heroku database"
```

### データベースのリバート {#reverting-your-database}

`run`コマンドを使用して、Heroku上でリバートやその他のコマンドを実行できます。

データベースをリバートするには：

```bash
heroku run App -- migrate --revert --all --yes --env production
```

マイグレーションを実行するには：

```bash
heroku run App -- migrate --env production
```