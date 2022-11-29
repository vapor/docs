# Async

## Async Await

Swift 5.5 introduceerde concurrency in de taal in de vorm van `async`/`await`. Dit biedt een uitstekende manier om met asynchrone code om te gaan in Swift en Vapor applicaties.

Vapor is gebouwd bovenop [SwiftNIO](https://github.com/apple/swift-nio.git), die primitieve types biedt voor asynchroon programmeren op een laag niveau. Deze werden (en worden nog steeds) gebruikt in Vapor voordat `async`/`await` kwam. Echter, de meeste app code kan nu geschreven worden met `async`/`await` in plaats van met `EventLoopFuture`s. Dit vereenvoudigt uw code en maakt het veel eenvoudiger om over te redeneren.

De meeste van Vapor's APIs bieden nu zowel `EventLoopFuture` als `async`/`await` versies zodat u kunt kiezen wat het beste is. In het algemeen moet u slechts één programmeermodel per route handler gebruiken en niet mixen en matchen in uw code. Voor toepassingen die expliciete controle nodig hebben over eventloops, of voor zeer high-performance toepassingen, moet je `EventLoopFuture` blijven gebruiken totdat aangepaste executors zijn geïmplementeerd. Voor alle anderen moet je `async`/`await` gebruiken, omdat de voordelen van leesbaarheid en onderhoudbaarheid veel groter zijn dan een klein prestatieverlies.

### Migreren naar async/await

Er zijn een paar stappen nodig om te migreren naar async/await. Om te beginnen, als je macOS gebruikt moet je macOS 12 Monterey of hoger en Xcode 13.1 of hoger hebben. Voor andere platformen moet je Swift 5.5 of hoger gebruiken. Zorg er vervolgens voor dat je al je dependencies hebt bijgewerkt.

Zet in uw Package.swift de tools versie op 5.5 bovenaan in het bestand:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Stel vervolgens de platvorm versie in op macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Update tenslotte de `Run` target om het als een uitvoerbaar target te markeren:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Opmerking: als je het op Linux uitrolt, zorg er dan voor dat je de versie van Swift daar ook update, bijv. op Heroku of in je Dockerfile. Bijvoorbeeld je Dockerfile zou veranderen in:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Nu kun je bestaande code migreren. Over het algemeen zijn functies die `EventLoopFuture` teruggeven nu `async`. Bijvoorbeeld:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Wordt nu:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Werken met oude en nieuwe API's

Als je API's tegenkomt die nog geen `async`/`await` versie bieden, kun je `.get()` aanroepen op een functie die een `EventLoopFuture` retourneert om het om te zetten.

Bijv.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // gebruik futureResult
}
```

Kan worden

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Als u de andere kant op moet, kunt u

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

omzetten naar

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`s

Het is u misschien opgevallen dat sommige APIs in Vapor een generiek `EventLoopFuture` type verwachten of retourneren. Als dit de eerste keer is dat u van futures hoort, kunnen ze in eerste instantie een beetje verwarrend lijken. Maar maak je geen zorgen, deze gids zal je laten zien hoe je voordeel kunt halen uit hun krachtige APIs. 

Promises en futures zijn verwante, maar verschillende soorten. Promises worden gebruikt om futures te _creëren_. Meestal zult u werken met futures die door Vapor's API's worden geretourneerd en hoeft u zich geen zorgen te maken over het maken van promises.

|type|beschrijving|muteerbaarheid|
|-|-|-|
|`EventLoopFuture`|Verwijzing naar een waarde die misschien nog niet beschikbaar is.|alleen-lezen|
|`EventLoopPromise`|Een belofte om asynchroon een waarde te leveren.|lezen/schrijven|

Futures zijn een alternatief voor callback-gebaseerde asynchrone API's. Futures kunnen worden geketend en getransformeerd op manieren die eenvoudige closures niet kunnen.

## Transformeren

Net als optionals en arrays in Swift, kunnen futures in kaart worden gebracht en flat-mapped worden. Dit zijn de meest voorkomende operaties die je op futures zult uitvoeren.

|methode|argument|beschrijving|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Zet een toekomstige waarde om in een andere waarde.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Zet een toekomstige waarde om in een andere waarde of een fout.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Wijst een toekomstige waarde toe aan een andere _toekomstige_ waarde.|
|[`transform`](#transform)|`U`|Wijst een toekomst toe aan een reeds beschikbare waarde.|

Als u kijkt naar de methode handtekeningen voor `map` en `flatMap` op `Optional<T>` en `Array<T>`, zult u zien dat ze erg lijken op de methoden die beschikbaar zijn op `EventLoopFuture<T>`.

### map

De `map` methode maakt het mogelijk om de waarde van de future om te zetten naar een andere waarde. Omdat de waarde van de future misschien nog niet beschikbaar is (het kan het resultaat zijn van een asynchrone taak) moeten we een closure voorzien om de waarde te aanvaarden.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

/// Zet de toekomstige string om in een geheel getal
let futureInt = futureString.map { string in
    print(string) // De eigenlijke String
    return Int(string) ?? 0
}

/// We hebben nu een toekomst integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

De `flatMapThrowing` methode maakt het mogelijk om de waarde van de future om te zetten in een andere waarde _of_ een fout te gooien. 

!!! info
    Omdat het gooien van een fout intern een nieuwe future moet aanmaken, heeft deze methode als voorvoegsel `flatMap`, ook al accepteert de closure geen teruggave van een future.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

/// Zet de toekomstige string om in een geheel getal
let futureInt = futureString.flatMapThrowing { string in
    print(string) // De eigenlijke String
    // Zet de string om in een integer of gooi een foutmelding
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We hebben nu een toekomst integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

De `flatMap` methode staat je toe om de waarde van de future om te zetten naar een andere future waarde. Het krijgt de naam `flatMap` omdat het je in staat stelt om geneste futures te vermijden (bijv. `EventLoopFuture<EventLoopFuture<T>>`). Met andere woorden, het helpt je om je generics plat te houden.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

/// Stel dat we een HTTP-client hebben gemaakt
let client: Client = ... 

/// flatMap de toekomstige string naar een toekomstig antwoord
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We hebben nu een toekomstig antwoord
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    Als we in plaats daarvan `map` hadden gebruikt in het bovenstaande voorbeeld, dan zouden we zijn uitgekomen op: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Om een werpmethode binnen een `flatMap` aan te roepen, gebruik je Swift's `do` / `catch` sleutelwoorden en maak je een [voltooide future](#makefuture).

```swift
/// Veronderstel toekomstige string en klant uit vorig voorbeeld.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Een of andere synchrone werpmethode.
        url = try convertToURL(string)
    } catch {
        // Gebruik een event lus om vooraf voltooide toekomst te maken.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

Met de `transform` methode kunt u de waarde van een future wijzigen, waarbij de bestaande waarde genegeerd wordt. Dit is vooral handig voor het transformeren van de resultaten van `EventLoopFuture<Void>` waarbij de werkelijke waarde van de future niet belangrijk is.

!!! tip
    `EventLoopFuture<Void>`, soms een signaal genoemd, is een future waarvan het enige doel is om u te informeren over de voltooiing of mislukking van een of andere async operatie.

```swift
/// Veronderstel dat we een ongeldige toekomst terugkrijgen van een API
let userDidSave: EventLoopFuture<Void> = ...

/// Zet de void future om in een HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Ook al hebben we een reeds beschikbare waarde aan `transform` meegegeven, is dit nog steeds een _transformatie_. De future zal pas voltooid zijn als alle voorgaande futures voltooid (of mislukt) zijn.

### Koppelen

Het mooie van transformaties op futures is dat ze aaneengeschakeld kunnen worden. Hierdoor kunt u veel conversies en subtaken gemakkelijk uitdrukken.

Laten we de voorbeelden van hierboven aanpassen om te zien hoe we voordeel kunnen halen uit chaining.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

/// Stel dat we een HTTP-client hebben gemaakt
let client: Client = ... 

/// Zet de string om in een url, en vervolgens in een antwoord
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

Na de initiële aanroep van map, wordt er een tijdelijke `EventLoopFuture<URL>` aangemaakt. Deze future wordt dan onmiddellijk flat-mapped naar een `EventLoopFuture<Response>`
    
## Future

Laten we eens kijken naar enkele andere methodes om `EventLoopFuture<T>` te gebruiken.

### makeFuture

U kunt een gebeurtenislus gebruiken om een vooraf voltooide toekomst te maken met ofwel de waarde ofwel een fout.

```swift
// Creëer een voorgespiegelde toekomst.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Creëer een vooraf mislukte toekomst.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


Je kunt `whenComplete` gebruiken om een callback toe te voegen die wordt uitgevoerd als de future slaagt of faalt.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // De eigenlijke String
    case .failure(let error):
        print(error) // Een Swift Error
    }
}
```

!!! note
    U kunt zoveel callbacks aan een future toevoegen als u wilt.
    
### Wait

Je kunt `.wait()` gebruiken om synchroon te wachten tot de future voltooid is. Omdat een future kan mislukken, werpt deze aanroep fouten.

```swift
/// Veronderstel dat we een toekomstige string terugkrijgen van een API
let futureString: EventLoopFuture<String> = ...

/// Blokkeer tot de string klaar is
let string = try futureString.wait()
print(string) /// String
```

`wait()` kan alleen worden gebruikt op een achtergrond thread of de hoofd thread, dus in `configure.swift`. Het kan _niet_ worden gebruikt op een event loop thread, d.w.z. in route closures.

!!! warning
    Pogingen om `wait()` op te roepen op een event loop thread zal een assertion failure veroorzaken.

    
## Promise

Meestal zult u futures transformeren die zijn geretourneerd door oproepen naar Vapor's APIs. Op een gegeven moment kan het echter nodig zijn dat je zelf een promise maakt.

Om een promise te maken, heb je toegang nodig tot een `EventLoop`. Je kunt toegang krijgen tot een event loop vanuit `Application` of `Request`, afhankelijk van de context.

```swift
let eventLoop: EventLoop 

// Maak een nieuwe promise voor een string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Voltooit de bijbehorende toekomst.
promiseString.succeed("Hello")

// Laat de geassocieerde toekomst mislukken.
promiseString.fail(...)
```

!!! info
    Een promise kan maar één keer worden vervuld. Latere afrondingen worden genegeerd.

Promises kunnen worden voltooid (`succeed` / `fail`) vanuit elke thread. Dit is de reden waarom promises een event loop vereisen om geïnitialiseerd te worden. Promises zorgen ervoor dat de voltooide actie wordt teruggestuurd naar zijn event loop voor uitvoering.

## Event Loop

Wanneer je applicatie opstart, maakt het gewoonlijk een event loop aan voor elke core in de CPU waar het op draait. Elke event loop heeft precies één thread. Als je bekend bent met event loops van Node.js, zijn die in Vapor vergelijkbaar. Het belangrijkste verschil is dat Vapor meerdere event loops in één proces kan draaien, omdat Swift multi-threading ondersteunt.

Telkens als een client verbinding maakt met je server, wordt hij toegewezen aan een van de event loops. Vanaf dat moment zal alle communicatie tussen de server en die client gebeuren op diezelfde event loop (en bij associatie, de thread van die event loop). 

De event loop is verantwoordelijk voor het bijhouden van de status van elke verbonden client. Als er een verzoek van de client is dat wacht om gelezen te worden, triggert de event loop een lees-notificatie, waardoor de gegevens worden gelezen. Zodra het volledige verzoek is gelezen, zullen alle futures die wachten op de gegevens van dat verzoek worden voltooid. 

In route closures, kun je de huidige event loop benaderen via `Request`. 

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor verwacht dat route closures op `req.eventLoop` blijven. Als je in threads hopt, moet je ervoor zorgen dat de toegang tot `Request` en de uiteindelijke response future allemaal gebeuren op de event loop van het request. 

Buiten route afsluitingen, kun je via `Application` een van de beschikbare event loops krijgen. 

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Je kunt de event loop van een future veranderen met `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

Het aanroepen van blokkerende code op een event loop thread kan voorkomen dat uw applicatie op tijd reageert op binnenkomende verzoeken. Een voorbeeld van een blokkerende aanroep zou iets zijn als `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Brengt de thread van de event-loop in slaap.
    sleep(5)
    
    /// Geeft een eenvoudige string terug zodra de draad opnieuw ontwaakt.
    return "Hello, world!"
}
```

`sleep(_:)` is een commando dat de huidige thread blokkeert voor het aantal opgegeven seconden. Als je blokkerend werk als dit direct op een event loop doet, zal de event loop niet in staat zijn om te reageren op andere clients die eraan zijn toegewezen voor de duur van het blokkerend werk. Met andere woorden, als je `sleep(5)` doet op een event loop, zullen alle andere clients die verbonden zijn met die event loop (mogelijk honderden of duizenden) minstens 5 seconden worden vertraagd. 

Zorg ervoor dat alle blokkerend werk in de achtergrond wordt uitgevoerd. Gebruik beloftes om de event loop te verwittigen wanneer dit werk gedaan is op een niet-blokkerende manier.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Stuur wat werk door naar een achtergrond thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Zet de achtergrond thread in slaap
        /// Dit zal geen invloed hebben op de event loops
        sleep(5)
        
        /// Als het "blokkeringswerk" klaar is,
        /// geef het resultaat terug.
        return "Hello world!"
    }
}
```

Niet alle blokkerende aanroepen zullen zo duidelijk zijn als `sleep(_:)`. Als je vermoedt dat een aanroep die je gebruikt kan blokkeren, onderzoek dan de methode zelf of vraag het iemand. De secties hieronder gaan meer in detail in op hoe methodes kunnen blokkeren.

### I/O Bound

I/O-gebonden blokkeren betekent wachten op een langzame bron zoals een netwerk of harde schijf, die ordes van grootte langzamer kunnen zijn dan de CPU. Blokkeren van de CPU terwijl je wacht op deze bronnen resulteert in verspilde tijd. 

!!! danger
    Doe nooit blokkerende I/O-gebonden aanroepen rechtstreeks op een event-lus.

Alle pakketten van Vapor zijn gebouwd op SwiftNIO en gebruiken niet-blokkerende I/O. Er zijn echter veel Swift pakketten en C libraries in het wild die blokkerende I/O gebruiken. De kans is groot dat als een functie schijf- of netwerk-I/O doet en een synchrone API gebruikt (geen callbacks of futures), dat deze blokkerend is.
    
### CPU Bound

Het grootste deel van de tijd tijdens een request wordt besteed aan het wachten op externe bronnen zoals database queries en netwerk requests om te laden. Omdat Vapor en SwiftNIO niet-blokkerend zijn, kan deze tijd worden gebruikt om andere inkomende verzoeken af te handelen. Het kan echter voorkomen dat sommige routes in uw applicatie zwaar CPU gebonden werk moeten doen als gevolg van een verzoek.

Terwijl een event loop CPU-gebonden werk verwerkt, zal het niet in staat zijn te reageren op andere inkomende verzoeken. Dit is normaal gesproken prima omdat CPU's snel zijn en het meeste CPU werk dat web applicaties doen licht is. Maar dit kan een probleem worden als routes met lang lopend CPU werk verhinderen dat verzoeken aan snellere routes snel beantwoord kunnen worden. 

Het identificeren van lang lopend CPU werk in je app en het verplaatsen ervan naar achtergrond threads kan helpen om de betrouwbaarheid en responsiviteit van je service te verbeteren. CPU-gebonden werk is meer een grijs gebied dan I/O-gebonden werk, en het is uiteindelijk aan jou om te bepalen waar je de grens wilt trekken. 

Een veel voorkomend voorbeeld van zwaar CPU-gebonden werk is Bcrypt hashing tijdens het aanmelden en inloggen van gebruikers. Bcrypt is opzettelijk zeer traag en CPU-intensief om veiligheidsredenen. Dit is misschien wel het meest CPU-intensieve werk dat een eenvoudige webapplicatie eigenlijk doet. Het hashen verplaatsen naar een achtergrondthread kan de CPU toestaan om event loop werk te scheiden tijdens het berekenen van hashes, wat resulteert in hogere concurrency.
