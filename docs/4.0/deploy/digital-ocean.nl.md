# Deployen naar DigitalOcean

Deze handleiding leidt u door het implementeren van een eenvoudige Hello, world Vapor applicatie op een [Droplet](https://www.digitalocean.com/products/droplets/). Om deze gids te volgen, heeft u een [DigitalOcean](https://www.digitalocean.com) account nodig met geconfigureerde facturering.

## Maak Server Aan

Laten we beginnen met het installeren van Swift op een Linux server. Gebruik het create menu om een nieuwe Droplet aan te maken.

![Create Droplet](../images/digital-ocean-create-droplet.png)

Onder distributies, selecteer Ubuntu 22.04 LTS. De volgende gids zal deze versie als voorbeeld gebruiken.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note  "Opmerking"
	U kunt elke Linux distributie kiezen met een versie die Swift ondersteunt. Op het moment van schrijven ondersteunt Swift 5.7.3 Ubuntu 18.04, 20.04, 22.04, CentOS 7, en Amazon Linux 2. U kunt controleren welke besturingssystemen officieel worden ondersteund op de [Swift Releases](https://swift.org/download/#releases) pagina.

Na het selecteren van de distributie, kies een plan en datacenter regio van uw voorkeur. Stel dan een SSH sleutel in om toegang te krijgen tot de server nadat deze is aangemaakt. Klik tenslotte op Droplet aanmaken en wacht tot de nieuwe server is opgestart.

Als de nieuwe server klaar is, ga dan met de muis over het IP adres van de Droplet en klik op kopiëren.

![Droplet List](../images/digital-ocean-droplet-list.png)

## Initiële Instelling

Open uw terminal en maak verbinding met de server als root met SSH.

```sh
ssh root@your_server_ip
```

DigitalOcean heeft een diepgaande gids voor [initiële serverinstallatie op Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). Deze gids zal snel de basis behandelen.

### Configureer Firewall

Sta OpenSSH toe door de firewall en schakel het in.

```sh
ufw allow OpenSSH
ufw enable
```

### Voeg Gebruiker Toe

Maak een nieuwe gebruiker aan naast `root`. Deze handleiding noemt de nieuwe gebruiker `vapor`.

```sh
adduser vapor
```

Sta de nieuw aangemaakte gebruiker toe `sudo` te gebruiken.

```sh
usermod -aG sudo vapor
```

Kopieer de geautoriseerde SSH sleutels van de root gebruiker naar de nieuw aangemaakte gebruiker. Dit zal u toelaten om in te SSH-en als de nieuwe gebruiker.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

Verlaat tenslotte de huidige SSH-sessie en meld u aan als de nieuw aangemaakte gebruiker. 

```sh
exit
ssh vapor@your_server_ip
```

## Installeer Swift

Nu dat je een nieuwe Ubuntu server hebt aangemaakt en ingelogd bent als een niet-root gebruiker kan je Swift installeren. 

### Swift Afhankelijkheden

Installeer de vereiste afhankelijkheden van Swift.

```sh
sudo apt-get update
sudo apt-get install binutils git gnupg2 libc6-dev libcurl4-openssl-dev 
 	\ libedit2 libgcc-9-dev libpython3.8 libsqlite3-0 libstdc++-9-dev 
 	\ libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev
```

### Swift Toolchain Downloaden

Deze handleiding installeert Swift 5.7.3. Bezoek de [Swift Releases](https://swift.org/download/#releases) pagina voor een link naar de laatste release. Kopieer de download link voor Ubuntu 22.04.

![Download Swift](../images/swift-download-ubuntu-copy-link.png)

Download en decomprimeer de Swift toolchain.

```sh
wget https://download.swift.org/swift-5.7.3-release/ubuntu2204/swift-5.7.3-RELEASE/swift-5.7.3-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-5.7.3-RELEASE-ubuntu22.04.tar.gz
```

!!! note "Opmerking"
	Swift's [Downloads gebruiken](https://swift.org/download/#using-downloads) gids bevat informatie over hoe downloads te verifiëren met PGP-handtekeningen.

### Installeer Swift Toolchain

Zet Swift ergens waar het makkelijk toegankelijk is. Deze gids zal `/swift` gebruiken met elke compiler versie in een submap. 

```sh
sudo mkdir /swift
sudo mv swift-5.7.3-RELEASE-ubuntu22.04 /swift/5.7.3
```

Voeg Swift toe aan `/usr/bin` zodat het kan worden uitgevoerd door `vapor` en `root`.

```sh
sudo ln -s /swift/5.7.3/usr/bin/swift /usr/bin/swift
```

Controleer of Swift correct is geïnstalleerd.

```sh
swift --version
```

## Installeer Vapor met de Vapor Toolbox

Nu Swift geïnstalleerd is, laten we Vapor installeren door de Vapor Toolbox te gebruiken. U moet via de broncode de toolbox bouwen. Bekijk de toolbox [releases](https://github.com/vapor/toolbox/releases) op Github om de laatste versie te vinden. In dit voorbeeld gebruiken we versie 18.6.0.

### Clone & Build Vapor

Kloon de Vapor Toolbox repository
```sh
git clone https://github.com/vapor/toolbox.git
```

Haal de laatste release op.

```sh
cd toolbox
git checkout 18.6.0
```

Bouw Vapor en verplaats de binary in je pad.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Maak een Vapor Project

Gebruik het `new` commando van de Toolbox om een nieuw project aan te maken

```sh
vapor new HelloWorld -n
```

!!! tip
	De `-n` vlag geeft je een barebones sjabloon door automatisch nee te antwoorden op alle vragen

![Vapor Splash](../images/vapor-splash.png)

Eens het commando gedaan is kan je naar de nieuw gemaakte folder gaan:

```sh
cd HelloWorld
```

### Open HTTP Port

Om je Vapor applicatie te kunnen gebruiken, moet je een HTTP poort openzetten.

```sh
sudo ufw allow 8080
```

### Run

Nu dat Vapor klaar is en we een open poort hebben, laten we het commando runnen.

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

Bezoek de IP van uw server via een browser of lokale terminal en u zou moeten zien "It works!". Het IP address in dit voorbeeld is `134.122.126.139`.

```
$ curl http://157.245.244.228
It works!
```

Terug op je server, zou je logs moeten zien voor het test verzoek.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

Gebruik `CTRL+C` om de server af te sluiten. Het afsluiten kan even duren.

Gefeliciteerd met het draaien van uw Vapor app op een DigitalOcean Droplet!

## Volgende Stappen

De rest van deze gids verwijst naar aanvullende bronnen om uw inzet te verbeteren. 

### Supervisor

Supervisor is een procescontrolesysteem dat uw Vapor executable kan draaien en bewaken. Met de setup van supervisor kan uw app automatisch starten wanneer de server opstart en herstart worden in geval van een crash. Meer informatie over [Supervisor](../deploy/supervisor.md).

### Nginx

Nginx is een extreem snelle, in de strijd geteste, en eenvoudig te configureren HTTP server en proxy. Hoewel Vapor het direct serveren van HTTP verzoeken ondersteunt, kan proxying achter Nginx voor betere prestaties, veiligheid en gebruiksgemak zorgen. Leer meer over [Nginx](../deploy/nginx.md).
