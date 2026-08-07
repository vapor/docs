# Systemd

Systemd est le gestionnaire de système et de services par défaut sur la plupart des distributions Linux. Vous n'aurez donc pas besoin de l'installer sur les distributions que Swift supporte.

## Configuration

Chaque application Vapor sur votre serveur doit avoir son propre fichier de service. Pour un projet d'exemple nommé `Hello`, le fichier de configuration se trouverait à l'emplacement `/etc/systemd/system/hello.service`. Ce fichier devrait ressembler au contenu suivant :

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

Comme spécifié dans notre fichier de configuration, le projet `Hello` se trouve dans le répertoire home de l'utilisateur `vapor`. La valeur de `WorkingDirectory` doit indiquer le dossier racine de votre projet, où se trouve le fichier `Package.swift`.

Le drapeau `--env production` désactivera le niveau verbeux de la journalisation.

### Environnement

Avec systemd, vous pouvez exposer des variables d'environnement à votre application Vapor de deux façons. Soit en créant des fichiers d'environnement qui contiendront toutes les variables, que vous référencerez ensuite comme ceci :

```sh
EnvironmentFile=/chemin/vers/fichier1
EnvironmentFile=/chemin/vers/fichier2
```

Soit en listant directement les variables dans la catégorie `[service]` comme ceci :

```sh
Environment="PORT=8123"
Environment="AUTREVARIABLE=/autre/valeur"
```

Les variables exposées sont accessibles dans Vapor via `Environment.get` :

```swift
let port = Environment.get("PORT")
```

## Démarrage

Vous pouvez maintenant charger, activer, démarrer, arrêter et redémarrer votre application avec les commandes suivantes à exécuter en tant que root :

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
