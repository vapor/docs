# Fly

Fly is een hosting platform waar U server applicaties en databases kunnen laten draaien met een focus op edge computing. Zie [hun website](https://fly.io/) voor meer informatie.

!!! opmerking
    De in dit document gespecificeerde commando's zijn onderworpen aan [Fly's pricing](https://fly.io/docs/about/pricing/), zorg ervoor dat u deze goed begrijpt voordat u verder gaat.

## Registreren
Als je nog geen account heb, dan zal je er [een moeten maken](https://fly.io/app/sign-up).

## Installeren van flyctl
De belangrijkste manier om met Fly te communiceren is met het bijbehorende CLI-programma, `flyctl`, dat je moet installeren.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Andere installatiemogelijkheden
Voor meer opties en details, zie [de `flyctl` installatie docs](https://fly.io/docs/hands-on/install-flyctl/).

## Aanmelden
Om aan te melden vanuit je terminal, voer je het volgende commando uit:
```bash
fly auth login
```

## Je Vapor project configureren
Alvorens te deployen naar Fly, moet u ervoor zorgen dat u een Vapor-project heeft met een correct geconfigureerd Dockerbestand, aangezien Fly dit nodig heeft om uw app te bouwen. In de meeste gevallen zou dit heel eenvoudig moeten zijn, omdat de standaard Vapor-sjablonen er al een bevatten.

### Nieuw Vapor project
De eenvoudigste manier om een nieuw project te maken is te beginnen met een sjabloon. U kunt er een maken met behulp van GitHub-sjablonen of de Vapor-toolbox. Als u een database nodig hebt, is het aanbevolen om Fluent met Postgres te gebruiken; Fly maakt het eenvoudig om een Postgres-database aan te maken om uw apps mee te verbinden (zie de [specifieke sectie](#configuratie-postgres) hieronder).

#### De Vapor toolbox gebruiken
Zorg er eerst voor dat je de Vapor toolbox hebt geïnstalleerd (zie de instructies voor [macOS](../install/macos.md#install-toolbox) of [Linux](../install/linux.md#install-toolbox)).
Maak uw nieuwe app aan met het volgende commando, waarbij u `app-name` vervangt door de gewenste app-naam:

```bash
vapor new app-name
```

Dit commando toont een interactieve prompt waarmee u uw Vapor-project kunt configureren, hier kunt u Fluent en Postgres selecteren als u die nodig hebt.

#### De GitHub sjablonen gebruiken
Kies in de volgende lijst het sjabloon dat het beste bij uw behoeften past. Je kunt het lokaal klonen met Git of een GitHub-project aanmaken met de knop "Gebruik dit sjabloon".

- [Barebones template](https://github.com/vapor/template-bare)
- [Fluent/Postgres template](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf template](https://github.com/vapor/template-fluent-postgres-leaf)

### Bestaand Vapor project
Als je een bestaand Vapor-project hebt, zorg er dan voor dat je een goed geconfigureerde `Dockerfile` in de root van je map hebt staan; de [Vapor docs over het gebruik van Docker](../deploy/docker.md) en [Fly docs over het deployen van een app via een Dockerfile](https://fly.io/docs/getting-started/dockerfile/) kunnen van pas komen.

## Start uw app op Fly
Zodra uw Vapor-project klaar is, kunt u het lanceren op Fly.

Zorg er eerst voor dat je huidige map is ingesteld op de hoofdmap van je Vapor-toepassing en voer het volgende commando uit:
```bash
fly launch
```

Dit start een interactieve prompt om de instellingen van uw Fly-toepassing te configureren:

- **Name:** u kunt er een typen of leeg laten om een automatisch gegenereerde naam te krijgen.
- **Region:** standaard is dit degene die het dichtst bij u staat. U kunt kiezen om die te gebruiken of een andere in de lijst. Dit is later gemakkelijk te veranderen.
- **Database:** u kunt Fly vragen om een database aan te maken voor gebruik met uw app. Als u dat liever zelf doet, kunt u later altijd hetzelfde doen met de `fly pg create` en `fly pg attach` commando's (zie de [Configuratie van Postgres sectie](#configuratie-postgres) voor meer details).

Het `fly launch` commando maakt automatisch een `fly.toml` bestand aan. Het bevat instellingen zoals private/publieke port mappings, health check parameters, en vele andere. Als je net een nieuw project hebt gemaakt met `vapor new`, hoeft het standaard `fly.toml` bestand niet gewijzigd te worden. Als je een bestaand project hebt, is de kans groot dat `fly.toml` ook in orde is met geen of kleine wijzigingen. U kunt meer informatie vinden in de [`fly.toml` documentatie](https://fly.io/docs/reference/configuration/).

Merk op dat als u Fly vraagt om een database aan te maken, u even moet wachten tot deze is aangemaakt en de health checks geslaagd zijn.

Voor het afsluiten zal het `fly launch` commando je vragen of je je app onmiddellijk wilt deployen. Je kunt dit accepteren of het later doen met `fly deploy`.

!!! tip
    Wanneer je huidige directory zich in de root van je app bevindt, detecteert de fly CLI tool automatisch de aanwezigheid van een `fly.toml` bestand dat Fly laat weten op welke app je commando's zich richten. Als je een specifieke app wilt gebruiken, ongeacht je huidige directory, kun je `-a naam-van-je-app` toevoegen aan de meeste Fly commando's.

## Deployen
U voert het `fly deploy` commando uit wanneer u nieuwe wijzigingen in Fly wilt toepassen.

Fly leest de `Dockerfile` en `fly.toml` bestanden van uw directory om te bepalen hoe uw Vapor project gebouwd en uitgevoerd moet worden.

Zodra uw container is gebouwd, start Fly een instantie ervan. Het zal verschillende health checks uitvoeren, om ervoor te zorgen dat uw applicatie goed draait en uw server reageert op verzoeken. Het `fly deploy` commando sluit af met een foutmelding als de gezondheidscontroles mislukken.

Standaard zal Fly teruggaan naar de laatste werkende versie van uw app als de health checks falen voor de nieuwe versie die u probeerde te implementeren.

## Configuratie Postgres

### Een Postgres database aanmaken op Fly
Als u geen database-app hebt gemaakt toen u uw app voor het eerst lanceerde, kunt u dat later doen met:
```bash
fly pg create
```

Dit commando creëert een Fly app die databases kan hosten die beschikbaar zijn voor uw andere apps op Fly, zie de [toegewijde Fly documentatie](https://fly.io/docs/reference/postgres/) voor meer details.

Zodra uw database-app is gemaakt, gaat u naar de hoofdmap van uw Vapor-app en voert u dit commando uit:
```bash
fly pg attach name-of-your-postgres-app
```
Als je de naam van je Postgres app niet weet, kun je hem vinden met `fly pg list`.

Het `fly pg attach` commando maakt een database en gebruiker aan die bestemd zijn voor je app, en stelt deze vervolgens bloot aan je app via de `DATABASE_URL` omgevingsvariabele.

!!! opmerking
    Het verschil tussen `fly pg create` en `fly pg attach` is dat de eerste een Fly app toewijst en configureert die Postgres databases zal kunnen hosten, terwijl de tweede een eigenlijke database en gebruiker aanmaakt die bestemd is voor de app van uw keuze. Als het aan uw eisen voldoet, kan een enkele Postgres Fly app meerdere databases hosten die door verschillende apps worden gebruikt. Wanneer je Fly vraagt om een database app aan te maken in `fly launch`, doet het het equivalent van het aanroepen van zowel `fly pg create` als `fly pg attach`.

### Je Vapor app verbinden met de database
Zodra uw app is gekoppeld aan uw database, stelt Fly de `DATABASE_URL` omgevingsvariabele in op de verbindings URL die uw referenties bevat (het moet worden behandeld als gevoelige informatie).

Bij de meeste gebruikelijke Vapor project setups, configureer je je database in `configure.swift`. Dit is hoe je dit zou kunnen doen:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Handel ontbrekende DATABASE_URL hier af...
    //
    // Als alternatief kunt u ook een andere configuratie instellen 
    // afhankelijk van of app.environment is ingesteld op 
    // `.development` of `.production`
}
```

Op dit punt zou je project klaar moeten zijn om migraties uit te voeren en de database te gebruiken.

### Migraties uitvoeren
Met `fly.toml`'s `release_command` kun je Fly vragen om een bepaald commando uit te voeren voordat je je hoofdserverproces uitvoert. Voeg dit toe aan `fly.toml`:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! opmerking
    De bovenstaande code snippet gaat ervan uit dat je de standaard Vapor Dockerfile gebruikt die je app `ENTRYPOINT` op `./Run` zet. Concreet betekent dit dat wanneer je `release_command` instelt op `migrate -y`, Fly `./Run migrate -y` zal aanroepen. Als je `ENTRYPOINT` op een andere waarde is ingesteld, moet je de waarde van `release_command` aanpassen.

Fly zal uw release commando uitvoeren in een tijdelijke instantie die toegang heeft tot uw interne Fly netwerk, geheimen en omgevingsvariabelen.

Als uw release commando mislukt, zal de deployment niet doorgaan.

### Andere databases
Hoewel Fly het gemakkelijk maakt om een Postgres database app te maken, is het ook mogelijk om andere soorten databases te hosten (zie bijvoorbeeld ["Gebruik een MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) in de Fly documentatie).

## Secrets en omgevingsvariabelen
### Secrets
Gebruik geheimen om gevoelige waarden in te stellen als omgevingsvariabelen.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning "Waarschuwing"
    Onthoud dat de meeste shells een geschiedenis bijhouden van de commando's die je getypt hebt. Wees hier voorzichtig mee als je op deze manier geheimen instelt. Sommige shells kunnen geconfigureerd worden om commando's die voorafgegaan worden door een spatie niet te onthouden. Zie ook het [`fly secrets import` commando](https://fly.io/docs/flyctl/secrets-import/).

Voor meer informatie, bekijk de [documentatie van `fly secrets`](https://fly.io/docs/reference/secrets/).

### Omgevingsvariabelen
U kunt andere niet-gevoelige [omgevingsvariabelen instellen in `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), bijvoorbeeld:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH connectie
U kunt verbinding maken met de instanties van een app met behulp van:
```bash
fly ssh console -s
```

## De logs controleren
U kunt de live logs van uw app controleren met:
```bash
fly logs
```

## Volgende stappen
Nu uw Vapor-app is uitgerold, kunt u nog veel meer doen, zoals uw apps verticaal en horizontaal schalen over meerdere regio's, persistente volumes toevoegen, continuous deployment opzetten of zelfs gedistribueerde app-clusters maken. De beste plaats om te leren hoe u dit alles en nog veel meer kunt doen is de [Fly docs](https://fly.io/docs/).