# Swift Package Manager

Der [Swift Package Manager](https://swift.org/package-manager/) (SPM) wird verwendet, um den Quellcode deines Projekts und dessen Abhängigkeiten zu erstellen. Da Vapor stark auf SPM setzt, ist es sinnvoll, die Grundlagen seiner Funktionsweise zu verstehen.

SPM ist vergleichbar mit CocoaPods, Ruby Gems und NPM. Du kannst SPM über die Kommandozeile mit Befehlen wie `swift build` und `swift test` oder mit kompatiblen IDEs verwenden. Im Gegensatz zu einigen anderen Paketmanagern gibt es bei SPM jedoch kein zentrales Paketregister. Stattdessen nutzt SPM URLs zu Git-Repositories und versioniert Abhängigkeiten mithilfe von [Git-Tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

## Paketbeschreibung

Der erste Ort, an dem SPM in deinem Projekt nachsieht, ist die Paketbeschreibung. Diese sollte sich immer im Hauptverzeichnis deines Projekts befinden und `Package.swift` heißen.

Wirf einen Blick auf dieses Beispiel einer Paketbeschreibung.

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

Jeder Teil der Paketbeschreibung wird in den folgenden Abschnitten erklärt.

### Swift-Tools

Die allererste Zeile einer Paketbeschreibung gibt die erforderliche Swift-Tools-Version an. Diese legt die minimale Swift-Version fest, die das Paket unterstützt. Auch die Package-Description-API kann sich zwischen Swift-Versionen ändern, daher stellt diese Zeile sicher, dass Swift weiß, wie es deine Paketbeschreibung parsen soll.

### Name

Das erste Argument von `Package` ist der Name des Pakets. Wenn das Paket öffentlich ist, solltest du das letzte Segment der URL des Git-Repositories als Namen verwenden.

### Platforms

Das `platforms`-Array gibt an, welche Plattformen dieses Paket unterstützt. Durch die Angabe von `.macOS(.v12)` benötigt dieses Paket macOS 12 oder neuer. Wenn Xcode dieses Projekt lädt, setzt es automatisch die minimale Bereitstellungsversion auf macOS 12, damit du alle verfügbaren APIs nutzen kannst.

### Dependencies

Dependencies sind andere SPM-Pakete, auf die dein Paket angewiesen ist. Alle Vapor-Anwendungen sind auf das Vapor-Paket angewiesen, du kannst aber beliebig viele weitere Abhängigkeiten hinzufügen.

Im obigen Beispiel siehst du, dass [vapor/vapor](https://github.com/vapor/vapor) in Version 4.76.0 oder neuer eine Abhängigkeit dieses Pakets ist. Wenn du eine Abhängigkeit zu deinem Paket hinzufügst, musst du anschließend angeben, welche [Targets](#targets) von den neu verfügbaren Modulen abhängen.

### Targets

Targets sind alle Module, ausführbaren Dateien und Tests, die dein Paket enthält. Die meisten Vapor-Apps haben zwei Targets, du kannst aber beliebig viele hinzufügen, um deinen Code zu organisieren. Jedes Target gibt an, von welchen Modulen es abhängt. Du musst hier Modulnamen hinzufügen, um sie in deinem Code importieren zu können. Ein Target kann von anderen Targets in deinem Projekt abhängen oder von Modulen, die von Paketen bereitgestellt werden, die du dem [Dependencies-Array](#dependencies) hinzugefügt hast.

## Ordnerstruktur

Unten siehst du die typische Ordnerstruktur eines SPM-Pakets.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Jedes `.target` oder `.executableTarget` entspricht einem Ordner im `Sources`-Ordner.
Jedes `.testTarget` entspricht einem Ordner im `Tests`-Ordner.

## Package.resolved

Beim ersten Erstellen deines Projekts legt SPM eine `Package.resolved`-Datei an, die die Version jeder Abhängigkeit speichert. Beim nächsten Erstellen deines Projekts werden dieselben Versionen verwendet, selbst wenn neuere Versionen verfügbar sind.

Um deine Abhängigkeiten zu aktualisieren, führe `swift package update` aus.

## Xcode

Wenn du Xcode 11 oder höher verwendest, werden Änderungen an Abhängigkeiten, Targets, Produkten usw. automatisch übernommen, sobald die Datei `Package.swift` geändert wird.

Wenn du auf die neuesten Abhängigkeiten aktualisieren möchtest, verwende Datei &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

Du solltest außerdem die Datei `.swiftpm` zu deiner `.gitignore` hinzufügen. Dort speichert Xcode deine Xcode-Projektkonfiguration.
