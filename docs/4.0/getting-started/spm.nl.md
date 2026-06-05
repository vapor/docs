# Swift Package Manager

De [Swift Package Manager](https://swift.org/package-manager/) (SPM) wordt gebruikt voor het bouwen van de broncode en afhankelijkheden van uw project. Aangezien Vapor zwaar leunt op SPM, is het een goed idee om de basis van hoe het werkt te begrijpen.

SPM is vergelijkbaar met Cocoapods, Ruby gems, en NPM. U kunt SPM vanaf de command line gebruiken met commando's als `swift build` en `swift test` of met compatibele IDE's. Echter, in tegenstelling tot sommige andere pakketbeheerders, is er geen centrale pakket index voor SPM pakketten. SPM maakt in plaats daarvan gebruik van URLs naar Git repositories en versies afhankelijkheden met behulp van [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

## Package Manifest

De eerste plaats waar SPM kijkt in uw project is het package manifest. Dit moet altijd in de root directory van je project staan en `Package.swift` heten.

Een voorbeeld van een package manifest kan hieronder gevonden worden.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Elk onderdeel van het manifest wordt in de volgende secties toegelicht.

### Tools Version

De allereerste regel van een pakketmanifest geeft de vereiste versie van Swift-tools aan. Dit specificeert de minimale versie van Swift die het pakket ondersteunt. De API van de pakketbeschrijving kan ook veranderen tussen Swift-versies, dus deze regel zorgt ervoor dat Swift weet hoe het je manifest moet parsen.

### Package Name

Het eerste argument voor `Package` is de naam van het pakket. Als het pakket publiek is, zou je het laatste segment van de Git repo URL als naam moeten gebruiken.

### Platforms

De `platforms` array specificeert welke platformen dit pakket ondersteunt. Door `.macOS(.v12)` op te geven heeft dit pakket macOS 12 of hoger nodig. Wanneer Xcode dit project laadt, zal het automatisch de minimale deployment versie op macOS 12 zetten, zodat je alle beschikbare APIs kunt gebruiken.

### Dependencies

Afhankelijkheden zijn andere SPM pakketten waar uw pakket afhankelijk van is. Alle Vapor applicaties vertrouwen op het Vapor pakket, maar u kunt zoveel andere afhankelijkheden toevoegen als u wilt.

In het bovenstaande voorbeeld kunt u zien dat [vapor/vapor](https://github.com/vapor/vapor) versie 4.0.0 of later een dependency is van dit pakket. Wanneer u een afhankelijkheid aan uw pakket toevoegt, moet u vervolgens aangeven welke [targets](#targets) afhankelijk zijn van
de nieuw beschikbare modules.

### Targets

Targets zijn alle modules, executables, en testen die je package bevat. De meeste Vapor applicaties zullen twee targets hebben, hoewel je er zoveel kunt toevoegen als je wilt om je code te organiseren. Elke target verklaart van welke modules het afhankelijk is. Je moet hier namen van modules toevoegen om ze te kunnen importeren in je code. Een target kan afhangen van andere targets in je project of van modules die je hebt toegevoegd aan
de [main dependencies](#dependencies) array.

## Folder Structure

Hieronder ziet u de typische mappenstructuur voor een SPM-pakket.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Elk `.target` of `.executableTarget` komt overeen met een map in de `Sources` map. 
Elk `.testTarget` komt overeen met een map in de `Tests` map.

## Package.resolved

De eerste keer dat u uw project bouwt, zal SPM een `Package.resolved` bestand maken dat de versie van elke dependency opslaat. De volgende keer dat u uw project bouwt, zullen dezelfde versies worden gebruikt, zelfs als er nieuwere versies beschikbaar zijn. 

Om uw dependencies te updaten, voert u `swift package update` uit.

## Xcode

Als je Xcode 11 of hoger gebruikt, zullen wijzigingen in afhankelijkheden, targets, producten, etc automatisch gebeuren wanneer het `Package.swift` bestand wordt gewijzigd. 

Als je wilt updaten naar de laatste afhankelijkheden, gebruik dan File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

Je wilt misschien ook het `.swiftpm` bestand toevoegen aan je `.gitignore`. Dit is waar Xcode je Xcode project configuratie opslaat.
