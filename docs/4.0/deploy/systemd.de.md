# Systemd

Systemd ist der Standard-System- und Dienst-Manager auf den meisten Linux-Distributionen. Er ist in der Regel bereits standardmäßig installiert, sodass auf unterstützten Swift-Distributionen keine Installation notwendig ist.

## Konfigurieren

Jede Vapor-App auf deinem Server sollte ihre eigene Servicedatei haben. Für ein Beispielprojekt namens `Hello` würde sich die Konfigurationsdatei unter `/etc/systemd/system/hello.service` befinden. Diese Datei sollte wie folgt aussehen:

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

Wie in unserer Konfigurationsdatei angegeben, befindet sich das `Hello`-Projekt im Home-Verzeichnis des Benutzers `vapor`. Stelle sicher, dass `WorkingDirectory` auf das Wurzelverzeichnis deines Projekts zeigt, in dem sich die Datei `Package.swift` befindet.

Das Flag `--env production` deaktiviert ausführliches Logging.

### Umgebung
Ansonsten ist das Anführen der Werte in Anführungszeichen optional, aber empfohlen.

Du kannst Variablen auf zwei Arten über systemd exportieren. Entweder indem du eine Umgebungsdatei erstellst, in der alle Variablen gesetzt sind:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Oder du fügst sie direkt in der Servicedatei unter `[service]` hinzu:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Exportierte Variablen können in Vapor mit `Environment.get` verwendet werden

```swift
let port = Environment.get("PORT")
```

## Starten

Du kannst deine App jetzt laden, aktivieren, starten, stoppen und neu starten, indem du Folgendes als root ausführst.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
