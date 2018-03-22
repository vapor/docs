# Parameters

Parameters are a registered type that can be initialized from a String.

They can be part of a [Route](route.md), and be extracted from requests that are called in that route.

## Creating custom parameters

To create a custom parameter type, simply conform to `Parameter` and implement the conversion function `make` and a unique slug.

In this example, the `User` class will be initialized from a parameter that represents its identifier.

We recommend prefixing custom Parameter identifiers.

```swift
class User : Parameter {
  var username: String

  // The unique (prefixed) identifier for this type
  static var uniqueSlug = "my-app:user"

  // Creates a new user from the raw `parameter`
  static func make(for parameter: String, in request: Request) throws -> User {
    return User(named: parameter)
  }

  init(named username: String) {
    self.username = username
  }
}
```

## Using (custom) parameters

After conforming a type to `Parameter` you can access its static property `parameter` as part of a path.

```swift
router.on(.get, to: "users", User.parameter, "profile") { request in
  let user = try request.parameter(User.self)

  // Return the user's Profile sync or async (depending on the router)
}
```
