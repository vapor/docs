# Validatie 

Vapor's Validatie API helpt u de body en query parameters van een inkomend verzoek te valideren voordat u de [Content](content.md) API gebruikt om gegevens te decoderen. 

## Introductie 

Vapor's diepe integratie van Swift's type-veilige `Codable` protocol betekent dat je je niet zoveel zorgen hoeft te maken over data validatie in vergelijking met dynamisch getypeerde talen. Er zijn echter nog steeds een paar redenen waarom je zou willen kiezen voor expliciete validatie met behulp van de Validatie API.

### Menselijk leesbare fouten

Het decoderen van structs met behulp van de [Content](content.md) API zal fouten opleveren als een van de gegevens niet geldig is. Echter, deze foutmeldingen kunnen soms onleesbaar zijn voor mensen. Neem bijvoorbeeld de volgende string-backed enum:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Als een gebruiker de string `"purple"` probeert door te geven aan een eigenschap van het type `Color`, krijgt hij een foutmelding zoals in het volgende voorbeeld:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Hoewel deze fout technisch correct is en het eindpunt met succes beschermt tegen een ongeldige waarde, zou het beter zijn om de gebruiker te informeren over de fout en welke opties beschikbaar zijn. Door de Validation API te gebruiken, kunt u fouten als de volgende genereren:

```
favoriteColor is not red, blue, or green
```

Verder zal `Codable` stoppen met het proberen te decoderen van een type zodra de eerste fout wordt gevonden. Dit betekent dat zelfs als er veel ongeldige eigenschappen in het verzoek zijn, de gebruiker alleen de eerste fout zal zien. De validatie API zal alle validatie fouten in een enkel verzoek rapporteren.

### Specifieke Validatie

`Codable` handelt type-validatie goed af, maar soms wil je meer dan dat. Bijvoorbeeld, het valideren van de inhoud van een string of het valideren van de grootte van een integer. De validatie API heeft validators om te helpen bij het valideren van gegevens zoals emails, character sets, integer ranges, en meer.

## Validatable

Om een verzoek te valideren, moet je een `Validations` collectie genereren. Dit wordt meestal gedaan door een bestaand type te conformeren aan `Validatable`. 

Laten we eens kijken hoe je validatie kunt toevoegen aan dit eenvoudige `POST /users` endpoint. Deze handleiding gaat ervan uit dat je al bekend bent met de [Content](content.md) API.

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

### Validaties Toevoegen

De eerste stap is om het type dat je aan het decoderen bent, in dit geval `CreateUser`, te conformeren aan `Validatable`. Dit kan gedaan worden in een extensie.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

De statische methode `validations(_:)` zal worden aangeroepen wanneer `CreateUser` wordt gevalideerd. Alle validaties die je wilt uitvoeren moeten worden toegevoegd aan de `Validations` collectie. Laten we eens kijken naar het toevoegen van een eenvoudige validatie om te eisen dat het e-mailadres van de gebruiker geldig is.

```swift
validations.add("email", as: String.self, is: .email)
```

De eerste parameter is de verwachte sleutel van de waarde, in dit geval `"email"`. Deze moet overeenkomen met de naam van de eigenschap op het type dat gevalideerd wordt. De tweede parameter, `as`, is het verwachte type, in dit geval `String`. Het type komt meestal overeen met het type van de eigenschap, maar niet altijd. Tenslotte kunnen na de derde parameter, `is`, nog één of meerdere validaties worden toegevoegd. In dit geval voegen we een enkele validator toe die controleert of de waarde een e-mailadres is.

### Valideren van verzoekinhoud

Als je je type hebt geconformeerd aan `Validatable`, kan de statische `validate(content:)` functie worden gebruikt om de request inhoud te valideren. Voeg de volgende regel toe voor `req.content.decode(CreateUser.self)` in de route handler.

```swift
try CreateUser.validate(content: req)
```

Probeer nu het volgende verzoek te sturen met een ongeldige e-mail:

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

U zou de volgende foutmelding moeten zien:

```
email is not a valid email address
```

### Valideren van verzoek query

Types die voldoen aan `Validatable` hebben ook `validate(query:)` die gebruikt kan worden om de query string van een request te valideren. Voeg de volgende regels toe aan de route handler.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Probeer nu het volgende verzoek te verzenden met een ongeldig e-mailadres in de querystring.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

U zou de volgende foutmelding moeten zien:

```
email is not a valid email address
```

### Integer Validatie

Geweldig, laten we nu eens proberen een validatie voor `leeftijd` toe te voegen.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

De leeftijdsvalidatie vereist dat de leeftijd groter of gelijk is aan `13`. Als je hetzelfde verzoek als hierboven probeert, zou je nu een nieuwe fout moeten zien:

```
age is less than minimum of 13, email is not a valid email address
```

### String Validatie

Laten we nu validaties voor `name` en `username` toevoegen. 

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

De naam validatie gebruikt de `!` operator om de `.empty` validatie om te keren. Dit vereist dat de string niet leeg is.

De gebruikersnaam validatie combineert twee validators met behulp van `&&`. Dit vereist dat de string minstens 3 tekens lang is _en_ alleen alfanumerieke tekens bevat.

### Enum Validatie

Laten we tenslotte eens kijken naar een iets meer geavanceerde validatie om te controleren of de opgegeven `favoriteColor` geldig is.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Omdat het niet mogelijk is om een `Kleur` te decoderen uit een ongeldige waarde, gebruikt deze validatie `String` als het basistype. Het gebruikt de `.in` validator om te controleren of de waarde een geldige optie is: rood, blauw, of groen. Omdat deze waarde optioneel is, wordt `required` op false gezet om aan te geven dat de validatie niet mag mislukken als deze sleutel ontbreekt in de request data.

Merk op dat terwijl de favoriete kleur validatie zal slagen als de sleutel ontbreekt, het niet zal slagen als `null` wordt geleverd. Als je `null` wilt ondersteunen, verander dan het validatie type in `String?` en gebruik het `.nil ||` (te lezen als: "is nil of ...") gemak.

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Aangepaste fouten

Het is mogelijk dat u aangepaste menselijk leesbare fouten wilt toevoegen aan uw `Validations` of `Validator`. Om dit te doen hoeft u alleen maar de `customFailureDescription` parameter op te geven, deze zal de standaard fout overschrijven.

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

Hieronder staat een lijst van de momenteel ondersteunde validaties en een korte uitleg van wat ze doen.

|Validatie|Beschrijving|
|-|-|
|`.ascii`|Bevat enkel ASCII karakters.|
|`.alphanumeric`|Bevat enkel alphanumerieke karakters.|
|`.characterSet(_:)`|Bevat enkel karakters uit de opgegeven `CharacterSet`.|
|`.count(_:)`|De telling van de collectie is binnen de opgegeven grenzen.|
|`.email`|Bevat een geldig email.|
|`.empty`|De verzameling is leeg.|
|`.in(_:)`|Waarde zit in de opgegeven `Collection`.|
|`.nil`|Waarde is `null`.|
|`.range(_:)`|Waarde is binnen de opgegeven `Range`.|
|`.url`|Bevat een geldige URL.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Aangepaste, eenmalige validatie.|

Validators kunnen ook gecombineerd worden om complexe validaties te bouwen met behulp van operatoren. Meer informatie over de `.custom` validator vindt u bij [Aangepaste Validators](#aangepaste-validators).

|Operator|Positie|Beschrijving|
|-|-|-|
|`!`|voorvoegsel|Voert een validator in, die het tegenovergestelde vereist.|
|`&&`|tussenvoegsel|Combineert twee validators, vereist beide.|
|`\|\|`|tussenvoegsel|Combineert twee validators, vereist één.|



## Aangepaste Validators

Er zijn twee manieren om aangepaste validators te maken.

### Uitbreiden van de Validatie API

Het uitbreiden van de Validatie API is het meest geschikt voor gevallen waarin u van plan bent de aangepaste validator in meer dan één `Content` object te gebruiken. In dit deel doorlopen we de stappen om een aangepaste validator te maken voor het valideren van postcodes.

Maak eerst een nieuw type aan om de validatieresultaten van `ZipCode` weer te geven. Deze struct is verantwoordelijk voor het rapporteren of een gegeven string een geldige postcode is.

```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

Vervolgens conformeert u het nieuwe type aan `ValidatorResult`, dat het gedrag definieert dat van een aangepaste validator wordt verwacht.

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

Tot slot implementeert u de validatielogica voor postcodes. Gebruik een reguliere expressie om te controleren of de invoerstring overeenkomt met het formaat van een Amerikaanse postcode.

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

Nu u de aangepaste `zipCode` validator hebt gedefinieerd, kunt u deze gebruiken om postcodes in uw applicatie te valideren. Voeg simpelweg de volgende regel toe aan uw validatiecode:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### `Custom` Validator

De `Custom` validator is het meest geschikt voor gevallen waarin u een eigenschap wilt valideren in slechts één `Content` object. Deze implementatie heeft de volgende twee voordelen in vergelijking met het uitbreiden van de Validatie API:

- Eenvoudiger om aangepaste validatielogica te implementeren.
- Kortere syntax.

In dit deel doorlopen we de stappen om een aangepaste validator te maken die controleert of een medewerker deel uitmaakt van ons bedrijf door te kijken naar de `nameAndSurname` eigenschap.

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
