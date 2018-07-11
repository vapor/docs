# PostgreSQL Schema Builder

Fluent lets you customize your schemas with PostgreSQL-specific column types. You can even set default values. Let's take a look at creating a simple `Planet` model with custom PostgreSQL field tpyes.

```swift
/// Type of planet.
enum PlanetType: String, Codable, CaseIterable, ReflectionDecodable {
    case smallRocky
    case gasGiant
    case dwarf
}

/// Represents a planet.
struct Planet: PostgreSQLModel, PostgreSQLMigration {
	/// Unique identifier.
    var id: Int?

    /// Name of the planet.
    let name: String

    /// Planet's specific type.
    let type: PlanetType
}
```

The above model looks great, but there are a couple of problems with the automatically generated migration:

- `name` uses a `TEXT` column, but we want to use `VARCHAR(64)`.
- `type` is defaulting to a `JSONB` column, but we want to store it as `ENUM()`.