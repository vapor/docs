# Supervisor

[Supervisor](http://supervisord.org) ist ein Prozesskontrollsystem, mit dem du deine Vapor-App einfach starten, stoppen und neu starten kannst.

## Installation

Supervisor kann unter Linux über Paketmanager installiert werden.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS und Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Konfigurieren

Jede Vapor-App auf deinem Server sollte ihre eigene Konfigurationsdatei haben. Für ein Beispielprojekt namens `Hello` würde sich die Konfigurationsdatei unter `/etc/supervisor/conf.d/hello.conf` befinden

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Wie in unserer Konfigurationsdatei angegeben, befindet sich das `Hello`-Projekt im Home-Verzeichnis des Benutzers `vapor`. Stelle sicher, dass `directory` auf das Wurzelverzeichnis deines Projekts zeigt, in dem sich die Datei `Package.swift` befindet.

Das Flag `--env production` deaktiviert ausführliches Logging.

### Umgebung

Mit Supervisor kannst du Variablen an deine Vapor-App exportieren. Um mehrere Umgebungswerte zu exportieren, schreibe sie alle in eine Zeile. Laut [Supervisor-Dokumentation](http://supervisord.org/configuration.html#program-x-section-values):

> Werte, die nicht-alphanumerische Zeichen enthalten, sollten in Anführungszeichen gesetzt werden (z. B. KEY="val:123",KEY2="val,456"). Ansonsten ist das Setzen von Anführungszeichen optional, wird aber empfohlen.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Exportierte Variablen können in Vapor mit `Environment.get` verwendet werden

```swift
let port = Environment.get("PORT")
```

## Starten

Du kannst deine App jetzt laden und starten.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
    Der Befehl `add` hat deine App möglicherweise bereits gestartet.
