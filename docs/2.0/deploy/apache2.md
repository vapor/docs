# Deploying with Apache2

[Apache2](https://httpd.apache.org/) is an effort to develop and maintain an open-source HTTP server for modern operating systems including UNIX and Windows. While Vapor supports directly serving HTTP requests with or without TLS, proxying behind Apache2 can provide increased performance, security, and ease-of-use. 

!!! note
    This page is for proxying behind Apache2. The recommened method is proxying Vapor HTTP servers behind [Nginx](nginx.md).

## Overview

What does it mean to proxy an HTTP server? In short, a proxy acts as a middleman between the public internet and your HTTP server. Requests come to the proxy and then it sends them to Vapor. 

An important feature of this middleman proxy is that it can alter or even redirect the requests. For instance, the proxy can require that the client use TLS (https), rate limit requests, or even serve public files without talking to your Vapor application.

![apache2-proxy](https://user-images.githubusercontent.com/2223276/28477961-5e32bafc-6e24-11e7-94f1-a09c59673d1f.png)

### More Detail

The default port for receiving HTTP requests is port `80` (and `443` for HTTPS). When you bind a Vapor server to port `80`, it will directly receive and respond to the HTTP requests that come to your server. When adding a proxy like Apache2, you bind Vapor to an internal port, like port `8080`. 

!!! note
    Ports greater than 1024 do not require `sudo` to bind.

When Vapor is bound to a port besides `80` or `443`, it will not be accessible to the outside internet. You then bind Apache2 to port `80` and configure it to route requests to your Vapor server bound at port `8080` (or whichever port you've chosen).

And that's it. If Apache2 is properly configured, you will see your Vapor app responding to requests on port `80`. Apache2 proxies the requests and responses invisibly.

## Install Apache2

The first step is installing Apache2. One of the great parts of Apache2 is the tremendous amount of community resources and documentation surrounding it. Because of this, we will not go into great detail here about installing Apache2 as there is almost definitely a tutorial for your specific platform, OS, and provider.

Tutorials:

- [How To Set Up Apache Virtual Hosts on Ubuntu 14.04 LTS](https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts)
- [How To Set Up Apache Virtual Hosts on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04)

### APT

Apache2 can be installed through APT.

```sh
sudo apt-get update
sudo apt-get install apache2
```

Check whether Apache2 was installed correctly by visiting your server's IP address in a browser

```sh
http://server_domain_name_or_IP
```

### Service

The service can be started or stopped.

```sh
sudo service apache2 stop
sudo service apache2 start
sudo service apache2 restart
```

## Booting Vapor

Apache2 can be started an stopped with the `sudo service apache2 ...` commands. You will need something similar to start and stop your Vapor server.

There are many ways to do this, and they depend on which platform you are deploying to. Check out the [Supervisor](supervisor.md) and [Nginx](nginx.md) instructions to add commands for starting and stopping your Vapor app.

## Configure Proxy

The configuration files for enabled sites can be found in `/etc/apache2/sites-enabled/`.

Create a new file or copy the example template from `/etc/apache2/sites-available/` to get started.

Here is an example configuration file for a Vapor project called `Hello` in the home directory.

```apache
# example.com Configuration

<VirtualHost *:80>
    DocumentRoot /home/vapor/Hello/Public/
    ServerName hello.com
    
    # Using ProxyPass will send the following headers:
    #   X-Forwarded-For: The IP address of the client.
    #   X-Forwarded-Host: The original host requested by the client in the Host HTTP request header.
    #   X-Forwarded-Server The hostname of the proxy server.
    
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
    
    ProxyTimeout 3
</VirtualHost>  
```

This configuration file assumes the `Hello` project binds to port `8080` when started in production mode.

### Serving Files

Apache2 can also serve public files without asking your Vapor app. This can improve performance by freeing up the Vapor process for other tasks under heavy load.

```apache
<VirtualHost *:80>
    ...
    
    ProxyPreserveHost On
    # Serve all files in Public folder directly, bypassing proxy (this must be before ProxyPass /)
    ProxyPass /Public !
    ProxyPass / http://127.0.0.1:8080/
    
    ...
</VirtualHost>
```

### TLS

Adding TLS is relatively straightforward as long as the certificates have been properly generated. To generate TLS certificates for free, check out [Let's Encrypt](https://letsencrypt.org/getting-started/).

```apache
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ...
    
    SSLCertificateFile /etc/letsencrypt/live/hello.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/hello.com/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
```

The configuration above match the settings for TLS generated by Let's Encrypt for Apache2.
