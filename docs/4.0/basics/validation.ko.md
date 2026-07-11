# 유효성 검사(Validation)

Vapor의 Validation API는 [Content](content.md) API를 사용하여 데이터를 디코딩하기 전에, 들어오는 요청의 본문(body)과 쿼리 파라미터의 유효성을 검사하는 데 도움을 줍니다.

## 소개

Vapor는 Swift의 타입 안전(type-safe) `Codable` 프로토콜과 깊이 통합되어 있기 때문에, 동적 타입 언어에 비해 데이터 유효성 검사에 대해 크게 걱정할 필요가 없습니다. 그러나 여전히 Validation API를 사용하여 명시적인 유효성 검사를 선택하고 싶은 몇 가지 이유가 있습니다.

### 사람이 읽기 쉬운 에러(Human-Readable Errors)

[Content](content.md) API를 사용하여 구조체를 디코딩할 때, 데이터가 유효하지 않으면 에러가 발생합니다. 하지만 이러한 에러 메시지는 때때로 사람이 읽기에 부족할 수 있습니다. 예를 들어 다음과 같은 문자열 기반 열거형(enum)을 살펴보겠습니다.

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

사용자가 `Color` 타입의 프로퍼티에 `"purple"`이라는 문자열을 전달하려고 하면, 다음과 같은 에러가 발생합니다.

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

이 에러는 기술적으로는 정확하며 엔드포인트를 잘못된 값으로부터 성공적으로 보호했지만, 사용자에게 실수와 사용 가능한 옵션에 대해 더 잘 알려줄 수 있습니다. Validation API를 사용하면 다음과 같은 에러를 생성할 수 있습니다.

```
favoriteColor is not red, blue, or green
```

또한 `Codable`은 첫 번째 에러가 발생하는 즉시 타입 디코딩 시도를 중단합니다. 즉, 요청에 유효하지 않은 프로퍼티가 여러 개 있더라도 사용자는 첫 번째 에러만 보게 됩니다. Validation API는 하나의 요청에서 발생하는 모든 유효성 검사 실패를 보고합니다.

### 구체적인 유효성 검사(Specific Validation)

`Codable`은 타입 유효성 검사를 잘 처리하지만, 때로는 그 이상이 필요할 때가 있습니다. 예를 들어 문자열의 내용을 검증하거나 정수의 크기를 검증하는 경우입니다. Validation API에는 이메일, 문자 집합, 정수 범위 등과 같은 데이터의 유효성을 검사하는 데 도움이 되는 검증기(validator)들이 있습니다.

## Validatable

요청의 유효성을 검사하려면 `Validations` 컬렉션을 생성해야 합니다. 이는 일반적으로 기존 타입을 `Validatable`에 준수시키는 방식으로 이루어집니다.

간단한 `POST /users` 엔드포인트에 유효성 검사를 추가하는 방법을 살펴보겠습니다. 이 가이드는 여러분이 이미 [Content](content.md) API에 익숙하다고 가정합니다.

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

### 유효성 검사 추가하기

첫 번째 단계는 디코딩하려는 타입, 이 경우 `CreateUser`를 `Validatable`에 준수시키는 것입니다. 이는 확장(extension)에서 수행할 수 있습니다.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

`CreateUser`의 유효성이 검사될 때 정적 메서드 `validations(_:)`가 호출됩니다. 수행하려는 유효성 검사는 제공된 `Validations` 컬렉션에 추가해야 합니다. 사용자의 이메일이 유효한지 요구하는 간단한 유효성 검사를 추가하는 방법을 살펴보겠습니다.

```swift
validations.add("email", as: String.self, is: .email)
```

첫 번째 매개변수는 값의 예상 키로, 이 경우 `"email"`입니다. 이는 유효성 검사 대상 타입의 프로퍼티 이름과 일치해야 합니다. 두 번째 매개변수인 `as`는 예상 타입으로, 이 경우 `String`입니다. 이 타입은 일반적으로 프로퍼티의 타입과 일치하지만, 항상 그런 것은 아닙니다. 마지막으로 세 번째 매개변수인 `is` 다음에 하나 이상의 검증기를 추가할 수 있습니다. 이 경우, 값이 이메일 주소인지 확인하는 단일 검증기를 추가하고 있습니다.

### 요청 본문(Content) 검증하기

타입을 `Validatable`에 준수시켰다면, 정적 메서드 `validate(content:)`를 사용하여 요청 본문의 유효성을 검사할 수 있습니다. 라우트 핸들러의 `req.content.decode(CreateUser.self)` 앞에 다음 줄을 추가하세요.

```swift
try CreateUser.validate(content: req)
```

이제 유효하지 않은 이메일을 포함한 다음 요청을 보내보세요.

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

다음과 같은 에러가 반환되는 것을 확인할 수 있습니다.

```
email is not a valid email address
```

### 요청 쿼리(Query) 검증하기

`Validatable`을 준수하는 타입에는 요청의 쿼리 문자열의 유효성을 검사하는 데 사용할 수 있는 `validate(query:)`도 있습니다. 라우트 핸들러에 다음 줄을 추가하세요.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

이제 쿼리 문자열에 유효하지 않은 이메일을 포함한 다음 요청을 보내보세요.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

다음과 같은 에러가 반환되는 것을 확인할 수 있습니다.

```
email is not a valid email address
```

### 정수 유효성 검사(Integer Validation)

좋습니다. 이제 `age`에 대한 유효성 검사를 추가해 보겠습니다.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

age 유효성 검사는 age가 `13` 이상이어야 함을 요구합니다. 위와 동일한 요청을 시도하면, 이제 새로운 에러가 나타나는 것을 확인할 수 있습니다.

```
age is less than minimum of 13, email is not a valid email address
```

### 문자열 유효성 검사(String Validation)

다음으로 `name`과 `username`에 대한 유효성 검사를 추가해 보겠습니다.

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

name 유효성 검사는 `!` 연산자를 사용하여 `.empty` 검증을 반전시킵니다. 이는 문자열이 비어 있지 않아야 함을 요구합니다.

username 유효성 검사는 `&&`를 사용하여 두 검증기를 결합합니다. 이는 문자열이 최소 3자 이상이어야 하고 _동시에_ 영숫자 문자만 포함해야 함을 요구합니다.

### 열거형 유효성 검사(Enum Validation)

마지막으로 제공된 `favoriteColor`가 유효한지 확인하는 조금 더 고급 유효성 검사를 살펴보겠습니다.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

유효하지 않은 값으로부터 `Color`를 디코딩할 수 없기 때문에, 이 유효성 검사는 `String`을 기본 타입으로 사용합니다. `.in` 검증기를 사용하여 값이 red, blue, green 중 유효한 옵션인지 확인합니다. 이 값은 옵셔널이므로, 요청 데이터에 이 키가 없다고 해서 유효성 검사가 실패하지 않도록 `required`를 false로 설정합니다.

favoriteColor 유효성 검사는 키가 없는 경우에는 통과하지만, `null`이 제공된 경우에는 통과하지 않는다는 점에 유의하세요. `null`을 지원하고 싶다면, 유효성 검사 타입을 `String?`으로 변경하고 `.nil ||` ("nil이거나 ..."로 읽습니다) 편의 기능을 사용하세요.

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### 커스텀 에러(Custom Errors)

`Validations`나 `Validator`에 사람이 읽기 쉬운 커스텀 에러를 추가하고 싶을 수 있습니다. 이를 위해서는 기본 에러를 재정의하는 추가 매개변수 `customFailureDescription`을 제공하기만 하면 됩니다.

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


## 검증기(Validators)

아래는 현재 지원되는 검증기 목록과 각각에 대한 간단한 설명입니다.

|검증|설명|
|-|-|
|`.ascii`|ASCII 문자만 포함합니다.|
|`.alphanumeric`|영숫자 문자만 포함합니다.|
|`.characterSet(_:)`|제공된 `CharacterSet`의 문자만 포함합니다.|
|`.count(_:)`|컬렉션의 개수가 제공된 범위 내에 있습니다.|
|`.email`|유효한 이메일을 포함합니다.|
|`.empty`|컬렉션이 비어 있습니다.|
|`.in(_:)`|값이 제공된 `Collection` 내에 있습니다.|
|`.nil`|값이 `null`입니다.|
|`.range(_:)`|값이 제공된 `Range` 내에 있습니다.|
|`.url`|유효한 URL을 포함합니다.|
|`.custom(_:, validationClosure: (value) -> Bool)`|커스텀, 일회성 유효성 검사.|

검증기는 연산자를 사용하여 결합해 복잡한 유효성 검사를 구성할 수도 있습니다. `.custom` 검증기에 대한 더 자세한 내용은 [커스텀 검증기](#custom-validators)를 참고하세요.

|연산자|위치|설명|
|-|-|-|
|`!`|prefix|검증기를 반전시켜 반대 조건을 요구합니다.|
|`&&`|infix|두 검증기를 결합하여 둘 다 요구합니다.|
|`\|\|`|infix|두 검증기를 결합하여 둘 중 하나를 요구합니다.|



## 커스텀 검증기(Custom Validators)

커스텀 검증기를 만드는 방법에는 두 가지가 있습니다.

### Validation API 확장하기

Validation API를 확장하는 방식은 커스텀 검증기를 둘 이상의 `Content` 객체에서 사용할 계획인 경우에 가장 적합합니다. 이 섹션에서는 우편번호(zip code)의 유효성을 검사하는 커스텀 검증기를 만드는 단계를 살펴보겠습니다.

먼저 `ZipCode` 유효성 검사 결과를 나타내는 새로운 타입을 생성합니다. 이 구조체는 주어진 문자열이 유효한 우편번호인지 여부를 보고하는 역할을 합니다.

```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

다음으로, 새로운 타입을 커스텀 검증기에 기대되는 동작을 정의하는 `ValidatorResult`에 준수시킵니다.

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

마지막으로, 우편번호에 대한 유효성 검사 로직을 구현합니다. 정규 표현식을 사용하여 입력 문자열이 미국 우편번호 형식과 일치하는지 확인합니다.

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

이제 커스텀 `zipCode` 검증기를 정의했으므로, 애플리케이션에서 우편번호의 유효성을 검사하는 데 사용할 수 있습니다. 유효성 검사 코드에 다음 줄을 추가하기만 하면 됩니다.

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### `Custom` 검증기

`Custom` 검증기는 하나의 `Content` 객체에서만 프로퍼티의 유효성을 검사하고 싶은 경우에 가장 적합합니다. 이 구현 방식은 Validation API를 확장하는 것에 비해 다음과 같은 두 가지 장점이 있습니다.

- 커스텀 유효성 검사 로직을 구현하기가 더 간단합니다.
- 문법이 더 짧습니다.

이 섹션에서는 `nameAndSurname` 프로퍼티를 확인하여 직원이 우리 회사 소속인지 확인하는 커스텀 검증기를 만드는 단계를 살펴보겠습니다.

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
