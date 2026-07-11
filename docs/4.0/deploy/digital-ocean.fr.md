# Déployer sur DigitalOcean

Ce guide va vous accompagner dans le déploiement d'une simple application Vapor Hello, world sur un [Droplet](https://www.digitalocean.com/products/droplets/). Pour suivre ce guide, vous devez avoir un compte [DigitalOcean](https://www.digitalocean.com) avec la facturation configurée.

## Créer le Serveur

Commençons par installer Swift sur un serveur Linux. Utilisez le menu de création pour créer un nouveau Droplet.

![Create Droplet](../images/digital-ocean-create-droplet.png)

Dans les distributions, sélectionnez Ubuntu 22.04 LTS. Le guide suivant utilisera cette version en exemple.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note 
    Vous pouvez sélectionner n'importe quelle distribution Linux dont la version est supportée par Swift. Vous pouvez vérifier les systèmes d'exploitation officiellement supportés sur la page des [Swift Releases](https://swift.org/download/#releases).

Après avoir sélectionné la distribution, choisissez le plan et la région du datacenter que vous préférez. Configurez ensuite une clé SSH pour accéder au serveur une fois qu'il sera créé. Enfin, cliquez sur créer le Droplet et attendez que le nouveau serveur démarre.

Une fois le nouveau serveur prêt, survolez l'adresse IP du Droplet et cliquez sur copier.

![Droplet List](../images/digital-ocean-droplet-list.png)

## Configuration Initiale

Ouvrez votre terminal et connectez-vous au serveur en tant que root via SSH.

```sh
ssh root@your_server_ip
```

DigitalOcean propose un guide détaillé pour la [configuration initiale d'un serveur sous Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). Ce guide en couvrira rapidement les bases.

### Configurer le Pare-feu

Autorisez OpenSSH à travers le pare-feu et activez-le.

```sh
ufw allow OpenSSH
ufw enable
```

### Ajouter un Utilisateur

Créez un nouvel utilisateur en plus de `root`. Ce guide appelle le nouvel utilisateur `vapor`.

```sh
adduser vapor
```

Autorisez le nouvel utilisateur créé à utiliser `sudo`.

```sh
usermod -aG sudo vapor
```

Copiez les clés SSH autorisées de l'utilisateur root vers le nouvel utilisateur créé. Cela vous permettra de vous connecter en SSH en tant que nouvel utilisateur.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

Enfin, quittez la session SSH actuelle et connectez-vous en tant que nouvel utilisateur créé. 

```sh
exit
ssh vapor@your_server_ip
```

## Installer Swift

Maintenant que vous avez créé un nouveau serveur Ubuntu et que vous êtes connecté en tant qu'utilisateur non-root, vous pouvez installer Swift. 

### Installation automatisée via l'outil CLI Swiftly (recommandé)

Rendez-vous sur [le site de Swiftly](https://swiftlang.github.io/swiftly/) pour les instructions d'installation de Swiftly et de Swift sur Linux. Après quoi, installez Swift avec la commande suivante :

#### Usage de base

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

## Installer Vapor en Utilisant la Vapor Toolbox

Maintenant que Swift est installé, installons Vapor en utilisant la Vapor Toolbox. Vous devrez compiler la toolbox depuis les sources. Consultez les [releases](https://github.com/vapor/toolbox/releases) de la toolbox sur GitHub pour trouver la dernière version. Dans cet exemple, nous utilisons la 18.6.0.

### Cloner et Compiler Vapor

Clonez le dépôt de la Vapor Toolbox.

```sh
git clone https://github.com/vapor/toolbox.git
```

Récupérez la dernière release.

```sh
cd toolbox
git checkout 18.6.0
```

Compilez Vapor et déplacez le binaire dans votre path.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Créer un Projet Vapor

Utilisez la commande new project de la Toolbox pour initialiser un projet.

```sh
vapor new HelloWorld -n
```

!!! tip
    Le drapeau `-n` vous donne un modèle minimal en répondant automatiquement non à toutes les questions.

![Vapor Splash](../images/vapor-splash.png)

Une fois la commande terminée, déplacez-vous dans le dossier nouvellement créé :

```sh
cd HelloWorld
``` 

### Ouvrir un Port HTTP

Afin d'accéder à Vapor sur votre serveur, ouvrez un port HTTP.

```sh
sudo ufw allow 8080
```

### Exécuter

Maintenant que Vapor est configuré et que nous avons un port ouvert, exécutons-le. 

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

Rendez-vous sur l'adresse IP de votre serveur via un navigateur ou un terminal local et vous devriez voir « It works! ». L'adresse IP est `134.122.126.139` dans cet exemple.

```
$ curl http://134.122.126.139:8080
It works!
```

De retour sur votre serveur, vous devriez voir les logs de la requête de test.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

Utilisez `CTRL+C` pour quitter le serveur. Cela peut prendre un moment pour s'arrêter.

Félicitations, votre application Vapor tourne désormais sur un Droplet DigitalOcean !

## Prochaines Étapes

Le reste de ce guide pointe vers des ressources supplémentaires pour améliorer votre déploiement. 

### Supervisor

Supervisor est un système de contrôle de processus qui peut exécuter et surveiller votre exécutable Vapor. Avec Supervisor configuré, votre application peut démarrer automatiquement au démarrage du serveur et redémarrer en cas de crash. En savoir plus sur [Supervisor](../deploy/supervisor.md).

### Nginx

Nginx est un serveur HTTP et un proxy extrêmement rapide, éprouvé et facile à configurer. Bien que Vapor prenne en charge le traitement direct des requêtes HTTP, faire transiter le trafic derrière Nginx peut offrir de meilleures performances, une sécurité accrue et une plus grande facilité d'utilisation. En savoir plus sur [Nginx](../deploy/nginx.md).
