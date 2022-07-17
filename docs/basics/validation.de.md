# Validierung

Mit der Validierung kann der Inhalt oder die Zeichenfolge einer eingehenden Serveranfrage vor dem Binden auf Korrektheit geprüft werden.

## Grundlagen 

Dank der Einbindung von Swift's Protokoll _Codable_ müssen wir uns nicht viel mehr Gedanken zur Validierung von Daten machen, wie bei anderen dynamischen Sprachen auch. Nicht desto trotz gibt es ein paar gute Gründe die Validerung von Vapor zu nutzen:

- [Lesbare Fehlermeldungen]()
- [Vollständige Lesung]()
- [Werteüberprüfung]()

**Lesbare Fehlermeldungen**

Beim Binden der Anfrage an das Datenobjekt werden Fehler zurückgegegeben, sollte der Inhalt nicht mit dem Objekt übereinstimmen. Dabei kann es natürlich vorkommen, dass die Fehlermeldung nicht immer ganz aussagekräftig und verständlich für den Anwender ist.

Beispiel:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Beim Versuch den String *purple* an die Eigenschaft vom Typ *Color* zu übergeben, wird folgender Fehler ausgegeben:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Auch wenn der Fehler technisch korrekt und der Endpunkt vor einer Falscheingabe bewahrt wird, kann es hilfreich sein, den Anwender über den Fehler zu informieren und ihm mögliche Lösungen anzubieten.

Mit Vapor's Validierung können wir den folgende Fehler erstellen:

```
favoriteColor is not red, blue, or green
```

**Vollständige Lesung**

Des Weiteren würde durch das Protokoll _Codable_ das Binden bereits beim Auftreten des ersten Fehlers abbrechen. Die Validierung von Vapor hingegen, liefert alle Fehler zurück.

**Werteüberprüfung**

Auch wenn das Protokoll gut validiert, gibt es Situationen in denen man den Wert gegenprüfen möchte. Vapor besitzt mehrere [Bedingungen](#bedingungen) um zum Beispiel Emailadressen, Zeichensätze, Wertebereiche usw. zu prüfen.

## Regelsammlung

Zur Überprüfung einer Anfrage, müssen wir ein Sammlung von Regeln anlegen. Das machen wir, indem wir dem Datenobjekt das Protokoll *Validtable* mitgeben.

```swift
extension CreateUser: Validatable {

    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

### Hinzufügen von Regeln

Mit der Methode *add(_:)* können wir der [Regeln]() hinzufügen.

```swift
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
```

Der erste Parameter der Methode zu erwartende Name. Der Name sollte mit dem Namen im Objekt übereinstimmen. Der zweite Parameter _as:_ ist der zu erwartende Typ. In den meisten Fällen stimmt der Typ mit dem Typ im Objekt überein. Beim dritten Parameter _is:_ können ein oder mehrere Bedingungen mit angegeben werden.

### Bedingungen

Zur Überprüfung können verschiedenste Bedingungen verwendet werden.

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

Mit Operatoren kannst du Bedingungen miteinander verknüpfen, um so komplexere Regeln zu bauen.

|Operatoren|Position|Beschreibung                                               |
|----------|--------|-----------------------------------------------------------|
|!         |prefix  |Dreht eine Bedingung um. Das Gegenteil wird somit erwartet.|
|&&        |infix   |Alle Bedingungen müssen stimmen.                           |
|\|\|      |infix   |Nur eine Bedingung muss stimmen.                           |

### Benutzerdefinierte Fehlerbeschreibung

Mit dem Parameter _customFailureDescription_ kannst du die standardmäßige Fehlermeldung überschreiben und eine Eigene zurückgeben.

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

Würdest wir jetzt eine Anfrage mit einer ungültigen Emailadresse stellen, würde wir folgenden Fehler erhalten:

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

Die Methode *validate(query:)* überprüft die Zeichenabfolge der Anfrage auf Korrektheit. Die Methode sollte vor dem Binden der Abfolge aufgerufen werden.

```swift
try CreateUser.validate(query: req)

req.query.decode(CreateUser.self)
```

Würdest wir jetzt eine Anfrage mit einer ungültigen Emailadresse in der Zeichenabfolge stellen, würde wir folgende Fehler erhalten:

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

```
email is not a valid email address
```

### Überprüfung des Wertes


**Wert vom Typ *Int***

Im folgenden Beispiel überprüfen wir, ob der Werte des Alters größer gleich 13 ist.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

```
age is less than minimum of 13, email is not a valid email address
```

**Wert vom Typ *String***

Beispiel:

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

Die erste Überprüfung verwendet `!` als Operator, was bedingt, dass der Wert nicht leer sein darf. Die zweite Überprüfung verknüpft zwei Bedingungen miteinander, was bedingt, dass der Wert größer als drei Zeichen und nur aus Buchstaben besteht.

**Wert vom Typ *Enum***

Finally, let's take a look at a slightly more advanced validation to check that the supplied `favoriteColor` is valid.

```swift
validations.add("favoriteColor", as: String.self, is: .in("red", "blue", "green"), required: false)
```

Die Überprüfung verwendet die Bedingung *in*, was bedingt, dass der Wert mit einer der Angaben im Beispiel (red, blue, green) übereinstimmen muss. Mit dem Parameter *required:* legen wir fest, dass die Überprüfung nicht fehlschlägt, sollte der Wert in der Anfrage fehlen.
