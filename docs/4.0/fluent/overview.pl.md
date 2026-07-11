# Fluent

Fluent to framework [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) dla Swift. Wykorzystuje on silny system typów Swift, aby zapewnić łatwy w użyciu interfejs dla twojej bazy danych. Korzystanie z Fluent opiera się na tworzeniu typów modeli, które reprezentują struktury danych w twojej bazie danych. Te modele są następnie wykorzystywane do wykonywania operacji tworzenia, odczytu, aktualizacji i usuwania zamiast pisania surowych zapytań.

## Konfiguracja

Podczas tworzenia projektu za pomocą `vapor new`, odpowiedz "yes" na dołączenie Fluent i wybierz, którego sterownika bazy danych chcesz użyć. Automatycznie doda to zależności do twojego nowego projektu wraz z przykładowym kodem konfiguracyjnym.

### Istniejący projekt

Jeśli masz istniejący projekt, do którego chcesz dodać Fluent, musisz dodać dwie zależności do swojego [pakietu](../getting-started/spm.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Jeden (lub więcej) sterownik(ów) Fluent według wyboru

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

Gdy pakiety zostaną dodane jako zależności, możesz skonfigurować swoje bazy danych za pomocą `app.databases` w `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Każdy z poniższych sterowników Fluent posiada bardziej szczegółowe instrukcje konfiguracji.

### Sterowniki

Fluent obecnie posiada cztery oficjalnie wspierane sterowniki. Możesz wyszukać na GitHubie tag [`fluent-driver`](https://github.com/topics/fluent-driver), aby zobaczyć pełną listę oficjalnych i stworzonych przez społeczność sterowników baz danych dla Fluent.

#### PostgreSQL

PostgreSQL to otwartoźródłowa, zgodna ze standardami baza danych SQL. Jest łatwa do skonfigurowania u większości dostawców hostingu w chmurze. Jest to **zalecany** sterownik bazy danych dla Fluent.

Aby użyć PostgreSQL, dodaj następujące zależności do swojego pakietu.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Gdy zależności zostaną dodane, skonfiguruj dane uwierzytelniające bazy danych za pomocą `app.databases.use` w `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

Możesz również przetworzyć dane uwierzytelniające z ciągu połączenia do bazy danych.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite to otwartoźródłowa, wbudowana baza danych SQL. Jej prosta natura sprawia, że jest świetnym kandydatem do prototypowania i testowania.

Aby użyć SQLite, dodaj następujące zależności do swojego pakietu.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Gdy zależności zostaną dodane, skonfiguruj bazę danych za pomocą `app.databases.use` w `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Możesz również skonfigurować SQLite, aby przechowywać bazę danych efemerycznie w pamięci.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Jeśli używasz bazy danych w pamięci, upewnij się, że skonfigurowałeś Fluent do automatycznego migrowania za pomocą `--auto-migrate` lub uruchom `app.autoMigrate()` po dodaniu migracji.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// lub
try await app.autoMigrate()
```

!!! tip
    Konfiguracja SQLite automatycznie włącza ograniczenia kluczy obcych na wszystkich utworzonych połączeniach, ale nie zmienia konfiguracji kluczy obcych w samej bazie danych. Usuwanie rekordów bezpośrednio w bazie danych może naruszyć ograniczenia i wyzwalacze kluczy obcych.

#### MySQL

MySQL to popularna otwartoźródłowa baza danych SQL. Jest dostępna u wielu dostawców hostingu w chmurze. Ten sterownik wspiera również MariaDB.

Aby użyć MySQL, dodaj następujące zależności do swojego pakietu.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Gdy zależności zostaną dodane, skonfiguruj dane uwierzytelniające bazy danych za pomocą `app.databases.use` w `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Możesz również przetworzyć dane uwierzytelniające z ciągu połączenia do bazy danych.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Aby skonfigurować lokalne połączenie bez udziału certyfikatu SSL, powinieneś wyłączyć weryfikację certyfikatu. Może być to konieczne na przykład podczas łączenia się z bazą danych MySQL 8 w Dockerze.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning
    Nie wyłączaj weryfikacji certyfikatu w środowisku produkcyjnym. Powinieneś dostarczyć certyfikat do `TLSConfiguration`, aby weryfikować względem niego.

#### MongoDB

MongoDB to popularna bezschematowa baza danych NoSQL zaprojektowana dla programistów. Sterownik wspiera wszystkich dostawców hostingu w chmurze oraz instalacje samodzielnie hostowane od wersji 3.4 wzwyż.

!!! note
    Ten sterownik jest oparty na kliencie MongoDB stworzonym i utrzymywanym przez społeczność, zwanym [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB utrzymuje oficjalny klient, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), wraz z integracją dla Vapor, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Aby użyć MongoDB, dodaj następujące zależności do swojego pakietu.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Gdy zależności zostaną dodane, skonfiguruj dane uwierzytelniające bazy danych za pomocą `app.databases.use` w `configure.swift`.

Aby się połączyć, przekaż ciąg połączenia w standardowym [formacie URI połączenia](https://docs.mongodb.com/docs/manual/reference/connection-string/) MongoDB.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Modele

Modele reprezentują ustalone struktury danych w twojej bazie danych, takie jak tabele czy kolekcje. Modele posiadają jedno lub więcej pól, które przechowują wartości zgodne z `Codable`. Wszystkie modele mają również unikalny identyfikator. Property wrappery są używane do oznaczania identyfikatorów i pól, a także bardziej złożonych mapowań wspomnianych później. Spójrz na następujący model reprezentujący galaktykę.

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"

    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?

    // The Galaxy's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Galaxy.
    init() { }

    // Creates a new Galaxy with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Aby stworzyć nowy model, stwórz nową klasę zgodną z protokołem `Model`.

!!! tip
    Zaleca się oznaczać klasy modeli jako `final`, aby poprawić wydajność i uprościć wymagania zgodności.

Pierwszym wymaganiem protokołu `Model` jest statyczny ciąg znaków `schema`.

```swift
static let schema = "galaxies"
```

Ta właściwość mówi Fluent, do której tabeli lub kolekcji odpowiada dany model. Może to być tabela, która już istnieje w bazie danych, lub taka, którą stworzysz za pomocą [migracji](#migracje). Schemat jest zazwyczaj w formacie `snake_case` i w liczbie mnogiej.

### Identyfikator

Kolejnym wymaganiem jest pole identyfikatora o nazwie `id`.

```swift
@ID(key: .id)
var id: UUID?
```

To pole musi używać property wrappera `@ID`. Fluent zaleca używanie `UUID` oraz specjalnego klucza pola `.id`, ponieważ jest to kompatybilne ze wszystkimi sterownikami Fluent.

Jeśli chcesz użyć niestandardowego klucza ID lub typu, użyj przeciążenia [`@ID(custom:)`](model.md#niestandardowy-identyfikator).

### Pola

Po dodaniu identyfikatora możesz dodać dowolną liczbę pól, aby przechowywać dodatkowe informacje. W tym przykładzie jedynym dodatkowym polem jest nazwa galaktyki.

```swift
@Field(key: "name")
var name: String
```

Dla prostych pól używany jest property wrapper `@Field`. Podobnie jak `@ID`, parametr `key` określa nazwę pola w bazie danych. Jest to szczególnie przydatne w przypadkach, gdy konwencja nazewnictwa pól w bazie danych różni się od tej w Swift, np. używanie `snake_case` zamiast `camelCase`.

Następnie, wszystkie modele wymagają pustego inicjalizatora. Pozwala to Fluent na tworzenie nowych instancji modelu.

```swift
init() { }
```

Na koniec możesz dodać wygodny inicjalizator dla swojego modelu, który ustawia wszystkie jego właściwości.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

Używanie wygodnych inicjalizatorów jest szczególnie pomocne, jeśli dodasz nowe właściwości do swojego modelu, ponieważ możesz otrzymać błędy kompilacji, jeśli metoda init ulegnie zmianie.

## Migracje

Jeśli twoja baza danych używa predefiniowanych schematów, jak bazy danych SQL, będziesz potrzebować migracji, aby przygotować bazę danych dla twojego modelu. Migracje są również przydatne do zasilania baz danych danymi. Aby stworzyć migrację, zdefiniuj nowy typ zgodny z protokołem `Migration` lub `AsyncMigration`. Spójrz na poniższą migrację dla wcześniej zdefiniowanego modelu `Galaxy`.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

Metoda `prepare` jest używana do przygotowania bazy danych do przechowywania modeli `Galaxy`.

### Schemat

W tej metodzie, `database.schema(_:)` jest używane do stworzenia nowego `SchemaBuilder`. Jedno lub więcej `field` jest następnie dodawane do budowniczego przed wywołaniem `create()`, aby stworzyć schemat.

Każde pole dodane do budowniczego posiada nazwę, typ oraz opcjonalne ograniczenia.

```swift
field(<name>, <type>, <optional constraints>)
```

Istnieje wygodna metoda `id()` do dodawania właściwości `@ID` przy użyciu zalecanych domyślnych ustawień Fluent.

Cofnięcie migracji odwraca wszelkie zmiany dokonane w metodzie prepare. W tym przypadku oznacza to usunięcie schematu Galaxy.

Gdy migracja zostanie zdefiniowana, musisz poinformować o niej Fluent, dodając ją do `app.migrations` w `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrowanie

Aby uruchomić migracje, wywołaj `swift run App migrate` z linii poleceń lub dodaj `migrate` jako argument do schematu App w Xcode.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Zapytania

Teraz, gdy pomyślnie stworzyłeś model i zmigrowałeś swoją bazę danych, jesteś gotowy, aby wykonać swoje pierwsze zapytanie.

### Wszystkie

Spójrz na poniższą trasę, która zwróci tablicę wszystkich galaktyk w bazie danych.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Aby zwrócić Galaxy bezpośrednio w domknięciu trasy, dodaj zgodność z `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` jest używane do stworzenia nowego budowniczego zapytań dla modelu. `req.db` jest referencją do domyślnej bazy danych dla twojej aplikacji. Na koniec, `all()` zwraca wszystkie modele przechowywane w bazie danych.

Jeśli skompilujesz i uruchomisz projekt oraz wykonasz żądanie `GET /galaxies`, powinieneś zobaczyć zwróconą pustą tablicę. Dodajmy trasę do tworzenia nowej galaktyki.

### Tworzenie


Zgodnie z konwencją RESTful, użyj endpointu `POST /galaxies` do tworzenia nowej galaktyki. Ponieważ modele są zgodne z `Codable`, możesz zdekodować galaktykę bezpośrednio z treści żądania.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    Zobacz [Content &rarr; Prezentacja](../basics/content.md), aby uzyskać więcej informacji o dekodowaniu treści żądań.

Gdy masz już instancję modelu, wywołanie `create(on:)` zapisuje model do bazy danych. Zwraca to `EventLoopFuture<Void>`, który sygnalizuje, że zapis się zakończył. Po zakończeniu zapisu, zwróć nowo utworzony model za pomocą `map`.

Jeśli używasz `async`/`await`, możesz napisać swój kod w ten sposób:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

W tym przypadku wersja async nic nie zwraca, ale zakończy się po zakończeniu zapisu.

Zbuduj i uruchom projekt, a następnie wyślij następujące żądanie.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Powinieneś otrzymać z powrotem utworzony model z identyfikatorem jako odpowiedź.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Teraz, jeśli ponownie wykonasz zapytanie `GET /galaxies`, powinieneś zobaczyć nowo utworzoną galaktykę zwróconą w tablicy.


## Relacje

Czym byłyby galaktyki bez gwiazd! Przyjrzyjmy się szybko potężnym możliwościom relacyjnym Fluent, dodając relację jeden-do-wielu między `Galaxy` a nowym modelem `Star`.

```swift
final class Star: Model, Content {
    // Name of the table or collection.
    static let schema = "stars"

    // Unique identifier for this Star.
    @ID(key: .id)
    var id: UUID?

    // The Star's name.
    @Field(key: "name")
    var name: String

    // Reference to the Galaxy this Star is in.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creates a new, empty Star.
    init() { }

    // Creates a new Star with all properties set.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

Nowy model `Star` jest bardzo podobny do `Galaxy`, z wyjątkiem nowego typu pola: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

Właściwość parent jest polem, które przechowuje identyfikator innego modelu. Model przechowujący referencję jest nazywany "dzieckiem" (ang. "child"), a model, do którego się odnosi, jest nazywany "rodzicem" (ang. "parent"). Ten typ relacji jest również znany jako "jeden-do-wielu". Parametr `key` tej właściwości określa nazwę pola, która powinna być używana do przechowywania klucza rodzica w bazie danych.

W metodzie init identyfikator rodzica jest ustawiany za pomocą `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

 Poprzedzając nazwę właściwości parent znakiem `$`, uzyskujesz dostęp do bazowego property wrappera. Jest to wymagane, aby uzyskać dostęp do wewnętrznego `@Field`, który przechowuje faktyczną wartość identyfikatora.

!!! seealso
    Zobacz propozycję Swift Evolution dotyczącą property wrapperów, aby uzyskać więcej informacji: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

Następnie stwórz migrację, aby przygotować bazę danych do obsługi `Star`.


```swift
struct CreateStar: AsyncMigration {
    // Prepares the database for storing Star models.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Jest to w większości takie samo jak migracja galaxy, z wyjątkiem dodatkowego pola do przechowywania identyfikatora galaktyki rodzica.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

To pole określa opcjonalne ograniczenie mówiące bazie danych, że wartość pola odnosi się do pola "id" w schemacie "galaxies". Jest to również znane jako klucz obcy i pomaga zapewnić integralność danych.

Gdy migracja zostanie stworzona, dodaj ją do `app.migrations` po migracji `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Ponieważ migracje uruchamiane są w kolejności, a `CreateStar` odnosi się do schematu galaxies, kolejność jest istotna. Na koniec, [uruchom migracje](#migrowanie), aby przygotować bazę danych.

Dodaj trasę do tworzenia nowych gwiazd.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Stwórz nową gwiazdę odnoszącą się do wcześniej utworzonej galaktyki za pomocą następującego żądania HTTP.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

Powinieneś zobaczyć nowo utworzoną gwiazdę zwróconą z unikalnym identyfikatorem.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

Przyjrzyjmy się teraz, jak możesz wykorzystać funkcję eager-loading Fluent, aby automatycznie zwracać gwiazdy galaktyki w trasie `GET /galaxies`. Dodaj następującą właściwość do modelu `Galaxy`.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

Property wrapper `@Children` jest odwrotnością `@Parent`. Przyjmuje jako argument `for` key-path do pola `@Parent` dziecka. Jego wartością jest tablica dzieci, ponieważ może istnieć zero lub więcej modeli-dzieci. Żadne zmiany w migracji galaxy nie są potrzebne, ponieważ wszystkie informacje potrzebne dla tej relacji są przechowywane w `Star`.

### Eager Load

Teraz, gdy relacja jest kompletna, możesz użyć metody `with` na budowniczym zapytań, aby automatycznie pobrać i zserializować relację galaxy-star.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Key-path do relacji `@Children` jest przekazywany do `with`, aby powiedzieć Fluent, żeby automatycznie ładował tę relację we wszystkich zwracanych modelach. Zbuduj, uruchom i wyślij kolejne żądanie do `GET /galaxies`. Powinieneś teraz zobaczyć gwiazdy automatycznie dołączone do odpowiedzi.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Logowanie zapytań

Sterowniki Fluent logują wygenerowane zapytania SQL na poziomie logowania debug. Niektóre sterowniki, jak FluentPostgreSQL, pozwalają to skonfigurować podczas konfigurowania bazy danych.

Aby ustawić poziom logowania, w pliku **configure.swift** (lub tam, gdzie konfigurujesz swoją aplikację) dodaj:

```swift
app.logger.logLevel = .debug
```

To ustawia poziom logowania na debug. Gdy następnym razem zbudujesz i uruchomisz swoją aplikację, instrukcje SQL wygenerowane przez Fluent będą logowane do konsoli.

## Następne kroki

Gratulacje z okazji stworzenia swoich pierwszych modeli i migracji oraz wykonania podstawowych operacji tworzenia i odczytu. Aby uzyskać bardziej szczegółowe informacje o wszystkich tych funkcjach, sprawdź odpowiednie sekcje w przewodniku Fluent.
