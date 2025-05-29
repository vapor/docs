# Supervisor

[Supervisor](http://supervisord.org)は、Vaporアプリの起動、停止、再起動を簡単に行えるプロセス制御システムです。

## インストール {#install}

SupervisorはLinuxのパッケージマネージャーからインストールできます。

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOSとAmazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## 設定 {#configure}

サーバー上の各Vaporアプリには独自の設定ファイルが必要です。例として`Hello`プロジェクトの場合、設定ファイルは`/etc/supervisor/conf.d/hello.conf`に配置されます。

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

設定ファイルで指定されているように、`Hello`プロジェクトはユーザー`vapor`のホームフォルダに配置されています。`directory`が`Package.swift`ファイルのあるプロジェクトのルートディレクトリを指していることを確認してください。

`--env production`フラグは冗長なログを無効にします。

### 環境変数 {#environment}

supervisorを使ってVaporアプリに変数をエクスポートできます。複数の環境値をエクスポートする場合は、すべて1行に記述します。[Supervisorドキュメント](http://supervisord.org/configuration.html#program-x-section-values)によると：

> 英数字以外の文字を含む値は引用符で囲む必要があります（例：KEY="val:123",KEY2="val,456"）。それ以外の場合、値を引用符で囲むことは任意ですが推奨されます。

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

エクスポートされた変数は、Vaporで`Environment.get`を使用して利用できます。

```swift
let port = Environment.get("PORT")
```

## 起動 {#start}

これでアプリをロードして起動できます。

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
	`add`コマンドはすでにアプリを起動している可能性があります。