# Validação

A API de Validação do Vapor ajuda você a validar o body e os parâmetros de query de uma requisição recebida antes de usar a API de [Conteúdo](content.md) para decodificar dados.

## Introdução

A integração profunda do Vapor com o protocolo `Codable` do Swift, que é type-safe, significa que você não precisa se preocupar tanto com validação de dados em comparação com linguagens de tipagem dinâmica. No entanto, ainda existem algumas razões pelas quais você pode querer optar pela validação explícita usando a API de Validação.

### Erros Legíveis

Decodificar structs usando a API de [Conteúdo](content.md) produzirá erros se algum dos dados não for válido. No entanto, essas mensagens de erro podem às vezes não ser muito legíveis para humanos. Por exemplo, considere o seguinte enum baseado em string:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Se um usuário tentar passar a string `"purple"` para uma propriedade do tipo `Color`, ele receberá um erro semelhante ao seguinte:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Embora este erro esteja tecnicamente correto e tenha protegido o endpoint de um valor inválido com sucesso, ele poderia informar melhor o usuário sobre o erro e quais opções estão disponíveis. Usando a API de Validação, você pode gerar erros como o seguinte:

```
favoriteColor is not red, blue, or green
```

Além disso, `Codable` parará de tentar decodificar um tipo assim que o primeiro erro for encontrado. Isso significa que mesmo se houver muitas propriedades inválidas na requisição, o usuário verá apenas o primeiro erro. A API de Validação reportará todas as falhas de validação em uma única requisição.

### Validação Específica

`Codable` lida bem com validação de tipos, mas às vezes você quer mais do que isso. Por exemplo, validar o conteúdo de uma string ou validar o tamanho de um inteiro. A API de Validação possui validadores para ajudar a validar dados como emails, conjuntos de caracteres, intervalos de inteiros e mais.

## Validatable

Para validar uma requisição, você precisará gerar uma coleção de `Validations`. Isso é mais comumente feito conformando um tipo existente a `Validatable`.

Vamos ver como você poderia adicionar validação a este endpoint simples `POST /users`. Este guia assume que você já está familiarizado com a API de [Conteúdo](content.md).

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
    // Faz algo com o usuário.
    return user
}
```

### Adicionando Validações

O primeiro passo é conformar o tipo que você está decodificando, neste caso `CreateUser`, a `Validatable`. Isso pode ser feito em uma extensão.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // As validações vão aqui.
    }
}
```

O método estático `validations(_:)` será chamado quando `CreateUser` for validado. Quaisquer validações que você queira realizar devem ser adicionadas à coleção `Validations` fornecida. Vamos ver como adicionar uma validação simples para exigir que o email do usuário seja válido.

```swift
validations.add("email", as: String.self, is: .email)
```

O primeiro parâmetro é a chave esperada do valor, neste caso `"email"`. Isso deve corresponder ao nome da propriedade no tipo sendo validado. O segundo parâmetro, `as`, é o tipo esperado, neste caso `String`. O tipo geralmente corresponde ao tipo da propriedade, mas nem sempre. Por fim, um ou mais validadores podem ser adicionados após o terceiro parâmetro, `is`. Neste caso, estamos adicionando um único validador que verifica se o valor é um endereço de email.

### Validando Conteúdo da Requisição

Uma vez que você conformou seu tipo a `Validatable`, a função estática `validate(content:)` pode ser usada para validar o conteúdo da requisição. Adicione a seguinte linha antes de `req.content.decode(CreateUser.self)` no handler de rota.

```swift
try CreateUser.validate(content: req)
```

Agora, tente enviar a seguinte requisição contendo um email inválido:

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

Você deverá ver o seguinte erro retornado:

```
email is not a valid email address
```

### Validando Query da Requisição

Tipos em conformidade com `Validatable` também possuem `validate(query:)` que pode ser usado para validar a query string de uma requisição. Adicione as seguintes linhas ao handler de rota.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Agora, tente enviar a seguinte requisição contendo um email inválido na query string.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Você deverá ver o seguinte erro retornado:

```
email is not a valid email address
```

### Validação de Inteiros

Ótimo, agora vamos tentar adicionar uma validação para `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

A validação de idade exige que a idade seja maior ou igual a `13`. Se você tentar a mesma requisição de antes, deverá ver um novo erro agora:

```
age is less than minimum of 13, email is not a valid email address
```

### Validação de Strings

Em seguida, vamos adicionar validações para `name` e `username`.

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

A validação de nome usa o operador `!` para inverter a validação `.empty`. Isso exigirá que a string não esteja vazia.

A validação de username combina dois validadores usando `&&`. Isso exigirá que a string tenha pelo menos 3 caracteres _e_ contenha apenas caracteres alfanuméricos.

### Validação de Enum

Por fim, vamos ver uma validação um pouco mais avançada para verificar se a `favoriteColor` fornecida é válida.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Como não é possível decodificar um `Color` a partir de um valor inválido, esta validação usa `String` como tipo base. Ela usa o validador `.in` para verificar se o valor é uma opção válida: red, blue ou green. Como este valor é opcional, `required` é definido como false para sinalizar que a validação não deve falhar se esta chave estiver ausente nos dados da requisição.

Note que embora a validação de cor favorita passe se a chave estiver ausente, ela não passará se `null` for fornecido. Se você quiser suportar `null`, altere o tipo de validação para `String?` e use a conveniência `.nil ||` (leia como: "é nil ou ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Erros Personalizados

Você pode querer adicionar erros personalizados legíveis às suas `Validations` ou `Validator`. Para isso, simplesmente forneça o parâmetro adicional `customFailureDescription` que substituirá o erro padrão.

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


## Validadores

Abaixo está uma lista dos validadores atualmente suportados e uma breve explicação do que eles fazem.

|Validação|Descrição|
|-|-|
|`.ascii`|Contém apenas caracteres ASCII.|
|`.alphanumeric`|Contém apenas caracteres alfanuméricos.|
|`.characterSet(_:)`|Contém apenas caracteres do `CharacterSet` fornecido.|
|`.count(_:)`|A contagem da coleção está dentro dos limites fornecidos.|
|`.email`|Contém um email válido.|
|`.empty`|A coleção está vazia.|
|`.in(_:)`|O valor está na `Collection` fornecida.|
|`.nil`|O valor é `null`.|
|`.range(_:)`|O valor está dentro do `Range` fornecido.|
|`.url`|Contém uma URL válida.|
|`.custom(_:, validationClosure: (value) -> Bool)`|Validação personalizada, de uso pontual.|

Validadores também podem ser combinados para construir validações complexas usando operadores. Mais informações sobre o validador `.custom` em [[#Validadores Personalizados]].

|Operador|Posição|Descrição|
|-|-|-|
|`!`|prefixo|Inverte um validador, exigindo o oposto.|
|`&&`|infixo|Combina dois validadores, exige ambos.|
|`||`|infixo|Combina dois validadores, exige um.|



## Validadores Personalizados

Existem duas maneiras de criar validadores personalizados.

### Estendendo a API de Validação

Estender a API de Validação é mais adequado para casos onde você planeja usar o validador personalizado em mais de um objeto `Content`. Nesta seção, vamos guiá-lo pelos passos para criar um validador personalizado para validar códigos postais.

Primeiro, crie um novo tipo para representar os resultados da validação de `ZipCode`. Esta struct será responsável por reportar se uma determinada string é um código postal válido.

```swift
extension ValidatorResults {
    /// Representa o resultado de um validador que verifica se uma string é um código postal válido.
    public struct ZipCode {
        /// Indica se a entrada é um código postal válido.
        public let isValidZipCode: Bool
    }
}
```

Em seguida, conforme o novo tipo a `ValidatorResult`, que define o comportamento esperado de um validador personalizado.

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

Por fim, implemente a lógica de validação para códigos postais. Use uma expressão regular para verificar se a string de entrada corresponde ao formato de um código postal dos EUA.

```swift
private let zipCodeRegex: String = "^\\d{5}(?:[-\\s]\\d{4})?$"

extension Validator where T == String {
    /// Valida se uma `String` é um código postal válido.
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

Agora que você definiu o validador personalizado `zipCode`, pode usá-lo para validar códigos postais na sua aplicação. Simplesmente adicione a seguinte linha ao seu código de validação:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### Validador `Custom`

O validador `Custom` é mais adequado para casos onde você quer validar uma propriedade em apenas um objeto `Content`. Esta implementação possui as seguintes duas vantagens em comparação com estender a API de Validação:

- Mais simples de implementar lógica de validação personalizada.
- Sintaxe mais curta.

Nesta seção, vamos guiá-lo pelos passos para criar um validador personalizado para verificar se um funcionário faz parte da nossa empresa, analisando a propriedade `nameAndSurname`.

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
      is: .custom("Valida se o funcionário faz parte da empresa XYZ verificando nome e sobrenome.") { nameAndSurname in
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
