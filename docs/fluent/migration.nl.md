# Migraties

Migraties zijn als een versiebeheersysteem voor uw database. Elke migratie definieert een wijziging aan de database en hoe deze ongedaan te maken. Door uw database aan te passen via migraties, creëert u een consistente, testbare en deelbare manier om uw databases in de loop van de tijd te laten evolueren. 

```swift
// Een voorbeeld migratie.
struct MyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // Breng een wijziging aan in de database.
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
    	// Maak de verandering in `prepare` ongedaan, indien mogelijk.
    }
}
```

Als je `async`/`await` gebruikt moet je het `AsyncMigration` protocol implementeren:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Breng een wijziging aan in de database.
    }

    func revert(on database: Database) async throws {
    	// Maak de verandering in `prepare` ongedaan, indien mogelijk.
    }
}
```

De `prepare` methode is waar je wijzigingen aanbrengt in de aangeleverde `Database`. Dit kunnen wijzigingen zijn aan het database schema, zoals het toevoegen of verwijderen van een tabel of collectie, veld, of constraint. Ze kunnen ook de inhoud van de database wijzigen, zoals het creëren van nieuwe modelinstanties, het bijwerken van veldwaarden, of het opschonen van de database.

De `revert` methode is waar je deze veranderingen ongedaan maakt, indien mogelijk. De mogelijkheid om migraties ongedaan te maken kan prototyping en testen makkelijker maken. Het geeft je ook een backup plan als een deploy naar productie niet gaat zoals gepland. 

## Registreren

Migraties worden geregistreerd in uw applicatie met `app.migrations`. 

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

U kunt een migratie naar een specifieke database toevoegen met de `naar` parameter, anders wordt de standaard database gebruikt.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Migraties moeten worden vermeld in volgorde van afhankelijkheid. Bijvoorbeeld, als `MigratieB` afhankelijk is van `MigratieA`, moet deze als tweede aan `app.migrations` worden toegevoegd.

## Migreren

Om uw database te migreren, voert u het `migrate` commando uit.

```sh
swift run App migrate
```

Je kunt ook dit [commando via Xcode] uitvoeren(../advanced/commands.md#xcode). Het migrate commando controleert de database om te zien of er nieuwe migraties zijn geregistreerd sinds de laatste keer dat het commando werd uitgevoerd. Als er nieuwe migraties zijn, vraagt het om een bevestiging voordat het wordt uitgevoerd.

### Ongedaan Maken

Om een migratie op uw database ongedaan te maken, voert u `migrate` uit met de `--revert` vlag.

```sh
swift run App migrate --revert
```

Het commando controleert de database om te zien welke batch van migraties het laatst is uitgevoerd en vraagt om een bevestiging voordat ze worden teruggedraaid.

### Auto Migrate

Als u wilt dat migraties automatisch worden uitgevoerd voordat andere commando's worden uitgevoerd, kunt u de `--auto-migrate` vlag meegeven. 

```sh
swift run App serve --auto-migrate
```

U kunt dit ook programmatisch doen. 

```swift
try app.autoMigrate().wait()

// of
try await app.autoMigrate()
```

Beide opties bestaan ook om terug te draaien: `--auto-revert` en `app.autoRevert()`. 

## Volgende Stappen

Kijk eens naar de [schema builder](schema.md) en [query builder](query.md) gidsen voor meer informatie over wat je in je migraties moet zetten. 
