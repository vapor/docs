# Swift Package Manager

Über den [Swift Package Manager](https://www.swift.org/package-manager/) können verschiedene Pakete in einem Projekt zusammengefasst und eingebunden werden. Damit ist der Manager ähnlich zu anderen Lösungen, wie CocoaPods, Ruby gems oder NPM. Ein offizielles, zentrales Paketeregister gibt es allerdings nicht, daher greift der Manager stattdessen über Git auf die jeweiligen Pakete zu. 

### Paketbeschreibung

Das Herzstück des Paketmanagers ist die Paketbeschreibung. Sie befindet sich im Hauptverzeichnis eines Paketes. Die Beschreibung beinhaltet unter anderem Angaben zu Swift-Tools, den Paketnamen, dem Paketinhalt und die Abhängigkeiten.

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

#### - Swift-Tools

Die erste Zeile in der Beschreibung deklariert die für das Paket notwendige Mindestversion von Swift. Je nach Versionsstand können sich zudem die Paketbeschreibungen unterscheiden!

#### - Name

Der Parameter _Name_ legt den Paketnamen fest.

#### - Platforms

Der Parameter _Platforms_ beschreibt für welche Systeme letzten Endes das Paket sein soll. Wenn z.B. als Plattform `.macOS(.v12)` angegeben wird, wird macOS 12 oder neuer erwartet.

#### - Dependencies

Dependencies sind Paketverweise, auf die das Paket aufbaut und daher für die Ausführung zwingend benötigt werden. Deshalb auch Abhängigkeiten genannt. Im Falle von Vapor, verweisen alle Vapor-Pakete auf die aktuelle Vapor-Version. Neben dem Vapor-Paketverweis, können weitere Verweise hinzugefügt werden.

#### - Targets

Targets sind Module, Dateien oder Tests. Vapor-Anwendungen beinhalten bis zu zwei Targets.

### Ordnerstruktur

Die Ordnerstruktur eines Paketes sieht wie folgt aus:

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

### Resolved-Datei

Bei der ersten Ausführung des Paketes wird automatisch im Hauptverzeichnis eine Datei _Package.resolved_ erstellt. Die Datei listet die angegeben Abhängigkeiten inklusive Versionsstand auf. Hier ist zu beachten, dass das Paket sich erstmal an den Vorgaben in der Resolved-Datei hält, selbst wenn es bereits einen neuen Versionsstand einer Abhängigkeit gibt.

Die Resolved-Datei kann über die Menüpunkte *File* → *Swift Packages* → *Update To Latest Swift Package Versions* aktualisiert werden.

### Xcode

Veränderungen an der Paketbeschreibung werden in Xcode mit Speichern sofort umgesetzt.