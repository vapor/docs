---
currentMenu: deploy-nginx
---

# 使用 Nginx 部署 （Deploying with Nginx）

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Nginx是一个非常快的、经过测试的、易于配置的 HTTP 服务器和代理。然后 Vapor 支持直接提供带有或者不带有 TLS 的 HTTP 请求服务，但是使用 Nginx 代理能够提高性能、安全性和易用性。

> 注意：我们建议使用 Nginx 代理 Vapor HTTP server。

## Overview

代理一个服务器是什么？简单的说，代理扮演从公网到你的 HTTP server 之间的一个中间件。Request 先到达代理，然后再发送它们到你的 Vapor。

这个中间的代理一个很重要的特性是能够修改甚至重定向 request。例如，代理可以要求客户端使用TLS（https），限制请求速率，甚至提供公共文件，而不与您的Vapor应用程序通信

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### More Detail

接收 HTTP request 的默认端口是 `80` (和 `443` for HTTPS)。当你绑定 Vapor server 到 `80` 端口。它将直接接收和响应到你的服务器的请求。当添加了代理例如 Nginx，需要绑定 Vapor 到一个内部端口，例如 `8080` 端口。

> 注意：大于 1024 的端口绑定的时候不需要使用 `sudo`。

当 Vapor 绑定到除了80或者443之外的端口，它是外网不能够访问的。然后你绑定 Nginx 到 `80` 端口，并且配置它将 request 路由到你的 绑定了 `8080` 端口（或者其他你选择的端口）的 Vapor server。

如果你正确的配置了 Nginx，你将看到你的 Vapor app 在 `80` 端口上响应请求。Nginx 代理对请求和响应是不可见的。

## Install Nginx

第一步是安装 Nginx。Nginx 的一个很大的部分是大量的社区资源和文档。因此，我们不会在这里详细介绍安装 Nginx，这里我们对您的特定平台，操作系统提供了教程。

Tutorials:
- [How To Install Nginx on Ubuntu 14.04 LTS](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-14-04-lts)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)
- [How To Run Nginx in a Docker Container on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-14-04)


### APT

Nginx 可以通过 APT 安装。

```sh
sudo apt-get update
sudo apt-get install nginx
```

可以在浏览器里访问你的服务器 ip，验证 Nginx 是否安装成功。

```sh
http://server_domain_name_or_IP
```

### Service

service 能够被启动或者停止。

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## 启动 Vapor （Booting Vapor）

可以使用 `sudo service nginx ...` 命令启动一个停止的 Nginx。您将需要类似的启动和停止您的 Vapor 服务器。

根据你部署平台的不同，有不同的方法去做这个。查看 [Supervisor](supervisor.md)指令，添加用于启动和停止 Vapor 应用程序的命令。

## 配置代理 （Configure Proxy）

可用的 site 的配置文件可以在 `/etc/nginx/sites-enabled/` 中找到。

Create a new file or copy the example template from `/etc/nginx/sites-available/` to get started.
创建一个新文件或者从 `/etc/nginx/sites-available/` 复制一个模板，然后开始。

这是一个在 home 目录的叫 `Hello` 的 Vapor 项目的配置文件的例子。

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
        proxy_pass_header Server;
        proxy_connect_timeout 3s;
        proxy_read_timeout 10s;
    }
}
```

这个配置文件假设  `Hello` 项目在生产模式下启动的时候会绑定到 `8080` 端口。

### 文件服务 （Serving Files）

Nginx也可以提供 public 文件，而不需要访问你的 Vapor 应用。这个可以在重负载的情况下，通过释放 Vapor 任务来提高性能。

```sh
server {
	...

	# Serve all public/static files via nginx and then fallback to Vapor for the rest
    try_files $uri @proxy;

	location @proxy {
		...
	}
}
```

### TLS

添加TLS相对简单，只要证书（certificates）已正确生成添加即可。要生成免费的 TLS 证书（certificates），访问 [Let's Encrypt](https://letsencrypt.org/getting-started/)。

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

上面的配置是使用 Nginx 的 TLS 的相对严格详细的设置。其中的许多配置不是必须的，但是配置后会增强安全性。
