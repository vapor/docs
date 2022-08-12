# Models

Modellen vertegenwoordigen gegevens die zijn opgeslagen in tabellen of verzamelingen in uw database. Modellen hebben één of meer velden die codeerbare waarden opslaan. Alle modellen hebben een unieke identifier. Property wrappers worden gebruikt om identifiers, velden, en relaties aan te duiden. 

Hieronder staat een voorbeeld van een eenvoudig model met één veld. Merk op dat modellen niet het volledige databaseschema beschrijven, zoals constraints, indexen, en foreign keys. Schema's worden gedefinieerd in [migraties](migration.md). Modellen zijn gericht op het representeren van de gegevens die zijn opgeslagen in uw databaseschema's.  

```swift
final class Planet: Model {
    // Naam van de tabel of verzameling.
    static let schema = "planets"

    // Unieke identificator voor deze planeet.
    @ID(key: .id)
    var id: UUID?

    // De naam van de Planeet.
    @Field(key: "name")
    var name: String

    // Maakt een nieuwe, lege Planeet aan.
    init() { }

    // Creëert een nieuwe planeet met alle eigenschappen ingesteld.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## Schema

Alle modellen hebben een statische, get-only `schema` eigenschap nodig. Deze string verwijst naar de naam van de tabel of collectie die dit model vertegenwoordigt. 

```swift
final class Planet: Model {
    // Naam van de tabel of verzameling.
    static let schema = "planets"
}
```

Bij het bevragen van dit model, zullen gegevens worden opgehaald uit en opgeslagen in het schema genaamd `"planets"`.

!!! tip
    De schema naam is typisch de klasse naam in meervoud en met kleine letters. 

## Identifier

Alle modellen moeten een `id` eigenschap hebben, gedefinieerd met de `@ID` eigenschap wrapper. Dit veld identificeert instanties van uw model op een unieke manier.

```swift
final class Planet: Model {
    // Unieke identificatiecode voor deze planeet.
    @ID(key: .id)
    var id: UUID?
}
```

Standaard moet de `@ID` eigenschap de speciale `.id` sleutel gebruiken die verwijst naar een sleutel voor de onderliggende database-driver. Voor SQL is dit `"id"` en voor NoSQL is dit `"_id"`. 

De `@ID` moet ook van het type `UUID` zijn. Dit is de enige identifier waarde die momenteel door alle database drivers wordt ondersteund. Fluent zal automatisch nieuwe UUID identifiers genereren wanneer modellen worden gemaakt. 

`@ID` heeft een optionele waarde, omdat niet-opgeslagen modellen nog geen identifier kunnen hebben. Om de identifier te krijgen of een foutmelding te krijgen, gebruik `requireID`.

```swift
let id = try planet.requireID()
```

### Exists

`@ID` heeft een `exists` eigenschap die weergeeft of het model bestaat in de database of niet. Wanneer u een model initialiseert, is de waarde `false`. Nadat je een model hebt opgeslagen of wanneer je een model ophaalt uit de database, is de waarde `true`. Deze eigenschap is muteerbaar.

```swift
if planet.$id.exists {
    // Dit model bestaat in de database.
}
```

### Custom Identifier

Fluent ondersteunt aangepaste identifier sleutels en types door gebruik te maken van de `@ID(custom:)` overload. 

```swift
final class Planet: Model {
    // Unieke identificatiecode voor deze planeet.
    @ID(custom: "foo")
    var id: Int?
}
```

Het bovenstaande voorbeeld gebruikt een `@ID` met aangepaste sleutel `"foo"` en identifier type `Int`. Dit is compatibel met SQL databases die auto-incrementing primary keys gebruiken, maar is niet compatibel met NoSQL. 

Custom `@ID`s staan de gebruiker toe om te specificeren hoe de identifier moet worden gegenereerd met behulp van de `generatedBy` parameter.

```swift
@ID(custom: "foo", generatedBy: .user)
```

De `generatedBy` parameter ondersteunt deze gevallen:

|Gegenereerd Door|Beschrijving|
|-|-|
|`.user`|De `@ID` eigenschap wordt verwacht ingesteld te zijn voordat een nieuw model wordt opgeslagen.|
|`.random`|`@ID` waardetype moet voldoen aan `RandomGeneratable`.|
|`.database`|Database wordt verwacht een waarde te genereren bij het opslaan.|

If the `generatedBy` parameter is omitted, Fluent will attempt to infer an appropriate case based on the `@ID` value type. For example, `Int` will default to `.database` generation unless otherwise specified.
Indien de `generatedBy` parameter is weggelaten, zal Fluent proberen een geschikt geval af te leiden op basis van het `@ID` waardetype. Bijvoorbeeld, `Int` zal standaard `.database` generatie gebruiken tenzij anders gespecificeerd.

## Initializer

Modellen moeten een lege initialisatiemethode hebben.

```swift
final class Planet: Model {
    // Maakt een nieuwe, lege planeet aan.
    init() { }
}
```

Fluent heeft deze methode intern nodig om modellen te initialiseren die door queries worden geretourneerd. Het wordt ook gebruikt voor reflectie. 

Misschien wilt u een gemakkelijke initializer aan uw model toevoegen die alle eigenschappen accepteert. 

```swift
final class Planet: Model {
    // Maakt een nieuwe planeet aan met alle eigenschappen ingesteld.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Het gebruik van gemaksinitializers maakt het gemakkelijker om in de toekomst nieuwe eigenschappen aan het model toe te voegen. 

## Field

Modellen kunnen nul of meer `@Field` eigenschappen hebben voor het opslaan van gegevens. 

```swift
final class Planet: Model {
    // De naam van de planeet.
    @Field(key: "name")
    var name: String
}
```

Voor velden moet de databasesleutel expliciet worden gedefinieerd. Deze hoeft niet dezelfde te zijn als de naam van de eigenschap. 

!!! tip
    Fluent raadt aan `snake_case` te gebruiken voor databasesleutels en `camelCase` voor eigenschapsnamen. 

Field waarden kunnen elk type zijn dat voldoet aan `Codable`. Het opslaan van geneste structuren en arrays in `@Field` wordt ondersteund, maar filterbewerkingen zijn beperkt. Zie [`@Group`](#group) voor een alternatief.

Voor velden die een optionele waarde bevatten, gebruik `@OptionalField`. 

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! warning "Waarschuwing"
    Een niet-optioneel veld dat een `willSet` property observer heeft die verwijst naar zijn huidige waarde of een `didSet` property observer die verwijst naar zijn `oldValue` zal resulteren in een fatale fout.

## Relaties

Modellen kunnen nul of meer relatie-eigenschappen hebben die verwijzen naar andere modellen zoals `@Parent`, `@Children`, en `@Siblings`. Leer meer over relaties in de [relations](relations.md) sectie.

## Timestamp

`@Timestamp` is een speciaal type `@Field` dat een `Foundation.Date` opslaat. Tijdstempels worden automatisch door Fluent ingesteld op basis van de gekozen trigger.

```swift
final class Planet: Model {
    // Wanneer deze planeet werd aangemaakt.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // Wanneer deze Planeet voor het laatst is bijgewerkt.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp` ondersteunt de volgende triggers.

|Trigger|Beschrijving|
|-|-|
|`.create`|Wordt ingesteld wanneer een nieuw model in de database wordt opgeslagen.|
|`.update`|Wordt ingesteld wanneer een bestaand model wordt opgeslagen in de database.|
|`.delete`|Ingesteld wanneer een model uit de database wordt verwijderd. Zie [soft delete](#soft-delete).|

De datumwaarde van `@Timestamp` is optioneel en moet op `nil` worden gezet bij het initialiseren van een nieuw model. 

### Timestamp Formaat

Standaard zal `@Timestamp` een efficiënte `datetime` codering gebruiken, gebaseerd op uw database driver. U kunt aanpassen hoe de tijdstempel wordt opgeslagen in de database met behulp van de `format` parameter.

```swift
// Slaat een ISO 8601 geformatteerd tijdstempel op dat weergeeft
// wanneer dit model voor het laatst werd bijgewerkt.
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

Merk op dat de bijbehorende migratie voor dit `.iso8601` voorbeeld opslag in `.string` formaat zou vereisen.

```swift
.field("updated_at", .string)
```

De beschikbare tijdstempelformaten worden hieronder opgesomd.

|Formaat|Beschrijving|Type|
|-|-|-|
|`.default`|Gebruikt een efficiënte `datetime` codering voor een specifieke database.|Date|
|`.iso8601`|[ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) string. Ondersteund `withMilliseconds` parameter.|String|
|`.unix`|Seconden sinds Unix epoch, inclusief fractie.|Double|

Je kunt de ruwe timestamp waarde direct benaderen met de `timestamp` eigenschap.

```swift
// Stel handmatig de tijdstempelwaarde in op deze
// ISO 8601-geformatteerde @Timestamp.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### Soft Delete

Het toevoegen van een `@Timestamp` die gebruik maakt van de `.delete` trigger aan je model zal soft-deletion mogelijk maken.

```swift
final class Planet: Model {
    // Wanneer deze planeet werd verwijderd.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

Soft-deleted modellen bestaan nog steeds in de database na verwijdering, maar zullen niet worden geretourneerd in queries. 

!!! tip
    U kunt handmatig een tijdstempel bij verwijderen instellen op een datum in de toekomst. Dit kan worden gebruikt als een vervaldatum.

Om te forceren dat een soft-deletable model uit de database wordt verwijderd, gebruikt u de `force` parameter in `delete`. 

```swift
// Verwijdert uit de database zelfs als het model 
// soft deletable is. 
model.delete(force: true, on: database)
```

Om een soft-deleted model te herstellen, gebruik de `restore` methode.

```swift
// Wist de tijdstempel bij verwijdering, 
// zodat dit model in query's kan worden geretourneerd. 
model.restore(on: database)
```

Om soft-deleted modellen in een query op te nemen, gebruikt u `withDeleted`. 

```swift
// Vangt alle planeten op, inclusief soft deleted planeten.
Planet.query(on: database).withDeleted().all()
```

## Enum

`@Enum` is een speciaal type van `@Field` voor het opslaan van string representeerbare types als native database enums. Native database enums bieden een extra laag van type veiligheid aan uw database en kunnen performanter zijn dan raw enums. 

```swift
// String representable, Codable enum voor diersoorten.
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // Slaat het type dier op als een native database enum.
    @Enum(key: "type")
    var type: Animal
}
```

Alleen typen die voldoen aan `RawRepresentable` waarbij `RawValue` `String` is, zijn compatibel met `@Enum`. `String` backed enums voldoen standaard aan deze eis.

Om een optionele enum op te slaan, gebruik `@OptionalEnum`. 

De database moet voorbereid zijn om via een migratie met enums om te gaan. Zie [enum](schema.md#enum) voor meer informatie.

### Raw Enums

Elk enum dat ondersteund wordt door een `Codable` type, zoals `String` of `Int`, kan worden opgeslagen in `@Field`. Het zal worden opgeslagen in de database als de ruwe waarde.

## Group

Met `@Group` kunt u een geneste groep van velden als een enkele eigenschap in uw model opslaan. In tegenstelling tot Codable structs opgeslagen in een `@Field`, zijn de velden in een `@Group` opvraagbaar. Fluent bereikt dit door `@Group` op te slaan als een platte structuur in de database.

Om een `@Group` te gebruiken, definieer eerst de geneste structuur die je wilt opslaan met het `Fields` protocol. Dit is vergelijkbaar met `Model` behalve dat er geen identifier of schema naam nodig is. Je kunt hier veel eigenschappen opslaan die `Model` ondersteunt zoals `@Field`, `@Enum`, of zelfs een andere `@Group`. 

```swift
// Een huisdier met naam en diersoort.
final class Pet: Fields {
    // De naam van het huisdier.
    @Field(key: "name")
    var name: String

    // Het soort huisdier. 
    @Field(key: "type")
    var type: String

    // Maakt een nieuw, leeg huisdier aan.
    init() { }
}
```

Nadat je de velddefinitie hebt gemaakt, kun je deze gebruiken als waarde van een `@Group` eigenschap.

```swift
final class User: Model {
    // Het geneste huisdier van de gebruiker.
    @Group(key: "pet")
    var pet: Pet
}
```

De velden van een `@Group` zijn toegankelijk via dot-syntax.

```swift
let user: User = ...
print(user.pet.name) // String
```

U kunt geneste velden als normaal opvragen door gebruik te maken van punt-syntax op de eigenschap-wrappers.

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

In de database, wordt `@Group` opgeslagen als een platte structuur met sleutels verbonden door `_`. Hieronder is een voorbeeld van hoe `User` er in de database uit zou zien.

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

Modellen voldoen standaard aan `Codable`. Dit betekent dat u uw modellen kunt gebruiken met Vapor's [content API](../basics/content.md) door conformiteit aan het `Content` protocol toe te voegen.

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // Geef een array van alle planeten.
    try await Planet.query(on: req.db).all()
}
```

Bij het serialiseren naar / van `Codable`, zullen model eigenschappen hun variabele namen gebruiken in plaats van sleutels. Relaties zullen serialiseren als geneste structuren en alle eager geladen data zal worden meegenomen. 

### Data Transfer Object

De standaard `Codable` conformiteit van het model kan eenvoudig gebruik en prototyping eenvoudiger maken. Het is echter niet geschikt voor elk gebruik. Voor bepaalde situaties zult u een data transfer object (DTO) moeten gebruiken. 

!!! tip
    Een DTO is een afzonderlijk `Codable` type dat de datastructuur voorstelt die je wilt coderen of decoderen. 

Ga uit van het volgende `User` model in de komende voorbeelden.

```swift
// Verkort gebruikersmodel ter referentie.
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

Een veel voorkomende toepassing van DTOs is het implementeren van `PATCH` verzoeken. Deze verzoeken bevatten alleen waarden voor velden die bijgewerkt moeten worden. Een poging om een `Model` direct uit zo'n verzoek te decoderen zou mislukken als een van de vereiste velden zou ontbreken. In het onderstaande voorbeeld zie je hoe een DTO wordt gebruikt om de request data te decoderen en een model te updaten.

```swift
// Structuur van PATCH /users/:id verzoek.
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // Decodeer de verzoekgegevens.
    let patch = try req.content.decode(PatchUser.self)
    // Haal de gewenste gebruiker uit de database.
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // Als er een voornaam is opgegeven, actualiseer die dan.
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // Als er een nieuwe achternaam is opgegeven, actualiseer die dan.
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // Sla de gebruiker op en stuur hem terug.
    try await user.save(on: req.db)
    return user
}
```

Een andere veel voorkomende use case voor DTOs is het aanpassen van het formaat van uw API antwoorden. Het onderstaande voorbeeld toont hoe een DTO kan worden gebruikt om een berekend veld aan een antwoord toe te voegen.

```swift
// Structuur van GET /users antwoord.
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // Haal alle gebruikers op uit de database.
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // Converteer elke gebruiker naar GET return type.
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

Zelfs als de structuur van de DTO identiek is aan de `Codable` conformiteit van het model, kan het hebben als een apart type helpen om grote projecten netjes te houden. Als u ooit een wijziging moet aanbrengen in de eigenschappen van uw modellen, hoeft u zich geen zorgen te maken over het verbreken van de publieke API van uw app. U kunt ook overwegen om uw DTOs in een apart pakket te stoppen dat gedeeld kan worden met gebruikers van uw API. 

Om deze redenen bevelen wij het gebruik van DTO's ten zeerste aan, waar mogelijk, vooral voor grote projecten.

## Alias

Met het `ModelAlias` protocol kunt u een model uniek identificeren dat meerdere malen in een query wordt samengevoegd. Voor meer informatie, zie [joins](query.md#join). 

## Save

Om een model op te slaan in de database, gebruik je de `save(on:)` methode.

```swift
planet.save(on: database)
```

Deze methode zal `create` of `update` intern aanroepen, afhankelijk van of het model al bestaat in de database.

### Create

Je kunt de `create` methode aanroepen om een nieuw model in de database op te slaan.

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` is ook beschikbaar op een array van modellen. Dit slaat alle modellen op in de database in een enkele batch / query. 

```swift
// Voorbeeld van batchcreatie.
[earth, mars].create(on: database)
```

!!! warning "Waarschuwing"
    Modellen die gebruik maken van [`@ID(custom:)`](#custom-identifier) met de `.database` generator (meestal auto-incrementing `Int`s) zullen hun nieuw aangemaakte identifiers niet toegankelijk hebben na batch create. Voor situaties waarin je toegang tot de identifiers nodig hebt, roep `create` aan voor elk model.

Om een array van modellen afzonderlijk te maken, gebruik `map` + `flatten`.

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

Als u `async`/`await` gebruikt kunt u als volgt te werk gaan:

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### Update

Je kunt de `update` methode aanroepen om een model op te slaan dat is opgehaald uit de database.

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

Om een array van modellen bij te werken, gebruik `map` + `flatten`.

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TODO
```

## Query

Modellen stellen een statische methode `query(on:)` beschikbaar die een query builder retourneert. 

```swift
Planet.query(on: database).all()
```

Leer meer over query's in de [query](./query.md) sectie.

## Find

Modellen hebben een statische `find(_:on:)` methode om een model instantie op identifier op te zoeken. 

```swift
Planet.find(req.parameters.get("id"), on: database)
```

Deze methode retourneert `nil` als er geen model met die identifier is gevonden.

## Lifecycle

Met model middleware kunt u inhaken op de lifecycle-events van uw model. De volgende lifecycle-events worden ondersteund.

|Methode|Beschrijving|
|-|-|
|`create`|Wordt uitgevoerd voordat een model wordt gemaakt.|
|`update`|Wordt uitgevoerd voordat een model wordt bijgewerkt.|
|`delete(force:)`|Wordt uitgevoerd voordat een model wordt verwijderd.|
|`softDelete`|Wordt uitgevoerd voordat een model soft deleted wordt.|
|`restore`|Wordt uitgevoerd voordat een model wordt hersteld (tegenovergestelde van soft delete).|

Model middleware worden gedeclareerd met het `ModelMiddleware` of `AsyncModelMiddleware` protocol. Alle lifecycle methodes hebben een standaard implementatie, zodat u alleen de methodes hoeft te implementeren die u nodig heeft. Elke methode accepteert het model in kwestie, een verwijzing naar de database, en de volgende actie in de keten. De middleware kan kiezen om vroegtijdig terug te keren, een mislukte future terug te sturen, of de volgende actie aan te roepen om normaal verder te gaan.

Met behulp van deze methoden kun je acties uitvoeren zowel voor als na het voltooien van de specifieke gebeurtenis. Het uitvoeren van acties nadat de gebeurtenis is voltooid kan worden gedaan door de toekomst in kaart te brengen die door de volgende responder wordt geretourneerd.

```swift
// Voorbeeld middleware die namen met hoofdletters schrijft.
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // Het model kan hier worden gewijzigd voordat het wordt gemaakt.
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // Zodra de planeet is gecreëerd, zal de code 
            // hier worden uitgevoerd.
            print ("Planet \(model.name) was created")
        }
    }
}
```

of als je `async`/`await` gebruikt:

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) async throws {
        // Het model kan hier worden gewijzigd voordat het wordt gemaakt.
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // Zodra de planeet is gecreëerd, zal de code 
        // hier worden uitgevoerd.
        print ("Planet \(model.name) was created")
    }
}
```

Nadat u uw middleware heeft aangemaakt, kunt u deze inschakelen met `app.databases.middleware`.

```swift
// Voorbeeld van het configureren van model middleware.
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## Database Space

Fluent ondersteunt het instellen van een ruimte voor een model, waardoor individuele Fluent-modellen kunnen worden gepartitioneerd tussen PostgreSQL-schema's, MySQL-databases, en meerdere gekoppelde SQLite-databases. MongoDB ondersteunt op het moment van schrijven nog geen ruimtes. Om een model in een andere ruimte dan de standaardruimte te plaatsen, voegt u een nieuwe statische eigenschap aan het model toe:

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

Fluent zal dit gebruiken bij het bouwen van alle database queries. 
