# Validazione

L'API Validation di Vapor ti aiuta a validare il body e i parametri della query di una richiesta in arrivo prima di usare l'API [Content](content.it.md) per decodificare i dati.

## Introduzione

La profonda integrazione di Vapor con il protocollo `Codable` type-safe di Swift significa che non hai bisogno di preoccuparti tanto della validazione dei dati rispetto ai linguaggi tipizzati dinamicamente. Tuttavia, ci sono ancora alcuni motivi per cui potresti voler optare per una validazione esplicita usando l'API Validation.

### Errori Leggibili dagli Utenti

La decodifica di struct usando l'API [Content](content.it.md) produrrà errori se uno qualsiasi dei dati non è valido. Tuttavia, questi messaggi di errore a volte possono mancare di leggibilità per l'utente. Per esempio, considera il seguente enum backed da stringhe:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Se un utente tenta di passare la stringa `"purple"` a una proprietà di tipo `Color`, riceverà un errore simile al seguente:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Sebbene questo errore sia tecnicamente corretto e abbia protetto con successo l'endpoint da un valore non valido, potrebbe fare di meglio nell'informare l'utente sull'errore e su quali opzioni sono disponibili. Usando l'API Validation, puoi generare errori come il seguente:

```
favoriteColor is not red, blue, or green
```

Inoltre, `Codable` smetterà di tentare di decodificare un tipo non appena viene colpito il primo errore. Ciò significa che anche se ci sono molte proprietà non valide nella richiesta, l'utente vedrà solo il primo errore. L'API Validation riporterà tutti i fallimenti di validazione in una singola richiesta.

### Validazione Specifica

`Codable` gestisce bene la validazione dei tipi, ma a volte vuoi qualcosa in più. Per esempio, validare il contenuto di una stringa o validare la dimensione di un intero. L'API Validation ha validatori per aiutare a validare dati come email, set di caratteri, intervalli di interi e altro.

## Validatable

Per validare una richiesta, dovrai generare una collezione di `Validations`. Questo viene fatto più comunemente conformando un tipo esistente a `Validatable`.

Vediamo come potresti aggiungere la validazione a questo semplice endpoint `POST /users`. Questa guida assume che tu abbia già familiarità con l'API [Content](content.it.md).

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
    // Fai qualcosa con user.
    return user
}
```

### Aggiungere Validazioni

Il primo passo è conformare il tipo che stai decodificando, in questo caso `CreateUser`, a `Validatable`. Questo può essere fatto in un'extension.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Le validazioni vanno qui.
    }
}
```

Il metodo statico `validations(_:)` verrà chiamato quando `CreateUser` viene validato. Qualsiasi validazione che vuoi eseguire dovrebbe essere aggiunta alla collezione `Validations` fornita. Vediamo come aggiungere una semplice validazione per richiedere che l'email dell'utente sia valida.

```swift
validations.add("email", as: String.self, is: .email)
```

Il primo parametro è la chiave attesa del valore, in questo caso `"email"`. Dovrebbe corrispondere al nome della proprietà sul tipo che viene validato. Il secondo parametro, `as`, è il tipo atteso, in questo caso `String`. Il tipo di solito corrisponde al tipo della proprietà, ma non sempre. Infine, uno o più validatori possono essere aggiunti dopo il terzo parametro, `is`. In questo caso, stiamo aggiungendo un singolo validatore che controlla se il valore è un indirizzo email.

### Validare il Contenuto della Richiesta

Una volta che hai conformato il tuo tipo a `Validatable`, la funzione statica `validate(content:)` può essere usata per validare il contenuto della richiesta. Aggiungi la seguente riga prima di `req.content.decode(CreateUser.self)` nell'handler della route.

```swift
try CreateUser.validate(content: req)
```

Ora, prova a inviare la seguente richiesta contenente un'email non valida:

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

Dovresti vedere il seguente errore restituito:

```
email is not a valid email address
```

### Validare la Query della Richiesta

I tipi conformi a `Validatable` hanno anche `validate(query:)` che può essere usato per validare la query string di una richiesta. Aggiungi le seguenti righe all'handler della route.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Ora, prova a inviare la seguente richiesta contenente un'email non valida nella query string.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Dovresti vedere il seguente errore restituito:

```
email is not a valid email address
```

### Validazione degli Interi

Ottimo, ora proviamo ad aggiungere una validazione per `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

La validazione dell'età richiede che l'età sia maggiore o uguale a `13`. Ora, se provi la stessa richiesta di prima dovresti vedere un nuovo errore:

```
age is less than minimum of 13, email is not a valid email address
```

### Validazione delle Stringhe

Poi, aggiungiamo validazioni per `name` e `username`.

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

La validazione del nome usa l'operatore `!` per invertire la validazione `.empty`. Questo richiederà che la stringa non sia vuota.

La validazione dello username combina due validatori usando `&&`. Questo richiederà che la stringa abbia almeno 3 caratteri _e_ contenga solo caratteri alfanumerici.

### Validazione degli Enum

Infine, diamo un'occhiata a una validazione leggermente più avanzata per controllare che il `favoriteColor` fornito sia valido.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Poiché non è possibile decodificare un `Color` da un valore non valido, questa validazione usa `String` come tipo di base. Usa il validatore `.in` per verificare che il valore sia un'opzione valida: red, blue, o green. Poiché questo valore è opzionale, `required` è impostato a false per segnalare che la validazione non dovrebbe fallire se questa chiave manca dai dati della richiesta.

Nota che mentre la validazione del colore preferito passerà se la chiave manca, non passerà se viene fornito `null`. Se vuoi supportare `null`, cambia il tipo di validazione in `String?` e usa `.nil ||` (si legge come: "è nil oppure ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Errori Personalizzati

Potresti voler aggiungere errori personalizzati leggibili dall'utente alle tue `Validations` o al tuo `Validator`. Per farlo, fornisci semplicemente il parametro aggiuntivo `customFailureDescription` che sovrascriverà l'errore predefinito.

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

## Validatori

Di seguito è riportato un elenco dei validatori attualmente supportati e una breve spiegazione di cosa fanno.

|Validazione|Descrizione|
|-|-|
|`.ascii`|Contiene solo caratteri ASCII.|
|`.alphanumeric`|Contiene solo caratteri alfanumerici.|
|`.characterSet(_:)`|Contiene solo caratteri dal `CharacterSet` fornito.|
|`.count(_:)`|Il conteggio della Collection è nei limiti forniti.|
|`.email`|Contiene un'email valida.|
|`.empty`|La Collection è vuota.|
|`.in(_:)`|Il valore è nella `Collection` fornita.|
|`.nil`|Il valore è `null`.|
|`.range(_:)`|Il valore è nel `Range` fornito.|
|`.url`|Contiene un URL valido.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Validazione personalizzata una tantum.|

I validatori possono anche essere combinati per costruire validazioni complesse usando gli operatori. Ulteriori informazioni sul validatore `.custom` in [[#Validatori Personalizzati]].

|Operatore|Posizione|Descrizione|
|-|-|-|
|`!`|prefisso|Inverte un validatore, richiedendo l'opposto.|
|`&&`|infisso|Combina due validatori, richiede entrambi.|
|`\|\|`|infisso|Combina due validatori, richiede uno.|

## Validatori Personalizzati

Ci sono due modi per creare validatori personalizzati.

### Estendere l'API Validation

Estendere l'API Validation è la soluzione migliore per i casi in cui prevedi di usare il validatore personalizzato in più di un oggetto `Content`. In questa sezione, ti guideremo attraverso i passaggi per creare un validatore personalizzato per la validazione dei codici postali (zip code).

Prima crea un nuovo tipo per rappresentare i risultati della validazione `ZipCode`. Questa struct sarà responsabile di riportare se una data stringa è un codice postale valido.

```swift
extension ValidatorResults {
    /// Rappresenta il risultato di un validatore che controlla se una stringa è un codice postale valido.
    public struct ZipCode {
        /// Indica se l'input è un codice postale valido.
        public let isValidZipCode: Bool
    }
}
```

Poi, conforma il nuovo tipo a `ValidatorResult`, che definisce il comportamento atteso da un validatore personalizzato.

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

Infine, implementa la logica di validazione per i codici postali. Usa un'espressione regolare per verificare se la stringa di input corrisponde al formato di un codice postale italiano.

```swift
private let zipCodeRegex: String = "^[0-9]{5}$"

extension Validator where T == String {
    /// Valida se una `String` è un codice postale valido.
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

Ora che hai definito il validatore personalizzato `zipCode`, puoi usarlo per validare i codici postali nella tua applicazione. Aggiungi semplicemente la seguente riga al tuo codice di validazione:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### Validatore `Custom`

Il validatore `Custom` è la soluzione migliore per i casi in cui vuoi validare una proprietà in un solo oggetto `Content`. Questa implementazione ha i seguenti due vantaggi rispetto all'estensione dell'API Validation:

- Implementazione della logica di validazione personalizzata più semplice.
- Sintassi più breve.

In questa sezione, ti guideremo attraverso i passaggi per creare un validatore personalizzato per verificare se un dipendente fa parte della nostra azienda guardando la proprietà `nameAndSurname`.

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
