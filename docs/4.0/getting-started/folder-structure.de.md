# Ordnerstruktur

Lass uns einen Blick auf die Ordnerstruktur von Vapor werfen. Die Ordnerstruktur von Vapor orientiert sich an den Vorgaben des [Swift Package Managers](spm.md). Falls du schon mal mit dem SPM gearbeitet hast, sollte sie dir bekannt vorkommen.

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

Die folgenden Abschnitte erläutern jeden Teil der Ordnerstruktur genauer.

## Public

Der Ordner _Public_ beinhaltet Dateien, die sozusagen mitveröffentlicht werden. Das können Dateien für die Seitendarstellung sein, wie z. B. Bilder, CSS/JS-Dateien sein. Ein Aufruf von `localhost:8080/favicon.ico` prüft beispielsweise, ob `Public/favicon.ico` existiert, und liefert diese Datei zurück. Damit Vapor während der Ausführung auf den Ordner zugreifen kann muss eine _FileMiddleware_ in der Datei `configure.swift` mitangegeben werden.

```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Im Ordner _Sources_ befinden sich die eigentlichen Anwendungsdateien deines Projektes.

### App

Der Ordner _App_ beinhaltet die Anwendungslogik und stellt zudem, wie in der [Paketbeschreibung](spm.md) angegeben, das Modul des Paketes dar.

#### Controllers

Der Ordner _Controllers_ beinhaltet die Definitionen der Endpunkte der Anwendung. Mehr dazu findest du im Abschnitt [Controllers](../basics/controllers.md).

#### Migrations

Der Ordner _Migrations_ beinhaltet die Definitionen zu Tabellen der Datenbank.

#### Models

Der Ordner _Models_ ist ein guter Ort, um deine `Content`-Structs oder Fluent `Model`s zu speichern.

#### configure.swift

Die Datei _configure.swift_ umfasst die Methode `configure(_:)`. Sie wird vom Einstiegspunkt aufgerufen um die Anwendung mit entsprechenden Angaben zu Endpunkten, zur Datenbank oder zu Providern zu konfigurieren.

#### entrypoint.swift

In der Datei _entrypoint.swift_ befindet sich der Einstiegspunkt (`@main`) für die Anwendung, von dem aus die Anwendung eingerichtet, konfiguriert und gestartet wird.

#### routes.swift

Die Datei _routes.swift_ beinhaltet die Methode `routes(_:)`. Sie wird am Ende von der `configure(_:)`-Methode aufgerufen um die Endpunkte zu registrieren. 

## Tests

Für jedes nicht-ausführbare Modul in deinem Ordner _Sources_ kann ein entsprechender Ordner unter _Tests_ angelegt werden. Dieser enthält Code, der auf dem `XCTest`-Modul aufbaut, um dein Paket zu testen. Tests können über die Kommandozeile mit `swift test` oder in Xcode mit ⌘+U ausgeführt werden.

### AppTests

Der Ordner _AppTests_ beinhaltet alle möglichen Tests für Komponenten der Anwendung.

## Package.swift

Die Datei _Package.swift_ ist die [Paketbeschreibung](spm.md) des SPM.
