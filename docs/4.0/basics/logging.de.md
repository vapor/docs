# Protokollierung 

Vapors Protokollierungs-API baut auf [SwiftLog](https://github.com/apple/swift-log) auf. Das bedeutet, dass Vapor mit allen [Backend-Implementierungen](https://github.com/apple/swift-log#backends) von SwiftLog kompatibel ist.

## Logger

Instanzen von `Logger` werden verwendet, um Protokollmeldungen auszugeben. Vapor bietet mehrere einfache Möglichkeiten, um Zugriff auf einen Logger zu erhalten.

### Request

Jede eingehende `Request` besitzt einen eigenen Logger, den du für alle Protokolle verwenden solltest, die sich auf diese Anfrage beziehen.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

Der Request-Logger enthält eine eindeutige UUID, die die eingehende Anfrage kennzeichnet, um das Nachverfolgen von Protokollen zu erleichtern.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
    Logger-Metadaten werden nur bei der Protokollstufe `debug` oder niedriger angezeigt.

### Application

Für Protokollmeldungen während des App-Starts und der Konfiguration verwendest du den Logger von `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Benutzerdefinierter Logger

Wenn du keinen Zugriff auf `Application` oder `Request` hast, kannst du einen neuen `Logger` initialisieren.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Benutzerdefinierte Logger geben zwar weiterhin auf deinem konfigurierten Protokollierungs-Backend aus, verfügen jedoch nicht über wichtige Metadaten wie die Request-UUID. Verwende nach Möglichkeit stets die Request- oder Application-spezifischen Logger. 

## Protokollstufe

SwiftLog unterstützt mehrere unterschiedliche Protokollstufen.

|name|description|
|-|-|
|trace|Geeignet für Meldungen, die normalerweise nur beim Nachverfolgen der Programmausführung nützlich sind.|
|debug|Geeignet für Meldungen, die normalerweise nur beim Debuggen eines Programms nützlich sind.|
|info|Geeignet für informative Meldungen.|
|notice|Geeignet für Zustände, die keine Fehlerzustände sind, aber möglicherweise eine besondere Behandlung erfordern.|
|warning|Geeignet für Meldungen, die keine Fehlerzustände sind, aber schwerwiegender als `notice`.|
|error|Geeignet für Fehlerzustände.|
|critical|Geeignet für kritische Fehlerzustände, die üblicherweise sofortiges Handeln erfordern.|

Wenn eine `critical`-Meldung protokolliert wird, steht es dem Protokollierungs-Backend frei, aufwendigere Operationen durchzuführen, um den Systemzustand zu erfassen (etwa das Erfassen von Stack-Traces), um das Debuggen zu erleichtern.

Standardmäßig verwendet Vapor die Protokollstufe `info`. Wird die Umgebung `production` verwendet, kommt zur Verbesserung der Performance die Stufe `notice` zum Einsatz. 

### Ändern der Protokollstufe

Unabhängig vom Umgebungsmodus kannst du die Protokollstufe überschreiben, um die Menge der erzeugten Protokolle zu erhöhen oder zu verringern. 

Die erste Methode besteht darin, beim Start deiner Anwendung das optionale Flag `--log` zu übergeben.

```sh
swift run App serve --log debug
```

Die zweite Methode besteht darin, die Umgebungsvariable `LOG_LEVEL` zu setzen.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Beides kann in Xcode über das Schema `App` eingestellt werden.

## Konfiguration

SwiftLog konfigurierst du, indem du `LoggingSystem` einmal pro Prozess bootstrappst. Vapor-Projekte tun dies üblicherweise in `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` ist eine von Vapor bereitgestellte Hilfsmethode, die den Standard-Log-Handler basierend auf Kommandozeilenargumenten und Umgebungsvariablen konfiguriert. Der Standard-Log-Handler unterstützt die Ausgabe von Meldungen im Terminal mit ANSI-Farbunterstützung. 

### Benutzerdefinierter Handler

Du kannst Vapors Standard-Log-Handler überschreiben und deinen eigenen registrieren.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Alle von SwiftLog unterstützten Backends funktionieren mit Vapor. Das Ändern der Protokollstufe über Kommandozeilenargumente und Umgebungsvariablen ist jedoch nur mit Vapors Standard-Log-Handler kompatibel.
