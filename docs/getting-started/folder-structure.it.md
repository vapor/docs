# Struttura della Cartella

Dopo aver creato, compilato ed eseguito la vostra prima applicazione, è il momento di dare un'occhiata a come Vapor struttura la cartella del progetto. La struttura si basa su [SwiftPM](spm.md), quindi se avete già familiarità con SwiftPM vi sentirete a casa.

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

Le seguenti sezioni spiegano in maggior dettaglio la struttura della cartella.

## Public

Questa cartella contiene tutti i file pubblici che saranno messi a disposizione dall'applicazione se `FileMiddleware` è abilitato. In genere si tratta di immagini, fogli di stile e script del browser. Ad esempio, una richiesta a `localhost:8080/favicon.ico` controlla se `Public/favicon.ico` esiste e lo restituisce.

Perché Vapor possa servire i file pubblici, bisognerà abilitare `FileMiddleware` nel file `configure.swift`.

```swift
// Fornisce i file dalla cartella `Public/`
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Questa cartella contiene tutti i file sorgente Swift che verranno utilizzati dal progetto.
La cartella di primo livello, `App`, riflette il modulo del vostro pacchetto, come dichiarato nel manifesto [SwiftPM](spm.md).

### App

La cartella `App` contiene tutta la logica dell'applicazione.

#### Controllers

I controller sono un ottimo modo per raggruppare la logica dell'applicazione. La maggior parte dei controller ha diverse funzioni che accettano una richiesta e restituiscono qualche tipo di risposta.

#### Migrations

Se si utilizza Fluent, questa cartella contiene le migrazioni del database.

#### Models

La cartella dei modelli è un ottimo posto per memorizzare le strutture `Content` e i modelli di Fluent.

#### configure.swift

Questo file contiene la funzione `configure(_:)`. Questo metodo viene chiamato da `entrypoint.swift` per configurare la nuova `Application` creata. Qui vengono registrati gli endpoints, i database, i providers e altro ancora.

#### entrypoint.swift

Questo file contiene la funzione `main(_:)`. Questo metodo viene chiamato dal sistema operativo per avviare l'applicazione. In genere non è necessario modificarlo.

#### routes.swift

Questo file contiene la funzione `routes(_:)`. Questo metodo viene chiamato da `configure(_:)` per registrare gli endpoints dell'applicazione.

## Tests

Per ogni mdulo non eseguibile nella cartella `Sources` si può avere una cartella corrispondente in `Tests`. Essa conterrà i test per quel modulo scritti sulla base del modulo di testing `XCTest`. I test possono essere eseguiti utilizzando `swift test` da riga di comando o premendo ⌘+U in Xcode.

### AppTests

Questa cartella contiene gli unit tests per il codice del modulo `App`.

## Package.swift

Infine, abbiamo il manifesto del pacchetto [SPM](spm.md).
