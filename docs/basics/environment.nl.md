# Omgeving

Vapor's Environment API helpt u om uw app dynamisch te configureren. Standaard zal uw app de `development` omgeving gebruiken. U kunt andere nuttige omgevingen definiëren zoals `production` of `staging` en wijzigen hoe uw app in elk geval wordt geconfigureerd. U kunt ook variabelen laden uit de omgeving van het proces of `.env` (dotenv) bestanden, afhankelijk van uw behoeften.

Om toegang te krijgen tot de huidige omgeving, gebruik `app.environment`. Je kunt deze eigenschap aanzetten in `configure(_:)` om verschillende configuratie logica uit te voeren. 

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Verander De Omgeving

Standaard zal uw app in de `development` omgeving draaien. U kunt dit veranderen door de `--env` (`-e`) vlag mee te geven tijdens het opstarten van de app.

```swift
vapor run serve --env production
```

Vapor omvat de volgende omgevingen:

|naam|kort|beschrijving|
|-|-|-|
|production|prod|Uitgerold naar uw gebruikers.|
|development|dev|Lokale ontwikkeling.|
|testing|test|Voor unit testen.|

!!! info
    De `production` omgeving zal standaard op `notice` niveau loggen tenzij anders aangegeven. Alle andere omgevingen hebben standaard `info`. 

Je kunt de volledige of korte naam doorgeven aan de `--env` (`-e`) vlag.

```swift
vapor run serve -e prod
```

## Procesvariabelen

`Environment` biedt een eenvoudige, string-gebaseerde API voor toegang tot de omgevingsvariabelen van het proces.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

In aanvulling op `get`, biedt `Environment` een dynamische lid lookup API via `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Wanneer u uw app in de terminal draait, kunt u omgevingsvariabelen instellen met `export`. 

```sh
export FOO=BAR
vapor run serve
```

Wanneer u uw app in Xcode uitvoert, kunt u omgevingsvariabelen instellen door het `App` schema te bewerken.

## .env (dotenv)

Dotenv bestanden bevatten een lijst van sleutel-waarde paren die automatisch in de omgeving geladen worden. Deze bestanden maken het gemakkelijk om omgevingsvariabelen te configureren zonder ze handmatig te hoeven instellen.

Vapor zal zoeken naar dotenv bestanden in de huidige werkmap. Als u Xcode gebruikt, zorg er dan voor dat u de werkdirectory instelt door het `App` schema aan te passen.

Veronderstel dat het volgende `.env` bestand in de hoofdmap van je project staat:

```sh
FOO=BAR
```

Wanneer uw applicatie opstart, heeft u toegang tot de inhoud van dit bestand zoals andere proces omgevingsvariabelen.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Variabelen gespecificeerd in `.env` bestanden zullen variabelen die al bestaan in de procesomgeving niet overschrijven. 

Naast `.env`, zal Vapor ook proberen om een dotenv bestand te laden voor de huidige omgeving. Bijvoorbeeld, wanneer Vapor zich in de `development` omgeving bevindt, zal Vapor `.env.development` laden. Alle waarden in het specifieke omgevingsbestand zullen voorrang krijgen boven het algemene `.env` bestand.

Een typisch patroon is voor projecten om een `.env` bestand op te nemen als een sjabloon met standaard waarden. Specifieke omgevingsbestanden worden genegeerd met het volgende patroon in `.gitignore`:

```gitignore
.env.*
```

Wanneer het project wordt gekloond naar een nieuwe computer, kan het sjabloon `.env` bestand worden gekopieerd en de juiste waarden worden ingevoegd. 

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Dotenv bestanden met gevoelige informatie zoals wachtwoorden mogen niet worden vastgelegd in versiebeheer.

Als je problemen hebt met het laden van dotenv bestanden, probeer dan debug logging in te schakelen met `--log debug` voor meer informatie. 

## Aangepaste Omgevingen

Om een aangepaste omgevingsnaam te definiëren, breidt u `Environment` uit.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

De omgeving van de applicatie wordt meestal ingesteld in `entrypoint.swift` met `Environment.detect()`.

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

De `detect` methode gebruikt de commandoregel argumenten van het proces en parst de `--env` vlag automatisch. Je kunt dit gedrag opheffen door een aangepaste `Environment` struct te initialiseren.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

De argumenten array moet ten minste één argument bevatten dat de naam van het uitvoerbare bestand weergeeft. Verdere argumenten kunnen worden meegegeven om het doorgeven van argumenten via de commandoregel te simuleren. Dit is vooral nuttig voor testen.
