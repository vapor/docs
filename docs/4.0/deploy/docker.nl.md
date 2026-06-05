# Docker Deploys

Docker gebruiken om uw Vapor app te implementeren heeft verschillende voordelen: 

1. Je docker app kan betrouwbaar worden opgestart met dezelfde commando's op elk platform met een Docker Daemon -- namelijk, Linux (CentOS, Debian, Fedora, Ubuntu), macOS, en Windows.
2. Je kunt docker-compose of Kubernetes manifests gebruiken om meerdere diensten te orkestreren die nodig zijn voor een volledige implementatie (bv. Redis, Postgres, nginx, enz.).
3. Het is gemakkelijk om te testen of uw app horizontaal kan schalen, zelfs lokaal op uw ontwikkelmachine.

Deze gids zal niet verder gaan dan het uitleggen hoe je je docker app op een server krijgt. De eenvoudigste manier zou zijn om Docker op je server te installeren en dezelfde commando's uit te voeren die je zou uitvoeren op je ontwikkelmachine om je applicatie op te starten. 

Meer gecompliceerde en robuuste implementaties zijn meestal anders, afhankelijk van uw hostingoplossing; veel populaire oplossingen zoals AWS hebben ingebouwde ondersteuning voor Kubernetes en aangepaste databaseoplossingen, waardoor het moeilijk is om best practices te schrijven op een manier die voor alle implementaties geldt. 

Niettemin is het gebruik van Docker om je volledige server stack lokaal op te draaien voor testdoeleinden ongelooflijk waardevol voor zowel grote als kleine serverside apps. Bovendien zijn de concepten beschreven in deze gids in grote lijnen van toepassing op alle Docker implementaties.

## Opzetten

Je zal je ontwikkelaarsomgeving moeten instellen om Docker te draaien en een basisbegrip moeten krijgen van de resource-bestanden die Docker stacks configureren.

### Installeer Docker

U moet Docker installeren voor uw ontwikkelaarsomgeving. U vindt informatie voor elk platform in de sectie [Ondersteunde platformen](https://docs.docker.com/install/#supported-platforms) van het Docker Engine-overzicht. Als u op Mac OS werkt, kunt u rechtstreeks naar de installatiepagina [Docker voor Mac](https://docs.docker.com/docker-for-mac/install/) springen.

### Genereer Template

Wij stellen voor om het Vapor sjabloon te gebruiken als startpunt. Als u al een app heeft, bouw dan het sjabloon zoals hieronder beschreven in een nieuwe map als referentiepunt terwijl u uw bestaande app dockerized -- u kunt de belangrijkste bronnen van het sjabloon kopiëren naar uw app en ze een beetje tweaken als een startpunt.

1. Installeer of bouw de Vapor Toolbox ([macOS](../install/macos.md#install-toolbox), [Linux](../install/linux.md#install-toolbox)).
2. Maak een nieuwe Vapor App met `vapor new my-dockerized-app` en loop door de prompts om relevante functies in of uit te schakelen. Uw antwoorden op deze prompts zullen invloed hebben op hoe de Docker resource bestanden worden gegenereerd.

## Docker Resources

Het is de moeite waard, nu of in de nabije toekomst, om uzelf vertrouwd te maken met het [Docker Overzicht](https://docs.docker.com/engine/docker-overview/). Het overzicht zal enkele belangrijke terminologie uitleggen die in deze gids gebruikt wordt. 

De sjabloon Vapor App heeft twee belangrijke Docker-specifieke bronnen: Een **Dockerfile** en een **docker-compose** bestand.

### Dockerfile

Een Dockerfile vertelt Docker hoe het een image moet bouwen van je dockerized app. Die image bevat zowel de executable van je app als alle dependencies die nodig zijn om hem te draaien. De [volledige referentie](https://docs.docker.com/engine/reference/builder/) is de moeite waard om open te houden wanneer je werkt aan het aanpassen van je Dockerfile.

Het Dockerfile dat gegenereerd wordt voor uw Vapor app heeft twee stadia. Het eerste stadium bouwt uw app en zet een wachtruimte op die het resultaat bevat. De tweede stap zet de basis van een veilige runtime omgeving op, verplaatst alles in de holding area naar waar het zal leven in de uiteindelijke image, en stelt een standaard entrypoint en commando in dat uw app in productie modus zal draaien op de standaard poort (8080). Deze configuratie kan worden opgeheven wanneer het image wordt gebruikt.

### Docker Compose File

Een Docker Compose bestand definieert de manier waarop Docker meerdere services moet uitbouwen in relatie tot elkaar. Het Docker Compose bestand in het Vapor App sjabloon biedt de nodige functionaliteit om uw app te implementeren, maar als u meer wilt weten kunt u het beste de [volledige referentie](https://docs.docker.com/compose/compose-file/) raadplegen die details bevat over alle beschikbare opties.

!!! note "Opmerking"
    Als je uiteindelijk van plan bent om Kubernetes te gebruiken om je app te orchestreren, is het Docker Compose bestand niet direct relevant. Kubernetes manifest bestanden zijn echter conceptueel vergelijkbaar en er zijn zelfs projecten gericht op het [porten van Docker Compose bestanden](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) naar Kubernetes manifesten.

Het Docker Compose bestand in uw nieuwe Vapor App zal services definiëren voor het draaien van uw app, het uitvoeren van migraties of het terugdraaien ervan, en het draaien van een database als persistentie laag van uw app. De exacte definities zullen variëren afhankelijk van welke database u koos om te gebruiken toen u `vapor new` uitvoerde.

Merk op dat uw Docker Compose-bestand een aantal gedeelde omgevingsvariabelen bovenaan heeft. (U kunt een andere set standaardvariabelen hebben, afhankelijk van of u Fluent gebruikt of niet, en welk Fluent-stuurprogramma in gebruik is als u dat doet).

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

U zult zien dat deze hieronder in meerdere services worden getrokken met de `<<: *shared_environment` YAML referentie syntax.

De `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME`, en `DATABASE_PASSWORD` variabelen zijn in dit voorbeeld hard gecodeerd terwijl de `LOG_LEVEL` zijn waarde krijgt van de omgeving waarin de service draait of terugvalt op `'debug'` als die variabele niet is ingesteld.

!!! note "Opmerking"
    Hard-coding van de gebruikersnaam en het wachtwoord is aanvaardbaar voor lokale ontwikkeling, maar u zou deze variabelen moeten opslaan in een geheimenbestand voor productie-uitrol. Een manier om dit in productie aan te pakken is door het secrets bestand te exporteren naar de omgeving waar je de deploy uitvoert en regels zoals de volgende te gebruiken in je Docker Compose bestand: 

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Dit geeft de omgevingsvariabele door aan de containers zoals gedefinieerd door de host.

Andere dingen om op te letten:

- Service afhankelijkheden worden gedefinieerd door `depends_on` arrays.
- Service poorten worden blootgesteld aan het systeem waarop de services draaien met `ports` arrays (geformatteerd als `<host_port>:<service_port>`).
- De `DATABASE_HOST` is gedefinieerd als `db`. Dit betekent dat uw app de database zal benaderen op `http://db:5432`. Dat werkt omdat Docker een netwerk gaat spinnen dat gebruikt wordt door uw diensten en de interne DNS op dat netwerk zal de naam `db` routeren naar de dienst met de naam `'db'`.
- De `CMD` directive in de Dockerfile wordt in sommige services overschreven met de `command` array. Merk op dat wat gespecificeerd wordt door `command` wordt uitgevoerd tegen het `ENTRYPOINT` in de Dockerfile.
- In de Zwermmodus (meer hierover hieronder) krijgen diensten standaard 1 instantie, maar de `migrate` en `revert` diensten zijn gedefinieerd als `deploy` `replicas: 0` zodat ze niet standaard opstarten als een Zwerm draait.

## Builden

Het Docker Compose bestand vertelt Docker hoe het uw app moet bouwen (door gebruik te maken van het Dockerfile in de huidige directory) en hoe het resulterende image moet heten (`my-dockerized-app:latest`). Dit laatste is eigenlijk de combinatie van een naam (`my-dockerized-app`) en een tag (`latest`) waarbij tags worden gebruikt om Docker images te versioneren.

Om een Docker image voor uw app te bouwen, voert u
```shell
docker compose build
```
uit vanuit de hoofdmap van het project van uw app (de map met `docker-compose.yml`).

Je zal zien dat je app en zijn afhankelijkheden opnieuw moeten gebouwd worden, zelfs als je ze voordien al gebouwd had op je ontwikkelmachine. Ze worden gebouwd in de Linux bouwomgeving die Docker gebruikt, dus de bouwartefacten van uw ontwikkelmachine zijn niet herbruikbaar.

Als het klaar is, zult u de afbeelding van uw app vinden wanneer u

```shell
docker image ls
```

uitvoert.

## Runnen

Je stack van diensten kan rechtstreeks vanuit het Docker Compose bestand worden uitgevoerd of je kan een orkestratielaag gebruiken zoals Swarm Mode of Kubernetes.

### Standalone

De eenvoudigste manier om je app te draaien is door hem te starten als een standalone container. Docker zal de `depends_on` arrays gebruiken om ervoor te zorgen dat alle afhankelijke services ook worden gestart.

Eerst, voer volgend commando uit:
```shell
docker compose up app
```
en zie dat zowel de `app` als `db` services zijn gestart.

Uw app luistert op poort 8080 en wordt, zoals gedefinieerd door het Docker Compose-bestand, toegankelijk gemaakt op uw ontwikkelmachine op **http://localhost:8080**.

Dit onderscheid in poorttoewijzing is heel belangrijk omdat je een willekeurig aantal diensten op dezelfde poorten kunt draaien als ze allemaal in hun eigen containers draaien en ze elk verschillende poorten naar de host machine blootleggen.

Bezoek `http://localhost:8080` en je ziet `It works! ` Maar bezoek `http://localhost:8080/todos` en je krijgt: 
```
{"error":true,"reason":"Something went wrong."}
```

Kijk eens naar de logs in de terminal waar je `docker compose up app` hebt uitgevoerd en je zult zien:
```
[ ERROR ] relation "todos" does not exist
```

Natuurlijk! We moeten migraties uitvoeren op de database. Druk op `Ctrl+C` om de app uit te schakelen. We gaan de app weer opstarten, maar deze keer met:
```shell
docker compose up --detach app
```

Nu zal je app "los" (op de achtergrond) opstarten. U kunt dit controleren door uit te voeren:
```shell
docker container ls
```
waar je zowel de database als je app in containers ziet draaien. Je kunt zelfs de logs bekijken door te draaien:
```shell
docker logs <container_id>
```

Om migraties uit te voeren, voer volgend commando uit:
```shell
docker compose run migrate
```

Nadat de migraties zijn uitgevoerd, kunt u `http://localhost:8080/todos` opnieuw bezoeken en krijgt u een lege lijst met todo's in plaats van een foutmelding.

#### Log Levels

Herinner hierboven dat de `LOG_LEVEL` omgevingsvariabele in het Docker Compose bestand zal worden geërfd van de omgeving waar de service is gestart, indien beschikbaar.

U kunt uw diensten starten met
```shell
LOG_LEVEL=trace docker-compose up app
```
om `trace` niveau logging te krijgen (het meest granulaire). Je kunt deze omgevingsvariabele gebruiken om de logging in te stellen op [elk beschikbaar niveau](../basics/logging.md#levels).

#### Alle Service Logs

Als je expliciet je databaseservice opgeeft wanneer je containers opstart, dan zul je logs zien voor zowel je database als je app.
```shell
docker-compose up app db
```

#### Standalone Containers Neerhalen

Nu dat je containers hebt draaien "losgekoppeld" van je host shell, moet je ze op een of andere manier vertellen om af te sluiten. Het is de moeite waard om te weten dat elke draaiende container gevraagd kan worden om af te sluiten met
```shell
docker container stop <container_id>
```
maar de makkelijkste manier om deze containers af te sluiten is
```shell
docker-compose down
```

#### De Database Wissen

Het Docker Compose bestand definieert een `db_data` volume om uw database tussen runs te bewaren. Er zijn een paar manieren om uw database te resetten.

U kunt het `db_data` volume verwijderen op het moment dat u uw containers neerhaalt met
```shell
docker-compose down --volumes
```

U kunt alle volumes zien die op dit moment gegevens bevatten met `docker volume ls`. Merk op dat de volumenaam meestal een voorvoegsel heeft van `my-dockerized-app_` of `test_`, afhankelijk van of u in Zwermmodus draait of niet. 

U kunt deze volumes één voor één verwijderen met bijv.
```shell
docker volume rm my-dockerized-app_db_data
```

U kunt ook alle volumes opruimen met
```shell
docker volume prune
```

Pas wel op dat je niet per ongeluk een volume met gegevens die je wilde bewaren, wegsnoeit!

Docker zal je geen volumes laten verwijderen die momenteel in gebruik zijn door draaiende of gestopte containers. Je kunt een lijst van draaiende containers krijgen met `docker container ls` en je kunt ook gestopte containers zien met `docker container ls -a`.

### Swarm Mode

Swarm Mode is een gemakkelijke interface om te gebruiken wanneer je een Docker Compose bestand bij de hand hebt en je wil testen hoe je app horizontaal schaalt. Je kan alles lezen over Swarm Mode in de pagina's geworteld in het [overzicht](https://docs.docker.com/engine/swarm/).

Het eerste wat we nodig hebben is een manager node voor onze Zwerm. Voer volgend commando uit
```shell
docker swarm init
```

Vervolgens zullen we ons Docker Compose bestand gebruiken om een stack genaamd `'test'` op te zetten met daarin onze services
```shell
docker stack deploy -c docker-compose.yml test
```

We kunnen zien hoe onze diensten het doen met
```shell
docker service ls
```

Je zou `1/1` replicas moeten zien voor je `app` en `db` services en `0/0` replicas voor je `migrate` en `revert` services.

We moeten een ander commando gebruiken om migraties in Swarm modus uit te voeren.
```shell
docker service scale --detach test_migrate=1
```

!!! note "Opmerking"
    We hebben zojuist een kortstondige dienst gevraagd om op te schalen naar 1 replica. Hij zal met succes opschalen, draaien, en dan afsluiten. Echter, dat zal hem achterlaten met `0/1` replica's die draaien. Dit is geen probleem totdat we weer migraties willen uitvoeren, maar we kunnen hem niet vertellen om "op te schalen naar 1 replica" als dat al is waar hij is. Een eigenaardigheid van deze setup is dat de volgende keer dat we migraties willen uitvoeren binnen dezelfde Swarm runtime, we de service eerst moeten opschalen naar `0` en dan weer terug naar `1`.

De beloning voor onze moeite in de context van deze korte gids is dat we nu onze app kunnen schalen naar wat we maar willen om te testen hoe goed hij omgaat met database contention, crashes, en meer.

Als je 5 instanties van je app gelijktijdig wilt draaien, voer dan
```shell
docker service scale test_app=5
```

Naast het kijken hoe docker je app opschaalt, kun je zien dat er inderdaad 5 replica's draaien door opnieuw `docker service ls` te controleren.

U kunt de logs voor uw app bekijken (en volgen) met
```shell
docker service logs -f test_app
```

#### Het naar beneden halen van Swarm Services

Als u uw diensten in Zwermmodus naar beneden wilt halen, doet u dat door de eerder aangemaakte stack te verwijderen.
```shell
docker stack rm test
```

## Production Deploys

Zoals bovenaan vermeld, zal deze gids niet in detail gaan over het uitrollen van je docker app naar productie omdat het onderwerp groot is en sterk varieert afhankelijk van de hosting service (AWS, Azure, enz.), tooling (Terraform, Ansible, enz.), en orkestratie (Docker Swarm, Kubernetes, enz.).

Echter, de technieken die je leert om je dockerized app lokaal op je ontwikkelmachine te draaien zijn grotendeels overdraagbaar naar productie-omgevingen. Een server instance die is ingesteld om de docker daemon te draaien, accepteert dezelfde commando's.

Kopieer je project bestanden naar je server, SSH naar de server, en voer een `docker-compose` of `docker stack deploy` commando uit om alles op afstand te laten werken.

Als alternatief, stel uw lokale `DOCKER_HOST` omgevingsvariabele in om naar uw server te wijzen en voer de `docker` commando's lokaal op uw machine uit. Het is belangrijk om op te merken dat met deze aanpak, je geen van je project bestanden naar de server hoeft te kopiëren _maar_ je moet wel je docker image ergens hosten waar je server het vandaan kan halen.
