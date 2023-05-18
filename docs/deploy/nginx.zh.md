# 使用 Nginx 部署

Nginx 是一款高性能、高可靠性、易于配置的 HTTP 服务器和 HTTP 反向代理服务器。
尽管 Vapor 可以直接处理 HTTP 请求，并且支持 TLS。但将 Vapor 应用置于 Nginx 反向代理之后，可以提高性能、安全性、以及易用性。

!!! note "注意"
    我们推荐你将 Vapor 应用配置在 Nginx 的反向代理之后。

## 概述

HTTP 反向代理是什么意思？简而言之，反向代理服务器就是外部网络和你的真实的 HTTP 服务器之间的一个中间人，反向代理服务器处理所有进入的 HTTP 请求，并将它们转发给 Vapor 服务器。

反向代理的一个重要特性就是，它可以修改用户的请求，以及对其进行重定向。通过这个特性，反向代理服务器可以配置 TLS (https)、限制请求速率、甚至越过你的 Vapor 应用直接管理 Vapor 应用中的静态文件。

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### 更多细节

默认的接收 HTTP 请求的端口是 `80` (HTTPS 是 `443`)。如果你将 Vapor 服务器绑定到 `80` 端口，它就可以直接处理和响应 HTTP 请求。如果你想要使用反向代理 (比如 Nginx)，你就需要将 Vapor 服务器绑定到一个内部端口上，比如 `8080`。

!!! note "注意"
    绑定到大于 1024 的端口号无需使用 `sudo` 命令。

一旦你的 Vapor 应用被绑定到 `80` 或 `443` 以外的端口，那么外部网络将无法直接访问它 (没有配置防火墙的情况下，带上端口号仍然可以访问)。然后将 Nginx 服务器绑定到 `80` 端口上，并配置它转发请求到 `8080` 端口上的 Vapor 应用。

就这样，如果你正确配置了 Nginx，你可以看到你的 Vapor 应用已经可以响应 `80` 端口上的请求了，而外部网络和你的 Vapor 应用都不会感知到 Nginx 的存在。

## 安装 Nginx

首先是安装 Nginx。网络上有着大量资源和文档来描述如何安装 Nginx，因此在这里不再赘述。不论你使用哪个平台、操作系统、或服务供应商，你都能找到相应的文档或教程。

教程:

- [如何在 Ubuntu 14.04 LTS 上安装 Nginx?](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-14-04-lts) (英文)
- [如何在 Ubuntu 16.04 上安装 Nginx?](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04) (英文)
- [如何在 Heroku 上部署 Nginx?](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/) (英文)
- [如何在 Ubuntu 14.04 上用 Docker 容器运行 Nginx?](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-14-04) (英文)


### APT

可以通过 APT 工具安装 Nginx

```sh
sudo apt-get update
sudo apt-get install nginx
```

你可以在浏览器中访问你的服务器的 IP 地址，来检查你的 Nginx 是否被正确安装.


```sh
http://server_domain_name_or_IP
```

### Service

如何停止/启动/重启 Nginx 服务 (service)

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## 启动 Vapor

Nginx 可以通过 `sudo service nginx ...` 命令来启动或停止。同样的，你也需要一些类似的操作来启动或停止你的 Vapor 服务器。

有许多方法可以做到这一点，这通常取决于你使用的是哪个平台或系统。Supervisor 是其中一个较为通用的方式，你可以查看 [Supervisor](supervisor.md) 的配置方法，来配置启动或停止你的 Vapor 应用的命令。

## 配置 Nginx

要启用的站点的配置需要放在 `/etc/nginx/sites-enabled/` 目录下。

创建一个新的文件或者从 `/etc/nginx/sites-available/` 目录下的模版文件中拷贝一份配置，然后你就可以开始配置 Nginx 了。

这是一份配置文件的样例，它为一个 Vapor 项目进行了配置，这个项目位于 Home 目录下的一个名为 `Hello` 目录中。

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

这份配置假定你的 `Hello` 程序绑定到了 `8080` 端口上，并启用了生产模式 (production mode)。

### 管理文件

Nginx 可以越过你的 Vapor 应用，直接管理静态资源文件。这样可以为你的 Vapor 进程减轻一些不必要的压力，以提高一些性能。

```sh
server {
    ...

    # nginx 直接处理所有静态资源文件的请求，其余请求则回落 (fallback) 到 Vapor 应用
    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        ...
    }
}
```

### TLS

如果你已经获取了 TLS 证书 (certification)，那么配置 TLS 相对来说是比较简单的。如果想要获取免费的 TLS 证书，可以看看 [Let's Encrypt](https://letsencrypt.org/getting-started/)。

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

上面这份 Nginx 的 TLS 配置是相对比较严格的。其中一些配置不是必须的，但能提高安全性。
