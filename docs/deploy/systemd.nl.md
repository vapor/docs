# Systemd

Systemd is het standaard systeem en service manager op de meeste Linux distributies. Het wordt meestal standaard geïnstalleerd, zodat geen installatie nodig is op ondersteunde Swift-distributies.

## Configureren

Elke Vapor app op uw server zou zijn eigen service bestand moeten hebben. Voor een voorbeeld `Hello` project, zou het configuratie bestand te vinden zijn in `/etc/systemd/system/hello.service`. Dit bestand zou er als volgt uit moeten zien:

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
ExecStart=/home/vapor/hello/.build/release/Run serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

Zoals gespecificeerd in ons configuratie bestand bevindt het `Hello` project zich in de thuismap van de gebruiker `vapor`. Zorg ervoor dat `WorkingDirectory` wijst naar de root directory van uw project waar het `Package.swift` bestand staat.

De `--env production` vlag schakelt verbose logging uit.

### Environment
Anders is het citeren van de waarden optioneel maar aanbevolen.

Je kunt variabelen op twee manieren exporteren via systemd. Ofwel door een omgevingsbestand aan te maken met alle variabelen erin ingesteld:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Of u kunt ze direct toevoegen aan het service bestand onder `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Geëxporteerde variabelen kunnen in Vapor gebruikt worden met `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Start

U kunt nu uw app laden, inschakelen, starten, stoppen en herstarten door het volgende uit te voeren als root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
