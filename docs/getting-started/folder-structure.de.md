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

## Public

Der Ordner _Public_ beinhaltet Dateien, die sozusagen mitveröffentlicht werden. Das können Dateien für die Seitendarstellung sein, wie z. B. Bilder, CSS/JS-Dateien sein. Damit Vapor während der Ausführung auf den Ordner zugreifen kann muss eine _FileMiddleware_ in der Datei `configure.swift` mitangegeben werden.

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

Der Ordner _App_ beinhaltet die Anwendungslogik und stellt zudem, wie in der [Paketbeschreibung](../getting-started/spm.md) angegeben, das Modul des Paketes dar.

#### Controllers

Der Ordner _Controllers_ beinhaltet die Definitionen der Endpunkte der Anwendung. Mehr dazu findest du im Abschnitt [Controllers](../basics/controllers.md).

#### Migrations

Der Ordner _Migrations_ beinhaltet die Definitionen zu Tabellen der Datebank.

#### Models

Der Ordner _Models_ beinhaltet die Klassendefinitionen für die Entitäten.

#### configure.swift

Die Datei _configure.swift_ umfasst die Methode `configure(_:)`. Sie wird vom Einstiegspunkt aufgerufen um die Anwendung mit entsprechenden Angaben zu Endpunkten, zur Datenbank oder zu Providern zu konfigurieren.

#### entrypoint.swift

In der Datei _entrypoint.swift_ befindet sich der Einstiegspunkt (`@main`) für die Anwendung, von dem aus die Anwendung eingerichtet, konfiguriert und gestartet wird.

#### routes.swift

Die Datei _routes.swift_ beinhaltet die Methode `routes(_:)`. Sie wird am Ende von der `configure(_:)`-Methode aufgerufen um die Endpunkte zu registrieren. 

## Tests

Für jedes Paketmodul kann ein entsprechender Ordner unter _Tests_ angelegt werden.

### AppTests

Der Ornder _AppTests_ beinhaltet alle möglichen Tests für Komponenten der Anwendung.

## Package.swift

Die Datei _Package.swift_ ist die Paketbeschreibung.
