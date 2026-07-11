# Deployment mit Nginx

Nginx ist ein extrem schneller, bewährter und einfach zu konfigurierender HTTP-Server und Proxy. Während Vapor die direkte Bedienung von HTTP-Anfragen mit oder ohne TLS unterstützt, kann ein Proxy mit Nginx davor mehr Leistung, Sicherheit und Benutzerfreundlichkeit bieten.

!!! note
    Wir empfehlen, Vapor-HTTP-Server hinter Nginx als Proxy zu betreiben.

## Übersicht

Was bedeutet es, einen HTTP-Server über einen Proxy laufen zu lassen? Kurz gesagt, ein Proxy fungiert als Mittelsmann zwischen dem öffentlichen Internet und deinem HTTP-Server. Anfragen kommen beim Proxy an, der sie anschließend an Vapor weiterleitet.

Eine wichtige Eigenschaft dieses Mittelsmann-Proxys ist, dass er die Anfragen verändern oder sogar umleiten kann. Der Proxy kann zum Beispiel verlangen, dass der Client TLS (https) verwendet, Anfragen ratenbegrenzen oder sogar öffentliche Dateien ausliefern, ohne mit deiner Vapor-Anwendung zu kommunizieren.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Mehr Details

Der Standardport zum Empfangen von HTTP-Anfragen ist Port `80` (und `443` für HTTPS). Wenn du einen Vapor-Server an Port `80` bindest, empfängt und beantwortet er direkt die HTTP-Anfragen, die bei deinem Server eingehen. Wenn du einen Proxy wie Nginx hinzufügst, bindest du Vapor stattdessen an einen internen Port, wie zum Beispiel Port `8080`.

!!! note
    Ports über 1024 benötigen kein `sudo`, um gebunden zu werden.

Wenn Vapor an einen anderen Port als `80` oder `443` gebunden ist, ist es vom öffentlichen Internet aus nicht erreichbar. Du bindest dann Nginx an Port `80` und konfigurierst es so, dass es Anfragen an deinen Vapor-Server weiterleitet, der an Port `8080` (oder einen anderen von dir gewählten Port) gebunden ist.

Und das war's schon. Wenn Nginx korrekt konfiguriert ist, siehst du, wie deine Vapor-App auf Anfragen an Port `80` reagiert. Nginx leitet die Anfragen und Antworten unsichtbar weiter.

## Nginx installieren

Der erste Schritt ist die Installation von Nginx. Einer der großen Vorteile von Nginx ist die enorme Menge an Community-Ressourcen und Dokumentation, die es umgibt. Deshalb gehen wir hier nicht im Detail auf die Installation von Nginx ein, da es mit ziemlicher Sicherheit ein Tutorial für deine spezifische Plattform, dein Betriebssystem und deinen Provider gibt.

Tutorials:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Paketmanager

Nginx kann unter Linux über Paketmanager installiert werden.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS und Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Installation überprüfen

Überprüfe, ob Nginx korrekt installiert wurde, indem du die IP-Adresse deines Servers in einem Browser aufrufst

```
http://server_domain_name_or_IP
```

### Dienst

Der Dienst kann gestartet oder gestoppt werden.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Vapor starten

Nginx kann mit den Befehlen `sudo service nginx ...` gestartet und gestoppt werden. Du benötigst etwas Ähnliches, um deinen Vapor-Server zu starten und zu stoppen.

Es gibt viele Möglichkeiten, dies zu tun, abhängig davon, auf welcher Plattform du dein Deployment durchführst. Sieh dir die [Supervisor](supervisor.md)-Anleitung an, um Befehle zum Starten und Stoppen deiner Vapor-App hinzuzufügen.

## Proxy konfigurieren

Die Konfigurationsdateien für aktivierte Sites findest du unter `/etc/nginx/sites-enabled/`.

Erstelle eine neue Datei oder kopiere die Beispielvorlage aus `/etc/nginx/sites-available/`, um loszulegen.

Hier ist eine Beispielkonfigurationsdatei für ein Vapor-Projekt namens `Hello` im Home-Verzeichnis.

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

Diese Konfigurationsdatei geht davon aus, dass das `Hello`-Projekt beim Start im Produktionsmodus an Port `8080` gebunden wird.

### Dateien ausliefern

Nginx kann auch öffentliche Dateien ausliefern, ohne deine Vapor-App zu fragen. Dies kann die Leistung verbessern, indem es den Vapor-Prozess unter hoher Last für andere Aufgaben freihält.

```sh
server {
    ...

    # Serve all public/static files via nginx and then fallback to Vapor for the rest
    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        ...
    }
}
```

### TLS

Das Hinzufügen von TLS ist relativ einfach, solange die Zertifikate korrekt generiert wurden. Um kostenlose TLS-Zertifikate zu erzeugen, sieh dir [Let's Encrypt](https://letsencrypt.org/getting-started/) an.

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

Die obige Konfiguration sind die relativ strengen Einstellungen für TLS mit Nginx. Einige dieser Einstellungen sind nicht erforderlich, erhöhen aber die Sicherheit.
