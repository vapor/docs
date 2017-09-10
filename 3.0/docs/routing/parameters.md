# Parameters

Parameters are a registered type that can be initialized from a String.

They can be part of a [Route](route.md), and be extracted from [Requests](../http/request.md) that are called in that Route.

## Creating custom parameters

To create a custom parameter type, simply conform to `Parameter` and implement the conversion function `make` and a unique slug.

In this example, the `User` class will be initialized from a parameter that represents it's identifier.

```swift
class User : Parameter {
  static var uniqueSlug = "my-app:user"

  static func make(for parameter: String, in request: Request) throws -> User {
    // Fetches the user from MySQL
    let user =
  }
}
```

TODO!!!
