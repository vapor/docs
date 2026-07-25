# Déployer sur DigitalOcean

Ce guide vous expliquera comment déployer une simple application Vapor Hello World sur un [Droplet](https://www.digitalocean.com/products/droplets/). Pour suivre ce guide, vous aurez besoin d'un compte [DigitalOcean](https://www.digitalocean.com) avec facturation configurée.

## Créer un serveur

Commençons par l'installation de Swift sur un serveur Linux. Utilisez le menu "create" pour créer un nouveau Droplet.

![Create Droplet](../images/digital-ocean-create-droplet.png)

Dans la liste des distributions, choisissez Ubuntu 22.04 LTS. Ce guide se basera sur cette version comme exemple.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! Note 
    Vous pouvez choisir n'importe quelle distribution Linux ayant une version supportée par Swift. Vous pouvez vérifier la liste officielle des systèmes d'exploitation supportés sur la page [Swift Releases](https://swift.org/download/#releases).

Une fois la distribution choisie, sélectionnez un plan et une région de datacenter selon vos préférences. Configurez ensuite une clé SSH pour accéder au serveur lorsqu'il sera créé. Enfin, cliquez sur "create Droplet" et attendez que le nouveau serveur démarre.

Une fois qu'il est prêt, placez la souris sur l'adresse IP du Droplet et cliquez sur "copy".

![Droplet List](../images/digital-ocean-droplet-list.png)

## Configuration initiale

Ouvrez un terminal et connectez-vous au serveur en tant que root via SSH.

```sh
ssh root@your_server_ip
```

DigitalOcean a un guide complet pour la [configuration initiale d'un serveur sous Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). Notre guide expliquera rapidement les bases.

### Configuration du pare-feu

Autorisez OpenSSH à traverser le pare-feu, puis activez-le.

```sh
ufw allow OpenSSH
ufw enable
```

### Ajout d'un utilisateur

Créez un utilisateur autre que `root`. Ce guide créera l'utilisateur `vapor`.

```sh
adduser vapor
```

Autorisez cet utilisateur à utiliser `sudo`.

```sh
usermod -aG sudo vapor
```

Copiez la clé SSH autorisée pour l'utilisateur root vers le nouvel utilisateur. Cela vous permettra de vous connecter en SSH avec cet utilisateur.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

Enfin, fermez la session SSH en cours et connectez-vous avec le nouvel utilisateur. 

```sh
exit
ssh vapor@your_server_ip
```

## Installation de Swift

Maintenant que vous avez un serveur Ubuntu et que vous êtes connecté avec un utilisateur non root, vous pouvez installer Swift. 

### Installation automatisée par Swiftly (recommandé)

Rendez-vous sur le [site de Swiftly](https://swiftlang.github.io/swiftly/) pour suivre les instructions d'installation de Swiftly et de Swift on Linux. Puis, installez Swift avec cette commande :

#### Utilisation basique

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## Installation de Vapor via la Toolbox

Maintenant que Swift est installé, nous allons installer Vapor via sa Toolbox. Vous devrez compiler la toolbox depuis ses sources. Cherchez la version la plus récente sur la page [releases](https://github.com/vapor/toolbox/releases) sur GitHub. Dans cet exemple, nous utilisons la version 18.6.0.

### Cloner et compiler Vapor

Clonez le dépot Vapor Toolbox.

```sh
git clone https://github.com/vapor/toolbox.git
```

Placez-vous sur le tag de version le plus récent.

```sh
cd toolbox
git checkout 18.6.0
```

Compilez Vapor et placez le binaire dans votre path.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Créer un projet Vapor

Utilisez la commande `new` de la Toolbox pour créer un nouveau projet.

```sh
vapor new HelloWorld -n
```

!!! Note
    Le drapeau `-n` crée un projet minimal en répondant non à toutes les questions de configuration initiale.

![Vapor Splash](../images/vapor-splash.png)

Une fois la commande terminée, placez-vous dans le dossier qu'elle a créé :

```sh
cd HelloWorld
``` 

### Ouverture de port HTTP

Afin d'accéder à Vapor sur votre serveur, ouvrez un port HTTP.

```sh
sudo ufw allow 8080
```

### Démarrage

Maintenant que Vapor est prêt et qu'un port est ouvert, démarrons-le. 

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

Accédez à l'adresse IP de votre serveur via navigateur ou terminal local et vous devriez obtenir le message "It works!". L'adresse IP de notre exemple est `134.122.126.139`.

```
$ curl http://134.122.126.139:8080
It works!
```

De retour sur votre serveur, vous devriez voir les journaux de logs créés par nos tests.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

Faites `CTRL+C` pour stopper le serveur. Il pourra avoir besoin de quelques secondes pour s'éteindre.

Bravo, vos avez fait tourner votre application Vapor sur un Droplet DigitalOcean !

## Pour aller plus loin

Voici des articles complémentaires pour améliorer vos déploiements. 

### Supervisor

Supervisor est un système de contrôle de processus qui peut exécuter et contrôler votre exécutable Vapor. Avec supervisor configuré, votre application peut démarrer avec le serveur et redémarrer en cas de crash. Découvrez notre guide [Supervisor](../deploy/supervisor.md).

### Nginx

Nginx est un proxy et serveur HTTP extrêmement rapide, éprouvé, et facile à configurer. Bien que Vapor sache gérer directement les requêtes HTTP, le mettre derrière un proxy Nginx peut améliorer les performances, la sécurité, et la simplicité d'utilisation. Découvrez notre guide [Nginx](../deploy/nginx.md).
