# Supervisor

[Supervisor](http://supervisord.org) is een procescontrolesysteem dat het eenvoudig maakt om uw Vapor-app te starten, te stoppen en opnieuw op te starten.

## Installeren

Supervisor kan worden geïnstalleerd via pakketbeheer op Linux.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS and Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Configureren

Elke Vapor toepassing op uw server zou zijn eigen configuratiebestand moeten hebben. Voor een voorbeeld van een `Hello` project, zou het configuratiebestand te vinden zijn in `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Zoals gespecificeerd in ons configuratie bestand staat het `Hello` project in de thuismap van de gebruiker `vapor`. Zorg ervoor dat `directory` wijst naar de root directory van uw project waar het `Package.swift` bestand staat.

De `--env production` vlag schakelt verbose logging uit.

### Environment

U kunt variabelen exporteren naar uw Vapor app met supervisor. Voor het exporteren van meerdere omgevingswaarden, zet ze allemaal op één regel. Per [Supervisor documentatie](http://supervisord.org/configuration.html#program-x-section-values):

> Waarden die niet-alfanumerieke tekens bevatten moeten worden geciteerd (bijv. KEY="val:123",KEY2="val,456"). Anders is het citeren van de waarden optioneel, maar aanbevolen.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Geëxporteerde variabelen kunnen in Vapor gebruikt worden met `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Start

U kunt nu uw app laden en starten.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "Opmerking"
	Het `add` commando kan uw app al gestart hebben.
