# Installeren op macOS

Om Vapor te gebruiken op macOS, zal je Swift 9 of hoger nodig hebben. Swift en al zijn afhankelijkheden komen gebundeld met Xcode.

## Installeer Xcode

Installeer [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) van de Mac App Store.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Nadat Xcode gedownload is, moet je het openen om de installatie te vervolledigen. Dit kan even duren.

Controleer nogmaals of de installatie is gelukt door de Terminal te openen en de Swift versie af te drukken.

```sh
swift --version
```

Je zou de Swift versie informatie afgedrukt moeten zien.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4 vereist Swift 5.9 of hoger.

## Installeer de Toolbox

Nu dat Swift geïnstalleerd is, laten we de [Vapor Toolbox](https://github.com/vapor/toolbox) installeren. Deze CLI tool is niet noodzakelijk om Vapor te gebruiken, maar het bevat wel handige hulpprogramma's zoals een nieuwe project creator.

De Toolbox wordt gedistribueerd via Homebrew. Als je Homebrew nog niet hebt geinstalleerd, bezoek dan <a href="https://brew.sh" target="_blank">brew.sh</a> voor installeer instructies. 

```sh
brew install vapor
```

Controleer of de installatie is gelukt door het help commando te gebruiken.

```sh
vapor --help
```

Je zou een lijst met beschikbare commando's moeten zien.

## Next

Nadat je Swift hebt geïnstalleerd, maak je eerste applicatie in [Aan De Slag &rarr; Hallo, wereld](../getting-started/hello-world.md).