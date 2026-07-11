# Leaf

Leaf ist eine leistungsstarke Templating-Sprache mit einer an Swift angelehnten Syntax. Du kannst sie verwenden, um dynamische HTML-Seiten für eine Frontend-Website zu erzeugen oder um umfangreiche E-Mails zu generieren, die von einer API versendet werden.

## Package

Der erste Schritt zur Nutzung von Leaf ist, es als Abhängigkeit zu deinem Projekt in der SPM-Package-Manifest-Datei hinzuzufügen.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## Konfiguration

Sobald du das Package zu deinem Projekt hinzugefügt hast, kannst du Vapor so konfigurieren, dass es verwendet wird. Das geschieht üblicherweise in [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Dies weist Vapor an, den `LeafRenderer` zu verwenden, wenn du in deinem Code `req.view` aufrufst.

!!! warning 
    Damit Leaf die Templates finden kann, wenn du aus Xcode heraus arbeitest, musst du das [benutzerdefinierte Arbeitsverzeichnis](../getting-started/xcode.md#custom-working-directory) für dein Xcode-Workspace festlegen.

### Cache für das Rendern von Seiten

Leaf verfügt über einen internen Cache zum Rendern von Seiten. Wenn die Umgebung der `Application` auf `.development` gesetzt ist, ist dieser Cache deaktiviert, sodass Änderungen an Templates sofort wirksam werden. In `.production` und allen anderen Umgebungen ist der Cache standardmäßig aktiviert. Änderungen an Templates werden erst nach einem Neustart der Anwendung wirksam.

Um den Cache von Leaf zu deaktivieren, gehe wie folgt vor:

```swift
app.leaf.cache.isEnabled = false
```

!!! warning
    Das Deaktivieren des Caches ist zwar beim Debuggen hilfreich, wird jedoch für Produktionsumgebungen nicht empfohlen, da es die Performance erheblich beeinträchtigen kann, weil Templates bei jeder Anfrage neu kompiliert werden müssen.

## Ordnerstruktur

Sobald du Leaf konfiguriert hast, musst du sicherstellen, dass ein `Views`-Ordner vorhanden ist, in dem du deine `.leaf`-Dateien ablegst. Standardmäßig erwartet Leaf, dass sich der Views-Ordner unter `./Resources/Views` relativ zum Root-Verzeichnis deines Projekts befindet.

Du möchtest wahrscheinlich außerdem Vapors [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) aktivieren, um Dateien aus deinem `/Public`-Ordner auszuliefern, falls du beispielsweise JavaScript- und CSS-Dateien bereitstellen möchtest.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## Eine View rendern

Nachdem Leaf nun konfiguriert ist, lass uns dein erstes Template rendern. Erstelle im Ordner `Resources/Views` eine neue Datei namens `hello.leaf` mit folgendem Inhalt:

```leaf
Hello, #(name)!
```

!!! tip
    Wenn du VSCode als Code-Editor verwendest, empfehlen wir dir, die Vapor-Erweiterung zu installieren, um Syntax-Highlighting zu aktivieren: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Registriere anschließend eine Route (üblicherweise in `routes.swift` oder einem Controller), um die View zu rendern.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Dies verwendet die generische Eigenschaft `view` auf `Request`, anstatt Leaf direkt aufzurufen. Dadurch kannst du in deinen Tests zu einem anderen Renderer wechseln.


Öffne deinen Browser und rufe `/hello` auf. Du solltest `Hello, Leaf!` sehen. Herzlichen Glückwunsch zum Rendern deiner ersten Leaf-View!
