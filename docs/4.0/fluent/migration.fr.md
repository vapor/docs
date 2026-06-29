# Migrations

Les migrations sont similaires à un système de contrôle de version pour vos bases de données. Chaque migration décrit des changements dans votre base de données, ainsi que la façon de les annuler. En utilisant les migrations pour appliquer vos modifications de bases de données, vous aurez une façon fiable, testable, et partageable de mettre à jour vos bases de données sur le long terme. 

```swift
// Exemple de migration.
struct MyMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // Effectue des changements sur la base de données.
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // Si possible, annule les changements appliqués dans la méthode prepare.
    }
}
```

Si vous utilisez `async`/`await`, utilisez plutôt le protocole `AsyncMigration` :

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Effectue des changements sur la base de données.
    }

    func revert(on database: any Database) async throws {
        // Si possible, annule les changements appliqués dans la méthode prepare.
    }
}
```

La méthode `prepare` est l'endroit où vous appliquerez les changements sur la base de données `Database` fournie en entrée. Il peut s'agir de modifications de schéma, comme l'ajout ou suppression de table ou collection, de champs, ou contraintes. Cela peut aussi être utilisé pour modifier les données en base, comme l'insertion de nouvelles lignes, la mise à jour de valeurs existantes, ou du nettoyage.

La méthode `revert` est l'endroit où vous définissez l'annulation de ces changements, si possible. Pouvoir annuler des migrations peut faciliter le prototypage et les tests. Cela vous aide également à assurer un plan de sauvegarde si un déploiement en production ne se passe pas comme prévu. 

## Enregistrement

Vous enregistrez vos migrations sur votre application via `app.migrations`. 

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Vous pouvez enregistrer une migration pour une base de données en particulier grâce au paramètre `to`, sans quoi elle sera appliquée à la base de données par défaut.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Les migrations devraient être enregistrées par ordre de dépendance. Par exemple, si `MigrationB` dépend de `MigrationA`, elle devrait être ajoutée à `app.migrations` en deuxième.

## Migrer

Pour lancer les migrations de vos bases de données, lancez la commande `migrate`.

```sh
swift run App migrate
```

Vous pouvez aussi exécuter cette commande [via Xcode](../advanced/commands.md#xcode). La commande migrate vérifiera votre base de données pour voir si de nouvelles migrations ont été enregistrées depuis la dernière qui a été exécutée. Si elle en trouve, elle vous demandera confirmation avant de les lancer.

### Annuler une migration

Pour annuler une migration sur vos bases de données, lancez la commande `migrate` avec le drapeau `--revert`.

```sh
swift run App migrate --revert
```

La commande vérifiera en base de données quel est le dernier lot de migrations qui a été lancé, et vous demandera confirmation avant d'annuler ses migrations.

### Migration automatique

Si vous souhaitez que les migrations soient automatiquement lancées avant toute autre commande, vous pouvez fournir le drapeau `--auto-migrate` à la commande serve. 

```sh
swift run App serve --auto-migrate
```

Vous pouvez également le faire depuis le code. 

```swift
try app.autoMigrate().wait()

// ou
try await app.autoMigrate()
```

Ces deux options existent aussi pour l'annulation de migrations : `--auto-revert` et `app.autoRevert()`. 

## Pour aller plus loin

Lisez les guides sur le [SchemaBuilder](schema.md) et le [QueryBuilder](query.md) pour plus d'informations sur quoi mettre dans vos migrations. 
