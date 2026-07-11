# Migracje

Migracje działają jak system kontroli wersji dla twojej bazy danych. Każda migracja definiuje zmianę w bazie danych oraz sposób jej cofnięcia. Modyfikując bazę danych za pomocą migracji, tworzysz spójny, testowalny i możliwy do współdzielenia sposób rozwijania swoich baz danych w czasie.

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

Jeśli korzystasz z `async`/`await`, powinieneś zaimplementować protokół `AsyncMigration`:

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

Metoda `prepare` to miejsce, w którym wprowadzasz zmiany do dostarczonej `Database`. Mogą to być zmiany w schemacie bazy danych, takie jak dodanie lub usunięcie tabeli albo kolekcji, pola lub ograniczenia. Mogą one również modyfikować zawartość bazy danych, na przykład tworzyć nowe instancje modeli, aktualizować wartości pól lub wykonywać porządki.

Metoda `revert` to miejsce, w którym cofasz te zmiany, jeśli to możliwe. Możliwość cofnięcia migracji może ułatwić prototypowanie i testowanie. Dają ci one również plan awaryjny na wypadek, gdyby wdrożenie na produkcję nie poszło zgodnie z planem.

## Rejestracja

Migracje są rejestrowane w twojej aplikacji za pomocą `app.migrations`.

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

Możesz dodać migrację do konkretnej bazy danych za pomocą parametru `to`, w przeciwnym razie zostanie użyta domyślna baza danych.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Migracje powinny być wymienione w kolejności zależności. Na przykład, jeśli `MigrationB` zależy od `MigrationA`, powinna zostać dodana do `app.migrations` jako druga.

## Migrowanie

Aby zmigrować swoją bazę danych, uruchom komendę `migrate`.

```sh
swift run App migrate
```

Możesz również uruchomić tę [komendę przez Xcode](../advanced/commands.md#xcode). Komenda migrate sprawdzi bazę danych, aby zobaczyć, czy od czasu jej ostatniego uruchomienia zarejestrowano jakieś nowe migracje. Jeśli istnieją nowe migracje, poprosi o potwierdzenie przed ich uruchomieniem.

### Cofanie

Aby cofnąć migrację w swojej bazie danych, uruchom `migrate` z flagą `--revert`.

```sh
swift run App migrate --revert
```

Komenda sprawdzi bazę danych, aby ustalić, jaka partia migracji została uruchomiona ostatnio, i poprosi o potwierdzenie przed ich cofnięciem.

### Automatyczne migrowanie

Jeśli chcesz, aby migracje uruchamiały się automatycznie przed uruchomieniem innych komend, możesz przekazać flagę `--auto-migrate`.

```sh
swift run App serve --auto-migrate
```

Możesz to również zrobić programowo.

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Obie te opcje istnieją również dla cofania: `--auto-revert` oraz `app.autoRevert()`.

## Następne kroki

Zapoznaj się z przewodnikami [schema builder](schema.md) oraz [query builder](query.md), aby uzyskać więcej informacji o tym, co umieszczać wewnątrz swoich migracji.
