# Message authentication

For message authentication, Vapor only supports HMAC.

## Using HMAC

To use HMAC you first need to select the used hashing algorithm for authentication. This works using generics.

```swift
let hash = HMAC<SHA224>.authenticate(message, withKey: authenticationKey)
```
