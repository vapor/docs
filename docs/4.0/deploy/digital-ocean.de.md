# Deployment auf DigitalOcean

Diese Anleitung führt dich durch das Deployment einer einfachen Hello-World-Vapor-Anwendung auf einem [Droplet](https://www.digitalocean.com/products/droplets/). Um dieser Anleitung zu folgen, benötigst du ein [DigitalOcean](https://www.digitalocean.com)-Konto mit eingerichteter Zahlungsmethode.

## Server erstellen

Beginnen wir damit, Swift auf einem Linux-Server zu installieren. Verwende das Create-Menü, um ein neues Droplet zu erstellen.

![Create Droplet](../images/digital-ocean-create-droplet.png)

Wähle unter Distributions Ubuntu 22.04 LTS aus. Die folgende Anleitung verwendet diese Version als Beispiel.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note 
    Du kannst jede Linux-Distribution mit einer von Swift unterstützten Version auswählen. Welche Betriebssysteme offiziell unterstützt werden, kannst du auf der Seite [Swift Releases](https://swift.org/download/#releases) nachsehen.

Nachdem du die Distribution ausgewählt hast, wähle einen beliebigen Plan und eine Rechenzentrumsregion deiner Wahl. Richte anschließend einen SSH-Key ein, um nach der Erstellung auf den Server zugreifen zu können. Klicke abschließend auf Droplet erstellen und warte, bis der neue Server hochgefahren ist.

Sobald der neue Server bereit ist, fahre mit der Maus über die IP-Adresse des Droplets und klicke auf Kopieren.

![Droplet List](../images/digital-ocean-droplet-list.png)

## Ersteinrichtung

Öffne dein Terminal und verbinde dich per SSH als root mit dem Server.

```sh
ssh root@your_server_ip
```

DigitalOcean bietet eine ausführliche Anleitung zur [Ersteinrichtung eines Servers unter Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). Diese Anleitung deckt kurz die Grundlagen ab.

### Firewall konfigurieren

Erlaube OpenSSH in der Firewall und aktiviere sie.

```sh
ufw allow OpenSSH
ufw enable
```

### Benutzer hinzufügen

Erstelle einen neuen Benutzer neben `root`. Diese Anleitung nennt den neuen Benutzer `vapor`.

```sh
adduser vapor
```

Erlaube dem neu erstellten Benutzer die Verwendung von `sudo`.

```sh
usermod -aG sudo vapor
```

Kopiere die autorisierten SSH-Keys des root-Benutzers zum neu erstellten Benutzer. So kannst du dich als neuer Benutzer per SSH anmelden.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

Beende zum Schluss die aktuelle SSH-Sitzung und melde dich als der neu erstellte Benutzer an.

```sh
exit
ssh vapor@your_server_ip
```

## Swift installieren

Nachdem du einen neuen Ubuntu-Server erstellt und dich als Nicht-root-Benutzer angemeldet hast, kannst du nun Swift installieren.

### Automatisierte Installation mit dem Swiftly-CLI-Tool (empfohlen)

Besuche die [Swiftly-Website](https://swiftlang.github.io/swiftly/) für Anweisungen zur Installation von Swiftly und Swift unter Linux. Installiere Swift anschließend mit folgendem Befehl:

#### Grundlegende Verwendung

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

## Vapor mit der Vapor Toolbox installieren

Nachdem Swift installiert ist, installieren wir nun Vapor mit der Vapor Toolbox. Du musst die Toolbox aus dem Quellcode bauen. Schau dir die [Releases](https://github.com/vapor/toolbox/releases) der Toolbox auf GitHub an, um die neueste Version zu finden. In diesem Beispiel verwenden wir 18.6.0.

### Vapor klonen und bauen

Klone das Vapor-Toolbox-Repository.

```sh
git clone https://github.com/vapor/toolbox.git
```

Wechsle zum neuesten Release.

```sh
cd toolbox
git checkout 18.6.0
```

Baue Vapor und verschiebe die Binärdatei in deinen Pfad.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Ein Vapor-Projekt erstellen

Verwende den New-Project-Befehl der Toolbox, um ein Projekt zu initiieren.

```sh
vapor new HelloWorld -n
```

!!! tip
    Das Flag `-n` gibt dir eine minimale Vorlage, indem alle Fragen automatisch mit Nein beantwortet werden.

![Vapor Splash](../images/vapor-splash.png)

Sobald der Befehl abgeschlossen ist, wechsle in den neu erstellten Ordner:

```sh
cd HelloWorld
``` 

### HTTP-Port öffnen

Um auf Vapor auf deinem Server zugreifen zu können, öffne einen HTTP-Port.

```sh
sudo ufw allow 8080
```

### Ausführen

Nachdem Vapor eingerichtet ist und wir einen offenen Port haben, lass es uns ausführen.

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

Besuche die IP-Adresse deines Servers über den Browser oder ein lokales Terminal, und du solltest "It works!" sehen. Die IP-Adresse ist in diesem Beispiel `134.122.126.139`.

```
$ curl http://134.122.126.139:8080
It works!
```

Zurück auf deinem Server solltest du Logs für die Testanfrage sehen.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

Verwende `CTRL+C`, um den Server zu beenden. Das Herunterfahren kann einen Moment dauern.

Herzlichen Glückwunsch, dass du deine Vapor-App auf einem DigitalOcean-Droplet zum Laufen gebracht hast!

## Nächste Schritte

Der Rest dieser Anleitung verweist auf zusätzliche Ressourcen, um dein Deployment zu verbessern.

### Supervisor

Supervisor ist ein Prozesssteuerungssystem, das deine Vapor-Executable ausführen und überwachen kann. Mit eingerichtetem Supervisor kann deine App automatisch starten, wenn der Server hochfährt, und im Falle eines Absturzes neu gestartet werden. Erfahre mehr über [Supervisor](../deploy/supervisor.md).

### Nginx

Nginx ist ein extrem schneller, bewährter und einfach zu konfigurierender HTTP-Server und Proxy. Während Vapor die direkte Bearbeitung von HTTP-Anfragen unterstützt, kann ein Proxy über Nginx eine erhöhte Leistung, Sicherheit und Benutzerfreundlichkeit bieten. Erfahre mehr über [Nginx](../deploy/nginx.md).
