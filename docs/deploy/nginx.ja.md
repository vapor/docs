# Nginxでのデプロイ {#deploying-with-nginx}

Nginxは非常に高速で、実戦で証明されており、設定が簡単なHTTPサーバーおよびプロキシです。VaporはTLSありまたはなしでHTTPリクエストを直接提供することをサポートしていますが、Nginxの背後でプロキシすることで、パフォーマンス、セキュリティ、使いやすさが向上します。

!!! note
    Vapor HTTPサーバーをNginxの背後でプロキシすることをお勧めします。

## 概要 {#overview}

HTTPサーバーをプロキシするとはどういう意味でしょうか？簡単に言えば、プロキシはパブリックインターネットとあなたのHTTPサーバーの間の仲介者として機能します。リクエストはプロキシに届き、その後Vaporに送信されます。

この仲介プロキシの重要な機能は、リクエストを変更したり、リダイレクトしたりできることです。例えば、プロキシはクライアントにTLS（https）の使用を要求したり、リクエストをレート制限したり、Vaporアプリケーションと通信せずにパブリックファイルを提供したりできます。

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### 詳細 {#more-detail}

HTTPリクエストを受信するデフォルトのポートはポート`80`（HTTPSの場合は`443`）です。Vaporサーバーをポート`80`にバインドすると、サーバーに届くHTTPリクエストを直接受信して応答します。Nginxのようなプロキシを追加する場合、Vaporを`8080`のような内部ポートにバインドします。

!!! note
    1024より大きいポートはバインドに`sudo`を必要としません。

Vaporが`80`または`443`以外のポートにバインドされている場合、外部のインターネットからアクセスできません。次に、Nginxをポート`80`にバインドし、ポート`8080`（または選択したポート）にバインドされたVaporサーバーにリクエストをルーティングするように設定します。

以上です。Nginxが適切に設定されていれば、Vaporアプリがポート`80`でリクエストに応答しているのが見えるでしょう。Nginxはリクエストとレスポンスを透過的にプロキシします。

## Nginxのインストール {#install-nginx}

最初のステップはNginxのインストールです。Nginxの素晴らしい点の1つは、それを取り巻く膨大なコミュニティリソースとドキュメントです。このため、特定のプラットフォーム、OS、プロバイダー向けのチュートリアルがほぼ確実に存在するため、ここではNginxのインストールについて詳しく説明しません。

チュートリアル：

- [Ubuntu 20.04にNginxをインストールする方法](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04-ja)
- [Ubuntu 18.04にNginxをインストールする方法](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [CentOS 8にNginxをインストールする方法](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [Ubuntu 16.04にNginxをインストールする方法](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [HerokuにNginxをデプロイする方法](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### パッケージマネージャー {#package-managers}

NginxはLinux上のパッケージマネージャーを通じてインストールできます。

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOSとAmazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### インストールの検証 {#validate-installation}

ブラウザでサーバーのIPアドレスにアクセスして、Nginxが正しくインストールされたか確認します

```
http://server_domain_name_or_IP
```

### サービス {#service}

サービスは開始または停止できます。

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Vaporの起動 {#booting-vapor}

Nginxは`sudo service nginx ...`コマンドで開始と停止ができます。Vaporサーバーを開始と停止するための同様のものが必要になります。

これを行う方法は多くあり、デプロイ先のプラットフォームによって異なります。Vaporアプリを開始と停止するコマンドを追加するには、[Supervisor](supervisor.md)の手順を確認してください。

## プロキシの設定 {#configure-proxy}

有効なサイトの設定ファイルは`/etc/nginx/sites-enabled/`にあります。

新しいファイルを作成するか、`/etc/nginx/sites-available/`からサンプルテンプレートをコピーして始めます。

以下は、ホームディレクトリにある`Hello`というVaporプロジェクトの設定ファイルの例です。

```sh
server {
    server_name hello.com;
    listen 80;

    root /home/vapor/Hello/Public/;

    location @proxy {
        proxy_pass http://127.0.0.1:8080;
        proxy_pass_header Server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 10s;
    }
}
```

この設定ファイルは、`Hello`プロジェクトがプロダクションモードで起動したときにポート`8080`にバインドすることを前提としています。

### ファイルの提供 {#serving-files}

NginxはVaporアプリに尋ねることなくパブリックファイルを提供することもできます。これにより、高負荷時にVaporプロセスを他のタスクのために解放し、パフォーマンスを向上させることができます。

```sh
server {
	...

	# すべてのpublic/staticファイルをnginx経由で提供し、残りはVaporにフォールバック
	location / {
		try_files $uri @proxy;
	}

	location @proxy {
		...
	}
}
```

### TLS

証明書が適切に生成されていれば、TLSの追加は比較的簡単です。無料でTLS証明書を生成するには、[Let's Encrypt](https://letsencrypt.org/getting-started/)を確認してください。

```sh
server {
    ...

    listen 443 ssl;

    ssl_certificate /etc/letsencrypt/live/hello.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hello.com/privkey.pem;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;

    ...

    location @proxy {
       ...
    }
}
```

上記の設定は、NginxでのTLSの比較的厳格な設定です。ここにある設定の一部は必須ではありませんが、セキュリティを強化します。