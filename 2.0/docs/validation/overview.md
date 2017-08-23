!!! error "Work in Progress"
    The subject of this page is Work in Progress and is not recommended for Production use.

!!! error "Outdated"
    This page contains outdated information.

# Validation

Vapor provides a few different ways to validate data coming into your application. Let's start by looking at the most common.

## Common Usage

Several useful convenience validators are included by default. You can use these to validate data coming into your application, or combine them and create your own.

Let's look at the most common way to validate data.

```swift
class Employee {
    var email: Valid<Email>
    var name: Valid<Name>

    init(request: Request) throws {
        name = try request.data["name"].validated()
        email = try request.data["email"].validated()
    }
}
```

Here we have a typical Employee model with an `email` and `name` property. By declaring both of these properties as `Valid<>`, you are ensuring that these properties can only ever contain valid data. The Swift type checking system will prevent anything that does not pass validation from being stored.

To store something in a `Valid<>` property, you must use the `.validated()` method. This is available for any data returned by `request.data`.

`Email` is a real `validator` included with Vapor, but `Name` is not. Let's take a look at how you can create a Validator.

```swift
Valid<OnlyAlphanumeric>
Valid<Email>
Valid<Unique<T>>
Valid<Matches<T>>
Valid<In<T>>
Valid<Contains<T>>
Valid<Count<T>>
```

## Validators vs. ValidationSuites

Validators, like `Count` or `Contains` can have multiple configurations. For example:

```swift
let name: Valid<Count<String>> = try "Vapor".validated(by: Count.max(5))
```

Here we are validating that the `String` is at most 5 characters long. The type of `Valid<Count>` tells us that the string has been validated to be a certain count, but it does not tell us exactly what that count was. The string could have been validated to be less than three characters or more than one million.

Because of this, `Validators` themselves are not as type safe as some applications might desire. `ValidationSuites` fix this. They combine multiple `Validators` and/or `ValidationSuites` together to represent exactly what type of data should be considered valid.

## Custom Validator

Here is how to create a custom `ValidationSuite`.

```swift
class Name: ValidationSuite {
    static func validate(input value: String) throws {
        let evaluation = OnlyAlphanumeric.self
            && Count.min(5)
            && Count.max(20)

        try evaluation.validate(input: value)
    }
}
```

You only have to implement one method. In this method, use any other validators or logic to create your custom validator. Here we are defining a `Name` as only accepting alphanumeric Strings that are between 5 and 20 characters.

Now we can be sure that anything of type `Valid<Name>` follows these rules.

## Combining Validators

In the `Name` validator, you can see that `&&` is being used to combine validators. You can use `&&` as well as `||` to combine any validator as you would boolean values with an `if` statement.

You can also use `!` to invert the validator.

```swift
let symbols = input.validated(by: !OnlyAlphanumeric.self)
```

## Testing Validity

While `validated() throw` is the most common method for validating, there are two others.

```swift
let passed = input.passes(Count.min(5))
let valid = try input.tested(Count.min(5))
```

`passes()` returns a boolean indicating whether or not the test passed. `tested()` will throw if the validation does not pass. But unlike `validated()` which returns a `Valid<>` type, `tested()` returns the original type of the item it was called on.

## Validation Failures

Vapor will automatically catch validation failures in the `ValidationMiddleware`. But you can catch them on your own, or customize responses for certain types of failures.

```swift
do {
    //validation here
} catch let error as ValidationErrorProtocol {
    print(error.message)
}
```
