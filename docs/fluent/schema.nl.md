# Schema

Fluent's schema API stelt u in staat om uw database schema programmatisch aan te maken en te updaten. Het wordt vaak gebruikt in combinatie met [migraties](migration.md) om de database voor te bereiden voor gebruik met [modellen](model.md).

```swift
// Een voorbeeld van Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Om een `SchemaBuilder` te maken, gebruik je de `schema` methode op database. Geef de naam op van de tabel of collectie die je wilt wijzigen. Als je het schema van een model wijzigt, zorg er dan voor dat deze naam overeenkomt met het [`schema`] van het model (model.md#schema). 

## Acties

De schema-API ondersteunt het maken, bijwerken en verwijderen van schema's. Elke actie ondersteunt een subset van de beschikbare methoden van de API. 

### Create

Het aanroepen van `create()` creëert een nieuwe tabel of collectie in de database. Alle methodes voor het definiëren van nieuwe velden en constraints worden ondersteund. Methodes voor updates of deletes worden genegeerd. 

```swift
// Een voorbeeld van schema creatie.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Als een tabel of collectie met de gekozen naam al bestaat, zal er een foutmelding worden gegeven. Om dit te negeren, gebruik `.ignoreExisting()`. 

### Update

Door `update()` aan te roepen wordt een bestaande tabel of collectie in de database bijgewerkt. Alle methodes voor het maken, updaten en verwijderen van velden en constraints worden ondersteund.

```swift
// Een voorbeeld schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Delete

Het oproepen van `delete()` verwijdert een bestaande tabel of collectie uit de database. Er worden geen extra methodes ondersteund.

```swift
// Een voorbeeld van schema verwijdering.
database.schema("planets").delete()
```

## Field

Velden kunnen worden toegevoegd bij het maken of bijwerken van een schema. 

```swift
// Voegt een nieuw veld toe
.field("name", .string, .required)
```

De eerste parameter is de naam van het veld. Deze moet overeenkomen met de sleutel die gebruikt wordt op de bijbehorende model-eigenschap. De tweede parameter is het [data type](#datatype) van het veld. Tenslotte kunnen nul of meer [constraints](#field-constraint) worden toegevoegd.  

### Data Type

Ondersteunde velddatatypes staan hieronder vermeld.

|DataType|Swift Type|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (aanbevolen)|
|`.time`|`Date` (zonder dag, maand en jaar)|
|`.date`|`Date` (het tijdstip weglaten)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Zie [dictionary](#dictionary)|
|`.array`|Zie [array](#array)|
|`.enum`|Zie [enum](#enum)|

### Field Constraint

Ondersteunde veldbeperkingen staan hieronder vermeld. 

|FieldConstraint|Beschrijving|
|-|-|
|`.required`|Staat `nil` waarden niet toe.|
|`.references`|Vereist dat de waarde van dit veld overeenkomt met een waarde in het schema waarnaar wordt verwezen. Zie [foreign key](#foreign-key)|
|`.identifier`|Duidt de primaire sleutel aan. Zie [identifier](#identifier)|

### Identifier

Als je model een standaard `@ID` eigenschap gebruikt, kun je de `id()` helper gebruiken om het veld aan te maken. Dit gebruikt de speciale `.id` veld sleutel en `UUID` waarde type.

```swift
// Voegt veld toe voor standaard identifier.
.id()
```

Voor aangepaste identifier-types moet u het veld handmatig specificeren. 

```swift
// Voegt veld toe voor aangepaste identifier.
.field("id", .int, .identifier(auto: true))
```

De `identifier` constraint mag gebruikt worden op een enkel veld en duidt de primaire sleutel aan. De `auto` vlag bepaalt of de database deze waarde automatisch moet genereren of niet. 

### Update Field

Je kunt het datatype van een veld bijwerken met `updateField`. 

```swift
// Updates van het veld naar `double` datatype.
.updateField("age", .double)
```

Zie [geavanceerd](advanced.md#sql) voor meer informatie over geavanceerde schema updates.

### Delete Field

U kunt een veld uit een schema verwijderen met `deleteField`.

```swift
// Verwijdert het veld "leeftijd".
.deleteField("age")
```

## Constraint

Constraints kunnen worden toegevoegd bij het maken of bijwerken van een schema. In tegenstelling tot [field constraints](#field-constraint), kunnen constraints op het hoogste niveau meerdere velden beïnvloeden.

### Unique

Een unieke beperking vereist dat er geen duplicaten zijn in één of meer velden. 

```swift
// Duplicaat e-mailadressen verbieden.
.unique(on: "email")
```

Indien meerdere velden worden beperkt, moet de specifieke combinatie van de waarde van elk veld uniek zijn.

```swift
// Verbied gebruikers met dezelfde volledige naam.
.unique(on: "first_name", "last_name")
```

Om een unieke beperking te verwijderen, gebruik `deleteUnique`. 

```swift
// Verwijdert duplicaat e-mail beperking.
.deleteUnique(on: "email")
```

### Constraint Name

Fluent genereert standaard unieke constraint namen. Het kan echter zijn dat je een aangepaste constraint naam wilt doorgeven. Je kunt dit doen met de `name` parameter.

```swift
// Duplicaat e-mailadressen verbieden.
.unique(on: "email", name: "no_duplicate_emails")
```

Om een benoemde constraint te verwijderen, moet je `deleteConstraint(name:)` gebruiken. 

```swift
// Verwijdert duplicaat e-mail beperking.
.deleteConstraint(name: "no_duplicate_emails")
```

## Foreign Key

Bij "Foreign key"-restricties moet de waarde van een veld overeenkomen met een van de waarden in het veld waarnaar wordt verwezen. Dit is nuttig om te voorkomen dat ongeldige gegevens worden opgeslagen. Foreign key constraints kunnen worden toegevoegd als veld of als top-level constraint. 

Om een foreign key constraint aan een veld toe te voegen, gebruik `.references`.

```swift
// Voorbeeld van het toevoegen van een veld foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

De bovenstaande beperking vereist dat alle waarden in het veld "star_id" overeenkomen met een van de waarden in het veld "id" van Star.

Dezelfde beperking kan worden toegevoegd als een beperking van het hoogste niveau met `foreignKey`.

```swift
// Voorbeeld van het toevoegen van een top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

In tegenstelling tot veldrestricties, kunnen top-level constraints worden toegevoegd in een schema-update. Ze kunnen ook [named](#constraint-name) zijn. 

Foreign key constraints ondersteunen optionele `onDelete` en `onUpdate` acties.

|ForeignKeyAction|Beschrijving|
|-|-|
|`.noAction`|Voorkomt vreemde sleutel schendingen (standaard).|
|`.restrict`|Zelfde als `.noAction`.|
|`.cascade`|Propagageert verwijderingen via vreemde sleutels.|
|`.setNull`|Stelt het veld in op null als de referentie verbroken is.|
|`.setDefault`|Stelt het veld in op standaard indien de referentie gebroken is.|

Hieronder staat een voorbeeld waarbij foreign key acties worden gebruikt.

```swift
// Voorbeeld van het toevoegen van een top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning "Waarschuwing"
    Vreemde sleutel acties gebeuren alleen in de database, buiten Fluent om. 
    Dit betekent dat zaken als model middleware en soft-delete mogelijk niet correct werken.

## Dictionary

Het dictionary datatype is in staat om geneste dictionary waarden op te slaan. Dit omvat structs die voldoen aan `Codable` en Swift dictionaries met een `Codable` waarde. 

!!! note "Opmerking"
    Fluent's SQL database drivers slaan geneste woordenboeken op in JSON kolommen.

Neem de volgende `Codable` struct.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Omdat deze `Pet` struct `Codable` is, kan het worden opgeslagen in een `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

Dit veld kan worden opgeslagen met behulp van het datatype `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Omdat `Codable` types heterogene dictionaries zijn, specificeren we de `of` parameter niet. 

Als de dictionary waarden homogeen waren, bijvoorbeeld `[String: Int]`, dan zou de `of` parameter het waardetype specificeren.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Dictionary sleutels moeten altijd strings zijn. 

## Array

Het array data type is in staat om geneste arrays op te slaan. Dit omvat Swift arrays die `Codable` waarden bevatten en `Codable` types die een ongesleutelde container gebruiken.

Neem het volgende `@Field` dat een array van strings opslaat.

```swift
@Field(key: "tags")
var tags: [String]
```

Dit veld kan worden opgeslagen met het datatype `.array(van:)`.

```swift
.field("tags", .array(of: .string), .required)
```

Omdat de array homogeen is, specificeren we de `of` parameter. 

Codable Swift `Array`s zullen altijd een homogene waarde type hebben. Aangepaste `Codable` types die heterogene waarden serialiseren naar ongesleutelde containers zijn de uitzondering en moeten het `.array` data type gebruiken.

## Enum

Het enum datatype is in staat om string-gebaseerde Swift enums in de eigen taal op te slaan. Native database enums bieden een extra laag van type veiligheid aan je database en kunnen performanter zijn dan raw enums.

Om een native database enum te definiëren, gebruik de `enum` methode op `Database`. Gebruik `case` om elk geval van de enum te definiëren.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Als een enum is aangemaakt, kunt u de `read()` methode gebruiken om een datatype te genereren voor uw schema veld.

```swift
// Een voorbeeld van het lezen van een enum en het gebruiken ervan om een nieuw veld te definiëren.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Of

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Om een enum te updaten, roep `update()` op. Uit bestaande enums kunnen zaken worden verwijderd.

```swift
// Een voorbeeld van een enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Om een enum te verwijderen, roep `delete()`.

```swift
// Een voorbeeld van het wissen van een enum.
database.enum("planet_type").delete()
```

## Model Coupling

Schema's bouwen is doelbewust losgekoppeld van modellen. In tegenstelling tot query-building, maakt schema-building geen gebruik van sleutelpaden en is volledig stringly typed. Dit is belangrijk omdat schemadefinities, vooral die welke voor migraties zijn geschreven, mogelijk naar modeleigenschappen moeten verwijzen die niet langer bestaan.

Kijk eens naar het volgende migratievoorbeeld om dit beter te begrijpen.

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Laten we aannemen dat deze migratie al is gepushed naar productie. Laten we nu eens aannemen dat we de volgende wijziging in het User model moeten aanbrengen.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Wij kunnen de nodige aanpassingen in het databaseschema aanbrengen met de volgende migratie.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("name")
            .field("first_name", .string)
            .field("last_name", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Merk op dat om deze migratie te laten werken, we tegelijkertijd moeten kunnen verwijzen naar zowel het verwijderde `naam` veld als de nieuwe `voornaam` en `achternaam` velden. Verder moet de originele `UserMigration` geldig blijven. Dit zou niet mogelijk zijn met sleutelpaden.

## Instellen Model Space

Om de [ruimte voor een model](/fluent/model/#database-space) te definiëren, geef de ruimte door aan de `schema(_:space:)` bij het maken van de tabel. Bijv.

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
