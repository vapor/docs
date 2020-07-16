# Validation

Vapor's Validation API helps you validate incoming request before using the [Content](content.md) API to decode data. 

## Introduction 

Vapor's deep integration of Swift's type-safe `Codable` protocol means you don't need to worry about data validation as much compared to dynamically typed languages. However, there are still a few reasons why you might want to opt-in to explicit validation using the Validation API.

### Human-Readable Errors

Decoding structs using the [Content](content.md) API will yield errors if any of the data is not valid. However, these error messages can sometimes lack human-readability. For example, take the following string-backed enum:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

If a user tries to pass the string `"purple"` to a property of type `Color`, they will get an error similar to the following:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

While this error is technically correct and successfully protected the endpoint from an invalid value, it could do better informing the user about the mistake and which options are available. By using the Validation API, you can generate errors like the following:

```
favoriteColor is not red, blue, or green
```

Furthermore, `Codable` will stop attempting to decode a type as soon as the first error is hit. This means that even if there are many invalid properties in the request, the user will only see the first error. The Validation API will report all validation failures in a single request.

### Specific Validation

`Codable` handles type validation well, but sometimes you want more than that. For example, validating the contents of a string or validating the size of an integer. The Validation API has validators for helping to validate data like emails, character sets, integer ranges, and more.

## Validatable

To validate a request, you will need to generate a `Validations` collection. This is most commonly done by conforming an existing type to `Validatable`. 

Let's take a look at how you could add validation to this simple `POST /users` endpoint. This guide assumes you are already familiar with the [Content](content.md) API.

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

### Adding Validations

The first step is to conform the type you are decoding, in this case `CreateUser`, to `Validatable`. This can be done in an extension.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

The static method `validations(_:)` will be called when `CreateUser` is validated. Any validations you want to perform should be added to the supplied `Validations` collection. Let's take a look at adding a simple validation to require that the user's email is valid.

```swift
validations.add("email", as: String.self, is: .email)
```

The first parameter is the value's expected key, in this case `"email"`. This should match the property name on the type being validated. The second parameter, `as`, is the expected type, in this case `String`. The type usually matches the property's type, but not always. Finally, one or more validators can be added after the third parameter, `is`. In this case, we are adding a single validator that checks if the value is an email address.

### Validating Request Content

Once you've conformed your type to `Validatable`, the static `validate(content:)` function can be used to validate request content. Add the following line before `req.content.decode(CreateUser.self)` in the route handler.

```swift
try CreateUser.validate(content: req)
```

Now, try sending the following request containing an invalid email:

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

You should see the following error returned:

```
email is not a valid email address
```

### Validating Request Query

Types conforming to `Validatable` also have `validate(query:)` which can be used to validate a request's query string. Add the following lines to the route handler.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Now, try sending the following request containing an invalid email in the query string.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

You should see the following error returned:

```
email is not a valid email address
```

### Integer Validation

Great, now let's try adding a validation for `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

The age validation requires that the age is greater than or equal to `13`. If you try the same request from above, you should see a new error now:

```
age is less than minimum of 13, email is not a valid email address
```

### String Validation

Next, let's add validations for `name` and `username`. 

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

The name validation uses the `!` operator to invert the `.empty` validation. This will require that the string is not empty.

The username validation combines two validators using `&&`. This will require that the string is at least 3 characters long _and_ contains only alphanumeric characters.

### Enum Validation

Finally, let's take a look at a slightly more advanced validation to check that the supplied `favoriteColor` is valid.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Since it's not possible to decode a `Color` from an invalid value, this validation uses `String` as the base type. It uses the `.in` validator to verify that the value is a valid option: red, blue, or green. Since this value is optional, `required` is set to false to signal that validation should not fail if this key is missing from the request data.

Note that while the favorite color validation will pass if the key is missing, it will not pass if `null` is supplied. If you want to support `null`, change the validation type to `String?` and use the `.nil ||` (read as: "is nil or ...") convenience.

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```


## Validators

Below is a list of the currently supported validators and a brief explanation of what they do.

|Validation|Description|
|-|-|
|`.ascii`|Contains only ASCII characters.|
|`.alphanumeric`|Contains only alphanumeric characters.|
|`.characterSet(_:)`|Contains only characters from supplied `CharacterSet`.|
|`.count(_:)`|Collection's count is within supplied bounds.|
|`.email`|Contains a valid email.|
|`.empty`|Collection is empty.|
|`.in(_:)`|Value is in supplied `Collection`.|
|`.nil`|Value is `null`.|
|`.range(_:)`|Value is within supplied `Range`.|
|`.url`|Contains a valid URL.|

Validators can also be combined to build complex validations using operators. 

|Operator|Position|Description|
|-|-|-|
|`!`|prefix|Inverts a validator, requiring the opposite.|
|`&&`|infix|Combines two validators, requires both.|
|`||`|infix|Combines two validators, requires one.|
