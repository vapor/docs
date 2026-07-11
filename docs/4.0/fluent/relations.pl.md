# Relacje

[API modelu](model.md) Fluenta pomaga tworzyć i utrzymywać odwołania między Twoimi modelami za pomocą relacji. Wspierane są trzy typy relacji:

- [Parent](#parent) / [Child](#optional-child) (jeden-do-jednego)
- [Parent](#parent) / [Children](#children) (jeden-do-wielu)
- [Siblings](#siblings) (wiele-do-wielu)

## Parent

Relacja `@Parent` przechowuje odwołanie do właściwości `@ID` innego modelu.

```swift
final class Planet: Model {
    // Przykład relacji rodzica.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` zawiera `@Field` o nazwie `id`, który jest używany do ustawiania i aktualizowania relacji.

```swift
// Ustaw identyfikator relacji rodzica
earth.$star.id = sun.id
```

Na przykład inicjalizator `Planet` mógłby wyglądać tak:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

Parametr `key` określa klucz pola używany do przechowywania identyfikatora rodzica. Zakładając, że `Star` ma identyfikator typu `UUID`, ta relacja `@Parent` jest kompatybilna z następującą [definicją pola](schema.md#pole).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Zwróć uwagę, że ograniczenie [`.references`](schema.md#ograniczenie-pola) jest opcjonalne. Zobacz [schemat](schema.md), aby uzyskać więcej informacji.

### Optional Parent

Relacja `@OptionalParent` przechowuje opcjonalne odwołanie do właściwości `@ID` innego modelu. Działa podobnie do `@Parent`, ale pozwala, aby relacja miała wartość `nil`.

```swift
final class Planet: Model {
    // Przykład opcjonalnej relacji rodzica.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

Definicja pola jest podobna do tej dla `@Parent`, z tą różnicą, że ograniczenie `.required` powinno zostać pominięte.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Kodowanie i dekodowanie rodziców

Jedną rzeczą, na którą należy uważać podczas pracy z relacjami `@Parent`, jest sposób, w jaki są one wysyłane i odbierane. Na przykład w formacie JSON `@Parent` dla modelu `Planet` może wyglądać tak:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

Zwróć uwagę, że właściwość `star` jest obiektem, a nie identyfikatorem, którego można by się spodziewać. Podczas wysyłania modelu jako ciała żądania HTTP, dane muszą mieć taką strukturę, aby dekodowanie zadziałało. Z tego powodu zdecydowanie zalecamy używanie DTO do reprezentowania modelu podczas wysyłania go przez sieć. Na przykład:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

Następnie możesz zdekodować DTO i przekonwertować je na model:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

To samo dotyczy zwracania modelu klientom. Twoi klienci muszą być w stanie obsłużyć zagnieżdżoną strukturę, albo musisz przekonwertować model na DTO przed jego zwróceniem. Więcej informacji o DTO znajdziesz w [dokumentacji Modelu](model.md#data-transfer-object)

## Optional Child

Właściwość `@OptionalChild` tworzy relację jeden-do-jednego między dwoma modelami. Nie przechowuje ona żadnych wartości w modelu głównym.

```swift
final class Planet: Model {
    // Przykład opcjonalnej relacji dziecka.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

Parametr `for` przyjmuje key-path do relacji `@Parent` lub `@OptionalParent`, odwołującej się do modelu głównego.

Nowy model może zostać dodany do tej relacji za pomocą metody `create`.

```swift
// Przykład dodawania nowego modelu do relacji.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Spowoduje to automatyczne ustawienie identyfikatora rodzica w modelu dziecka.

Ponieważ ta relacja nie przechowuje żadnych wartości, dla modelu głównego nie jest wymagany żaden wpis w schemacie bazy danych.

Charakter jeden-do-jednego tej relacji powinien być wymuszony w schemacie modelu dziecka za pomocą ograniczenia `.unique` na kolumnie odwołującej się do modelu rodzica.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Przykład ograniczenia unikalności
    .unique(on: "planet_id")
    .create()
```
!!! warning
    Pominięcie ograniczenia unikalności na polu identyfikatora rodzica w schemacie klienta może prowadzić do nieprzewidywalnych rezultatów.
    Jeśli nie ma ograniczenia unikalności, tabela dziecka może zawierać więcej niż jeden wiersz dziecka dla danego rodzica; w takim przypadku właściwość `@OptionalChild` nadal będzie mogła uzyskać dostęp tylko do jednego dziecka naraz, bez możliwości kontrolowania, które dziecko zostanie załadowane. Jeśli chcesz przechowywać wiele wierszy dziecka dla danego rodzica, użyj zamiast tego `@Children`.

## Children

Właściwość `@Children` tworzy relację jeden-do-wielu między dwoma modelami. Nie przechowuje ona żadnych wartości w modelu głównym.

```swift
final class Star: Model {
    // Przykład relacji dzieci.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

Parametr `for` przyjmuje key-path do relacji `@Parent` lub `@OptionalParent`, odwołującej się do modelu głównego. W tym przypadku odwołujemy się do relacji `@Parent` z poprzedniego [przykładu](#parent).

Nowe modele mogą zostać dodane do tej relacji za pomocą metody `create`.

```swift
// Przykład dodawania nowego modelu do relacji.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Spowoduje to automatyczne ustawienie identyfikatora rodzica w modelu dziecka.

Ponieważ ta relacja nie przechowuje żadnych wartości, żaden wpis w schemacie bazy danych nie jest wymagany.

## Siblings

Właściwość `@Siblings` tworzy relację wiele-do-wielu między dwoma modelami. Osiąga to za pomocą trzeciego modelu zwanego pivotem.

Przyjrzyjmy się przykładowi relacji wiele-do-wielu między `Planet` a `Tag`.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Przykład modelu pivota.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

Każdy model, który zawiera co najmniej dwie relacje `@Parent`, po jednej dla każdego modelu, który ma zostać powiązany, może zostać użyty jako pivot. Model może zawierać dodatkowe właściwości, takie jak jego ID, a nawet inne relacje `@Parent`.

Dodanie ograniczenia [unique](schema.md#unikalność) do modelu pivota może pomóc zapobiec powielaniu wpisów. Zobacz [schemat](schema.md), aby uzyskać więcej informacji.

```swift
// Zapobiega duplikowaniu relacji.
.unique(on: "planet_id", "tag_id")
```

Gdy pivot zostanie utworzony, użyj właściwości `@Siblings`, aby utworzyć relację.

```swift
final class Planet: Model {
    // Przykład relacji rodzeństwa.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

Właściwość `@Siblings` wymaga trzech parametrów:

- `through`: Typ modelu pivota.
- `from`: Key-path od pivota do relacji rodzica odwołującej się do modelu głównego.
- `to`: Key-path od pivota do relacji rodzica odwołującej się do powiązanego modelu.

Odwrotna właściwość `@Siblings` w powiązanym modelu dopełnia relację.

```swift
final class Tag: Model {
    // Przykład relacji rodzeństwa.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

Właściwość `@Siblings` posiada metody do dodawania i usuwania modeli z relacji.

Użyj metody `attach()`, aby dodać pojedynczy model lub tablicę modeli do relacji. Modele pivota są tworzone i zapisywane automatycznie w razie potrzeby. Można podać domknięcie zwrotne, aby wypełnić dodatkowe właściwości każdego utworzonego pivota:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Dodaje model do relacji.
try await earth.$tags.attach(inhabited, on: database)
// Wypełnij atrybuty pivota podczas nawiązywania relacji.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Dodaj wiele modeli z atrybutami do relacji.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Podczas dołączania pojedynczego modelu możesz użyć parametru `method`, aby wybrać, czy relacja powinna zostać sprawdzona przed zapisem.

```swift
// Dołącza tylko wtedy, gdy relacja jeszcze nie istnieje.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Użyj metody `detach`, aby usunąć model z relacji. Powoduje to usunięcie odpowiadającego modelu pivota.

```swift
// Usuwa model z relacji.
try await earth.$tags.detach(inhabited, on: database)
```

Możesz sprawdzić, czy model jest powiązany, czy nie, za pomocą metody `isAttached`.

```swift
// Sprawdza, czy modele są powiązane.
earth.$tags.isAttached(to: inhabited)
```

## Get

Użyj metody `get(on:)`, aby pobrać wartość relacji.

```swift
// Pobiera wszystkie planety słońca.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Lub

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Użyj parametru `reload`, aby wybrać, czy relacja powinna zostać ponownie pobrana z bazy danych, jeśli została już wcześniej załadowana.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Użyj metody `query(on:)` na relacji, aby utworzyć query builder dla powiązanych modeli.

```swift
// Pobierz wszystkie planety słońca, których nazwa zaczyna się na M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Zobacz [zapytania](query.md), aby uzyskać więcej informacji.

## Eager Loading

Query builder Fluenta pozwala na wstępne ładowanie relacji modelu podczas jego pobierania z bazy danych. Nazywa się to eager loading i pozwala na synchroniczny dostęp do relacji bez konieczności wcześniejszego wywoływania [`get`](#get).

Aby wczytać relację z wyprzedzeniem, przekaż key-path do relacji do metody `with` na query builderze.

```swift
// Przykład eager loadingu.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` jest tutaj dostępne synchronicznie 
        // ponieważ zostało wcześniej załadowane (eager loaded).
        print(planet.star.name)
    }
}

// Lub

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` jest tutaj dostępne synchronicznie 
    // ponieważ zostało wcześniej załadowane (eager loaded).
    print(planet.star.name)
}
```

W powyższym przykładzie key-path do relacji [`@Parent`](#parent) o nazwie `star` jest przekazywany do `with`. Powoduje to, że query builder wykonuje dodatkowe zapytanie po załadowaniu wszystkich planet, aby pobrać wszystkie powiązane z nimi gwiazdy. Gwiazdy są następnie dostępne synchronicznie za pomocą właściwości `@Parent`.

Każda relacja załadowana w ten sposób wymaga tylko jednego dodatkowego zapytania, niezależnie od liczby zwróconych modeli. Eager loading jest możliwe tylko z metodami `all` i `first` query buildera.


### Nested Eager Load

Metoda `with` query buildera pozwala na wczytanie z wyprzedzeniem relacji modelu, który jest przedmiotem zapytania. Możesz jednak również wczytać z wyprzedzeniem relacje modeli powiązanych.

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` jest tutaj dostępne synchronicznie 
    // ponieważ zostało wcześniej załadowane (eager loaded).
    print(planet.star.galaxy.name)
}
```

Metoda `with` przyjmuje jako drugi parametr opcjonalne domknięcie. To domknięcie przyjmuje eager load builder dla wybranej relacji. Nie ma ograniczenia co do głębokości zagnieżdżenia eager loadingu.

## Lazy Eager Loading

W przypadku, gdy masz już pobrany model rodzica i chcesz załadować jedną z jego relacji, możesz użyć w tym celu metody `get(reload:on:)`. Spowoduje to pobranie powiązanego modelu z bazy danych (lub z cache, jeśli jest dostępny) i umożliwi dostęp do niego jako do lokalnej właściwości.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Lub

try await planet.$star.get(on: database)
print(planet.star.name)
```

Jeśli chcesz mieć pewność, że otrzymywane dane nie pochodzą z cache, użyj parametru `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

Aby sprawdzić, czy relacja została załadowana, użyj właściwości `value`.

```swift
if planet.$star.value != nil {
    // Relacja została załadowana.
    print(planet.star.name)
} else {
    // Relacja nie została załadowana.
    // Próba dostępu do planet.star zakończy się niepowodzeniem.
}
```

Jeśli masz już powiązany model w zmiennej, możesz ręcznie ustawić relację za pomocą wspomnianej wyżej właściwości `value`.

```swift
planet.$star.value = star
```

Spowoduje to dołączenie powiązanego modelu do rodzica tak, jakby został on załadowany metodą eager loading lub lazy loading, bez dodatkowego zapytania do bazy danych.
