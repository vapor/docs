# Installeren op Linux

Om Vapor te gebruiken, heb je Swift 5.9 of hoger nodig. Dit kan geïnstalleerd worden met de CLI-tool [Swiftly](https://swiftlang.github.io/swiftly/), aangeboden door de Swift Server Workgroup (aanbevolen), of met de toolchains die beschikbaar zijn op [Swift.org](https://swift.org/download/).

## Ondersteunde distributies en versies

Vapor ondersteunt dezelfde versies van Linux distributies die Swift 5.9 of nieuwere versies ondersteunen. Raadpleeg de [officiële support pagina](https://www.swift.org/platform-support/) voor actuele informatie over welke besturingssystemen officieel ondersteund worden.

Linux distributies die niet officieel ondersteund zijn, kunnen mogelijks ook Swift uitvoeren door de broncode te compileren, maar Vapor kan geen stabiliteit garanderen. Meer informatie over het compileren van Swift kan gevonden worden op de [Swift repo](https://github.com/apple/swift#getting-started).

## Installeer Swift

### Geautomatiseerde installatie met de Swiftly CLI-tool (aanbevolen)

Bezoek de [Swiftly website](https://swiftlang.github.io/swiftly/) voor instructies over het installeren van Swiftly en Swift op Linux. Installeer daarna Swift met het volgende commando:

#### Basisgebruik

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

### Handmatige installatie met de toolchain

Bezoek Swift.org's [Using Downloads](https://swift.org/download/#using-downloads) gids voor instructies over het installeren van Swift op Linux.

### Fedora

Fedora gebruikers kunnen eenvoudig het volgende commando gebruiken om Swift te installeren:

```sh
sudo dnf install swift-lang
```

Als je Fedora 35 gebruikt, dan zal je EPEL 8 moeten toevoegen om Swift 5.9 of nieuwere versies te krijgen.

## Docker

Je kan ook de officiële Docker images van Swift gebruiken, die met de compiler vooraf geïnstalleerd komen. Meer informatie op [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Installeer de Toolbox

Nu dat je Swift hebt geïnstalleerd, laten we de [Vapor Toolbox](https://github.com/vapor/toolbox) installeren. Deze CLI tool is niet noodzakelijk om Vapor te gebruiken, maar het helpt bij het aanmaken van nieuwe Vapor projecten.

### Homebrew

De Toolbox wordt gedistribueerd via Homebrew. Als je Homebrew nog niet hebt, bezoek dan <a href="https://brew.sh" target="_blank">brew.sh</a> voor installatie-instructies.

```sh
brew install vapor
```

Controleer of de installatie is gelukt door het help commando te gebruiken.

```sh
vapor --help
```

Je zou een lijst met beschikbare commando's moeten zien.

### Makefile

Als je wilt, kan je de Toolbox ook vanaf de bron bouwen. Bekijk de <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> van de Toolbox op GitHub om de nieuwste versie te vinden.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Controleer of de installatie is gelukt door het help commando te gebruiken.

```sh
vapor --help
```

Je zou een lijst met beschikbare commando's moeten zien.

## Volgende stap

Nu dat je Swift en de Vapor Toolbox hebt geïnstalleerd, maak je eerste applicatie in [Aan De Slag &rarr; Hallo, wereld](../getting-started/hello-world.md).
