# Supervisor

[Supervisor](http://supervisord.org) est un système de contrôle de processus qui facilite le démarrage, l'arrêt et le redémarrage de votre application Vapor.

## Installation

Supervisor peut être installé via les gestionnaires de paquets sur Linux.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS et Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Configuration

Chaque application Vapor sur votre serveur doit avoir son propre fichier de configuration. Pour un exemple de projet `Hello`, le fichier de configuration se trouverait à `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Comme indiqué dans notre fichier de configuration, le projet `Hello` se trouve dans le dossier personnel de l'utilisateur `vapor`. Assurez-vous que `directory` pointe vers le répertoire racine de votre projet, là où se trouve le fichier `Package.swift`.

Le drapeau `--env production` désactivera la journalisation détaillée (verbose logging).

### Environnement

Vous pouvez exporter des variables vers votre application Vapor avec supervisor. Pour exporter plusieurs valeurs d'environnement, mettez-les toutes sur une seule ligne. Comme le précise la [documentation de Supervisor](http://supervisord.org/configuration.html#program-x-section-values) :

> Les valeurs contenant des caractères non alphanumériques doivent être entourées de guillemets (par exemple `KEY="val:123",KEY2="val,456"`). Dans les autres cas, entourer les valeurs de guillemets est optionnel mais recommandé.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Les variables exportées peuvent être utilisées dans Vapor grâce à `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Démarrage

Vous pouvez maintenant charger et démarrer votre application.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
    La commande `add` peut avoir déjà démarré votre application.
