# Deploying with Nginx

Nginx is an extremely fast, battle tested, and easy-to-configure HTTP server and proxy. While Vapor supports directly serving HTTP requests with or without TLS, proxying behind Nginx can provide increased performance, security, and ease-of-use. 

!!! note
    We recommend proxying Vapor HTTP servers behind Nginx.

## Overview

What does it mean to proxy an HTTP server? In short, a proxy acts as a middleman between the public internet and your HTTP server. Requests come to the proxy and then it sends them to Vapor. 

An important feature of this middleman proxy is that it can alter or even redirect the requests. For instance, the proxy can require that the client use TLS (https), rate limit requests, or even serve public files without talking to your Vapor application.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### More Detail

The default port for receiving HTTP requests is port `80` (and `443` for HTTPS). When you bind a Vapor server to port `80`, it will directly receive and respond to the HTTP requests that come to your server. When adding a proxy like Nginx, you bind Vapor to an internal port, like port `8080`. 

!!! note
    Ports greater than 1024 do not require `sudo` to bind.

When Vapor is bound to a port besides `80` or `443`, it will not be accessible to the outside internet. You then bind Nginx to port `80` and configure it to route requests to your Vapor server bound at port `8080` (or whichever port you've chosen).

And that's it. If Nginx is properly configured, you will see your Vapor app responding to requests on port `80`. Nginx proxies the requests and responses invisibly.

## Install Nginx

The first step is installing Nginx. One of the great parts of Nginx is the tremendous amount of community resources and documentation surrounding it. Because of this, we will not go into great detail here about installing Nginx as there is almost definitely a tutorial for your specific platform, OS, and provider.

Tutorials:

- [How To Install Nginx on Ubuntu 14.04 LTS](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-14-04-lts)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)
- [How To Run Nginx in a Docker Container on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-14-04)


### APT

Nginx can be installed through APT.

```sh
sudo apt-get update
sudo apt-get install nginx
```

Check whether Nginx was installed correctly by visiting your server's IP address in a browser

```sh
http://server_domain_name_or_IP
```

### Service

The service can be started or stopped.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Booting Vapor

Nginx can be started an stopped with the `sudo service nginx ...` commands. You will need something similar to start and stop your Vapor server.

There are many ways to do this, and they depend on which platform you are deploying to. Check out the [Supervisor](supervisor.md) instructions to add commands for starting and stopping your Vapor app.

## Configure Proxy

The configuration files for enabled sites can be found in `/etc/nginx/sites-enabled/`.

Create a new file or copy the example template from `/etc/nginx/sites-available/` to get started.

Here is an example configuration file for a Vapor project called `Hello` in the home directory.

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

This configuration file assumes the `Hello` project binds to port `8080` when started in production mode.

### Serving Files

Nginx can also serve public files without asking your Vapor app. This can improve performance by freeing up the Vapor process for other tasks under heavy load.

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

Adding TLS is relatively straightforward as long as the certificates have been properly generated. To generate TLS certificates for free, check out [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

The configuration above are the relatively strict settings for TLS with Nginx. Some of the settings here are not required, but enhance security.
