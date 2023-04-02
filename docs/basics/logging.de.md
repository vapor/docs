# Protokollierung 

Mit der Protokollierung können Statusinformationen und Systemereignisse in Vapor festgehalten und ausgegeben werden. Die Protokollierung in Vapor baut auf Apple's [SwiftLog](https://github.com/apple/swift-log) auf.

## Logger

Die _Logger_ Instanz gibt die Protokollinformationen aus. Wir haben verschiedene Möglichkeiten auf die Instanz zuzugreifen.

**Zugriff über die Anfrage**

Jede eingehende Anfrage besitzt eine unabhängige _Logger_ Instanz, die für die jeweilige Anfrage verwendet werden kann.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

**Zugriff über die Anwendung**

Für Informationen während des Startens oder der Einrichtung können wir die Instanz _Application_ nutzen.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Benutzerdefinierte Protokollierung

Falls wir nicht auf Beides zurückgreifen können, können wir eine eigene Instanz erstellen.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

## Protokollstufen

Protokollstufen steuern den Informationsumfang. Vapor protokolliert standardmäßig auf der Stufe _info_. Mit Wechseln in die Produktionsumgebung verwendet Vapor zur Verbesserung der Performance die Stufe _notice_. Es gibt noch weitere Protokollstufen:

|Stufen|Beschreibung|
|-----------|---------------------------------------------------------------------------------------------------------------|
|trace|Geeignet für Informationen, die zur Ablaufverfolgung nüztlich sein können.|
|debug|Geeignet für Informationen, die fürs Debuggen nützlich sein können.|
|info|Geeignet für allgemeinen Informationen.|
|notice|Geeignet für unerwartete Ereignisse, die jedoch zu keinem Anwendungsausfall führen.|
|warning|Geeignet für unerwartete Ereignisse, die allerdings schwerwiegender sind als in _notice_.|
|error|Geeigent für Fehlerzustände.|
|critical|Geeignet für kritische Fehlerzustände, die ein sofortiges Handeln erfordern.|

### Festlegen einer Protokollstufe

Unhabhängig von der Umgebung können wir Protokollstufen mit Hilfe des Parameters _--log_ oder der Umgebungsvariable _LOG_LEVEL_ festlegen.

```sh
vapor run serve --log debug
```

oder 

```sh
export LOG_LEVEL=debug
vapor run serve
```

Beides kann über das Schema _Run_ in Xcode eingestellt werden. Im Abschnitt [Xcode](../getting-started/xcode.md) erklären wir dir, wie du ein Schema bearbeitest.

## Einrichtung

_SwiftLog_ wird von Vapor mit Hilfe der Methode _bootstrap(_:) basierend auf dem Kommandozeilenargument oder der Umgebungsvariable einmal pro Prozess eingerichtet. 

```swift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

### Protokollierungsanbieter

Der Standardanbieter kann, wenn gewünscht, überschrieben werden. Dank der Verwendung von _SwiftLog_ kann jeder kompatible [Protokollierungsanbieter](https://github.com/apple/swift-log#backends) verwendet werden. Allerdings ist das Ändern der Protokollierstufe per Kommandozeilenargument oder Umgebungsvariable nur mit dem Standardanbieter möglich.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```