# Migraciones

Las migraciones son una especie de control de versiones para tu base de datos. Cada migración define un cambio en la base de datos y cómo deshacerlo. Modificando tu base de datos mediante migraciones creas una manera consistente, testable y fácil de compartir, de evolucionar tu base de datos a lo largo del tiempo.

```swift
// Una migración de ejemplo.
struct MyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // Haz un cambio en la base de datos.
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
    	// Deshaz el cambio hecho en `prepare`, si es posible.
    }
}
```

Si estás usando `async`/`await` deberías implementar el protocolo `AsyncMigration`:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Haz un cambio en la base de datos.
    }

    func revert(on database: Database) async throws {
    	// Deshaz el cambio hecho en `prepare`, si es posible.
    }
}
```

En el método `prepare` haces cambios en la `Database` proporcionada. Pueden ser cambios en el esquema de la base de datos, como añadir o quitar una tabla, colección, campo o restricción. También pueden modificar el contenido de la base de datos, por ejemplo creando una nueva instancia de un modelo, actualizando valores de campos o haciendo una limpieza general.

En el método `revert` deshaces estos cambios, siempre y cuando sea posible. Tener la capacidad de deshacer migraciones puede facilitar el prototipado y el testing. También te ofrece un plan de recuperación si un despliegue en producción no marcha según lo planeado. 

## Registro

Las migraciones son registradas en tu aplicación usando `app.migrations`. 

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Puedes añadir una migración a una base de datos específica mediante el parámetro `to`, sino se usará la base de datos por defecto.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Las migraciones deberían estar listadas según el orden de dependencia. Por ejemplo, si `MigrationB` depende de `MigrationA`, debería añadirse a `app.migrations` la segunda.

## Migrar

Para migrar tu base de datos, ejecuta el comando `migrate`.

```sh
swift run App migrate
```

También puedes ejecutar este [comando desde Xcode](../advanced/commands.md#xcode). El comando de migración comprobará la base de datos para ver si se han registrado nuevas migraciones desde la última ejecución. Si hay nuevas migraciones pedirá confirmación antes de ejecutarlas.

### Revertir

Para deshacer una migración en tu base de datos, ejecuta `migrate` con la marca `--revert`.

```sh
swift run App migrate --revert
```

El comando comprobará la base de datos para ver que conjunto de migraciones fue ejecutado la vez anterior y pedirá confirmación antes de revertirlas.

### Migración Automática

Si quieres que tus migraciones se ejecuten automáticamente antes de ejecutar otros comandos, añade la marca `--auto-migrate`. 

```sh
swift run App serve --auto-migrate
```

También puedes hacerlo de manera programática. 

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Ambas opciones también exiten para revertir: `--auto-revert` y `app.autoRevert()`. 

## Próximos Pasos

Echa un vistazo a las guías de [schema builder](schema.md) y [query builder](query.md) para más información acerca de qué poner dentro de tus migraciones. 
