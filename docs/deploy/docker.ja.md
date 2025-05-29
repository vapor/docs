# Docker デプロイ {#docker-deploys}

Docker を使用して Vapor アプリをデプロイすることには、いくつかの利点があります：

1. Docker 化されたアプリは、Docker デーモンを持つあらゆるプラットフォーム（Linux（CentOS、Debian、Fedora、Ubuntu）、macOS、Windows）で同じコマンドを使用して確実に起動できます。
2. docker-compose や Kubernetes マニフェストを使用して、完全なデプロイメントに必要な複数のサービス（Redis、Postgres、nginx など）をオーケストレーションできます。
3. 開発マシン上でもローカルで、アプリの水平スケーリング能力を簡単にテストできます。

このガイドでは、Docker 化されたアプリをサーバーに配置する方法の説明は省略します。最も簡単なデプロイは、サーバーに Docker をインストールし、開発マシンでアプリケーションを起動するのと同じコマンドを実行することです。

より複雑で堅牢なデプロイメントは、通常、ホスティングソリューションによって異なります。AWS のような多くの人気のあるソリューションには、Kubernetes のビルトインサポートやカスタムデータベースソリューションがあり、すべてのデプロイメントに適用されるベストプラクティスを書くことが困難です。

それでも、Docker を使用してサーバースタック全体をローカルで起動してテストすることは、大小問わずサーバーサイドアプリにとって非常に価値があります。さらに、このガイドで説明する概念は、すべての Docker デプロイメントに大まかに適用されます。

## セットアップ {#set-up}

Docker を実行するための開発環境をセットアップし、Docker スタックを構成するリソースファイルの基本的な理解を得る必要があります。

### Docker のインストール {#install-docker}

開発環境用に Docker をインストールする必要があります。Docker Engine Overview の [Supported Platforms](https://docs.docker.com/install/#supported-platforms) セクションで、任意のプラットフォームの情報を見つけることができます。Mac OS を使用している場合は、[Docker for Mac](https://docs.docker.com/docker-for-mac/install/) のインストールページに直接ジャンプできます。

### テンプレートの生成 {#generate-template}

Vapor テンプレートを出発点として使用することをお勧めします。既にアプリがある場合は、既存のアプリを Docker 化する際の参照ポイントとして、以下で説明するようにテンプレートを新しいフォルダにビルドしてください。テンプレートから主要なリソースをアプリにコピーし、出発点として少し調整できます。

1. Vapor Toolbox をインストールまたはビルドします（[macOS](../install/macos.md#install-toolbox)、[Linux](../install/linux.md#install-toolbox)）。
2. `vapor new my-dockerized-app` で新しい Vapor アプリを作成し、プロンプトに従って関連する機能を有効または無効にします。これらのプロンプトへの回答は、Docker リソースファイルの生成方法に影響します。

## Docker リソース {#docker-resources}

今すぐでも近い将来でも、[Docker Overview](https://docs.docker.com/engine/docker-overview/) に慣れることは価値があります。概要では、このガイドで使用するいくつかの重要な用語が説明されています。

テンプレート Vapor アプリには、2つの重要な Docker 固有のリソースがあります：**Dockerfile** と **docker-compose** ファイルです。

### Dockerfile

Dockerfile は、Docker 化されたアプリのイメージをビルドする方法を Docker に指示します。そのイメージには、アプリの実行可能ファイルと、それを実行するために必要なすべての依存関係が含まれています。Dockerfile をカスタマイズする際は、[完全なリファレンス](https://docs.docker.com/engine/reference/builder/)を開いておくことをお勧めします。

Vapor アプリ用に生成された Dockerfile には2つのステージがあります。最初のステージはアプリをビルドし、結果を含む保持領域を設定します。2番目のステージは、安全なランタイム環境の基本を設定し、保持領域内のすべてを最終イメージ内の配置場所に転送し、デフォルトポート（8080）でプロダクションモードでアプリを実行するデフォルトのエントリポイントとコマンドを設定します。この設定は、イメージを使用するときに上書きできます。

### Docker Compose ファイル {#docker-compose-file}

Docker Compose ファイルは、Docker が複数のサービスを相互に関連付けてビルドする方法を定義します。Vapor アプリテンプレートの Docker Compose ファイルは、アプリをデプロイするために必要な機能を提供しますが、詳細を学びたい場合は、利用可能なすべてのオプションの詳細が記載されている[完全なリファレンス](https://docs.docker.com/compose/compose-file/)を参照してください。

!!! note
    最終的に Kubernetes を使用してアプリをオーケストレーションする予定がある場合、Docker Compose ファイルは直接関係ありません。ただし、Kubernetes マニフェストファイルは概念的に似ており、[Docker Compose ファイルの移植](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)を目的としたプロジェクトもあります。

新しい Vapor アプリの Docker Compose ファイルは、アプリの実行、マイグレーションの実行または元に戻す、およびアプリの永続レイヤーとしてデータベースを実行するためのサービスを定義します。正確な定義は、`vapor new` を実行したときに選択したデータベースによって異なります。

Docker Compose ファイルの上部付近に共有環境変数があることに注意してください。（Fluent を使用しているかどうか、および使用している場合はどの Fluent ドライバーを使用しているかによって、デフォルト変数のセットが異なる場合があります。）

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

これらは、`<<: *shared_environment` YAML 参照構文で複数のサービスに取り込まれているのがわかります。

`DATABASE_HOST`、`DATABASE_NAME`、`DATABASE_USERNAME`、および `DATABASE_PASSWORD` 変数はこの例ではハードコードされていますが、`LOG_LEVEL` はサービスを実行している環境から値を取得するか、その変数が設定されていない場合は `'debug'` にフォールバックします。

!!! note
    ユーザー名とパスワードのハードコーディングはローカル開発では許容されますが、本番デプロイメントではこれらの変数をシークレットファイルに保存する必要があります。本番環境でこれを処理する1つの方法は、シークレットファイルをデプロイを実行している環境にエクスポートし、Docker Compose ファイルで次のような行を使用することです：

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    これにより、ホストで定義されている環境変数がコンテナに渡されます。

その他の注意点：

- サービスの依存関係は `depends_on` 配列で定義されます。
- サービスポートは `ports` 配列でサービスを実行しているシステムに公開されます（`<host_port>:<service_port>` の形式）。
- `DATABASE_HOST` は `db` として定義されています。これは、アプリが `http://db:5432` でデータベースにアクセスすることを意味します。これは、Docker がサービスで使用されるネットワークを起動し、そのネットワーク上の内部 DNS が `db` という名前を `'db'` という名前のサービスにルーティングするため機能します。
- Dockerfile の `CMD` ディレクティブは、一部のサービスで `command` 配列によって上書きされます。`command` で指定されたものは、Dockerfile の `ENTRYPOINT` に対して実行されることに注意してください。
- Swarm モード（詳細は後述）では、サービスはデフォルトで1つのインスタンスが与えられますが、`migrate` と `revert` サービスは `deploy` `replicas: 0` を持つように定義されているため、Swarm を実行するときにデフォルトでは起動しません。

## ビルド {#building}

Docker Compose ファイルは、アプリをビルドする方法（現在のディレクトリの Dockerfile を使用）と、結果のイメージに付ける名前（`my-dockerized-app:latest`）を Docker に指示します。後者は実際には名前（`my-dockerized-app`）とタグ（`latest`）の組み合わせで、タグは Docker イメージのバージョン管理に使用されます。

アプリの Docker イメージをビルドするには、アプリのプロジェクトのルートディレクトリ（`docker-compose.yml` を含むフォルダ）から以下を実行します：

```shell
docker compose build
```

開発マシンで以前にビルドしていても、アプリとその依存関係を再度ビルドする必要があることがわかります。Docker が使用している Linux ビルド環境でビルドされているため、開発マシンからのビルドアーティファクトは再利用できません。

完了すると、以下を実行したときにアプリのイメージが表示されます：

```shell
docker image ls
```

## 実行 {#running}

サービスのスタックは Docker Compose ファイルから直接実行することも、Swarm モードや Kubernetes などのオーケストレーションレイヤーを使用することもできます。

### スタンドアロン {#standalone}

アプリを実行する最も簡単な方法は、スタンドアロンコンテナとして起動することです。Docker は `depends_on` 配列を使用して、依存するサービスも開始されることを確認します。

まず、以下を実行します：

```shell
docker compose up app
```

`app` と `db` の両方のサービスが開始されることに注意してください。

アプリはポート 8080 でリッスンしており、Docker Compose ファイルで定義されているように、開発マシンで **http://localhost:8080** でアクセスできます。

このポートマッピングの区別は非常に重要です。なぜなら、すべてが独自のコンテナで実行され、それぞれがホストマシンに異なるポートを公開している場合、同じポートで任意の数のサービスを実行できるからです。

`http://localhost:8080` にアクセスすると `It works!` が表示されますが、`http://localhost:8080/todos` にアクセスすると以下が表示されます：

```
{"error":true,"reason":"Something went wrong."}
```

`docker compose up app` を実行したターミナルのログ出力を見ると、以下が表示されます：

```
[ ERROR ] relation "todos" does not exist
```

もちろん！データベースでマイグレーションを実行する必要があります。`Ctrl+C` を押してアプリを停止します。今度は以下でアプリを再起動します：

```shell
docker compose up --detach app
```

これで、アプリは「デタッチ」（バックグラウンド）で起動します。以下を実行して確認できます：

```shell
docker container ls
```

データベースとアプリの両方がコンテナで実行されているのがわかります。以下を実行してログを確認することもできます：

```shell
docker logs <container_id>
```

マイグレーションを実行するには、以下を実行します：

```shell
docker compose run migrate
```

マイグレーションが実行された後、`http://localhost:8080/todos` に再度アクセスすると、エラーメッセージの代わりに空の todos リストが表示されます。

#### ログレベル {#log-levels}

上記で説明したように、Docker Compose ファイルの `LOG_LEVEL` 環境変数は、利用可能な場合、サービスが開始される環境から継承されます。

以下でサービスを起動できます：

```shell
LOG_LEVEL=trace docker-compose up app
```

`trace` レベルのロギング（最も詳細）を取得します。この環境変数を使用して、ロギングを[利用可能な任意のレベル](../basics/logging.md#levels)に設定できます。

#### すべてのサービスログ {#all-service-logs}

コンテナを起動するときにデータベースサービスを明示的に指定すると、データベースとアプリの両方のログが表示されます。

```shell
docker-compose up app db
```

#### スタンドアロンコンテナの停止 {#bringing-standalone-containers-down}

ホストシェルから「デタッチ」されて実行されているコンテナがあるので、何らかの方法でシャットダウンを指示する必要があります。実行中のコンテナは以下でシャットダウンを要求できることを知っておく価値があります：

```shell
docker container stop <container_id>
```

しかし、これらの特定のコンテナを停止する最も簡単な方法は以下です：

```shell
docker-compose down
```

#### データベースのワイプ {#wiping-the-database}

Docker Compose ファイルは、実行間でデータベースを永続化するために `db_data` ボリュームを定義しています。データベースをリセットする方法はいくつかあります。

コンテナを停止すると同時に `db_data` ボリュームを削除できます：

```shell
docker-compose down --volumes
```

`docker volume ls` で現在データを永続化しているボリュームを確認できます。ボリューム名は通常、Swarm モードで実行していたかどうかに応じて、`my-dockerized-app_` または `test_` のプレフィックスが付いていることに注意してください。

これらのボリュームは、例えば以下で1つずつ削除できます：

```shell
docker volume rm my-dockerized-app_db_data
```

以下ですべてのボリュームをクリーンアップすることもできます：

```shell
docker volume prune
```

保持しておきたいデータのあるボリュームを誤って削除しないように注意してください！

Docker は、実行中または停止したコンテナで現在使用されているボリュームを削除することはできません。`docker container ls` で実行中のコンテナのリストを取得でき、`docker container ls -a` で停止したコンテナも確認できます。

### Swarm モード {#swarm-mode}

Swarm モードは、Docker Compose ファイルが手元にあり、アプリが水平方向にどのようにスケールするかをテストしたい場合に使用する簡単なインターフェースです。Swarm モードのすべてについては、[概要](https://docs.docker.com/engine/swarm/)をルートとするページで読むことができます。

最初に必要なのは、Swarm のマネージャーノードです。以下を実行します：

```shell
docker swarm init
```

次に、Docker Compose ファイルを使用して、サービスを含む `'test'` という名前のスタックを起動します：

```shell
docker stack deploy -c docker-compose.yml test
```

サービスがどのようになっているかは以下で確認できます：

```shell
docker service ls
```

`app` と `db` サービスには `1/1` レプリカ、`migrate` と `revert` サービスには `0/0` レプリカが表示されるはずです。

Swarm モードでマイグレーションを実行するには、別のコマンドを使用する必要があります。

```shell
docker service scale --detach test_migrate=1
```

!!! note
    短命なサービスに1つのレプリカにスケールするよう要求しました。正常にスケールアップし、実行し、その後終了します。ただし、これにより `0/1` レプリカが実行されたままになります。マイグレーションを再度実行するまでは大した問題ではありませんが、すでにその状態にある場合は「1つのレプリカにスケールアップ」するように指示することはできません。このセットアップの特徴は、同じ Swarm ランタイム内で次回マイグレーションを実行したい場合、最初にサービスを `0` にスケールダウンしてから `1` に戻す必要があることです。

この短いガイドの文脈での苦労の見返りは、データベースの競合、クラッシュなどをどれだけうまく処理するかをテストするために、アプリを必要なものにスケールできることです。

アプリの5つのインスタンスを同時に実行したい場合は、以下を実行します：

```shell
docker service scale test_app=5
```

Docker がアプリをスケールアップするのを見るだけでなく、`docker service ls` を再度確認することで、実際に5つのレプリカが実行されていることを確認できます。

アプリのログを表示（およびフォロー）できます：

```shell
docker service logs -f test_app
```

#### Swarm サービスの停止 {#bringing-swarm-services-down}

Swarm モードでサービスを停止したい場合は、以前に作成したスタックを削除することで行います。

```shell
docker stack rm test
```

## 本番デプロイ {#production-deploys}

冒頭で述べたように、このガイドでは Docker 化されたアプリを本番環境にデプロイする方法について詳しく説明しません。なぜなら、このトピックは大規模であり、ホスティングサービス（AWS、Azure など）、ツール（Terraform、Ansible など）、オーケストレーション（Docker Swarm、Kubernetes など）によって大きく異なるからです。

ただし、開発マシンで Docker 化されたアプリをローカルで実行するために学ぶテクニックは、本番環境に大部分転用できます。docker デーモンを実行するように設定されたサーバーインスタンスは、すべて同じコマンドを受け入れます。

プロジェクトファイルをサーバーにコピーし、サーバーに SSH 接続し、`docker-compose` または `docker stack deploy` コマンドを実行してリモートで起動します。

または、ローカルの `DOCKER_HOST` 環境変数をサーバーを指すように設定し、マシンでローカルに `docker` コマンドを実行します。このアプローチでは、プロジェクトファイルをサーバーにコピーする必要はありません*が*、サーバーがプルできる場所に docker イメージをホストする必要があることに注意することが重要です。