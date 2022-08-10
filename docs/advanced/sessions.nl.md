# Sessies

Sessies maken het mogelijk om de gegevens van een gebruiker te bewaren tussen meerdere verzoeken. Sessies werken door een unieke cookie aan te maken en terug te sturen samen met het HTTP-antwoord wanneer een nieuwe sessie wordt geïnitialiseerd. Browsers zullen deze cookie automatisch detecteren en in toekomstige verzoeken opnemen. Hierdoor kan Vapor automatisch de sessie van een specifieke gebruiker herstellen in uw request handler. 

Sessies zijn geweldig voor front-end webapplicaties gebouwd in Vapor die HTML direct aan webbrowsers serveren. Voor API's raden we aan om stateless, [token-based authentication] (../security/authentication.md) te gebruiken om gebruikersgegevens tussen verzoeken te bewaren.

## Configuratie

Om sessies in een route te gebruiken, moet het verzoek door `SessionsMiddleware` gaan. De makkelijkste manier om dit te bereiken is door deze middleware globaal toe te voegen.

```swift
app.middleware.use(app.sessions.middleware)
```

Als slechts een subset van uw routes gebruik maakt van sessies, kunt u in plaats daarvan `SessionsMiddleware` toevoegen aan een route groep.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Het HTTP-cookie dat door sessies wordt gegenereerd, kan worden geconfigureerd met `app.sessions.configuration`. U kunt de cookienaam wijzigen en een aangepaste functie declareren voor het genereren van cookie-waarden.

```swift
// Verander de cookie naam in "foo".
app.sessions.configuration.cookieName = "foo"

// Configureert cookie waarde creatie.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}
```

Standaard zal Vapor `vapor_session` gebruiken als cookie naam.

## Drivers

Sessie drivers zijn verantwoordelijk voor het opslaan en ophalen van sessie gegevens op basis van een identifier. U kunt aangepaste drivers maken door te voldoen aan het `SessionDriver` protocol.

!!! warning "Waarschuwing"
	De sessie driver moet worden geconfigureerd _voordat_ u `app.sessions.middleware` toevoegt aan uw applicatie.

### In-Memory

Vapor maakt standaard gebruik van in-memory sessies. In-memory sessies vereisen geen configuratie en blijven niet bestaan tussen het opstarten van applicaties, waardoor ze zeer geschikt zijn voor testen. Om in-memory sessies handmatig in te schakelen, gebruik `.memory`:

```swift
app.sessions.use(.memory)
```

Voor productie gebruik, kijk eens naar de andere sessie drivers die databases gebruiken om sessies te bewaren en te delen over meerdere instances van je app.

### Fluent

Fluent heeft ondersteuning voor het opslaan van sessie data in de database van uw applicatie. Deze sectie gaat ervan uit dat u Fluent [geconfigureerd](../fluent/overview.md) heeft en verbinding kan maken met een database. De eerste stap is om de Fluent sessies driver in te schakelen.

```swift
import Fluent

app.sessions.use(.fluent)
```

Dit zal sessies configureren om de standaard database van de toepassing te gebruiken. Om een specifieke database te specificeren, geef de identifier van de database door.

```swift
app.sessions.use(.fluent(.sqlite))
```

Voeg tenslotte `SessionRecord`'s migratie toe aan de migraties van uw database. Dit zal uw database voorbereiden op het opslaan van sessie data in het `_fluent_sessions` schema.

```swift
app.migrations.add(SessionRecord.migration)
```

Zorg ervoor dat u de migraties van uw applicatie uitvoert na het toevoegen van de nieuwe migratie. Sessies worden nu opgeslagen in de database van uw applicatie waardoor ze kunnen blijven bestaan tussen herstarts en kunnen worden gedeeld tussen meerdere instanties van uw app.

### Redis

Redis biedt ondersteuning voor het opslaan van sessiegegevens in uw geconfigureerde Redis-instantie. Deze sectie gaat er van uit dat u [Redis geconfigureerd hebt](../redis/overview.md) en commando's kunt sturen naar de Redis instantie.

Om Redis voor Sessies te gebruiken, selecteert u het bij het configureren van uw toepassing:

```swift
import Redis

app.sessions.use(.redis)
```

Dit zal sessies configureren om de Redis sessies driver te gebruiken met het standaard gedrag.

!!! seealso "Zie ook"
    Raadpleeg [Redis &rarr; Sessions](../redis/sessions.md) voor meer gedetailleerde informatie over Redis en Sessions.

## Sessiegegevens

Nu de sessies geconfigureerd zijn, ben je klaar om data te persisteren tussen requests. Nieuwe sessies worden automatisch geïnitialiseerd wanneer data wordt toegevoegd aan `req.session`. De voorbeeld route handler hieronder accepteert een dynamische route parameter en voegt de waarde toe aan `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Gebruik het volgende verzoek om een sessie met de naam Vapor te initialiseren.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

U zou een antwoord moeten krijgen dat lijkt op het volgende:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Merk op dat de `set-cookie` header automatisch is toegevoegd aan het antwoord na het toevoegen van gegevens aan `req.session`. Door deze cookie in volgende verzoeken op te nemen, krijgt u toegang tot de sessiegegevens.

Voeg de volgende route handler toe voor het opvragen van de naamwaarde uit de sessie.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Gebruik het volgende verzoek om toegang te krijgen tot deze route en zorg ervoor dat u de cookie-waarde uit het vorige antwoord doorgeeft.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

U zou de naam Vapor terug moeten zien in het antwoord. U kunt naar eigen wens gegevens aan de sessie toevoegen of eruit verwijderen. Sessiegegevens worden automatisch gesynchroniseerd met de sessiedriver voordat de HTTP-respons wordt teruggestuurd. 

Om een sessie te beëindigen, gebruik `req.session.destroy`. Dit verwijdert de data uit de sessie-driver en maakt het sessie-cookie ongeldig. 

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
