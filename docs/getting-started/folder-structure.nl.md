# Folder Structuur

Nu dat je je eerste Vapor app hebt gemaakt, gebouwd en uitgevoerd, laten we een moment nemen om jezelf vertrouwd te maken met Vapor's folder structuur. De structuur is gebaseerd op [SPM](spm.md)'s folder structuur, dus als je al met SPM hebt gewerkt zou deze je bekend voor moeten komen. 

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

The secties hieronder leggen elk deel van de folder structuur uit in meer detail.

## Public

Deze map bevat alle publieke bestanden die door uw app geserveerd zullen worden als `FileMiddleware` is ingeschakeld. Dit zijn meestal afbeeldingen, stylesheets en browserscripts. Bijvoorbeeld, een verzoek aan `localhost:8080/favicon.ico` zal controleren of `Public/favicon.ico` bestaat en deze terugsturen.

U moet `FileMiddleware` aanzetten in uw `configure.swift` bestand voordat Vapor publieke bestanden kan serveren.

```swift
// Dient bestanden op uit `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Deze map bevat alle Swift bronbestanden voor je project. 
De mappen op het hoogste niveau, `App` en `Run`, geven de modules van uw pakket weer, 
zoals aangegeven in het [SPM](spm.md) manifest.

### App

Dit is waar al je applicatie logica naartoe gaat. 

#### Controllers

Controllers zijn een goede manier om applicatie logica te groeperen. De meeste controllers hebben veel functies die een verzoek aannemen en een soort antwoord teruggeven.

#### Migrations

De migraties map is waar uw database migraties naar toe gaan als u Fluent gebruikt.

#### Models

De models map is een goede plaats om uw `Content` structs of Fluent `Model`s op te slaan.

#### configure.swift

Dit bestand bevat de `configure(_:)` functie. Deze methode wordt aangeroepen door `main.swift` om de nieuw aangemaakte `Application` te configureren. Dit is waar je services zoals routes, databases, providers, en meer moet registreren.

#### entrypoint.swift

Dit bestand bevat het `@main`-toegangspunt voor de toepassing die uw Vapor-toepassing instelt, configureert en uitvoert.

#### routes.swift

Dit bestand bevat de `routes(_:)` functie. Deze methode wordt aangeroepen aan het einde van `configure(_:)` om routes te registreren voor je `Application`. 

## Tests

Elke niet-uitvoerbare module in je `Sources` folder kan een overeenkomstige folder hebben in `Tests`. Deze bevalt code gebouwd op de `XCTest` module om je pakket te testen. Testen kunnen uitgevoerd worden door `swift test` te gebruiken op de command line of door ⌘+U in te drukken in Xcode.

### AppTests

Deze folder bevat de unit tests voor code in je `App` module.

## Package.swift

Tenslotte is er [SPM](spm.md)'s pakket manifest.