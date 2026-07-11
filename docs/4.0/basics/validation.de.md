# Validierung

Vapors Validierungs-API hilft dir dabei, den Body und die Zeichenfolge einer eingehenden Anfrage zu validieren, bevor du die [Content](content.md)-API zum Dekodieren der Daten verwendest.

## Einführung 

Durch die tiefe Integration von Swifts typsicherem `Codable`-Protokoll musst du dir bei Vapor weniger Gedanken über die Validierung von Daten machen als bei dynamisch typisierten Sprachen. Dennoch gibt es einige Gründe, warum du dich für eine explizite Validierung mit der Validierungs-API entscheiden solltest.

### Lesbare Fehlermeldungen

Beim Dekodieren von Structs mit der [Content](content.md)-API werden Fehler ausgegeben, wenn Daten ungültig sind. Diese Fehlermeldungen können jedoch manchmal schwer verständlich sein. Nimm zum Beispiel das folgende, auf einem String basierende Enum:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Wenn ein Benutzer versucht, den String `"purple"` an eine Eigenschaft vom Typ `Color` zu übergeben, erhält er eine Fehlermeldung ähnlich der folgenden:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Auch wenn diese Fehlermeldung technisch korrekt ist und den Endpunkt erfolgreich vor einem ungültigen Wert geschützt hat, könnte sie den Benutzer besser über den Fehler und die verfügbaren Optionen informieren. Mit der Validierungs-API kannst du Fehlermeldungen wie die folgende erzeugen:

```
favoriteColor is not red, blue, or green
```

Außerdem bricht `Codable` den Dekodierversuch eines Typs ab, sobald der erste Fehler auftritt. Das bedeutet, dass der Benutzer selbst dann, wenn viele Eigenschaften in der Anfrage ungültig sind, nur den ersten Fehler sieht. Die Validierungs-API meldet dagegen alle Validierungsfehler in einer einzigen Anfrage.

### Spezifische Validierung

`Codable` erledigt die Typvalidierung gut, aber manchmal möchtest du mehr als das. Zum Beispiel den Inhalt eines Strings validieren oder die Größe eines Integers überprüfen. Die Validierungs-API bietet Validatoren, die dir helfen, Daten wie E-Mail-Adressen, Zeichensätze, Integer-Bereiche und mehr zu validieren.

## Validatable

Um eine Anfrage zu validieren, musst du eine `Validations`-Sammlung erzeugen. Das geschieht meistens dadurch, dass ein bestehender Typ dem Protokoll `Validatable` angepasst wird. 

Schauen wir uns an, wie du diesem einfachen `POST /users`-Endpunkt eine Validierung hinzufügen könntest. Dieser Guide setzt voraus, dass du bereits mit der [Content](content.md)-API vertraut bist.

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

### Validierungen hinzufügen

Der erste Schritt besteht darin, den Typ, den du dekodierst – in diesem Fall `CreateUser` – dem Protokoll `Validatable` anzupassen. Das kannst du in einer Extension tun.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

Die statische Methode `validations(_:)` wird aufgerufen, wenn `CreateUser` validiert wird. Alle Validierungen, die du durchführen möchtest, solltest du der bereitgestellten `Validations`-Sammlung hinzufügen. Schauen wir uns an, wie du eine einfache Validierung hinzufügst, die verlangt, dass die E-Mail-Adresse des Benutzers gültig ist.

```swift
validations.add("email", as: String.self, is: .email)
```

Der erste Parameter ist der erwartete Schlüssel des Wertes, in diesem Fall `"email"`. Dieser sollte mit dem Namen der Eigenschaft des zu validierenden Typs übereinstimmen. Der zweite Parameter, `as`, ist der erwartete Typ, in diesem Fall `String`. Der Typ stimmt meist mit dem Typ der Eigenschaft überein, aber nicht immer. Schließlich können nach dem dritten Parameter, `is`, ein oder mehrere Validatoren angegeben werden. In diesem Fall fügen wir einen einzelnen Validator hinzu, der prüft, ob der Wert eine E-Mail-Adresse ist.

### Anfrageinhalt validieren

Sobald dein Typ dem Protokoll `Validatable` angepasst wurde, kannst du mit der statischen Funktion `validate(content:)` den Inhalt einer Anfrage validieren. Füge die folgende Zeile im Route-Handler vor `req.content.decode(CreateUser.self)` ein.

```swift
try CreateUser.validate(content: req)
```

Versuche nun, die folgende Anfrage mit einer ungültigen E-Mail-Adresse zu senden:

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

Du solltest folgenden Fehler erhalten:

```
email is not a valid email address
```

### Zeichenfolge der Anfrage validieren

Typen, die dem Protokoll `Validatable` entsprechen, besitzen auch `validate(query:)`, mit dem du die Zeichenfolge einer Anfrage validieren kannst. Füge dem Route-Handler die folgenden Zeilen hinzu.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Versuche nun, die folgende Anfrage mit einer ungültigen E-Mail-Adresse in der Zeichenfolge zu senden.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Du solltest folgenden Fehler erhalten:

```
email is not a valid email address
```

### Integer-Validierung

Gut, versuchen wir nun, eine Validierung für `age` hinzuzufügen.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

Die Validierung von `age` verlangt, dass das Alter größer oder gleich `13` ist. Wenn du die gleiche Anfrage wie oben ausprobierst, solltest du nun einen neuen Fehler sehen:

```
age is less than minimum of 13, email is not a valid email address
```

### String-Validierung

Als Nächstes fügen wir Validierungen für `name` und `username` hinzu. 

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

Die Validierung von `name` verwendet den `!`-Operator, um die Validierung `.empty` umzukehren. Dadurch wird verlangt, dass der String nicht leer ist.

Die Validierung von `username` kombiniert zwei Validatoren mit `&&`. Dadurch wird verlangt, dass der String mindestens 3 Zeichen lang ist _und_ nur alphanumerische Zeichen enthält.

### Enum-Validierung

Schauen wir uns abschließend eine etwas fortgeschrittenere Validierung an, um zu prüfen, ob der angegebene Wert für `favoriteColor` gültig ist.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Da es nicht möglich ist, aus einem ungültigen Wert einen `Color` zu dekodieren, verwendet diese Validierung `String` als Basistyp. Sie nutzt den Validator `.in`, um zu prüfen, ob der Wert eine gültige Option ist: red, blue oder green. Da dieser Wert optional ist, wird `required` auf false gesetzt, um anzuzeigen, dass die Validierung nicht fehlschlagen soll, wenn dieser Schlüssel in den Anfragedaten fehlt.

Beachte, dass die Validierung von favoriteColor zwar erfolgreich ist, wenn der Schlüssel fehlt, aber fehlschlägt, wenn `null` übergeben wird. Wenn du `null` unterstützen möchtest, ändere den Validierungstyp zu `String?` und verwende die Kurzform `.nil ||` (gelesen als: „ist nil oder …“).

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Benutzerdefinierte Fehler

Möglicherweise möchtest du deinen `Validations` oder `Validator` benutzerdefinierte, lesbare Fehlermeldungen hinzufügen. Gib dazu einfach den zusätzlichen Parameter `customFailureDescription` an, der die Standardfehlermeldung überschreibt.

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


## Validatoren

Im Folgenden findest du eine Liste der aktuell unterstützten Validatoren mit einer kurzen Erklärung ihrer Funktion.

|Validierung|Beschreibung|
|-|-|
|`.ascii`|Enthält nur ASCII-Zeichen.|
|`.alphanumeric`|Enthält nur alphanumerische Zeichen.|
|`.characterSet(_:)`|Enthält nur Zeichen aus dem angegebenen `CharacterSet`.|
|`.count(_:)`|Die Anzahl der Elemente der Collection liegt innerhalb der angegebenen Grenzen.|
|`.email`|Enthält eine gültige E-Mail-Adresse.|
|`.empty`|Die Collection ist leer.|
|`.in(_:)`|Der Wert ist in der angegebenen `Collection` enthalten.|
|`.nil`|Der Wert ist `null`.|
|`.range(_:)`|Der Wert liegt innerhalb des angegebenen `Range`.|
|`.url`|Enthält eine gültige URL.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Benutzerdefinierte, einmalige Validierung.|

Validatoren können außerdem mit Operatoren kombiniert werden, um komplexere Validierungen zu erstellen. Weitere Informationen zum `.custom`-Validator findest du unter [Benutzerdefinierte Validatoren](#custom-validators).

|Operator|Position|Beschreibung|
|-|-|-|
|`!`|prefix|Kehrt einen Validator um und verlangt das Gegenteil.|
|`&&`|infix|Kombiniert zwei Validatoren, beide müssen zutreffen.|
|`\|\|`|infix|Kombiniert zwei Validatoren, einer muss zutreffen.|



## Benutzerdefinierte Validatoren

Es gibt zwei Möglichkeiten, benutzerdefinierte Validatoren zu erstellen. 

### Validierungs-API erweitern

Das Erweitern der Validierungs-API eignet sich am besten für Fälle, in denen du den benutzerdefinierten Validator in mehr als einem `Content`-Objekt verwenden möchtest. In diesem Abschnitt zeigen wir dir Schritt für Schritt, wie du einen benutzerdefinierten Validator zur Validierung von Postleitzahlen erstellst. 

Erstelle zunächst einen neuen Typ, der die Validierungsergebnisse von `ZipCode` darstellt. Diese Struct ist dafür verantwortlich, zu melden, ob ein gegebener String eine gültige Postleitzahl ist.

```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

Als Nächstes passt du den neuen Typ dem Protokoll `ValidatorResult` an, das das von einem benutzerdefinierten Validator erwartete Verhalten definiert.

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

Implementiere abschließend die Validierungslogik für Postleitzahlen. Verwende dazu einen regulären Ausdruck, um zu prüfen, ob die Eingabezeichenfolge dem Format einer US-amerikanischen Postleitzahl entspricht.

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

Nachdem du nun den benutzerdefinierten Validator `zipCode` definiert hast, kannst du ihn verwenden, um Postleitzahlen in deiner Anwendung zu validieren. Füge dazu einfach die folgende Zeile zu deinem Validierungscode hinzu:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### Der Validator `Custom`

Der Validator `Custom` eignet sich am besten für Fälle, in denen du eine Eigenschaft nur in einem einzigen `Content`-Objekt validieren möchtest. Diese Implementierung hat im Vergleich zur Erweiterung der Validierungs-API die folgenden zwei Vorteile:

- Einfacher zu implementierende Validierungslogik.
- Kürzere Syntax.

In diesem Abschnitt zeigen wir dir Schritt für Schritt, wie du einen benutzerdefinierten Validator erstellst, der anhand der Eigenschaft `nameAndSurname` prüft, ob ein Mitarbeiter Teil unseres Unternehmens ist.

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
