# Migrations

Migrations são como um sistema de controle de versão para seu banco de dados. Cada migration define uma alteração no banco de dados e como desfazê-la. Ao modificar seu banco de dados através de migrations, você cria uma maneira consistente, testável e compartilhável de evoluir seus bancos de dados ao longo do tempo.

```swift
// An example migration.
struct MyMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // Make a change to the database.
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

Se estiver usando `async`/`await`, você deve implementar o protocolo `AsyncMigration`:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Make a change to the database.
    }

    func revert(on database: any Database) async throws {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

O método `prepare` é onde você faz alterações no `Database` fornecido. Essas podem ser alterações no schema do banco de dados, como adicionar ou remover uma tabela ou coleção, campo ou constraint. Também podem modificar o conteúdo do banco de dados, como criar novas instâncias de models, atualizar valores de campos ou fazer limpeza.

O método `revert` é onde você desfaz essas alterações, se possível. Poder desfazer migrations pode tornar a prototipagem e os testes mais fáceis. Também fornece um plano de backup caso um deploy em produção não saia como planejado.

## Registrar

Migrations são registradas na sua aplicação usando `app.migrations`.

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Você pode adicionar uma migration a um banco de dados específico usando o parâmetro `to`, caso contrário o banco de dados padrão será usado.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Migrations devem ser listadas em ordem de dependência. Por exemplo, se `MigrationB` depende de `MigrationA`, ela deve ser adicionada a `app.migrations` em segundo lugar.

## Migrate

Para migrar seu banco de dados, execute o comando `migrate`.

```sh
swift run App migrate
```

Você também pode executar este [comando pelo Xcode](../advanced/commands.md#xcode). O comando migrate verificará o banco de dados para ver se alguma nova migration foi registrada desde a última execução. Se houver novas migrations, ele pedirá confirmação antes de executá-las.

### Revert

Para desfazer uma migration no seu banco de dados, execute `migrate` com a flag `--revert`.

```sh
swift run App migrate --revert
```

O comando verificará o banco de dados para ver qual lote de migrations foi executado por último e pedirá confirmação antes de revertê-las.

### Auto Migrate

Se você deseja que as migrations sejam executadas automaticamente antes de executar outros comandos, você pode passar a flag `--auto-migrate`.

```sh
swift run App serve --auto-migrate
```

Você também pode fazer isso programaticamente.

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Ambas as opções também existem para reverter: `--auto-revert` e `app.autoRevert()`.

## Próximos Passos

Dê uma olhada nos guias do [schema builder](schema.md) e do [query builder](query.md) para mais informações sobre o que colocar dentro das suas migrations.
