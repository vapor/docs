# Leaf

Leaf is een krachtige templating taal met een op Swift geïnspireerde syntax. U kunt het gebruiken om dynamische HTML-pagina's te genereren voor een front-end website of om rijke e-mails te genereren om te verzenden vanuit een API.

## Package

De eerste stap om Leaf te gebruiken is het toevoegen als een afhankelijkheid aan uw project in uw SPM pakket manifest bestand.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Eventuele andere afhankelijkheden ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Eventuele andere afhankelijkheden
        ]),
        // Andere targets
    ]
)
```

## Configuratie

Zodra u het pakket aan uw project hebt toegevoegd, kunt u Vapor configureren om het te gebruiken. Dit wordt meestal gedaan in [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Dit vertelt Vapor om de `LeafRenderer` te gebruiken wanneer u `req.view` aanroept in uw code.

!!! note "Opmerking"
    Leaf heeft een interne cache voor het renderen van pagina's. Wanneer de omgeving van de `Application` is ingesteld op `.development`, is deze cache uitgeschakeld, zodat wijzigingen in sjablonen direct worden doorgevoerd. In `.production` en alle andere omgevingen is de cache standaard ingeschakeld; wijzigingen in sjablonen worden pas van kracht als de applicatie opnieuw wordt opgestart.

!!! warning "Waarschuwing"
    Om ervoor te zorgen dat Leaf de sjablonen kan vinden wanneer het vanuit Xcode werkt, moet u de [custom-working-directory](../getting-started/xcode.md#custom-working-directory) instellen voor uw Xcode werkruimte.

## Folder Structuur

Zodra je Leaf hebt geconfigureerd, moet je er voor zorgen dat je een `Views` map hebt om je `.leaf` bestanden in op te slaan. Standaard verwacht Leaf dat de views map een `./Resources/Views` is relatief aan de root van je project.

U zult waarschijnlijk ook Vapor's [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) willen inschakelen om bestanden uit uw `/Public` folder te serveren als u van plan bent om bijvoorbeeld Javascript en CSS bestanden te serveren.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## Een View Renderen

Nu Leaf is geconfigureerd, laten we je eerste template renderen. Maak in de map `Resources/Views` een nieuw bestand aan met de naam `hello.leaf` met de volgende inhoud:

```leaf
Hello, #(name)!
```

Registreer dan een route (meestal gedaan in `routes.swift` of een controller) om de view te renderen.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// of

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Dit gebruikt de generieke `view` eigenschap op `Request` in plaats van Leaf direct aan te roepen. Hierdoor kunt u in uw tests overschakelen op een andere renderer.

Open je browser en ga naar `/hello`. Je zou `Hello, Leaf!` moeten zien. Gefeliciteerd met het renderen van je eerste Leaf view!
