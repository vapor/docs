# Environment

L'API `Environment` di Vapor ti aiuta a configurare la tua app dinamicamente. Per impostazione predefinita, la tua app utilizzerà l'ambiente `development`. Puoi definire altri ambienti utili come `production` o `staging` e cambiare come la tua app è configurata in ogni caso. Puoi anche caricare variabili dall'ambiente del processo o da file `.env` (dotenv) a seconda delle tue esigenze.

Per accedere all'ambiente corrente, usa `app.environment`. Puoi fare uno switch su questa proprietà in `configure(_:)` per eseguire diverse logiche di configurazione.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Cambiare Ambiente

Per impostazione predefinita, la tua app verrà eseguita nell'ambiente `development`. Puoi cambiarlo passando il flag `--env` (`-e`) durante l'avvio dell'app.

```swift
swift run App serve --env production
```

Vapor include i seguenti ambienti:

|Nome|Abbreviazione|Descrizione|
|-|-|-|
|production|prod|Distribuito agli utenti|
|development|dev|Sviluppo locale|
|testing|test|Per i test unitari|

!!! info "Informazione"
    L'ambiente `production` utilizzerà di default il livello di log `notice` a meno che non sia specificato diversamente. Tutti gli altri ambienti utilizzano di default `info`.

Puoi passare il nome completo o abbreviato al flag `--env` (`-e`).

```swift
swift run App serve -e prod
```

## Variabili di Processo

`Environment` offre una semplice API basata su stringhe per accedere alle variabili d'ambiente del processo.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Oltre a `get`, `Environment` offre un'API di dynamic member lookup tramite `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Quando esegui la tua app nel terminale, puoi impostare le variabili d'ambiente usando `export`.

```sh
export FOO=BAR
swift run App serve
```

Quando esegui la tua app in Xcode, puoi impostare le variabili d'ambiente modificando lo schema `App`.

## .env (dotenv)

I file dotenv contengono un elenco di coppie chiave-valore da caricare automaticamente nell'ambiente. Questi file rendono facile configurare le variabili d'ambiente senza doverle impostare manualmente.
Vapor cercherà i file dotenv nella directory di lavoro corrente.

!!! tip "Suggerimento"
    Se stai usando Xcode, assicurati di impostare la directory di lavoro modificando lo schema `App`.

Supponi che il seguente file `.env` sia posizionato nella cartella radice del tuo progetto:

```sh
FOO=BAR
```

Quando la tua applicazione si avvia, potrai accedere al contenuto di questo file come alle altre variabili d'ambiente del processo.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info "Informazione"
    Le variabili specificate nei file `.env` non sovrascriveranno le variabili che esistono già nell'ambiente del processo.

Oltre a `.env`, Vapor tenterà anche di caricare un file dotenv per l'ambiente corrente. Per esempio, quando si è nell'ambiente `development`, Vapor caricherà `.env.development`. Qualsiasi valore nel file dell'ambiente specifico avrà la precedenza sul file `.env` generale.

Un pattern tipico è che i progetti includano un file `.env` come template con valori predefiniti. I file di ambiente specifici vengono ignorati con il seguente pattern in `.gitignore`:

```gitignore
.env.*
```

Quando il progetto viene clonato su un nuovo computer, il file template `.env` può essere copiato e i valori corretti inseriti.

```sh
cp .env .env.development
vim .env.development
```

!!! warning "Attenzione"
    I file dotenv con informazioni sensibili come le password non devono essere committati nel controllo di versione.

Se hai difficoltà a far caricare i file dotenv, prova ad abilitare il logging di debug con `--log debug` per maggiori informazioni.

## Ambienti Personalizzati

Per definire un nome di ambiente personalizzato, estendi `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

L'ambiente dell'applicazione viene solitamente impostato in `entrypoint.swift` usando `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)
        defer { app.shutdown() }

        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

Il metodo `detect` usa gli argomenti della riga di comando del processo e analizza automaticamente il flag `--env`. Puoi sovrascrivere questo comportamento inizializzando una struct `Environment` personalizzata.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

L'array degli argomenti deve contenere almeno un argomento che rappresenta il nome dell'eseguibile. Ulteriori argomenti possono essere forniti per simulare il passaggio di argomenti tramite la riga di comando. Questo è particolarmente utile per i test.
