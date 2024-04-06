# Migrazioni

Le migrazioni sono come un sistema di controllo versione per il tuo database. Ogni migrazione definisce un cambiamento al database e come disfarlo. Utilizzando le migrazioni per applicare modifiche al database, stabilisci un approccio coeso, testabile, e condivisibile per evolvere nel tempo i tuoi database.

```swift
// Un esempio di migrazione.
struct MyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // Fai una modifica al database.
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
    	// Disfai le modifiche fatte in `prepare`, se possibile.
    }
}
```

Se usi `async`/`await` devi implementare il protocollo `AsyncMigration`:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Fai una modifica al database.
    }

    func revert(on database: Database) async throws {
    	// Disfai le modifiche fatte in `prepare`, se possibile.
    }
}
```

Il metodo `prepare` è dove fai le modifiche al `Database` fornito. Potrebbero essere modifiche allo schema del database come aggiungere o rimuovere una relazione o una collezione, attributo, o vincolo. Possono anche modificare il contenuto del database, come creare nuove istanze del modello, aggiornare valori di un attributo, o fare pulizia.

Il metodo `revert` è dove disfai queste modifiche, se possibile. Essere in grado di disfare le migrazioni può rendere la prototipazione e il testing più facili. Forniscono anche un piano di backup se un deploy in produzione non va come pianificato. 

## Registra

Le migrazioni vengono registrate alla tua applicazione usando `app.migrations`. 

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Puoi aggiungere una migrazione a un database specifico usando il parametro `to`, altrimenti sarà utilizzato il database di default.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Le migrazioni dovrebbero essere listate in ordine di dipendenza. Per esempio, se `MigrationB` dipende da `MigrationA`, deve essere aggiunto a `app.migrations` per secondo.

## Migra

Per migrare il tuo database, esegui il comando `migrate`.

```sh
swift run App migrate
```

Puoi anche eseguire questo [comando attraverso Xcode](../advanced/commands.md#xcode). Il comando di migrazione controllerà il database per vedere se sono state registrate nuove migrazioni dall'ultima volta in cui è stato eseguito. Se ci sono nuove migrazioni, chiederà una conferma prima di eseguirle.

### Ripristinare

Per disfare una migrazione sul tuo database, esegui `migrate` con la flag `--revert`.

```sh
swift run App migrate --revert
```

Il comando controllerà il database per vedere quale gruppo di migrazioni è stato eseguito per ultimo e chiederà conferma prima di ripristinarle.

### Migra Automaticamente

Se vuoi che le migrazioni vengano eseguite automaticamente prima degli altri comandi, puoi passare la flag `--auto-migrate`. 

```sh
swift run App serve --auto-migrate
```

Puoi farlo anche programmaticamente. 

```swift
try app.autoMigrate().wait()

// oppure
try await app.autoMigrate()
```

Entrambe queste opzioni esistono anche per ripristinare: `--auto-revert` e `app.autoRevert()`. 

## Prossimi Passi

Guarda le guide per [costruire gli schemi](schema.md) e per [costruire le query](query.md) per avere più informazioni riguardo a cosa mettere dentro le tue migrazioni. 
