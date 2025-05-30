# Systemd

Systemdは、ほとんどのLinuxディストリビューションにおけるデフォルトのシステムおよびサービスマネージャーです。通常はデフォルトでインストールされているため、サポートされているSwiftディストリビューションでは追加のインストールは必要ありません。

## 設定 {#configure}

サーバー上の各Vaporアプリには独自のサービスファイルが必要です。例えば`Hello`プロジェクトの場合、設定ファイルは`/etc/systemd/system/hello.service`に配置されます。このファイルは以下のようになります：

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/App serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

設定ファイルで指定されているように、`Hello`プロジェクトはユーザー`vapor`のホームフォルダーに配置されています。`WorkingDirectory`が`Package.swift`ファイルがあるプロジェクトのルートディレクトリを指していることを確認してください。

`--env production`フラグは詳細なログ出力を無効にします。

### 環境変数 {#environment}
値のクォートは任意ですが、推奨されます。

systemd経由で変数をエクスポートする方法は2つあります。すべての変数が設定された環境ファイルを作成する方法：

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```

または、`[service]`セクションの下のサービスファイルに直接追加する方法：

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
エクスポートされた変数は、`Environment.get`を使用してVaporで使用できます

```swift
let port = Environment.get("PORT")
```

## 起動 {#start}

rootとして以下のコマンドを実行することで、アプリのロード、有効化、開始、停止、再起動ができます。

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```