# Query

Met de query API van Fluent kunt u modellen aanmaken, lezen, bijwerken en verwijderen uit de database. Het ondersteunt het filteren van resultaten, joins, chunking, aggregaten, en nog veel meer. 

```swift
// Een voorbeeld van Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Query builders zijn gebonden aan een enkel modeltype en kunnen worden aangemaakt met de static [`query`](model.md#query) methode. Ze kunnen ook worden aangemaakt door het modeltype door te geven aan de `query` methode op een database object.

```swift
// Maakt ook een query builder.
database.query(Planet.self)
```

!!! note "Opmerking"
    U moet Fluent `importeren` in het bestand met uw queries, zodat de compiler de helper-functies van Fluent kan zien.

## All

De `all()` methode geeft een array van modellen terug.

```swift
// Haalt alle planeten op.
let planets = try await Planet.query(on: database).all()
```

De `all` methode ondersteunt ook het ophalen van slechts een enkel veld uit de resultatenverzameling. 

```swift
// Haalt alle planeetnamen op.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

De `first()` methode retourneert een enkel, optioneel model. Als de query meer dan één model oplevert, wordt alleen het eerste model teruggegeven. Als de query geen resultaten heeft, wordt `nil` geretourneerd. 

```swift
// Haalt de eerste planeet genaamd Earth op.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    Bij gebruik van `EventLoopFuture`s, kan deze methode gecombineerd worden met [`unwrap(of:)`](../basics/errors.md#abort) om een niet-optioneel model te retourneren of een foutmelding te geven. 

## Filter

De `filter` methode staat je toe om de modellen in de resultaten set te beperken. Er zijn verschillende overloads voor deze methode. 

### Value Filter

De meest gebruikte `filter` methode accepteert een operator expressie met een waarde.

```swift
// Een voorbeeld van het filteren van veldwaarden.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Deze operator expressies accepteren een veld sleutelpad aan de linkerkant en een waarde aan de rechterkant. De geleverde waarde moet overeenkomen met het verwachte waardetype van het veld en wordt gebonden aan de resulterende query. Filteruitdrukkingen zijn sterk getypeerd, zodat een syntax met leidende punten kan worden gebruikt.

Hieronder staat een lijst van alle ondersteunde waarde operatoren. 

|Operator|Beschrijving|
|-|-|
|`==`|Gelijk aan.|
|`!=`|Niet gelijk aan.|
|`>=`|Groter dan of gelijk aan.|
|`>`|Groter dan.|
|`<`|Kleiner dan.|
|`<=`|Kleiner dan of gelijk aan.|

### Field Filter

De `filter` methode ondersteunt het vergelijken van twee velden. 

```swift
// Alle gebruikers met dezelfde voor- en achternaam.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Veldfilters ondersteunen dezelfde operatoren als [value filters](#value-filter).

### Subset Filter

De `filter` methode ondersteunt het controleren of de waarde van een veld bestaat in een gegeven set van waarden. 

```swift
// Alle planeten met ofwel gasreus ofwel klein rotsachtig type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

De opgegeven set van waarden kan elke Swift `Collection` zijn waarvan het `Element` type overeenkomt met het veld waarde type.

Hieronder staat een lijst van alle ondersteunde subset operatoren. 

|Operator|Beschrijving|
|-|-|
|`~~`|Waarde in verzameling.|
|`!~`|Waarde niet in verzameling.|

### Contains Filter

De `filter` methode ondersteunt het controleren of de waarde van een string veld een gegeven substring bevat. 

```swift
// Alle planeten waarvan de naam begint met de letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Deze operatoren zijn alleen beschikbaar voor velden met string-waarden. 

Hieronder vindt u een lijst van alle ondersteunde bevat operatoren. 

|Operator|Beschrijving|
|-|-|
|`~~`|Bevat een substring.|
|`!~`|Bevat geen substring.|
|`=~`|Komt overeen met voorvoegsel.|
|`!=~`|Komt niet overeen met voorvoegsel.|
|`~=`|Komt overeen met achtervoegsel.|
|`!~=`|Komt niet overeen met achtervoegsel.|

### Group

Standaard moeten alle filters die aan een query zijn toegevoegd overeenkomen. Query builder ondersteunt het maken van een groep filters waarbij slechts één filter moet overeenkomen. 

```swift
// Alle planeten die Aarde of Mars heten
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

De `group` methode ondersteunt het combineren van filters door `and` of `or` logica. Deze groepen kunnen oneindig genest worden. Top-level filters kunnen worden gezien als in een `en` groep.

## Aggregate

Query builder ondersteunt verschillende methoden om berekeningen uit te voeren op een reeks waarden, zoals tellen of het gemiddelde berekenen. 

```swift
// Aantal planeten in de database.
Planet.query(on: database).count()
```

Alle aggregate methodes behalve `count` vereisen een sleutelpad naar een veld dat moet worden doorgegeven.

```swift
// Laagste naam alfabetisch gesorteerd.
Planet.query(on: database).min(\.$name)
```

Hieronder vindt u een lijst van alle beschikbare aggregatiemethoden.

|Aggregate|Beschrijving|
|-|-|
|`count`|Aantal Resultaten.|
|`sum`|Som van resultaatwaarden.|
|`average`|Gemiddelde van resultaatwaarden.|
|`min`|Minimale resultaatwaarde.|
|`max`|Maximale resultaatwaarde.|

Alle aggregatiemethoden behalve `count` retourneren het waardetype van het veld als resultaat. `count` retourneert altijd een geheel getal.

## Chunk

Query builder ondersteunt het teruggeven van een resultaat set als afzonderlijke chunks. Dit helpt je om het geheugengebruik te controleren bij het uitvoeren van grote database lezingen.

```swift
// Haalt alle planeten op in stukken van maximaal 64 per keer.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Behandel een stuk planeten.
}
```

De meegeleverde closure wordt nul of meer keer aangeroepen, afhankelijk van het totale aantal resultaten. Elk item is een `Result` met ofwel het model of een foutmelding bij het decoderen van de databank gegevens. 

## Field

Standaard worden alle velden van een model door een query uit de database gelezen. U kunt ervoor kiezen om alleen een subset van de velden van een model te selecteren met de `field` methode.

```swift
// Selecteer alleen het id en naam veld van de planeet
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Alle modelvelden die tijdens een query niet zijn geselecteerd, zullen in een niet-geïnitialiseerde toestand verkeren. Pogingen om niet-geïnitialiseerde velden direct te benaderen zullen resulteren in een fatale fout. Om te controleren of de veldwaarde van een model is ingesteld, gebruikt u de `value` eigenschap. 

```swift
if let name = planet.$name.value {
    // Naam werd opgehaald.
} else {
    // Naam werd niet opgehaald.
    // Toegang tot `planet.name` zal mislukken.
}
```

## Unique

Query builder's `unique` methode zorgt ervoor dat alleen verschillende resultaten (geen duplicaten) worden geretourneerd. 

```swift
// Geeft als resultaat alle unieke voornamen van gebruikers. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` is vooral handig bij het ophalen van een enkel veld met `all`. U kunt echter ook meerdere velden selecteren met de [`field`](#field) methode. Omdat model identifiers altijd uniek zijn, moet u voorkomen dat u ze selecteert wanneer u `unique` gebruikt. 

## Range

Met de `range` methoden van de Query builder kunt u een subset van de resultaten kiezen met behulp van Swift ranges.

```swift
// Haal de eerste 5 planeten op.
Planet.query(on: self.database)
    .range(..<5)
```

Bereikwaarden zijn niet-ondertekende gehele getallen beginnend bij nul. Meer informatie over

```swift
// Sla de eerste 2 resultaten over.
.range(2...)
```

## Join

Query bouwer's `join` methode staat u toe om een ander model velden op te nemen in uw resultaat set. Meer dan één model kan worden toegevoegd aan uw query. 

```swift
// Haalt alle planeten met een ster genaamd Zon op.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

De `op` parameter accepteert een gelijkheidsexpressie tussen twee velden. Een van de velden moet al bestaan in de huidige resultatenset. Het andere veld moet bestaan in het model dat wordt samengevoegd. Deze velden moeten hetzelfde waardetype hebben.

De meeste query builder methodes, zoals `filter` en `sort`, ondersteunen samengevoegde modellen. Als een methode gegroepeerde modellen ondersteunt, zal deze het gegroepeerde model type accepteren als de eerste parameter. 

```swift
// Sorteren op het samengevoegde veld "naam" op het Star-model.
.sort(Star.self, \.$name)
```

Queries die joins gebruiken zullen nog steeds een array van het basismodel teruggeven. Om toegang te krijgen tot het joined model, gebruik de `joined` methode.

```swift
// Toegang tot samengevoegd model vanuit query resultaat.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Model aliassen staan u toe om hetzelfde model meerdere malen aan een query toe te voegen. Om een model alias aan te geven, maakt u een of meer types die voldoen aan `ModelAlias`. 

```swift
// Voorbeeld van model aliassen.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Deze types verwijzen naar het model dat gealiased wordt via de `model` eigenschap. Eenmaal aangemaakt, kunt u model aliassen gebruiken zoals normale modellen in een query builder.

```swift
// Haal alle wedstrijden op waar de naam van de thuisploeg Vapor is
// en sorteer op de naam van het uitteam.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Alle modelvelden zijn toegankelijk via het model alias type via `@dynamicMemberLookup`.

```swift
// Toegang tot het samengevoegde model vanuit het resultaat.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

Query builder ondersteunt het updaten van meer dan één model tegelijk met behulp van de `update` methode.

```swift
// Update alle planeten genaamd "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` ondersteunt de `set`, `filter`, en `range` methoden. 

## Delete

Query builder ondersteunt het verwijderen van meer dan een model tegelijk met behulp van de `delete` methode.

```swift
// Verwijder alle planeten genaamd "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` ondersteunt de `filter` methode.

## Paginate

Fluent's query API ondersteunt automatische paginering van resultaten met behulp van de `paginate` methode. 

```swift
// Voorbeeld van paginering op verzoek.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

De `paginate(for:)` methode gebruikt de `page` en `per` parameters beschikbaar in de request URI om de gewenste set resultaten terug te geven. Metadata over de huidige pagina en het totaal aantal resultaten is opgenomen in de `metadata` sleutel.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

Het bovenstaande verzoek zou een antwoord opleveren met de volgende structuur.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Paginanummers beginnen bij `1`. U kunt ook een handmatige pagina aanvraag doen.

```swift
// Voorbeeld van handmatige paginering.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

Query resultaten kunnen worden gesorteerd op veldwaarden met de `sort` methode.

```swift
// Planeten ophalen gesorteerd op naam.
Planet.query(on: database).sort(\.$name)
```

Extra soorten kunnen worden toegevoegd als fallbacks in geval van een gelijke stand. De fallbacks worden gebruikt in de volgorde waarin ze zijn toegevoegd aan de query bouwer.

```swift
// Zoek gebruikers gesorteerd op naam. Als twee gebruikers dezelfde naam hebben, sorteer ze dan op leeftijd.
User.query(on: database).sort(\.$name).sort(\.$age)
```
