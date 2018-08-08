# Validation Overview

Validation is a framework for validating data sent to your application. It can help validate things like names, emails and more. It is also extensible, allowing you to easily create custom validators.

## Swift & Codable

Swift's strong type system and `Codable` take care of most of the basic validation that web apps need to do. 

```swift
struct User: Codable {
    var id: UUID?
    var name: String
    var age: Int
    var email: String?
    var profilePictureURL: String?
}
```

For example, when you decode the above `User` model, Swift will automatically ensure the following:

  - `id` is a valid `UUID` or is `nil`.
  - `name` is a valid `String` and is _not_ `nil`.
  - `age` is a valid `Int` and is _not_ `nil`.
  - `email` is a valid `String` or is `nil`.
  - `profilePictureURL` is a valid `String` or is `nil`.

This is a great first step, but there is still room for improvement here. Here are some examples of things Swift and `Codable` would not mind, but are not ideal:

  - `name` is empty string `""`
  - `name` contains non-alphanumeric characters
  - `age` is a negative number `-42`
  - `email` is not correctly formatted `test@@vapor.codes`
  - `profilePictureURL` is not a `URL` without a scheme

Luckily the Validation package can help.

## Validatable

Let's take a look at how the Validation package can help you validate incoming data. We'll start by conforming our `User` model from the previous section to the [`Validatable`](https://api.vapor.codes/validation/latest/Validation/Protocols/Validatable.html) protocol. 

!!! note
    This assumes `User` already conforms to `Reflectable` (added by default when using one of Fluent's `Model` protocols). If not, you will need to add conformance to `Reflectable` manually.

```swift
extension User: Validatable {
     /// See `Validatable`.
     static func validations() -> Validations<User> {
         // define validations
     }
}

let user = User(...)
// since User conforms to Validatable, we get a new method validate()
// that throws an error if any validations fail
try user.validate() 
```

This is the basic structure of [`Validatable`](https://api.vapor.codes/validation/latest/Validation/Protocols/Validatable.html) conformance. Let's take a look at how we can implement the static `validations()` method.

## Validations

First let's start by verifying that the name is at least 3 characters long.

```swift
extension User: Validatable {
    /// See `Validatable`.
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(3...))
        return validations
    }
}
```

The `count(...)` validation accepts Swift [`Range`](https://developer.apple.com/documentation/swift/range) notation and will validate that a collection's count is within that range. By only placing a value on the left side of `...`, we only set a minimum range.

Take a look at all of the available validators [here](https://api.vapor.codes/validation/latest/Validation/Structs/Validator.html).

### Operators

Validating that the name is three or more characters is great, but we also want to make sure that the name is alphanumeric characters only. We can do this by combining multiple validators using `&&`.

```swift
try validations.add(\.name, .count(3...) && .alphanumeric)
```

Now our name will only be considered valid if it is three or more characters _and_ alphanumeric. Take a look at all of the available operators [here](https://api.vapor.codes/validation/latest/Validation/Functions.html).

### Nil

You may want to run validations on optionals only if a value is present. The `&&` and `||` operators have special overloads that help you do this. 

```swift
try validations.add(\.email, .email || .nil)
```

The [`nil`](https://api.vapor.codes/validation/latest/Validation/Structs/Validator.html#/s:10Validation9ValidatorV3nilXevZ) validator checks if a `T?` optional value is `nil`.

The [`email`](https://api.vapor.codes/validation/latest/Validation/Structs/Validator.html#/s:10Validation9ValidatorVAASSRszlE5emailACySSGvZ) validator checks if a `String` is a valid email address. However, the property on our `User` is a `String?`. This means the email validator cannot be used directly with the property.

We can combine these two operators using `||` to express the validation we want: validate the email is correctly formatted if it is not nil.

## Validate

Let's finish up the rest of our validations using our new knowledge.

```swift
extension User: Validatable {
    /// See `Validatable`.
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .alphanumeric && .count(3...))
        try validations.add(\.age, .range(18...))
        try validations.add(\.email, .email || .nil)
        try validations.add(\.profilePictureURL, .url || .nil)
        return validations
    }
}
```

Now let's try out validating our model.

```swift
router.post(User.self, at: "users") { req, user -> User in
    try user.validate()
    return user
}
```

When you query that route, you should see that errors are thrown if the data does not meet your validations. If the data is correct, your user model is returned successfully.

Congratulations on setting up your first `Validatable` model! Check out the [API docs](https://api.vapor.codes/validation/latest/Validation/index.html) for more information and code samples.
