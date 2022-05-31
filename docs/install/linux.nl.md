# Installeren op Linux

Om Vapor te gebruiken op Linux, zal je Swift 5.2 of hoger nodig hebben. Dit kan geïnstalleerd worden met de toolchains te vinden op [Swift.org](https://swift.org/download/).

## Ondersteunde distributies en versies

Vapor ondersteund dezelfde versies van Linux distributies die Swift 5.2 of hogere versies ook ondersteunen.

!!! Opmerking
    The ondersteunde versies hieronder kunnen op elke moment verouderd zijn. Je kan zien welke besturingssystemen officiele ondersteuning krijgen op de [Swift Releases](https://swift.org/download/#releases/) pagina.

|Distribution|Version|Swift Version|
|-|-|-|
|Ubuntu|16.04, 18.04|>= 5.2|
|Ubuntu|20.04|>= 5.2.4|
|Fedora|>= 30|>= 5.2|
|CentOS|8|>= 5.2.4|
|Amazon Linux|2|>= 5.2.4|

Linux distributies die niet officieel ondersteund zijn kunnen mogelijks ook Swift uitvoeren door de broncode te compileren, maar Vapor kan geen stabiliteit garanderen. Meer informatie over het compileren van Swift kan gevonden worden op de [Swift repo](https://github.com/apple/swift#getting-started).

## Installeer Swift

Bezoek Swift.org's [Using Downlaods](https://swift.org/download/#using-downloads) gids voor instructies over het installeren van Swift op Linux.

### Fedora

Fedora gebruikers kunnen eenvoudig het volgende commando gebruiken om Swift te installeren:

```sh
sudo dnf install swift-lang
```

Als je Fedore 30 gebruikt, dan zal je EPEL 8 moeten toevoegen om Swift 5.2 of nieuwere versies te krijgen.

## Docker

Je kan ook de officiële Docker images van Swift gebruiken, die met de compiler vooraf geïnstalleerd komen. Meer informatie op [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Installeer de Toolbox

Nu dat je Swift hebt geïnstalleerd, laten we [Vapor's Toolbox](https://github.com/vapor/toolbox) installeren. Deze CLI tool is niet noodzakelijk om Vapor te gebruiken, maar het bevat wel handige hulpprogramma's.

Op Linux zal je de toolbox moeten bouwen vanaf de bron. Bekijk de <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> van de toolbox op GitHub om de nieuwste versie te vinden.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Controlleer of de installatie is gelukt door het help commando te gebruiken.

```sh
vapor --help
```

Je zou een lijst met beschikbare commando's moeten zien.

## Next

Nadat je Swift hebt geïnstalleerd, maak je eerste applicatie in [Aan De Slag &rarr; Hallo, wereld](../getting-started/hello-world.md).
