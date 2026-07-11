# Systemd

Systemd est le gestionnaire de système et de services par défaut sur la plupart des distributions Linux. Il est généralement installé par défaut, donc aucune installation n'est nécessaire sur les distributions Swift prises en charge.

## Configuration

Chaque application Vapor sur votre serveur doit avoir son propre fichier de service. Pour un exemple de projet `Hello`, le fichier de configuration se trouverait à `/etc/systemd/system/hello.service`. Ce fichier devrait ressembler à ceci :

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

Comme indiqué dans notre fichier de configuration, le projet `Hello` se trouve dans le dossier personnel de l'utilisateur `vapor`. Assurez-vous que `WorkingDirectory` pointe vers le répertoire racine de votre projet, là où se trouve le fichier `Package.swift`.

Le drapeau `--env production` désactivera la journalisation détaillée (verbose logging).

### Environnement
Autrement, mettre les valeurs entre guillemets est optionnel mais recommandé.

Vous pouvez exporter des variables via systemd de deux manières. Soit en créant un fichier d'environnement contenant toutes les variables définies :

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Soit en les ajoutant directement au fichier de service sous `[service]` :

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Les variables exportées peuvent être utilisées dans Vapor grâce à `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Démarrage

Vous pouvez désormais charger, activer, démarrer, arrêter et redémarrer votre application en exécutant ce qui suit en tant que root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
