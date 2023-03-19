# Protokollierung 

Die Protokollierung in Vapor baut auf Apple's [SwiftLog](https://github.com/apple/swift-log) auf.

## Logger

Die Instanz _Logger_ gibt die Einträge aus. Du kannst über mehrere Wege auf die Instanz zugreifen.

### Request

Jede eingehende Anfrage besitzt eine unabhängige Logger-Instanz, die du für die jeweilige Anfrage verwenden kannst. Zudem kannst du über die Logging-ID leichter zurückverfolgen.

Beispiel:

```swift
/// [controller.swift]

app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info Logger metadata will only be shown in debug log level or lower.

### Application

Für Protokollausgaben während des Bootvorganges oder der Einrichtung, kannst du über Instanz _Application_ auf die Logger-Instanz zu greifen.

Beispiel:

```swift
/// [configure.swift]

app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Custom Logger

Falls du nicht auf Instanzen _Application_ oder _Request_ zurückgreifen kannst, kannst du selbstverständlich auch eine neue eigene Logger-Instanz erstellen. Beachte jedoch, dass diese Instanz nicht die selben Metdadaten besitzt, wie beispielweise einen bestehende Instanz über _Application_ oder _Request_, daher empfehlen wir dir, wenn möglich, eher diese zu benutzen.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

## Protokolliergrade

In SwiftLog gibt es mehrere verschiedenen Protokolliergrade:

|Bezeichnung|Beschreibung                                                                                                   |
|-----------|---------------------------------------------------------------------------------------------------------------|
|trace      |Appropriate for messages that contain information normally of use only when tracing the execution of a program.|
|debug      |Zum Debuggen und für die Entwicklung.
|info       |Für allgemeine Informationen.                                                                                  |
|notice     |Für ungewöhnliche oder unerwartete Ereignisse, die jedoch zu keinen Ausfall der Anwendung führen.              |
|warning    |Für ..             |
|error      |Für Fehler und Ausnahmen.                                                                                      |
|critical   |Für Fehler, die sofortige Aufmerksamkeit erfordern.                                                            |

When a `critical` message is logged, the logging backend is free to perform more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate debugging.

Vapor protokolliert standardmäßig mit den Grad _info_. Mit Wechseln in die Produktionsumgebung verwendet Vapor zur Verbesserung der Performaance den Grad _notice_.

### Changing Log Level

Unhabhängig von der Umgebung kannst du Vapor den gewünschten Protokolliergrad mit Hilfe des Parameters _--log_ oder der Umgebungsvariable _LOG_LEVEL_ beim Booten mitgeben.

```sh
vapor run serve --log debug
```

oder 

```sh
export LOG_LEVEL=debug
vapor run serve
```

Beides kann über das Schema _Run_ in Xcode eingestellt werden. Wie du ein Schema in Xcode veränderst, wird dir im Abschnitt [Xcode]() erklärt.

## Einrichtung

```swift
/// [main.swift]

import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` is a helper method provided by Vapor that will configure the default log handler based on command-line arguments and environment variables. The default log handler supports outputting messages to the terminal with ANSI color support. 

### Custom Handler

You can override Vapor's default log handler and register your own.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Dadurch würde die Protokollierung in Vapor auch mit jedem anderen SwiftLog [Protokollierungsanbieter](https://github.com/apple/swift-log#backends) funktionieren.

All of SwiftLog's supported backends will work with Vapor. However, changing the log level with command-line arguments and environment variables is only compatible with Vapor's default log handler.