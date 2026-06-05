# Logging

L'API di logging di Vapor è costruita utilizzando [SwiftLog](https://github.com/apple/swift-log). Ciò significa che Vapor è compatibile con tutte le [implementazioni backend](https://github.com/apple/swift-log?tab=readme-ov-file#available-log-handler-backends) supportate da SwiftLog.

## Logger

Le istanze di `Logger` sono usate per produrre messaggi di log. Vapor fornisce alcuni modi semplici per accedere a un logger.

### Request

Ogni `Request` in arrivo ha un logger univoco che dovresti usare per qualsiasi log specifico a quella richiesta.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

Il logger della richiesta include un UUID univoco che identifica la richiesta in arrivo per rendere più facile il tracciamento dei log.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info "Informazione"
	I metadati del logger verranno mostrati solo a livello di log debug o inferiore.

### Application

Per i messaggi di log durante l'avvio e la configurazione dell'app, usa il logger di `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Logger Personalizzato

In situazioni dove non hai accesso ad `Application` o `Request`, puoi inizializzare un nuovo `Logger`.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Sebbene i logger personalizzati producano ancora output nel tuo backend di logging configurato, non avranno metadati importanti allegati come l'UUID della richiesta. Usa i logger specifici per la richiesta o per l'applicazione ovunque possibile.

## Livello

SwiftLog supporta diversi livelli di logging.

|Nome|Descrizione|
|-|-|
|trace|Appropriato per messaggi che contengono informazioni normalmente utili solo quando si traccia l'esecuzione di un programma.|
|debug|Appropriato per messaggi che contengono informazioni normalmente utili solo quando si esegue il debug di un programma.|
|info|Appropriato per messaggi informativi.|
|notice|Appropriato per condizioni che non sono errori, ma che potrebbero richiedere una gestione speciale.|
|warning|Appropriato per messaggi che non sono errori, ma più gravi di notice.|
|error|Appropriato per condizioni di errore.|
|critical|Appropriato per condizioni di errore critico che di solito richiedono attenzione immediata.|

Quando viene registrato un messaggio `critical`, il backend di logging è libero di eseguire operazioni più pesanti per acquisire lo stato del sistema (come acquisire stack trace) per facilitare il debug.

Come impostazione predefinita, Vapor utilizzerà il livello di logging `info`. Quando eseguito con l'ambiente `production`, verrà usato `notice` per migliorare le prestazioni.

### Cambiare il Livello di Log

Indipendentemente dalla modalità dell'ambiente, puoi sovrascrivere il livello di logging per aumentare o diminuire la quantità di log prodotti.

Il primo metodo è passare il flag opzionale `--log` quando si avvia l'applicazione.

```sh
swift run App serve --log debug
```

Il secondo metodo è impostare la variabile d'ambiente `LOG_LEVEL`.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Entrambe queste operazioni possono essere eseguite in Xcode modificando lo schema `App`.

## Configurazione

SwiftLog è configurato attraverso il bootstrap di `LoggingSystem` una volta per processo. I progetti Vapor tipicamente lo fanno in `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` è un metodo helper fornito da Vapor che configurerà il log handler predefinito in base agli argomenti della riga di comando e alle variabili d'ambiente. Il log handler predefinito supporta la produzione di messaggi nel terminale con supporto al colore ANSI.

### Handler Personalizzato

Puoi sovrascrivere il log handler predefinito di Vapor e registrare il tuo.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Tutti i backend supportati da SwiftLog funzioneranno con Vapor. Tuttavia, la modifica del livello di log con argomenti della riga di comando e variabili d'ambiente è compatibile solo con il log handler predefinito di Vapor.
