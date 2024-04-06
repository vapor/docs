# Migrazioni

Le migrazioni sono come un sistema di controllo versione per il tuo database. Ogni migrazione definisce un cambiamento al database e come disfarlo. Modificando il tuo database con le migrazioni, crei un modo consistente, testabile, e condivisibile per evolvere nel tempo i tuoi database. 

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

Migrations should be listed in order of dependency. For example, if `MigrationB` depends on `MigrationA`, it should be added to `app.migrations` second.

## Migrate

To migrate your database, run the `migrate` command.

```sh
swift run App migrate
```

You can also run this [command through Xcode](../advanced/commands.md#xcode). The migrate command will check the database to see if any new migrations have been registered since it was last run. If there are new migrations, it will ask for a confirmation before running them.

### Revert

To undo a migration on your database, run `migrate` with the `--revert` flag.

```sh
swift run App migrate --revert
```

The command will check the database to see which batch of migrations was last run and ask for a confirmation before reverting them.

### Auto Migrate

If you would like migrations to run automatically before running other commands, you can pass the `--auto-migrate` flag. 

```sh
swift run App serve --auto-migrate
```

You can also do this programatically. 

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Both of these options exist for reverting as well: `--auto-revert` and `app.autoRevert()`. 

## Next Steps

Take a look at the [schema builder](schema.md) and [query builder](query.md) guides for more information about what to put inside your migrations. 
