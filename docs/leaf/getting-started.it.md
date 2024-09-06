# Leaf

Leaf è un potente linguaggio di templating con la sintassi ispirata a Swift. Puoi usarlo per generare pagine HTML dinamiche per un sito front-end o per generare email abbellite da inviare con una API.

## Pacchetto

Il primo passo per usare Leaf è aggiungerlo come una dipendenza al tuo progetto nel tuo file di manifesto del pacchetto SPM.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Qualsiasi altra dipendenza ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Qualsiasi altra dipendenza
        ]),
        // Altri target
    ]
)
```

## Configura

Non appena hai aggiunto il pacchetto al tuo progetto, puoi configurare Vapor per usarlo. Di solito si fa in [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Questo dice a Vapor di usare `LeafRenderer` quando chiami `req.view` nel tuo codice.

!!! note 
    Leaf ha una cache interna per renderizzare le pagine. Quando l'ambiente di `Application` è impostato su `.development` questa cache è disabilitata, così che i cambiamenti ai template abbiano effetto immediatamente. In `.production` e tutti gli altri ambienti la cache è abilitata di default; qualsiasi cambiamento fatto ai template non avrà effetto finché l'applicazione non viene riavviata.

!!! warning 
    Per fare in modo che Leaf trovi i template quando gira su Xcode, devi impostare la [directory di lavoro personalizzata](../getting-started/xcode.md#custom-working-directory) per il tuo ambiente di lavoro Xcode.
## Struttura della Cartella

Non appena hai configurato Leaf, devi assicurarti di avere una cartella `Views` dove salvare i tuoi file `.leaf`. Di default, Leaf si aspetta che la cartella delle view sia `./Resources/Views`, relativamente alla radice del tuo progetto.

Probabilmente vorrai abilitare anche il [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) di Vapor per servire file dalla tua cartella `/Public` se hai in mente di servire file Javascript e CSS per esempio.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (immagini)
│   ├── styles (risorse css)
└── Sources
    └── ...
```

## Renderizzare una View

Adesso che Leaf è configurato, renderizziamo il tuo primo template. Dentro la cartella `Resources/Views`, crea un nuovo file chiamato `hello.leaf` con il seguente contenuto:

```leaf
Hello, #(name)!
```

!!! tip
    Se usi VSCode come editor di testo, raccomandiamo di installare l'estensione Leaf per abilitare l'evidenziazione della sintassi: [Leaf HTML](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf).

Quindi, registra una route (di solito fatto in `routes.swift` o un controller) per renderizzare la view.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// oppure

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Questo usa la generica proprietà `view` su `Request` invece di chiamare Leaf direttamente. Questo ti permette di passare a un renderer diverso nei tuoi test.


Apri il tuo browser e visita `/hello`. Dovresti vedere `Hello, Leaf!`. Congratulazioni per aver renderizzato la tua prima view Leaf!
