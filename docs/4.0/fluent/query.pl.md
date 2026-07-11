# Zapytania

API zapytań Fluent pozwala tworzyć, odczytywać, aktualizować i usuwać modele z bazy danych. Wspiera ono filtrowanie wyników, złączenia (joins), dzielenie na fragmenty (chunking), agregaty i wiele więcej.

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Budowniczy zapytań (query builder) jest powiązany z pojedynczym typem modelu i można go stworzyć za pomocą statycznej metody [`query`](model.md#query). Można go również stworzyć, przekazując typ modelu do metody `query` na obiekcie bazy danych.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note
    Musisz zaimportować `Fluent` w pliku ze swoimi zapytaniami, aby kompilator mógł widzieć funkcje pomocnicze Fluent.

## Wszystkie

Metoda `all()` zwraca tablicę modeli.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

Metoda `all` wspiera również pobieranie tylko pojedynczego pola z zestawu wyników.

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### Pierwszy

Metoda `first()` zwraca pojedynczy, opcjonalny model. Jeśli zapytanie zwróci więcej niż jeden model, zwrócony zostanie tylko pierwszy. Jeśli zapytanie nie zwróci żadnych wyników, zwracane jest `nil`.

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    Jeśli używasz `EventLoopFuture`, ta metoda może być połączona z [`unwrap(or:)`](../basics/errors.md#abort), aby zwrócić nieopcjonalny model lub rzucić błąd.

## Filtr

Metoda `filter` pozwala ograniczyć modele uwzględnione w zestawie wyników. Istnieje kilka przeciążeń tej metody.

### Filtr wartości

Najczęściej używana metoda `filter` przyjmuje wyrażenie operatora wraz z wartością.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Te wyrażenia operatorów przyjmują ścieżkę klucza pola po lewej stronie oraz wartość po prawej. Podana wartość musi odpowiadać oczekiwanemu typowi wartości pola i jest wiązana z wynikowym zapytaniem. Wyrażenia filtrów są silnie typowane, co pozwala na użycie składni z wiodącą kropką.

Poniżej znajduje się lista wszystkich wspieranych operatorów wartości.

|Operator|Description|
|-|-|
|`==`|Equal to.|
|`!=`|Not equal to.|
|`>=`|Greater than or equal to.|
|`>`|Greater than.|
|`<`|Less than.|
|`<=`|Less than or equal to.|

### Filtr pola

Metoda `filter` wspiera porównywanie dwóch pól.

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Filtry pól wspierają te same operatory co [filtry wartości](#filtr-wartości).

### Filtr podzbioru

Metoda `filter` wspiera sprawdzanie, czy wartość pola istnieje w podanym zbiorze wartości.

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

Podany zbiór wartości może być dowolną kolekcją Swift (`Collection`), której typ `Element` odpowiada typowi wartości pola.

Poniżej znajduje się lista wszystkich wspieranych operatorów podzbioru.

|Operator|Description|
|-|-|
|`~~`|Value in set.|
|`!~`|Value not in set.|

### Filtr zawierania

Metoda `filter` wspiera sprawdzanie, czy wartość pola typu string zawiera podany podciąg.

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Te operatory są dostępne wyłącznie dla pól z wartościami typu string.

Poniżej znajduje się lista wszystkich wspieranych operatorów zawierania.

|Operator|Description|
|-|-|
|`~~`|Contains substring.|
|`!~`|Does not contain substring.|
|`=~`|Matches prefix.|
|`!=~`|Does not match prefix.|
|`~=`|Matches suffix.|
|`!~=`|Does not match suffix.|

### Grupa

Domyślnie wszystkie filtry dodane do zapytania muszą zostać spełnione. Budowniczy zapytań wspiera tworzenie grupy filtrów, w której wystarczy, aby spełniony był tylko jeden filtr.

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

Metoda `group` wspiera łączenie filtrów za pomocą logiki `and` lub `or`. Te grupy mogą być zagnieżdżane bez ograniczeń. Filtry na najwyższym poziomie można traktować jako znajdujące się w grupie `and`.

## Agregat

Budowniczy zapytań wspiera kilka metod do wykonywania obliczeń na zestawie wartości, takich jak liczenie czy uśrednianie.

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

Wszystkie metody agregujące poza `count` wymagają przekazania ścieżki klucza do pola.

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

Poniżej znajduje się lista wszystkich dostępnych metod agregujących.

|Aggregate|Description|
|-|-|
|`count`|Number of results.|
|`sum`|Sum of result values.|
|`average`|Average of result values.|
|`min`|Minimum result value.|
|`max`|Maximum result value.|

Wszystkie metody agregujące poza `count` zwracają jako wynik typ wartości pola. `count` zawsze zwraca liczbę całkowitą.

## Fragmenty (Chunk)

Budowniczy zapytań wspiera zwracanie zestawu wyników jako osobnych fragmentów. Pomaga to kontrolować zużycie pamięci podczas obsługi dużych odczytów z bazy danych.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

Podane domknięcie zostanie wywołane zero lub więcej razy, w zależności od całkowitej liczby wyników. Każdy zwrócony element to `Result` zawierający albo model, albo błąd zwrócony podczas próby zdekodowania wpisu z bazy danych.

## Pole

Domyślnie wszystkie pola modelu są odczytywane z bazy danych przez zapytanie. Możesz wybrać tylko podzbiór pól modelu za pomocą metody `field`.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Wszelkie pola modelu, które nie zostały wybrane podczas zapytania, będą w stanie niezainicjalizowanym. Próba bezpośredniego dostępu do niezainicjalizowanych pól spowoduje błąd krytyczny. Aby sprawdzić, czy wartość pola modelu jest ustawiona, użyj właściwości `value`.

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unikalność

Metoda `unique` budowniczego zapytań powoduje, że zwracane są tylko unikalne wyniki (bez duplikatów).

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` jest szczególnie przydatne przy pobieraniu pojedynczego pola za pomocą `all`. Możesz jednak również wybrać wiele pól za pomocą metody [`field`](#pole). Ponieważ identyfikatory modeli są zawsze unikalne, powinieneś unikać ich wybierania podczas używania `unique`.

## Zakres

Metody `range` budowniczego zapytań pozwalają wybrać podzbiór wyników za pomocą zakresów Swift.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

Wartości zakresu to liczby całkowite bez znaku, zaczynające się od zera. Dowiedz się więcej o [zakresach w Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
.range(2...)
```

## Złączenie (Join)

Metoda `join` budowniczego zapytań pozwala uwzględnić w zestawie wyników pola innego modelu. Do zapytania można dołączyć więcej niż jeden model.

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

Parametr `on` przyjmuje wyrażenie równości pomiędzy dwoma polami. Jedno z pól musi już istnieć w bieżącym zestawie wyników. Drugie pole musi istnieć na modelu, który jest dołączany. Te pola muszą mieć ten sam typ wartości.

Większość metod budowniczego zapytań, takich jak `filter` i `sort`, wspiera dołączone modele. Jeśli metoda wspiera dołączone modele, przyjmie typ dołączonego modelu jako pierwszy parametr.

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

Zapytania korzystające ze złączeń nadal będą zwracać tablicę modelu bazowego. Aby uzyskać dostęp do dołączonego modelu, użyj metody `joined`.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Alias modelu

Aliasy modelu pozwalają dołączyć ten sam model do zapytania wielokrotnie. Aby zadeklarować alias modelu, stwórz jeden lub więcej typów zgodnych z `ModelAlias`.

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Te typy odwołują się do aliasowanego modelu za pomocą właściwości `model`. Po utworzeniu, aliasów modelu możesz używać w budowniczym zapytań tak jak zwykłych modeli.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Wszystkie pola modelu są dostępne poprzez typ aliasu modelu za pomocą `@dynamicMemberLookup`.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Aktualizacja

Budowniczy zapytań wspiera aktualizowanie więcej niż jednego modelu naraz za pomocą metody `update`.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` wspiera metody `set`, `filter` i `range`.

## Usuwanie

Budowniczy zapytań wspiera usuwanie więcej niż jednego modelu naraz za pomocą metody `delete`.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` wspiera metodę `filter`.

## Stronicowanie

API zapytań Fluent wspiera automatyczne stronicowanie wyników za pomocą metody `paginate`.

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

Metoda `paginate(for:)` użyje parametrów `page` i `per` dostępnych w URI żądania, aby zwrócić żądany zestaw wyników. Metadane dotyczące bieżącej strony oraz całkowitej liczby wyników są zawarte w kluczu `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

Powyższe żądanie zwróciłoby odpowiedź o strukturze zbliżonej do poniższej.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Numery stron zaczynają się od `1`. Możesz również wykonać ręczne żądanie strony.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sortowanie

Wyniki zapytania mogą być sortowane według wartości pól za pomocą metody `sort`.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

Dodatkowe sortowania mogą zostać dodane jako rozwiązania zapasowe na wypadek remisu. Rozwiązania zapasowe będą stosowane w kolejności, w jakiej zostały dodane do budowniczego zapytań.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
