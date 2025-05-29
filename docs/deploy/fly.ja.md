# Fly

Flyは、エッジコンピューティングに焦点を当てたサーバーアプリケーションとデータベースの実行を可能にするホスティングプラットフォームです。詳細については[公式サイト](https://fly.io/)をご覧ください。

!!! note
    このドキュメントで指定されるコマンドは[Flyの価格設定](https://fly.io/docs/about/pricing/)の対象となります。続行する前に適切に理解しておいてください。

## サインアップ {#signing-up}
アカウントをお持ちでない場合は、[アカウントを作成](https://fly.io/app/sign-up)する必要があります。

## flyctlのインストール {#installing-flyctl}
Flyとやり取りする主な方法は、専用のCLIツール`flyctl`を使用することです。これをインストールする必要があります。

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### その他のインストールオプション {#other-install-options}
その他のオプションと詳細については、[`flyctl`インストールドキュメント](https://fly.io/docs/flyctl/install/)をご覧ください。

## ログイン {#logging-in}
ターミナルからログインするには、次のコマンドを実行します：
```bash
fly auth login
```

## Vaporプロジェクトの設定 {#configuring-your-vapor-project}
Flyにデプロイする前に、Flyがアプリをビルドするために必要なDockerfileが適切に設定されたVaporプロジェクトがあることを確認する必要があります。ほとんどの場合、デフォルトのVaporテンプレートにはすでにDockerfileが含まれているため、これは非常に簡単です。

### 新しいVaporプロジェクト {#new-vapor-project}
新しいプロジェクトを作成する最も簡単な方法は、テンプレートから始めることです。GitHubテンプレートまたはVaporツールボックスを使用して作成できます。データベースが必要な場合は、PostgresでFluentを使用することをお勧めします。Flyでは、アプリが接続できるPostgresデータベースを簡単に作成できます（下記の[専用セクション](#configuring-postgres)を参照）。

#### Vaporツールボックスを使用 {#using-the-vapor-toolbox}
まず、Vaporツールボックスがインストールされていることを確認してください（[macOS](../install/macos.md#install-toolbox)または[Linux](../install/linux.md#install-toolbox)のインストール手順を参照）。
次のコマンドで新しいアプリを作成し、`app-name`を希望のアプリ名に置き換えてください：
```bash
vapor new app-name
```

このコマンドは、Vaporプロジェクトを設定できる対話型プロンプトを表示します。ここでFluentとPostgresが必要な場合は選択できます。

#### GitHubテンプレートを使用 {#using-github-templates}
以下のリストから、ニーズに最も適したテンプレートを選択してください。Gitを使用してローカルにクローンするか、「Use this template」ボタンでGitHubプロジェクトを作成できます。

- [ベアボーンテンプレート](https://github.com/vapor/template-bare)
- [Fluent/Postgresテンプレート](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leafテンプレート](https://github.com/vapor/template-fluent-postgres-leaf)

### 既存のVaporプロジェクト {#existing-vapor-project}
既存のVaporプロジェクトがある場合は、ディレクトリのルートに適切に設定された`Dockerfile`があることを確認してください。[VaporのDockerに関するドキュメント](../deploy/docker.md)と[FlyのDockerfileを介したアプリのデプロイに関するドキュメント](https://fly.io/docs/languages-and-frameworks/dockerfile/)が役立つかもしれません。

## Flyでアプリを起動する {#launch-your-app-on-fly}
Vaporプロジェクトの準備ができたら、Flyで起動できます。

まず、現在のディレクトリがVaporアプリケーションのルートディレクトリに設定されていることを確認し、次のコマンドを実行します：
```bash
fly launch
```

これにより、Flyアプリケーション設定を構成するための対話型プロンプトが開始されます：

- **名前：** 名前を入力するか、空白のままにして自動生成された名前を取得できます。
- **リージョン：** デフォルトは最も近いリージョンです。これを使用するか、リストの他のリージョンを選択できます。これは後で簡単に変更できます。
- **データベース：** アプリで使用するデータベースをFlyに作成するよう依頼できます。希望する場合は、後で`fly pg create`と`fly pg attach`コマンドを使用して同じことができます（詳細については[Postgresの設定セクション](#configuring-postgres)を参照）。

`fly launch`コマンドは自動的に`fly.toml`ファイルを作成します。これには、プライベート/パブリックポートマッピング、ヘルスチェックパラメータなどの設定が含まれています。`vapor new`を使用してゼロから新しいプロジェクトを作成した場合、デフォルトの`fly.toml`ファイルは変更不要です。既存のプロジェクトがある場合も、`fly.toml`は変更なしまたは軽微な変更のみで問題ない可能性があります。詳細については[`fly.toml`ドキュメント](https://fly.io/docs/reference/configuration/)をご覧ください。

Flyにデータベースの作成を依頼した場合、データベースが作成されてヘルスチェックを通過するまで少し待つ必要があることに注意してください。

終了する前に、`fly launch`コマンドはアプリをすぐにデプロイするかどうか尋ねます。承諾するか、後で`fly deploy`を使用してデプロイできます。

!!! tip
    現在のディレクトリがアプリのルートにある場合、fly CLIツールは`fly.toml`ファイルの存在を自動的に検出し、どのアプリをターゲットにしているかをFlyに知らせます。現在のディレクトリに関係なく特定のアプリをターゲットにしたい場合は、ほとんどのFlyコマンドに`-a name-of-your-app`を追加できます。

## デプロイ {#deploying}
Flyに新しい変更をデプロイする必要があるときはいつでも`fly deploy`コマンドを実行します。

Flyはディレクトリの`Dockerfile`と`fly.toml`ファイルを読み取り、Vaporプロジェクトのビルドと実行方法を決定します。

コンテナがビルドされると、Flyはそのインスタンスを開始します。アプリケーションが正常に動作し、サーバーがリクエストに応答することを確認するため、さまざまなヘルスチェックを実行します。ヘルスチェックが失敗した場合、`fly deploy`コマンドはエラーで終了します。

デフォルトでは、デプロイしようとした新しいバージョンのヘルスチェックが失敗した場合、Flyはアプリの最新の動作バージョンにロールバックします。

## Postgresの設定 {#configuring-postgres}

### FlyでPostgresデータベースを作成する {#creating-a-postgres-database-on-fly}
アプリを最初に起動したときにデータベースアプリを作成しなかった場合は、後で次のコマンドを使用して作成できます：
```bash
fly pg create
```

このコマンドは、Fly上の他のアプリが利用できるデータベースをホストできるFlyアプリを作成します。詳細については[専用のFlyドキュメント](https://fly.io/docs/postgres/)をご覧ください。

データベースアプリが作成されたら、Vaporアプリのルートディレクトリに移動して次を実行します：
```bash
fly pg attach name-of-your-postgres-app
```
Postgresアプリの名前がわからない場合は、`fly pg list`で確認できます。

`fly pg attach`コマンドは、アプリ用のデータベースとユーザーを作成し、`DATABASE_URL`環境変数を通じてアプリに公開します。

!!! note
    `fly pg create`と`fly pg attach`の違いは、前者がPostgresデータベースをホストできるFlyアプリを割り当てて設定するのに対し、後者は選択したアプリ用の実際のデータベースとユーザーを作成することです。要件に適合する場合、単一のPostgres Flyアプリが様々なアプリで使用される複数のデータベースをホストできます。`fly launch`でFlyにデータベースアプリの作成を依頼すると、`fly pg create`と`fly pg attach`の両方を呼び出すのと同等の処理が行われます。

### VaporアプリをデータベースにAndroidする {#connecting-your-vapor-app-to-the-database}
アプリがデータベースにアタッチされると、Flyは`DATABASE_URL`環境変数に資格情報を含む接続URLを設定します（機密情報として扱う必要があります）。

最も一般的なVaporプロジェクトの設定では、`configure.swift`でデータベースを設定します。以下は設定例です：

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // ここでDATABASE_URLが欠落している場合の処理...
    //
    // または、app.environmentが`.development`か
    // `.production`に設定されているかによって
    // 異なる設定を行うこともできます
}
```

この時点で、プロジェクトはマイグレーションを実行し、データベースを使用する準備ができているはずです。

### マイグレーションの実行 {#running-migrations}
`fly.toml`の`release_command`を使用すると、メインサーバープロセスを実行する前に特定のコマンドを実行するようFlyに依頼できます。`fly.toml`に以下を追加します：
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    上記のコードスニペットは、アプリの`ENTRYPOINT`を`./App`に設定するデフォルトのVapor Dockerfileを使用していることを前提としています。具体的には、`release_command`を`migrate -y`に設定すると、Flyは`./App migrate -y`を呼び出します。`ENTRYPOINT`が異なる値に設定されている場合は、`release_command`の値を適応させる必要があります。

Flyは、内部Flyネットワーク、シークレット、環境変数にアクセスできる一時的なインスタンスでリリースコマンドを実行します。

リリースコマンドが失敗した場合、デプロイは続行されません。

### その他のデータベース {#other-databases}
FlyはPostgresデータベースアプリを簡単に作成できますが、他のタイプのデータベースもホストすることが可能です（例えば、Flyドキュメントの["MySQLデータベースを使用する"](https://fly.io/docs/app-guides/mysql-on-fly/)を参照）。

## シークレットと環境変数 {#secrets-and-environment-variables}
### シークレット {#secrets}
シークレットを使用して、機密値を環境変数として設定します。
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    ほとんどのシェルは入力したコマンドの履歴を保持することに留意してください。この方法でシークレットを設定する場合は注意してください。一部のシェルは、空白で始まるコマンドを記憶しないように設定できます。[`fly secrets import`コマンド](https://fly.io/docs/flyctl/secrets-import/)も参照してください。

詳細については、[`fly secrets`のドキュメント](https://fly.io/docs/apps/secrets/)をご覧ください。

### 環境変数 {#environment-variables}
その他の機密でない[環境変数は`fly.toml`で設定](https://fly.io/docs/reference/configuration/#the-env-variables-section)できます。例：
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH接続 {#ssh-connection}
次のコマンドでアプリのインスタンスに接続できます：
```bash
fly ssh console -s
```

## ログの確認 {#checking-the-logs}
次のコマンドでアプリのライブログを確認できます：
```bash
fly logs
```

## 次のステップ {#next-steps}
Vaporアプリがデプロイされたら、複数のリージョンにわたってアプリを垂直的および水平的にスケーリングしたり、永続ボリュームを追加したり、継続的デプロイメントを設定したり、分散アプリクラスターを作成したりするなど、さらに多くのことができます。これらすべてを行う方法を学ぶ最良の場所は[Flyドキュメント](https://fly.io/docs/)です。