# Déployer avec Nginx

Nginx est un serveur et proxy HTTP extrêmement rapide, éprouvé et facile à configurer. Bien que Vapor prenne en charge le service direct des requêtes HTTP avec ou sans TLS, le fait de le mettre en proxy derrière Nginx peut apporter de meilleures performances, une sécurité accrue et une plus grande facilité d'utilisation.

!!! note
    Nous recommandons de mettre les serveurs HTTP Vapor en proxy derrière Nginx.

## Vue d'ensemble

Que signifie mettre un serveur HTTP en proxy ? En résumé, un proxy agit comme un intermédiaire entre l'internet public et votre serveur HTTP. Les requêtes arrivent au proxy, qui les transmet ensuite à Vapor.

Une fonctionnalité importante de ce proxy intermédiaire est qu'il peut modifier voire rediriger les requêtes. Par exemple, le proxy peut exiger que le client utilise TLS (https), limiter le débit des requêtes, ou même servir des fichiers publics sans passer par votre application Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Plus de détails

Le port par défaut pour recevoir les requêtes HTTP est le port `80` (et `443` pour HTTPS). Lorsque vous liez un serveur Vapor au port `80`, il reçoit et répond directement aux requêtes HTTP qui arrivent sur votre serveur. Lorsque vous ajoutez un proxy comme Nginx, vous liez Vapor à un port interne, comme le port `8080`.

!!! note
    Les ports supérieurs à 1024 ne nécessitent pas `sudo` pour être liés.

Lorsque Vapor est lié à un port autre que `80` ou `443`, il ne sera pas accessible depuis l'internet extérieur. Vous liez alors Nginx au port `80` et le configurez pour router les requêtes vers votre serveur Vapor lié au port `8080` (ou tout autre port que vous avez choisi).

Et c'est tout. Si Nginx est correctement configuré, vous verrez votre application Vapor répondre aux requêtes sur le port `80`. Nginx met en proxy les requêtes et les réponses de manière invisible.

## Installer Nginx

La première étape consiste à installer Nginx. L'un des grands avantages de Nginx est la quantité considérable de ressources communautaires et de documentation qui l'entourent. Pour cette raison, nous n'entrerons pas dans les détails de l'installation de Nginx ici, car il existe presque certainement un tutoriel pour votre plateforme, système d'exploitation et fournisseur spécifiques.

Tutoriels :

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Gestionnaires de paquets

Nginx peut être installé via des gestionnaires de paquets sous Linux.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS et Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Valider l'installation

Vérifiez que Nginx a été correctement installé en visitant l'adresse IP de votre serveur dans un navigateur

```
http://server_domain_name_or_IP
```

### Service

Le service peut être démarré ou arrêté.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Démarrer Vapor

Nginx peut être démarré et arrêté avec les commandes `sudo service nginx ...`. Vous aurez besoin de quelque chose de similaire pour démarrer et arrêter votre serveur Vapor.

Il existe de nombreuses façons de faire cela, et elles dépendent de la plateforme sur laquelle vous déployez. Consultez les instructions [Supervisor](supervisor.md) pour ajouter des commandes de démarrage et d'arrêt de votre application Vapor.

## Configurer le proxy

Les fichiers de configuration des sites activés se trouvent dans `/etc/nginx/sites-enabled/`.

Créez un nouveau fichier ou copiez le modèle d'exemple depuis `/etc/nginx/sites-available/` pour commencer.

Voici un exemple de fichier de configuration pour un projet Vapor appelé `Hello` situé dans le répertoire personnel.

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

Ce fichier de configuration suppose que le projet `Hello` se lie au port `8080` lorsqu'il est démarré en mode production.

### Servir des fichiers

Nginx peut aussi servir des fichiers publics sans passer par votre application Vapor. Cela peut améliorer les performances en libérant le processus Vapor pour d'autres tâches en cas de forte charge.

```sh
server {
    ...

    # Serve all public/static files via nginx and then fallback to Vapor for the rest
    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        ...
    }
}
```

### TLS

Ajouter TLS est relativement simple tant que les certificats ont été correctement générés. Pour générer des certificats TLS gratuitement, consultez [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

La configuration ci-dessus correspond aux réglages relativement stricts pour TLS avec Nginx. Certains de ces réglages ne sont pas requis, mais renforcent la sécurité.
