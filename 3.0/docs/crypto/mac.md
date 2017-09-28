# Message authentication

Message authentication is used for verifying message authenticity and validity.

Common use cases are JSON Web Tokens.

For message authentication, Vapor only supports HMAC.

## Using HMAC

To use HMAC you first need to select the used hashing algorithm for authentication. This works using generics.

```swift
let hash = HMAC<SHA224>.authenticate(message, withKey: authenticationKey)
```
