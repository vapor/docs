# Walidacja

API Validation Vapora pomaga zwalidować treść (body) i parametry zapytania (query parameters) przychodzącego żądania przed użyciem API [Content](content.md) do dekodowania danych.

## Wprowadzenie

Głęboka integracja Vapora z typowo bezpiecznym protokołem `Codable` w Swifcie oznacza, że nie musisz przejmować się walidacją danych tak bardzo, jak w językach z dynamicznym typowaniem. Istnieje jednak kilka powodów, dla których warto skorzystać z jawnej walidacji przy użyciu API Validation.

### Czytelne dla człowieka błędy

Dekodowanie struktur za pomocą API [Content](content.md) zwróci błędy, jeśli którekolwiek z danych są nieprawidłowe. Jednak te komunikaty błędów mogą czasem nie być zbyt czytelne dla człowieka. Weźmy na przykład poniższy enum oparty na stringu:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Jeśli użytkownik spróbuje przekazać string `"purple"` do właściwości typu `Color`, otrzyma błąd podobny do poniższego:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Chociaż ten błąd jest technicznie poprawny i skutecznie zabezpieczył endpoint przed nieprawidłową wartością, mógłby lepiej informować użytkownika o pomyłce i dostępnych opcjach. Korzystając z API Validation, możesz generować błędy takie jak poniższy:

```
favoriteColor is not red, blue, or green
```

Co więcej, `Codable` przestaje próbować dekodować typ, gdy tylko napotka pierwszy błąd. Oznacza to, że nawet jeśli w żądaniu jest wiele nieprawidłowych właściwości, użytkownik zobaczy tylko pierwszy błąd. API Validation zgłosi wszystkie niepowodzenia walidacji w ramach jednego żądania.

### Szczegółowa walidacja

`Codable` dobrze radzi sobie z walidacją typów, ale czasami potrzebujesz czegoś więcej. Na przykład walidacji zawartości stringa albo walidacji zakresu liczby całkowitej. API Validation ma walidatory pomagające sprawdzać dane, takie jak adresy e-mail, zestawy znaków, zakresy liczb całkowitych i wiele innych.

## Validatable

Aby zwalidować żądanie, musisz wygenerować kolekcję `Validations`. Najczęściej robi się to, dostosowując istniejący typ do protokołu `Validatable`.

Przyjrzyjmy się, jak można dodać walidację do tego prostego endpointu `POST /users`. Ten przewodnik zakłada, że znasz już API [Content](content.md).

```swift
enum Color: String, Codable {
    case red, blue, green
}

struct CreateUser: Content {
    var name: String
    var username: String
    var age: Int
    var email: String
    var favoriteColor: Color?
}

app.post("users") { req -> CreateUser in
    let user = try req.content.decode(CreateUser.self)
    // Do something with user.
    return user
}
```

### Dodawanie walidacji

Pierwszym krokiem jest dostosowanie typu, który dekodujesz, w tym przypadku `CreateUser`, do protokołu `Validatable`. Można to zrobić w rozszerzeniu (extension).

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

Statyczna metoda `validations(_:)` zostanie wywołana, gdy `CreateUser` będzie walidowany. Wszystkie walidacje, które chcesz przeprowadzić, powinny zostać dodane do dostarczonej kolekcji `Validations`. Przyjrzyjmy się dodaniu prostej walidacji wymagającej, aby adres e-mail użytkownika był prawidłowy.

```swift
validations.add("email", as: String.self, is: .email)
```

Pierwszy parametr to oczekiwany klucz wartości, w tym przypadku `"email"`. Powinien on odpowiadać nazwie właściwości w walidowanym typie. Drugi parametr, `as`, to oczekiwany typ, w tym przypadku `String`. Typ zwykle odpowiada typowi właściwości, ale nie zawsze. Na koniec, po trzecim parametrze, `is`, można dodać jeden lub więcej walidatorów. W tym przypadku dodajemy pojedynczy walidator sprawdzający, czy wartość jest adresem e-mail.

### Walidacja treści żądania

Po dostosowaniu swojego typu do protokołu `Validatable`, statyczna funkcja `validate(content:)` może zostać użyta do walidacji treści żądania. Dodaj poniższą linię przed `req.content.decode(CreateUser.self)` w handlerze trasy.

```swift
try CreateUser.validate(content: req)
```

Teraz spróbuj wysłać poniższe żądanie zawierające nieprawidłowy adres e-mail:

```http
POST /users HTTP/1.1
Content-Length: 67
Content-Type: application/json

{
    "age": 4,
    "email": "foo",
    "favoriteColor": "green",
    "name": "Foo",
    "username": "foo"
}
```

Powinieneś zobaczyć zwrócony poniższy błąd:

```
email is not a valid email address
```

### Walidacja zapytania żądania

Typy dostosowane do protokołu `Validatable` mają również `validate(query:)`, który może zostać użyty do walidacji ciągu zapytania (query string) żądania. Dodaj poniższe linie do handlera trasy.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Teraz spróbuj wysłać poniższe żądanie zawierające nieprawidłowy adres e-mail w ciągu zapytania.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Powinieneś zobaczyć zwrócony poniższy błąd:

```
email is not a valid email address
```

### Walidacja liczb całkowitych

Świetnie, teraz spróbujmy dodać walidację dla `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

Walidacja wieku wymaga, aby wiek był większy lub równy `13`. Jeśli spróbujesz wysłać to samo żądanie co powyżej, powinieneś teraz zobaczyć nowy błąd:

```
age is less than minimum of 13, email is not a valid email address
```

### Walidacja stringów

Następnie dodajmy walidacje dla `name` i `username`.

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

Walidacja `name` używa operatora `!`, aby odwrócić walidator `.empty`. Będzie to wymagało, aby string nie był pusty.

Walidacja `username` łączy dwa walidatory za pomocą `&&`. Będzie to wymagało, aby string miał co najmniej 3 znaki długości _i_ zawierał wyłącznie znaki alfanumeryczne.

### Walidacja enumów

Na koniec przyjrzyjmy się nieco bardziej zaawansowanej walidacji, sprawdzającej, czy podany `favoriteColor` jest prawidłowy.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Ponieważ nie jest możliwe zdekodowanie `Color` z nieprawidłowej wartości, ta walidacja używa `String` jako typu bazowego. Wykorzystuje walidator `.in`, aby zweryfikować, że wartość jest jedną z prawidłowych opcji: red, blue lub green. Ponieważ ta wartość jest opcjonalna, `required` jest ustawione na false, aby zasygnalizować, że walidacja nie powinna zawieść, jeśli tego klucza brakuje w danych żądania.

Zauważ, że chociaż walidacja koloru ulubionego przejdzie, jeśli klucz jest nieobecny, nie przejdzie, jeśli podano `null`. Jeśli chcesz obsługiwać `null`, zmień typ walidacji na `String?` i użyj udogodnienia `.nil ||` (czytane jako: "is nil or ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Niestandardowe błędy

Możesz chcieć dodać niestandardowe, czytelne dla człowieka błędy do swoich `Validations` lub `Validator`. Aby to zrobić, po prostu podaj dodatkowy parametr `customFailureDescription`, który nadpisze domyślny błąd.

```swift
validations.add(
    "name",
    as: String.self,
    is: !.empty,
    customFailureDescription: "Provided name is empty!"
)
validations.add(
    "username",
    as: String.self,
    is: .count(3...) && .alphanumeric,
    customFailureDescription: "Provided username is invalid!"
)
```


## Walidatory

Poniżej znajduje się lista aktualnie wspieranych walidatorów wraz z krótkim wyjaśnieniem, co robią.

|Walidacja|Opis|
|-|-|
|`.ascii`|Zawiera wyłącznie znaki ASCII.|
|`.alphanumeric`|Zawiera wyłącznie znaki alfanumeryczne.|
|`.characterSet(_:)`|Zawiera wyłącznie znaki z podanego `CharacterSet`.|
|`.count(_:)`|Liczba elementów kolekcji mieści się w podanych granicach.|
|`.email`|Zawiera prawidłowy adres e-mail.|
|`.empty`|Kolekcja jest pusta.|
|`.in(_:)`|Wartość znajduje się w podanej `Collection`.|
|`.nil`|Wartość ma wartość `null`.|
|`.range(_:)`|Wartość mieści się w podanym `Range`.|
|`.url`|Zawiera prawidłowy URL.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Niestandardowa, jednorazowa walidacja.|

Walidatory mogą być również łączone w celu budowania złożonych walidacji za pomocą operatorów. Więcej informacji o walidatorze `.custom` znajdziesz w sekcji [Niestandardowe walidatory](#custom-validators).

|Operator|Pozycja|Opis|
|-|-|-|
|`!`|przedrostkowy (prefix)|Odwraca walidator, wymagając przeciwieństwa.|
|`&&`|infiksowy (infix)|Łączy dwa walidatory, wymaga obu.|
|`\|\|`|infiksowy (infix)|Łączy dwa walidatory, wymaga jednego.|



## Niestandardowe walidatory

Istnieją dwa sposoby tworzenia niestandardowych walidatorów.

### Rozszerzanie API Validation

Rozszerzanie API Validation najlepiej sprawdza się w przypadkach, gdy planujesz używać niestandardowego walidatora w więcej niż jednym obiekcie `Content`. W tej sekcji przeprowadzimy Cię przez kroki tworzenia niestandardowego walidatora do walidacji kodów pocztowych.

Najpierw stwórz nowy typ reprezentujący wyniki walidacji `ZipCode`. Ta struktura będzie odpowiedzialna za zgłaszanie, czy dany string jest prawidłowym kodem pocztowym.

```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

Następnie dostosuj nowy typ do protokołu `ValidatorResult`, który definiuje zachowanie oczekiwane od niestandardowego walidatora.

```swift
extension ValidatorResults.ZipCode: ValidatorResult {
    public var isFailure: Bool {
        !self.isValidZipCode
    }
    
    public var successDescription: String? {
        "is a valid zip code"
    }
    
    public var failureDescription: String? {
        "is not a valid zip code"
    }
}
```

Na koniec zaimplementuj logikę walidacji kodów pocztowych. Użyj wyrażenia regularnego, aby sprawdzić, czy podany string pasuje do formatu amerykańskiego kodu pocztowego.

```swift
private let zipCodeRegex: String = "^\\d{5}(?:[-\\s]\\d{4})?$"

extension Validator where T == String {
    /// Validates whether a `String` is a valid zip code.
    public static var zipCode: Validator<T> {
        .init { input in
            guard let range = input.range(of: zipCodeRegex, options: [.regularExpression]),
                  range.lowerBound == input.startIndex && range.upperBound == input.endIndex
            else {
                return ValidatorResults.ZipCode(isValidZipCode: false)
            }
            return ValidatorResults.ZipCode(isValidZipCode: true)
        }
    }
}
```

Teraz, gdy zdefiniowałeś niestandardowy walidator `zipCode`, możesz go użyć do walidacji kodów pocztowych w swojej aplikacji. Po prostu dodaj poniższą linię do swojego kodu walidacji:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### Walidator `Custom`

Walidator `Custom` najlepiej sprawdza się w przypadkach, gdy chcesz zwalidować właściwość tylko w jednym obiekcie `Content`. Ta implementacja ma następujące dwie zalety w porównaniu do rozszerzania API Validation:

- Prostszą implementację niestandardowej logiki walidacji.
- Krótszą składnię.

W tej sekcji przeprowadzimy Cię przez kroki tworzenia niestandardowego walidatora sprawdzającego, czy pracownik jest częścią naszej firmy, patrząc na właściwość `nameAndSurname`.

```swift
let allCompanyEmployees: [String] = [
  "Everett Erickson",
  "Sabrina Manning",
  "Seth Gates",
  "Melina Hobbs",
  "Brendan Wade",
  "Evie Richardson",
]

struct Employee: Content {
  var nameAndSurname: String
  var email: String
  var age: Int
  var role: String

  static func validations(_ validations: inout Validations) {
    validations.add(
      "nameAndSurname",
      as: String.self,
      is: .custom("Validates whether employee is part of XYZ company by looking at name and surname.") { nameAndSurname in
          for employee in allCompanyEmployees {
            if employee == nameAndSurname {
              return true
            }
          }
          return false
        }
    )
  }
}
```
