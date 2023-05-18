# Loggen 

Vapor's logging API is gebouwd bovenop [SwiftLog](https://github.com/apple/swift-log). 
Dit betekent dat Vapor compatibel is met alle [backend implementaties](https://github.com/apple/swift-log#backends) van SwiftLog.

## Logger

Instanties van `Logger` worden gebruikt voor het wegschrijven van log berichten. Vapor biedt een paar eenvoudige manieren om toegang te krijgen tot een logger.

### Verzoek

Elk inkomende `Request` heeft een unieke logger die je moet gebruiken voor alle logs die specifiek zijn voor dat verzoek.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

De verzoeklogger bevat een unieke UUID die het inkomende verzoek identificeert om het traceren van logs te vergemakkelijken.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
	Logger metadata zal alleen getoond worden in debug log level of lager.

### Applicatie

Voor log berichten tijdens het opstarten en configureren van de app, gebruik `Application`'s logger.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Aangepaste Logger

In situaties waar je geen toegang hebt tot `Application` of `Request`, kan je een nieuwe `Logger` initialiseren. 

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Hoewel aangepaste loggers nog steeds zullen uitvoeren naar je geconfigureerde logboek backend, zullen ze geen belangrijke metadata zoals verzoek UUID bijgevoegd hebben. Gebruik waar mogelijk de verzoek- of applicatiespecifieke loggers. 

## Niveaus

SwiftLog ondersteunt verschillende logging niveaus.

|naam|beschrijving|
|-|-|
|trace|Geschikt voor berichten die informatie bevatten die normaal alleen van nut is bij het traceren van de uitvoering van een programma.|
|debug|Geschikt voor berichten die informatie bevatten die normaal alleen nuttig is bij het debuggen van een programma.|
|info|Geschikt voor informatieve berichten.|
|notice|Geschikt voor omstandigheden die geen foutomstandigheden zijn, maar die mogelijk een speciale behandeling vereisen.|
|warning|Geschikt voor berichten die geen foutconditie zijn, maar ernstiger dan een mededeling.|
|error|Geschikt voor foutcondities.|
|critical|Geschikt voor kritieke foutcondities die gewoonlijk onmiddellijke aandacht vereisen.|

Wanneer een `critical` bericht is gelogd, is de logging backend vrij om zwaardere operaties uit te voeren om systeem status vast te leggen (zoals het vastleggen van stack traces) om debugging te vergemakkelijken.

Standaard zal Vapor `info` niveau logging gebruiken. Wanneer de `productie` omgeving wordt gebruikt, zal `notice` worden gebruikt om de performance te verbeteren. 

### Log Niveau Veranderen

Ongeacht de omgevingsmodus, kunt u het log-niveau aanpassen om de hoeveelheid geproduceerde logs te vergroten of te verkleinen. 

De eerste methode is om de optionele `--log` vlag mee te geven bij het opstarten van je applicatie. 

```sh
swift run App serve --log debug
```

De tweede methode is het instellen van de `LOG_LEVEL` omgevingsvariabele.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Beide kunnen worden gedaan in Xcode door het `App` schema te bewerken.

## Configuratie

SwiftLog wordt geconfigureerd door het `LoggingSystem` één keer per proces te bootstrappen. Vapor projecten doen dit meestal in `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` is een helper methode van Vapor die de standaard log handler configureert gebaseerd op command-line argumenten en omgevingsvariabelen. De standaard log handler ondersteunt de uitvoer van berichten naar de terminal met ondersteuning voor ANSI kleuren. 

### Aangepaste Handler

U kunt Vapor's standaard log handler overschrijven en uw eigen log handler registreren.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Alle ondersteunde backends van SwiftLog werken met Vapor. Echter, het veranderen van het log niveau met command-line argumenten en omgevingsvariabelen is alleen compatibel met Vapor's standaard log handler.
