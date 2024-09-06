# Validierung

Mit der Validierung kann der Inhalt oder die Zeichenfolge einer eingehenden Serveranfrage vor dem Binden auf Korrektheit geprüft werden.

## Grundlagen 

Dank Swift's Protokoll _Codable_ müssen wir uns nicht viel mehr Gedanken zur Validierung von Daten machen, wie eben bei anderen dynamischen Sprachen auch. Nicht desto trotz gibt es einige gute Gründe, die für die Validierung in Vapor sprechen.

**Lesbare Fehlermeldungen**

Sollte der Inhalt nicht mit dem Objekt übereinstimmen, werden beim Binden der Anfrage an das Datenobjekt Fehler zurückgegegeben. Dabei kann es natürlich vorkommen, dass die Fehlermeldungen nicht immer aussagekräftig und verständlich für den Anwender sind.

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Beispielsweise beim Versuch den String *purple* an die Eigenschaft vom Typ *Color* zu übergeben, wird folgender Fehler ausgegeben:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Auch wenn die Fehlermeldung technisch korrekt und der Endpunkt vor einer Falscheingabe bewahrt wird, kann es hilfreich sein, dem Anwender über gewisse Fehler zu informieren und ihm mögliche Lösungen aufzuzeigen. Mit Vapor's Validierung können wir beispielsweise folgenden Fehler ausgeben:

```
favoriteColor is not red, blue, or green
```

**Vollständige Lesung**

Des Weiteren würde durch das Protokoll _Codable_ das Binden bereits beim Auftreten des ersten Fehlers abbrechen. Die Validierung von Vapor hingegen, liefert alle Fehler zurück.

**Werteüberprüfung**

Auch wenn die Validierung mittels Protokoll gut funktioniert, gibt es Situationen in denen man eher den Wert prüfen möchte. Vapor besitzt mehrere Bedingungen um zum Beispiel Emailadressen, Zeichensätze, Wertebereiche usw. zu prüfen.

## Regelsammlung

Zur Überprüfung einer Anfrage müssen wir ein Art Regelsammlung anlegen. Das machen wir, indem wir dem Datenobjekt das Protokoll *Validatable* mitgeben. Mittels der Methode *add(_:)* können wir Regeln hinzufügen.

```swift
extension CreateUser: Validatable {

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}
```

Der erste Parameter der Methode ist der zu erwartende Name. Der Name sollte mit dem Feldnamen des Datenobjekts übereinstimmen. Der zweite Parameter _as:_ ist der zu erwartende Typ. In den meisten Fällen stimmt der Typ ebenfalls mit dem Datentyp des Feldes im Objekt überein. Beim dritten Parameter _is:_ können mehrere Bedingungen angegeben werden.

### Bedingungen

Mit Bedingungen können wir Anweisungen für eine Regel festlegen.

|Bedingung       |Beschreibung                                           |
|----------------|-------------------------------------------------------|
|ascii           |Der Wert besteht nur aus ASCII Zeichen.                |
|alphanumeric    |Der Wert besteht nur aus Buchstaben.                   |
|characterSet(_:)|Der Wert besteht aus den angegebenen Zeichensatz.      |
|count(_:)       |Der Wert entspricht der angegebenen Anzahl.            |
|email           |Beim Wert handelt es sich um eine gültige Emailadresse.|
|empty           |Der Wert ist leer.                                     |
|in(_:)          |Der Wert befindet sich in der angegebenen Sammlung.    |
|nil             |Der Wert ist `null`.                                   |
|range(_:)       |Der Wert ist innerhalb des angegebenen Bereichs.       |
|url             |Beim Wert handelt es sich um eine gültige URL.         |

### Operatoren

Mit Operatoren können wir Bedingungen miteinander verknüpfen, um so komplexere Regeln zu bilden.

|Operatoren|Position|Beschreibung                                               |
|----------|--------|-----------------------------------------------------------|
|!         |prefix  |Dreht eine Bedingung um. Das Gegenteil wird somit erwartet.|
|&&        |infix   |Alle Bedingungen müssen stimmen.                           |
|\|\|      |infix   |Nur eine Bedingung muss stimmen.                           |

### Benutzerdefinierte Fehlerbeschreibung

Mit dem Parameter _customFailureDescription_ können wir die Standardfehlermeldung von Vapor überschreiben.

```swift
validations.add("name", as: String.self, is: !.empty, customFailureDescription: "Provided name is empty!")
```

## Überprüfung

### Überprüfung des Inhaltes

Die Methode *validate(content:)* überprüft den Inhalt der Anfrage auf Korrektheit. Die Methode sollte vor dem Binden des Inhaltes aufgerufen werden.

```swift
try CreateUser.validate(content: req)

req.content.decode(CreateUser.self)
```

Bei einer Anfrage mit einer ungültigen Emailadresse, würden wir folgenden Fehler erhalten:

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

```
email is not a valid email address
```

### Überprüfung der Zeichenfolge

Die Methode *validate(query:)* überprüft die Zeichenfolge der Anfrage auf Korrektheit. Die Methode sollte vor dem Binden der Abfolge aufgerufen werden.

```swift
try CreateUser.validate(query: req)

req.query.decode(CreateUser.self)
```

Bei einer Anfrage mit einer ungültigen Emailadresse in der Zeichenfolge, würde wir folgende Fehler erhalten:

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

```
email is not a valid email address
```

### Überprüfung des Wertes


**am Beispiel vom Typ *Integer***

Im folgenden Beispiel überprüfen wir, ob der Wert größer gleich 13 ist.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

```
age is less than minimum of 13, email is not a valid email address
```

**am Beispiel vom Typ *String***

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

Die erste Überprüfung verwendet `!` als Operator, was bedingt, dass der Wert nicht leer sein darf. Die zweite Überprüfung verknüpft zwei Bedingungen miteinander, was bedingt, dass der Wert größer als drei Zeichen und nur aus Buchstaben besteht.

**am Beispiel vom Typ *Enum***

```swift
validations.add("favoriteColor", as: String.self, is: .in("red", "blue", "green"), required: false)
```

Die Überprüfung verwendet die Bedingung *in*, was bedingt, dass der Wert mit einer der Angaben im Beispiel (red, blue, green) übereinstimmen muss. Mit dem Parameter *required:* legen wir fest, dass die Überprüfung nicht fehlschlägt, sollte der Wert in der Anfrage fehlen.

## Benutzerdefinierte Validatoren

Durch die Erstellung einer eigenen Regelvorlage können wir Vapors bestehendes Regelwerk erweitern.  Im folgenden Abschnitt erstellen wir eine neue Vorlage, um eine Postleitzahl zu gegenzuprüfen.

Zunächst erstellen wir einen neuen Typ, um die Ergebnisse der Validierung darzustellen. Diese Struktur ist dafür verantwortlich, zu melden, ob eine bestimmte Zeichenfolge eine gültige Postleitzahl ist.
```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

Als Nächstes wird der neue Typ an `ValidatorResult` angepasst, das das von einem benutzerdefinierten Validator erwartete Verhalten definiert.

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

Abschließend wird die Validierungslogik für Postleitzahlen implementiert. Dabei wird ein regulärer Ausdruck verwendet, um zu prüfen, ob die Eingabezeichenfolge dem Format einer US-amerikanischen Postleitzahl entspricht.

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


Nachdem die neue Vorlage definiert wurde, kann sie in der Anwendung verwendet werden:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

