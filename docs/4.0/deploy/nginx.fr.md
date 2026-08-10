# Déployer avec Nginx

Nginx est un serveur HTTP et proxy extrêmement rapide, éprouvé, et facile à configuré. Bien que Vapor puisse recevoir des requêtes HTTP directement avec ou sans TLS, placer votre application derrière un proxy Nginx peut améliorer les performances, la sécurité, et simplifier son utilisation. 

!!! Note
    Nous recommandons de placer les serveurs HTTP Vapor derrière un proxy Nginx.

## Aperçu

Que signifie placer un serveur HTTP derrière un proxy ? En résumé, un proxy agit comme intermédiaire entre l'internet publique et votre serveur HTTP. Les requêtes arrivent au proxy qui les envoie ensuite à Vapor. 

Une fonctionnalité majeure de ce proxy intermédiaire est sa capacité à modifier ou même rediriger les requêtes. Par exemple, le proxy peut forcer le client à utiliser TLS (https), limiter le nombre de requêtes par secondes, ou même servir des fichiers publiques sans communiquer avec votre application Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Plus de détails

Le port de réception pour les requêtes HTTP est le port `80` par défaut (et `443` pour HTTPS). Lorsque vous couplez une application Vapor au port `80`, elle recevra et répondra directement aux requêtes HTTP qui arrivent sur votre serveur. En ajoutant un proxy comme Nginx, vous couplez Vapor à un port interne, comme le port `8080`. 

!!! Note
    Les ports supérieurs au port 1024 n'ont pas besoin d'utiliser `sudo` pour être couplés.

Lorsque Vapor est couplé à un port différent de `80` ou `443`, il ne sera pas accessible par l'internet publique. Vous couplez alors Nginx au port `80` et le configurez pour qu'il achemine les requêtes à votre application Vapor couplée au port `8080` (ou tout autre port que vous auriez choisi).

Et c'est tout. Si Nginx est correctement configuré, vous observerez votre application Vapor répondant aux requêtes arrivant sur le port `80`. Nginx achemine les requêtes et réponses de façon transparente.

## Installer Nginx

Vous devrez commencer par installer Nginx. L'un des points forts de Nginx est l'abondante quantité de ressources communautaires et la documentation qui l'entoure. De ce fait, nous n'entrerons pas en détail sur l'installation de Nginx puisque vous trouverez certainement un tutoriel adapté à votre plateforme, système d'exploitation, et hébergeur.

Quelques tutoriels :

- [Installation de Nginx sur Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [Installation de Nginx sur Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [Installation de Nginx sur CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [Installation de Nginx sur Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [Déploiement de Nginx sur Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Gestionnaires de paquets

Sur Linux, Nginx peut s'installer via un gestionnaire de paquets.

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

Vérifiez que Nginx a été correctement installé en vous rendant sur l'adresse de votre serveur dans un navigateur.

```
http://nom_de_domaine_ou_adresse_IP
```

### Service

Le service Nginx peut être démarré, arrêté ou redémarré avec ces commandes :

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Démarrer Vapor

Nginx peut démarrer par une commande `sudo service nginx ...`. Vous aurez besoin de commandes similaires pour votre application Vapor.

Vous avez plusieurs options possibles, qui dépendent de la plateforme sur laquelle vous déployez. Consultez les instructions concernant [Supervisor](supervisor.md) pour ajouter des commandes de démarrage et d'arrêt de votre application Vapor.

## Configurer le proxy

Les fichiers de configuration des sites actifs se trouvent dans `/etc/nginx/sites-enabled/`.

Créez un nouveau fichier ou copiez le modèle d'exemple de `/etc/nginx/sites-available/` pour commencer.

Voici un exemple de fichier de configuration pour un projet Vapor nommé `Hello` et placé dans le dossier home de l'utilisateur vapor.

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

Ce fichier de configuration suppose que le projet `Hello` se couple au port `8080` lorsqu'il démarre en mode production.

### Servir des fichiers

Nginx peut également servir des fichiers publiques sans passer par votre application Vapor. Cela peut améliorer les performances en libérant le processus Vapor pour d'autres tâches lorsque votre traffic augmente.

```sh
server {
    ...

    # Sert tout les fichiers publiques/statiques par Nginx et délègue le reste à Vapor.
    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        ...
    }
}
```

### TLS

L'ajout de TLS est relativement simple si les certificats sont correctement générés. Pour générer gratuitement des certificats TLS, regardez du côté de [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

La configuration ci-dessus contient des paramètres relativement stricts pour du TLS avec Nginx. Certains de ces paramètres sont optionnels, mais améliorent la sécurité.
