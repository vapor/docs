# Swift Package Manager

Il [Swift Package Manager](https://swift.org/package-manager/) (SPM) è utilizzato per la compilazione del codice sorgente e delle dipendenze del vostro progetto. Poiché Vapor si basa molto su SPM, è una buona idea capire i suoi funzionamenti di base.

SPM è simile a Cocoapods, Ruby gems e NPM. Si può utilizzare SPM dalla riga di comando con comandi come `swift build` e `swift test` o con IDE compatibili. Tuttavia, a differenza di alcuni altri package manager, non esiste un indice centrale dei pacchetti SPM. Esso sfrutta invece gli URL delle repository Git e le dipendenze delle versioni utilizzando i [tag Git](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

## Manifesto del Pacchetto

Il primo posto in cui SPM cerca nel vostro progetto è il manifesto del pacchetto. Questo dovrebbe sempre essere situato nella directory principale del vostro progetto e chiamarsi `Package.swift`.

Diamo un'occhiata a questo esempio di manifesto del pacchetto.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git",
        from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Nelle sezioni seguenti vengono spiegate tutte le parti del manifesto.

### Versione degli Strumenti

La prima riga di un manifesto del pacchetto indica la versione degli strumenti Swift richiesta. Essa specifica la versione minima di Swift che il pacchetto supporta. L'API della descrizione del pacchetto può anche cambiare tra le versioni di Swift, quindi questa riga assicura che Swift sappia come analizzare il manifesto.

### Nome del Pacchetto

Il primo argomento di `Package` è il nome del pacchetto. Se il pacchetto è pubblico, bisogna utilizzare l'ultimo segmento dell'URL della repo Git come nome.

### Piattaforme

L'array `platforms` specifica quali piattaforme il pacchetto supporta. Specificando `.macOS(.v12)` il pacchetto richiederà macOS 12 o successivi. Quando Xcode caricherà il progetto, imposterà automaticamente la versione di distribuzione minima su macOS 12 in modo che si possano utilizzare tutte le API disponibili.

### Dipendenze

Le dipendenze sono altri pacchetti SPM da cui il pacchetto dipende. Tutte le applicazioni Vapor si basano sul pacchetto Vapor, ma se ne possono aggiungere senza limiti.

Nell'esempio precedente, si può notare che il pacchetto dipende da [vapor/vapor](https://github.com/vapor/vapor), versione 4.76.0 o successive. Nel momento in cui si aggiunge una dipendenza al pacchetto, bisogna segnalare quali [target](#targets) dipendono dai moduli appena inseriti.

### Target

I target sono i moduli che compongono il vostro pacchetto. I target possono essere eseguibili, librerie o test. Solitamente un progetto Vapor ha due target, tuttavia se ne possono aggiungere in modo da organizzare il codice.
Ogni target dichiara i moduli da cui dipende. Per poter importare ed usare i vari moduli nel codice bisogna dichiarare qui i loro nomi. Un target può dipendere da altri target nello stesso pacchetto o da qualsiasi modulo presente nei pacchetti aggiunto all'array delle [dipendenze principali](#dependencies).

## Struttura della Cartella

Questa è la tipica struttura di una cartella di un pacchetto SPM:

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Ogni `.target` o `.executableTarget` corrisponde a una cartella nella cartella `Sources`.
Ogni `.testTarget` corrisponde a una cartella nella cartella `Tests`.

## Package.resolved

La prima volta che il progetto viene compilato, SPM creerà il file `Package.resolved` che contiene l'elenco delle dipendenze e delle versioni utilizzate. Durante le compilazioni successive saranno quelle le versioni utilizzate, anche se ce ne dovessero essere di più recenti.

Per aggiornare le dipendenze basta eseguire `swift package update` e SPM aggiornerà automaticamente il file `Package.resolved` con le versioni più recenti.

# Xcode

Usando Xcode qualsiasi cambiamento a dipendenze, target, prodotti ecc. sarà automatico non appena si salva il file `Package.swift`.

Per aggiornare le dipendenze, basta andare su File &rarr; Swift Packages &rarr; Update to Latest Package Versions.

In genere è consigliabile aggiungere il file `.swiftpm` al `.gitignore`. Questo file contiene la configurazione del progetto di Xcode.
