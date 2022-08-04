# Relaties

Fluent's [model API](model.md) helpt u bij het maken en onderhouden van verwijzingen tussen uw modellen door middel van relaties. Drie typen relaties worden ondersteund:

- [Parent](#parent) / [Child](#optional-child) (Eén-op-één)
- [Parent](#parent) / [Children](#children) (Eén-op-veel)
- [Siblings](#siblings) (Veel-op-veel)

## Parent

De `@Parent` relatie slaat een verwijzing op naar de `@ID` eigenschap van een ander model.

```swift
final class Planet: Model {
    // Voorbeeld van een parent relatie.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` bevat een `@Field` genaamd `id` welke wordt gebruikt voor het instellen en bijwerken van de relatie.

```swift
// Stel parent relatie id in
earth.$star.id = sun.id
```

Bijvoorbeeld, de `Planet` initializer zou er zo uitzien:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

De `key` parameter definieert de veldsleutel om te gebruiken voor het opslaan van de identifier van de parent. Ervan uitgaande dat `Star` een `UUID` identifier heeft, is deze `@Parent` relatie compatibel met de volgende [veld definitie](schema.md#field).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Merk op dat de [`.references`](schema.md#field-constraint) constraint optioneel is. Zie [schema](schema.md) voor meer informatie.

### Optionele Parent

De `@OptionalParent` relatie slaat een optionele verwijzing op naar de `@ID` eigenschap van een ander model. Het werkt hetzelfde als `@Parent` maar staat toe dat de relatie `nil` is.

```swift
final class Planet: Model {
    // Voorbeeld van een optionele parent relatie.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

De velddefinitie is gelijk aan die van `@Parent`, behalve dat de `.required` restrictie moet worden weggelaten.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

## Optionele Child

De `@OptionalChild` eigenschap creëert een één-op-één relatie tussen de twee modellen. Het slaat geen waarden op in het root model. 

```swift
final class Planet: Model {
    // Voorbeeld van een optionele child relatie.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

De `for` parameter accepteert een sleutelpad naar een `@Parent` of `@OptionalParent` relatie die verwijst naar het root model.

Een nieuw model kan aan deze relatie worden toegevoegd met de `create` methode.

```swift
// Voorbeeld van het toevoegen van een nieuw model aan een relatie.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Dit zal de parent id op het child model automatisch instellen.

Aangezien deze relatie geen waarden opslaat, is er geen databaseschema-item vereist voor het basismodel.

Het één-op-één-karakter van de relatie moet in het schema van het child-model worden afgedwongen met een `.unique` restrictie op de kolom die naar het parent-model verwijst.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Voorbeeld van unieke beperking
    .unique(on: "planet_id")
    .create()
```
!!! warning "Waarschuwing"
    Het weglaten van de unieke beperking op het parent ID veld uit het schema van de klant kan leiden tot onvoorspelbare resultaten.
    Als er geen uniciteits beperking is, kan de child tabel meer dan een child rij bevatten voor een gegeven parent; in dit geval zal een `@OptionalChild` eigenschap nog steeds slechts toegang hebben tot één child per keer, met geen enkele manier om te controleren welk child geladen wordt. Als je meerdere child rijen voor een bepaalde parent moet opslaan, gebruik dan `@Children`.

## Children

De `@Children` eigenschap creëert een één-op-veel relatie tussen twee modellen. Het slaat geen waarden op in het root model. 

```swift
final class Star: Model {
    // Voorbeeld van een children relatie.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

De `for` parameter accepteert een sleutelpad naar een `@Parent` of `@OptionalParent` relatie die verwijst naar het root model. In dit geval verwijzen we naar de `@Parent` relatie uit het vorige [voorbeeld](#parent). 

Nieuwe modellen kunnen aan deze relatie worden toegevoegd met de `create` methode.

```swift
// Voorbeeld van het toevoegen van een nieuw model aan een relatie.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Dit zal de parent id op het child model automatisch instellen.

Aangezien deze relatie geen waarden opslaat, is er geen invoer in het databaseschema vereist. 

## Siblings

De `@Siblings` eigenschap creëert een veel-op-veel relatie tussen twee modellen. Het doet dit door middel van een tertiair model, een pivot genaamd.

Laten we eens kijken naar een voorbeeld van een veel-op-veel relatie tussen een `Planet` en een `Tag`.

```swift
// Voorbeeld van een pivot model.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
    }
}
```

Pivots zijn normale modellen die twee `@Parent` relaties bevatten. Één voor elk van de modellen die gerelateerd moeten worden. Extra eigenschappen kunnen worden opgeslagen op de pivot indien gewenst. 

Het toevoegen van een [unieke](schema.md#unique) constraint aan het pivot model kan helpen om overbodige entries te voorkomen. Zie [schema](schema.md) voor meer informatie.

```swift
// Staat duplicaat relaties niet toe.
.unique(on: "planet_id", "tag_id")
```

Zodra de pivot is gemaakt, gebruik de `@Siblings` eigenschap om de relatie te maken. 

```swift
final class Planet: Model {
    // Voorbeeld van een siblings relatie.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

De `@Siblings` eigenschap vereist drie parameters:

- `through`: Het type van het pivot model.
- `from`: Sleutelpad van de pivot naar de parent-relatie die verwijst naar het basismodel.
- `to`: Sleutelpad van de pivot naar de parent relation die naar het gerelateerde model verwijst.

De inverse `@Siblings` eigenschap op het verwante model maakt de relatie compleet.

```swift
final class Tag: Model {
    // Voorbeeld van een siblings relatie.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

De `@Siblings` eigenschap heeft methoden voor het toevoegen en verwijderen van modellen uit de relatie. 

Gebruik de `attach` methode om een model aan de relatie toe te voegen. Hierdoor wordt het pivot model automatisch aangemaakt en opgeslagen.

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Voegt het model toe aan de relatie.
try await earth.$tags.attach(inhabited, on: database)
```

Bij het koppelen van een enkel model, kunt u de `method` parameter gebruiken om te kiezen of de relatie wel of niet gecontroleerd moet worden voor het opslaan.

```swift
// Koppelt alleen als de relatie nog niet bestaat.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Gebruik de `detach` methode om een model uit de relatie te verwijderen. Dit verwijdert het corresponderende pivot model.

```swift
// Verwijdert het model uit de relatie.
try await earth.$tags.detach(inhabited, on: database)
```

Je kunt controleren of een model gerelateerd is of niet met de `isAttached` methode.

```swift
// Controleert of de modellen verwant zijn.
earth.$tags.isAttached(to: inhabited)
```

## Get

Gebruik de `get(on:)` methode om de waarde van een relatie op te halen. 

```swift
// Haalt alle planeten van de zon op.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Of

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Gebruik de `reload` parameter om te kiezen of de relatie wel of niet opnieuw moet worden opgehaald uit de database als deze al eerder is geladen. 

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Gebruik de `query(on:)` methode op een relatie om een query builder te maken voor de gerelateerde modellen. 

```swift
// Haal alle planeten van de zon op die een naam hebben die begint met M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Zie [query](query.md) voor meer informatie.

## Eager Loading

Fluent's query bouwer maakt het mogelijk om de relaties van een model vooraf te laden wanneer het wordt opgehaald uit de database. Dit wordt eager loading genoemd en stelt u in staat om synchroon relaties te benaderen zonder dat u eerst [`load`](#lazy-eager-loading) of [`get`](#get) hoeft aan te roepen. 

Om een relatie eager te laden, geef je een sleutelpad naar de relatie door aan de `with` methode op query builder. 

```swift
// Voorbeeld van eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` is hier synchroon toegankelijk 
        // omdat het eager geladen is.
        print(planet.star.name)
    }
}

// Of

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` is hier synchroon toegankelijk
    // omdat het eager geladen is.
    print(planet.star.name)
}
```

In het bovenstaande voorbeeld wordt een sleutelpad naar de [`@Parent`](#parent) relatie genaamd `star` doorgegeven aan `with`. Dit zorgt ervoor dat de query bouwer een extra query uitvoert nadat alle planeten zijn geladen om al hun gerelateerde sterren op te halen. De sterren zijn dan synchroon toegankelijk via de `@Parent` eigenschap. 

Elke relatie die eager wordt geladen vereist slechts één extra query, ongeacht hoeveel modellen er worden geretourneerd. Eager loading is alleen mogelijk met de `all` en `first` methodes van query builder. 


### Nested Eager Load

Met de `with` methode van de query bouwer kunnen relaties eager geladen worden op het model waarop de query betrekking heeft. U kunt echter ook relaties op gerelateerde modellen eager laden.  

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star` is hier synchroon toegankelijk
    // omdat het eager geladen is.
    print(planet.star.galaxy.name)
}
```

De `with` methode accepteert een optionele closure als tweede parameter. Deze closure accepteert een eager load builder voor de gekozen relatie. Er is geen limiet aan hoe diep eager loading genest kan worden. 

## Lazy Eager Loading

In het geval dat u het bovenliggende model al heeft opgehaald en u wilt een van zijn relaties laden, dan kunt u de `load(on:)` methode voor dat doel gebruiken. Hiermee wordt het gerelateerde model opgehaald uit de database en kan het worden benaderd als een lokale eigenschap.

```swift
planet.$star.load(on: database).map {
    print(planet.star.name)
}

// Of

try await planet.$star.load(on: database)
print(planet.star.name)
```

Om te controleren of een relatie al dan niet geladen is, gebruik je de `value` eigenschap.

```swift
if planet.$star.value != nil {
    // Relatie is geladen.
    print(planet.star.name)
} else {
    // De relatie is niet geladen.
    // Pogingen om toegang te krijgen tot planet.star zullen mislukken.
}
```

Als u het gerelateerde model al in een variabele heeft, kunt u de relatie handmatig instellen met behulp van de `value` eigenschap die hierboven is genoemd.

```swift
planet.$star.value = star
```

Dit zal het gerelateerde model aan de ouder koppelen alsof het eager loaded of lazy loaded was zonder een extra database query.
