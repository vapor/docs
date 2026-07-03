# La validation de données

L'API Validation de Vapor vous aide à valider les données du corps ou de la QueryString d'une requête entrante avant d'utiliser l'API [Contenu](content.md) pour les décoder. 

## Introduction 

La forte intégration du protocole `Codable` de Swift et sa sécurité de typage dans Vapor signifie que vous n'avez pas autant à vous soucier de la validation des données en comparaison à d'autres langages au typage dynamique. Cependant, il reste quelques raisons pour lesquelles vous souhaiterez probablement passer à une validation explicite par l'API Validation.

### Erreurs lisibles pour les humains

Le décodage de structs par l'API [Contenu](content.md) produira des erreurs si une quelconque donnée est invalide. Néanmoins, ces messages d'erreur ont quelquefois des problèmes de clarté. Par exemple, si vous prenez cette enum :

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Si un utilisateur essaie d'attribuer la valeur `"purple"` à une propriété typée avec `Color`, il verra une error du style :

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Bien que ce message soit techniquement correct et qu'il ait réussi à protéger notre API d'une valeur invalide, il pourrait mieux indiquer à l'utilisateur quelle erreur il a commise, et quelles possibilités lui sont offertes. En utilisant l'API Validation, vous pouvez générer des erreurs comme celle-ci :

```
favoriteColor is not red, blue, or green
```

De plus, `Codable` arrêtera sa tentative de décodage dès la première erreur rencontrée. Cela signifie que si plusieurs valeurs sont invalides dans la requête, l'utilisateur ne verra que la première erreur. L'API Validation rapportera tout les échecs rencontrés sur une même requête.

### Validation spécifique

`Codable` gère très bien la validation des types, mais des fois nous avons besoin de plus que ça. Par exemple, valider le contenu d'une chaîne ou valider la taille d'un entier. L'API Validation fournit des valideurs pour vous aider à valider des données comme les emails, des jeux de caractères, la portée d'entiers, et plus.

## Validatable

Afin de valider une requête, vous devrez générer une collection de `Validations`. Cela se fait généralement en conformant un type existant à `Validatable`. 

Voyons comment vous pourriez ajouter une validation sur l'endpoint `POST /users`. Ce guide considère que vous vous êtes déjà familiarisé avec l'API [Contenu](content.md).

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
    // Faire quelque-chose de la variable user.
    return user
}
```

### Ajout de Validations

La première étape consite à conformer le type que vous décodez, dans notre cas `CreateUser`, à `Validatable`. Vous pouvez le faire dans une extension.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Les Validations iront ici.
    }
}
```

La méthode statique `validations(_:)` sera invoquée lorsque `CreateUser` sera validé. Toute validation que vous souhaitez appliquer devra être ajoutée à la collection fournie par `Validations`. Voyons comment ajouter une validation basique qui nécessite que l'email de l'utilisateur soit valide.

```swift
validations.add("email", as: String.self, is: .email)
```

Le premier paramètre est la clé attendue pour la valeur à valider, soit `"email"` dans le cas présent. Cela doit correspondre au nom de la propriété du type en cours de validation. Le second paramètre, `as`, est le type attendu, soit `String` pour notre cas. Ce type correspond généralement à celui de la propriété, mais pas systématiquement. Enfin, un valideur ou plus peuvent être fournis au troisième paramètre, `is`. Ici, nous ajoutons un valideur unique qui vérifie si la valeur est bien un email.

### Valider le corps d'une requête

Une fois votre type en conformité avec `Validatable`, on peut utiliser la fonction statique `validate(content:)` pour valider le contenu de la requête. Ajoutez la ligne ci-dessous juste avant `req.content.decode(CreateUser.self)` dans votre gestionnaire de requête.

```swift
try CreateUser.validate(content: req)
```

Essayez maintenant d'envoyer cette requête qui contient un email invalide :

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

Vous devriez recevoir l'erreur suivante :

```
email is not a valid email address
```

### Valider la QueryString d'une requête

Les types en conformité avec `Validatable` ont également une fonction `validate(query:)` que l'on peut utiliser pour valider la QueryString. Ajoutez les lignes suivantes dans votre gestionnaire de requête :

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Maintenant, essayez d'envoyer la requête suivante qui contient un email invalide dans la QueryString.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Vous devriez recevoir cette erreur :

```
email is not a valid email address
```

### Valider des entiers

Parfait, essayons maintenant d'ajouter une validation pour `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

Cette validation nécessite que l'âge soit supérieur ou égal à `13`. Si vous ré-essayez la requête précédente, vous devriez voir une nouvelle erreur :

```
age is less than minimum of 13, email is not a valid email address
```

### Valider des chaînes de caractères

Ajoutons ensuite des validations pour `name` et `username`. 

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

La validation de name utilise l'opérateur `!` pour inverser la règle `.empty`. Cela nécessitera donc que la chaîne ne soit pas vide.

La validation pour username combine deux valideurs avec l'opérateur `&&`. Cela nécessitera que la chaîne comporte au moins 3 caractères _et_ qu'elle ne contienne que des caractères alphanumériques.

### Valider des Enums

Enfin, voyons un cas de validation légèrement plus avancé pour vérifier que `favoriteColor` est valide.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Puisque l'on ne peut pas décoder un objet `Color` à partir d'une valeur invalide, cette validation utilise `String` comme type de base. Elle utilise ensuite le valideur `.in` pour vérifier que la valeur correspond à une des options valides : red, blue, ou green. Puisque cette valeur est optionnelle, `required` est défini à false pour indiquer que la validation ne doit pas lever une erreur si la clé est manquante dans les données de la requête.

Notez cependant que, bien que la validation sur favoriteColor passera si la clé est manquante, elle ne passera pas si elle est définie avec la valeur `null`. Si vous souhaitez permettre la valeur `null`, changez le type de validation à `String?` et utilisez le valideur `.nil ||` (se lit : "est null ou ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Erreurs personnalisées

Vous voudrez peut-être définir des messages d'erreur personnalisés dans vos objets `Validations` ou `Validator`. Pour cela, renseignez simplement le paramètre additionnel `customFailureDescription` qui remplacera le message par défaut.

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

## Valideurs fournis

Vous trouverez ci-dessous la liste des valideurs actuellement fournis et une brève explication de ce qu'ils font.

|Validation|Description|
|-|-|
|`.ascii`|Ne doit contenir que des caractères ASCII.|
|`.alphanumeric`|Ne doit contenir que des caractères alphanumériques.|
|`.characterSet(_:)`|Ne doit contenir que des caractères du `CharacterSet` fourni.|
|`.count(_:)`|La Collection ne doit pas avoir plus d'éléments que défini.|
|`.email`|Doit être un email valide.|
|`.empty`|Doit être vide.|
|`.in(_:)`|Doit correspondre à une valeur définie dans la `Collection` fournie.|
|`.nil`|Doit être `null`.|
|`.range(_:)`|La valeur doit se situer dans la portée définie par `Range`.|
|`.url`|Doit être un URL valide.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Validation personnalisée, pour un cas particulier.|

Les valideurs peuvent aussi être combinés grâce à des opérateurs pour construire des règles plus complexes. Plus d'informations sur la règle `.custom` dans la section [Valideurs personnalisés](#valideurs-personnalisés) qui suit.

|Opérateur|Position|Description|
|-|-|-|
|`!`|préfixe|Inverse un valideur, nécessitant le contraire de la règle définie.|
|`&&`|insert|Combine deux valideurs, nécessite que les deux règles soient respectées.|
|`\|\|`|insert|Combine deux valideurs, nécessite qu'au moins une des règles soit respectée.|


## Valideurs personnalisés

Il existe deux façons de créer vos valideurs personnalisés. 

### Etendre l'API Validation

Etendre l'API Validation est plus adapté pour les cas où votre valideur personnalisé sera utilisé dans plus d'un objet `Content`. Dans cette section, nous allons vous guider à travers les étapes nécessaires à la création d'un valideur personnalisé qui devra valider des codes postaux. 

Commencez par créer un nouveau type représentant les résultats de validation de `ZipCode`. Cette struct aura la responsabilité de nous indiquer si une chaîne donnée est un code postal valide.

```swift
extension ValidatorResults {
    /// Représente le résultat d'un valideur qui vérifie si une chaîne est un code postal valide.
    public struct ZipCode {
        /// Indique si la valeur d'entrée est un code postal valide ou non.
        public let isValidZipCode: Bool
    }
}
```

Conformez ensuite ce type à `ValidatorResult`, qui permet de définir le comportement attendu d'un valideur personnalisé.

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

Pour finir, implémentez la logique de validation d'un code postal. Utilisez une expression régulière pour vérifier si la chaîne reçue correspond au format d'un code postal Américain.

```swift
private let zipCodeRegex: String = "^\\d{5}(?:[-\\s]\\d{4})?$"

extension Validator where T == String {
    /// Valide si un type `String` est un code postal valide.
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

Maintenant que le valideur personnalisé `zipCode` est défini, vous pouvez l'utiliser dans votre application pour valider des codes postaux. Ajoutez simplement cette ligne dans votre code de validation :

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### La règle `Custom`

La règle `Custom` est plus adaptée pour les cas où votre logique de validation ne concerne qu'une propriété d'un unique objet `Content`. Cette implémentation a les deux avantages suivants comparé à l'approche qui étend l'API Validation :

- La logique de validation personnalisée est plus simple à implémenter.
- La syntaxe est plus courte.

Dans cette section, vous allez créer un valideur personnalisé qui vérifiera si un employé fait partie de l'entreprise en se basant sur la propriété `nameAndSurname`.

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
      is: .custom("Valide si l'employé appartient à l'entreprise en vérifiant son nom et prénom.") { nameAndSurname in
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
