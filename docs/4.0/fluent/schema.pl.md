# Schemat

API schematu Fluenta pozwala programowo tworzyć i aktualizować schemat swojej bazy danych. Jest ono często używane razem z [migracjami](migration.md), aby przygotować bazę danych do użycia z [modelami](model.md).

```swift
// An example of Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Aby utworzyć `SchemaBuilder`, użyj metody `schema` na bazie danych. Przekaż nazwę tabeli lub kolekcji, którą chcesz zmodyfikować. Jeśli edytujesz schemat dla modelu, upewnij się, że ta nazwa odpowiada wartości [`schema`](model.md#schema) modelu.

## Akcje

API schematu obsługuje tworzenie, aktualizowanie i usuwanie schematów. Każda akcja obsługuje podzbiór dostępnych metod API.

### Tworzenie

Wywołanie `create()` tworzy nową tabelę lub kolekcję w bazie danych. Obsługiwane są wszystkie metody definiowania nowych pól i ograniczeń. Metody służące do aktualizacji lub usuwania są ignorowane.

```swift
// An example schema creation.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Jeśli tabela lub kolekcja o wybranej nazwie już istnieje, zostanie zgłoszony błąd. Aby to zignorować, użyj `.ignoreExisting()`.

### Aktualizacja

Wywołanie `update()` aktualizuje istniejącą tabelę lub kolekcję w bazie danych. Obsługiwane są wszystkie metody tworzenia, aktualizowania i usuwania pól oraz ograniczeń.

```swift
// An example schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Usuwanie

Wywołanie `delete()` usuwa istniejącą tabelę lub kolekcję z bazy danych. Żadne dodatkowe metody nie są obsługiwane.

```swift
// An example schema deletion.
database.schema("planets").delete()
```

## Pole

Pola można dodawać podczas tworzenia lub aktualizacji schematu.

```swift
// Adds a new field
.field("name", .string, .required)
```

Pierwszy parametr to nazwa pola. Powinna ona odpowiadać kluczowi używanemu we właściwości powiązanego modelu. Drugi parametr to [typ danych](#typ-danych) pola. Na koniec można dodać zero lub więcej [ograniczeń](#ograniczenie-pola).

### Typ danych

Poniżej wymieniono obsługiwane typy danych pól.

|DataType|Typ Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (zalecane)|
|`.date`|`Date` (bez godziny)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Zobacz [dictionary](#dictionary)|
|`.array`|Zobacz [array](#array)|
|`.enum`|Zobacz [enum](#enum)|

### Ograniczenie pola

Poniżej wymieniono obsługiwane ograniczenia pól.

|FieldConstraint|Opis|
|-|-|
|`.required`|Zabrania wartości `nil`.|
|`.references`|Wymaga, aby wartość tego pola pasowała do wartości w schemacie, do którego się odwołuje. Zobacz [klucz obcy](#klucz-obcy).|
|`.identifier`|Oznacza klucz główny. Zobacz [identyfikator](#identyfikator).|
|`.sql(SQLColumnConstraintAlgorithm)`|Definiuje dowolne ograniczenie, które nie jest obsługiwane (np. `default`). Zobacz [SQL](#sql) oraz [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/).|

### Identyfikator

Jeśli twój model używa standardowej właściwości `@ID`, możesz użyć pomocnika `id()`, aby utworzyć dla niej pole. Wykorzystuje ono specjalny klucz pola `.id` oraz typ wartości `UUID`.

```swift
// Adds field for default identifier.
.id()
```

Dla niestandardowych typów identyfikatorów musisz zdefiniować pole ręcznie.

```swift
// Adds field for custom identifier.
.field("id", .int, .identifier(auto: true))
```

Ograniczenie `identifier` może być użyte na pojedynczym polu i oznacza klucz główny. Flaga `auto` określa, czy baza danych powinna generować tę wartość automatycznie.

### Aktualizacja pola

Możesz zaktualizować typ danych pola za pomocą `updateField`.

```swift
// Updates the field to `double` data type.
.updateField("age", .double)
```

Zobacz [zaawansowane](advanced.md#sql), aby uzyskać więcej informacji na temat zaawansowanych aktualizacji schematu.

### Usuwanie pola

Możesz usunąć pole ze schematu za pomocą `deleteField`.

```swift
// Deletes the field "age".
.deleteField("age")
```

## Ograniczenie

Ograniczenia można dodawać podczas tworzenia lub aktualizacji schematu. W przeciwieństwie do [ograniczeń pól](#ograniczenie-pola), ograniczenia najwyższego poziomu mogą dotyczyć wielu pól.

### Unikalność

Ograniczenie unikalności wymaga, aby w jednym lub wielu polach nie było zduplikowanych wartości.

```swift
// Disallow duplicate email addresses.
.unique(on: "email")
```

Jeśli ograniczonych jest wiele pól, unikalna musi być konkretna kombinacja wartości każdego z nich.

```swift
// Disallow users with the same full name.
.unique(on: "first_name", "last_name")
```

Aby usunąć ograniczenie unikalności, użyj `deleteUnique`.

```swift
// Removes duplicate email constraint.
.deleteUnique(on: "email")
```

### Nazwa ograniczenia

Fluent domyślnie generuje unikalne nazwy ograniczeń. Możesz jednak chcieć przekazać własną nazwę ograniczenia. Możesz to zrobić za pomocą parametru `name`.

```swift
// Disallow duplicate email addresses.
.unique(on: "email", name: "no_duplicate_emails")
```

Aby usunąć nazwane ograniczenie, musisz użyć `deleteConstraint(name:)`.

```swift
// Removes duplicate email constraint.
.deleteConstraint(name: "no_duplicate_emails")
```

## Klucz obcy

Ograniczenia klucza obcego wymagają, aby wartość pola pasowała do jednej z wartości w polu, do którego się odwołuje. Jest to przydatne do zapobiegania zapisywaniu nieprawidłowych danych. Ograniczenia klucza obcego mogą być dodawane zarówno jako ograniczenie pola, jak i ograniczenie najwyższego poziomu.

Aby dodać ograniczenie klucza obcego do pola, użyj `.references`.

```swift
// Example of adding a field foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

Powyższe ograniczenie wymaga, aby wszystkie wartości w polu "star_id" pasowały do jednej z wartości w polu "id" modelu Star.

To samo ograniczenie można dodać jako ograniczenie najwyższego poziomu za pomocą `foreignKey`.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

W przeciwieństwie do ograniczeń pól, ograniczenia najwyższego poziomu mogą zostać dodane podczas aktualizacji schematu. Mogą też mieć [nazwę](#nazwa-ograniczenia).

Ograniczenia klucza obcego obsługują opcjonalne akcje `onDelete` i `onUpdate`.

|ForeignKeyAction|Opis|
|-|-|
|`.noAction`|Zapobiega naruszeniom klucza obcego (domyślne).|
|`.restrict`|To samo co `.noAction`.|
|`.cascade`|Propaguje usunięcia poprzez klucze obce.|
|`.setNull`|Ustawia pole na null, jeśli odwołanie zostanie przerwane.|
|`.setDefault`|Ustawia pole na wartość domyślną, jeśli odwołanie zostanie przerwane.|

Poniżej znajduje się przykład użycia akcji klucza obcego.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    Akcje klucza obcego odbywają się wyłącznie w bazie danych, z pominięciem Fluenta.
    Oznacza to, że rzeczy takie jak middleware modelu czy soft-delete mogą nie działać poprawnie.

## SQL

Parametr `.sql` pozwala dodać dowolny kod SQL do schematu. Jest to przydatne przy dodawaniu specyficznych ograniczeń lub typów danych.
Częstym przypadkiem użycia jest zdefiniowanie wartości domyślnej dla pola:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

albo nawet wartości domyślnej dla znacznika czasu:

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary

Typ danych dictionary umożliwia przechowywanie zagnieżdżonych wartości słownikowych. Obejmuje to struktury zgodne z `Codable` oraz słowniki Swift z wartością zgodną z `Codable`.

!!! note
    Sterowniki baz danych SQL Fluenta przechowują zagnieżdżone słowniki w kolumnach JSON.

Weźmy następującą strukturę `Codable`.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Ponieważ struktura `Pet` jest zgodna z `Codable`, może być przechowywana w `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

To pole może być przechowywane przy użyciu typu danych `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Ponieważ typy `Codable` są heterogenicznymi słownikami, nie określamy parametru `of`.

Gdyby wartości słownika były jednorodne, na przykład `[String: Int]`, parametr `of` określałby typ wartości.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Klucze słownika muszą zawsze być łańcuchami znaków.

## Array

Typ danych array umożliwia przechowywanie zagnieżdżonych tablic. Obejmuje to tablice Swift zawierające wartości `Codable` oraz typy `Codable`, które używają kontenera bez kluczy (unkeyed container).

Weźmy następujące `@Field`, które przechowuje tablicę łańcuchów znaków.

```swift
@Field(key: "tags")
var tags: [String]
```

To pole może być przechowywane przy użyciu typu danych `.array(of:)`.

```swift
.field("tags", .array(of: .string), .required)
```

Ponieważ tablica jest jednorodna, określamy parametr `of`.

Tablice `Array` zgodne z `Codable` w Swift zawsze będą mieć jednorodny typ wartości. Wyjątkiem są niestandardowe typy `Codable`, które serializują heterogeniczne wartości do kontenerów bez kluczy — powinny one używać typu danych `.array`.

## Enum

Typ danych enum umożliwia natywne przechowywanie enumów Swift opartych na łańcuchach znaków. Natywne enumy bazy danych zapewniają dodatkową warstwę bezpieczeństwa typów w twojej bazie danych i mogą być bardziej wydajne niż surowe enumy.

Aby zdefiniować natywny enum bazy danych, użyj metody `enum` na `Database`. Użyj `case`, aby zdefiniować każdy przypadek enuma.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Po utworzeniu enuma możesz użyć metody `read()`, aby wygenerować typ danych dla pola swojego schematu.

```swift
// An example of reading an enum and using it to define a new field.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Or

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Aby zaktualizować enum, wywołaj `update()`. Z istniejących enumów można usuwać przypadki.

```swift
// An example of enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Aby usunąć enum, wywołaj `delete()`.

```swift
// An example of enum deletion.
database.enum("planet_type").delete()
```

## Powiązanie z modelem

Budowanie schematu jest celowo oddzielone od modeli. W przeciwieństwie do budowania zapytań, budowanie schematu nie korzysta z key path'ów i jest całkowicie oparte na łańcuchach znaków (stringly typed). Jest to istotne, ponieważ definicje schematu, zwłaszcza te napisane dla migracji, mogą potrzebować odwoływać się do właściwości modelu, które już nie istnieją.

Aby lepiej to zrozumieć, spójrzmy na poniższy przykład migracji.

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

Załóżmy, że ta migracja została już wypchnięta na produkcję. Teraz załóżmy, że musimy wprowadzić następującą zmianę w modelu User.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Niezbędne zmiany w schemacie bazy danych możemy wprowadzić za pomocą poniższej migracji.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // It is not currently possible to express this update without using custom SQL.
        // This also doesn't try to deal with splitting the name into first and last,
        // as that requires database-specific syntax.
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

Zwróć uwagę, że aby ta migracja zadziałała, musimy być w stanie odwołać się jednocześnie zarówno do usuwanego pola `name`, jak i nowych pól `firstName` oraz `lastName`. Co więcej, oryginalna migracja `UserMigration` powinna nadal pozostać poprawna. Nie byłoby to możliwe przy użyciu key path'ów.

## Ustawianie przestrzeni modelu

Aby zdefiniować [przestrzeń dla modelu](model.md#database-space), przekaż przestrzeń do `schema(_:space:)` podczas tworzenia tabeli. Np.

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
