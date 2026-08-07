# Supervisor

[Supervisor](http://supervisord.org) est un système de contrôle de processus qui facilite le démarrage, l'arrêt, et le redémarrage de votre application Vapor.

## Installation

Supervisor peut s'installer via des gestionnaires de paquets sur Linux.

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

Chaque application Vapor de votre serveur doit avoir son propre fichier de configuration. Pour un projet d'exemple nommé `Hello`, le fichier de configuration se trouverait à l'emplacement `/etc/supervisor/conf.d/hello.conf` et contiendrait quelque-chose comme ceci :

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Comme le spécifie ce fichier de configuration, le projet `Hello` se trouve dans le dossier home de l'utilisateur `vapor`. La valeur de `directory` doit indiquer le dossier racine de votre projet, où se trouve le fichier `Package.swift`.

Le drapeau `--env production` désactivera le niveau verbeux de la journalisation.

### Environnement

Avec supervisor, vous pouvez exposer des variables d'environnement à votre application Vapor. Pour en exposer plusieurs, vous devrez toutes les mettre sur une seule ligne. Selon la [documentation de Supervisor](http://supervisord.org/configuration.html#program-x-section-values) :

> Les valeurs contenant des caractères non-alphanumériques doivent être placées entre double-quotes (ex : KEY="val:123",KEY2="val,456"). Pour les autres valeurs, les doubles-quotes sont recommandées mais optionnelles.

```sh
environment=PORT=8123,AUTREVALEUR="/autre/chose"
```

Les variables exposées sont accessibles dans Vapor via `Environment.get` :

```swift
let port = Environment.get("PORT")
```

## Démarrage

Vous pouvez désormais charger et démarrer votre application :

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! Note
    La commande `add` peut avoir déjà démarré votre application.
