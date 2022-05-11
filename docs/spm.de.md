# Swift Package Manager

Über den [Swift Package Manager](https://www.swift.org/package-manager/) können verschiedene Pakete in einem Projekt zusammengefasst und eingebunden werden. Damit ist der Manager ähnlich zu anderen Lösungen, wie CocoaPods, Ruby gems oder NPM. Ein offizielles, zentrales Paketeregister gibt es allerdings nicht, daher greift der Manager stattdessen über Git auf die jeweiligen Pakete zu. 

### Paketbeschreibung

Das Herzstück des Paketmanagers ist die Paketbeschreibung. Sie befindet sich im Hauptverzeichnis eines Paketes. Die Beschreibung beinhaltet unter anderem Angaben zu Swift-Tools, den Paketnamen, dem Paketinhalt und die Abhängigkeiten.

```swift
/// [Package.swift]

// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "app",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "Run", targets: ["Run"]),
        .library(name: "App", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [.product(name: "Vapor", package: "vapor")]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
```

#### - Swift-Tools

Die erste Zeile in der Beschreibung deklariert die für das Paket notwendige Mindestversion von Swift. Je nach Versionsstand können sich zudem die Paketbeschreibungen unterscheiden!

#### - Name

Der Parameter _Name_ legt den Paketnamen fest.

#### - Platforms

Der Parameter _Platforms_ beschreibt für welche Systeme letzten Endes das Paket sein soll. Wenn z.B. als Plattform `.macOS(.v10.14)` angegeben wird, wird macOS Mojave oder neuer erwartet.

#### - Products

Der Parameter _Products_ fasst die Targets zusammen.

#### - Dependencies

Dependencies sind Paketverweise, auf die das Paket aufbaut und daher für die Ausführung zwingend benötigt werden. Deshalb auch Abhängigkeiten genannt. Im Falle von Vapor, verweisen alle Vapor-Pakete auf die aktuelle Vapor-Version. Neben dem Vapor-Paketverweis, können weitere Verweise hinzugefügt werden.

#### - Targets

Targets sind Module, Dateien oder Tests. Vapor-Anwendungen beinhalten bis zu drei Targets.

### Ordnerstruktur

Die Ordnerstruktur eines Paketes sieht wie folgt aus:

```
.
├── Sources
│   ├── App
│   │   └── (Source code)
│   └── Run
│       └── main.swift
├── Tests
│   └── AppTests
└── Package.swift
```

### Resolved-Datei

Bei der ersten Ausführung des Paketes wird automatisch im Hauptverzeichnis eine Datei _Package.resolved_ erstellt. Die Datei listet die angegeben Abhängigkeiten inklusive Versionsstand auf. Hier ist zu beachten, dass das Paket sich erstmal an den Vorgaben in der Resolved-Datei hält, selbst wenn es bereits einen neuen Versionsstand einer Abhängigkeit gibt.

Die Resolved-Datei kann über die Menüpunkte *File* → *Swift Packages* → *Update To Latest Swift Package Versions* aktualisiert werden.

### Xcode

Veränderungen an der Paketbeschreibung werden in Xcode mit Speichern sofort umgesetzt.