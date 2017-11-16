# JSON

Vapor doesn't recommend using a "raw" JSON API. We instead recommend using `Foundation.JSONEncoder` and `Foundation.JSONDecoder` for type-safe JSON communication.

This requires you to `import Foundation` when working with JSON.

## Login screen Example

For the purpose of a demo this example does not use [password hashing/encryption](../crypto/passwords.md) or a [database](../getting-started/databases.md).

### The raw data

First, create the models for the JSON requests, responses, errors and the underlying (internal) data structure.

```swift
/// The model, can be stored in the database
class User: Codable {
  /// The profile of this user, containing public information
  struct Profile: Codable {
    var firstName: String
    var lastName: String
  }

  var profile: Profile
  var email: String
  var password: String
}
```

The models must be formatted according to the expected input/output in JSON.

```swift
/// A Login request (input)
/// Requires an email address and a password
struct LoginRequest: Decodable {
  var email: String
  var password: String
}

/// A login response (success output)
struct LoginResponse: Encodable, ResponseRepresentable {
  var token: String

  // The profile will be encoded to JSON
  var user: User.Profile
}

/// A login error (unsuccessful output)
struct LoginError: Encodable, ResponseRepresentable {
  // The reason will be represented in JSON as a `String`
  enum Reason: String, Encodable {
    case invalidCredentials
    case accountSuspended
  }

  var reason: Reason
}
```

### Decoding the Request

[`Request`](../http/request.md) has a [Body](../http/body.md) that will need to be decoded using Foundation's `JSONDecoder`.

```swift
let loginRequest = try JSONDecoder().decode(LoginRequest.self, from: request.body.data)
```

The result is a type-safe instantiation of the login request.

```json
{
  "email": "test@example.com",
  "password": "hunter2"
}
```

Decoding the above using the `JSONDecoder` will result in the following `loginRequest`.

```swift
print(loginRequest.email) // prints "test@example.com"
print(loginRequest.password) // prints "hunter2"
```

## Encoding an (error) response

First you need to instantiate your `ResponseRepresentable` response.

Returning this from a `Route` will convert it to a [`Response`](../http/response.md) automatically.

```swift
return LoginError(reason: .invalidCredentials)
```
