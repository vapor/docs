---
currentMenu: auth-request
---

# Request

The `auth` property on `Request` let's you authenticate users and also provides some convenience methods for accessing common authorization headers.

## Authorization

The authorization header is a great place to send credentials from a client. 

```
Authorization: xxxxxxxxxx
```

You can access the authorization header through `req.auth.header`. Two common patterns are basic and bearer.

### Basic

Basic authorization consists of a username and password concatenated into a string and base64 encoded.

```
Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l
```

Here is what an example header looks like. You can read more about basic auth on [wikipedia](https://en.wikipedia.org/wiki/Basic_access_authentication).

```swift
guard let credentials = req.auth.header?.basic else {
    throw Abort.badRequest
}
```

The basic header returns an `APIKey` credential.

```
class APIKey: Credentials {
	let id: String
	let secret: String
}
```

### Bearer

Another common method is bearer which consists of a single API key.

```
Authorization: Bearer apikey123
```

It is accessed similarly to the basic header and returns an `AccessToken` credential.

```
class AccessToken: Credentials {
	let string: String
}
```

### Raw

To access the raw authorization header, use `req.auth.header?.header`.

## Credentials

Both Basic and Bearer return something that conforms to `Credentials`. You can always create a custom `Credentials` object for authorization by conforming your own class to `Credentials` or by manually creating an `APIKey` or `AccessToken`.

```swift
let key = AccessToken(string: "apikey123")
```

### Form

You can also create credentials from form or JSON data.

```swift
guard 
	let username = req.data["username"]?.string,
	let password = req.data["password"]?.string
else {
	throw Abort.badRequest
}

let key = APIKey(id: username, secret: password)
```

## Login

Once you have some object that conforms to `Credentials`, you can try to login the user.

```swift
try req.auth.login(credentials)
```

If this call succeeds, the user is logged in and a session has been started. They will stay logged in as long as their cookie is valid.

### Authenticate

Logging in calls the `authenticate` method on the `Realm`. If you have simply passed an `Auth.User` conformer to the `AuthMiddleware`, then this will call the `authenticate` method on that type.

The method will be passed whichever credentials you are trying to login with, so make sure you add support for all the credential types you may want to use on your `Auth.User`.

### Identifier

One important credential type is the `Identifier` type. This is used by Vapor when fetching the `User` object from the authorization cookie. It is also a convenient way to log a user in manually.

```swift
static func authenticate(credentials: Credentials) throws -> Auth.User {
	if ... {
		...
	} else if let id = credentials as? Identifier {
		guard let user = try User.find(id.id) else {
			throw Abort.custom(status: .badRequest, message: "Invalid identifier.")
		}

		return user
	} else {
		...
	}
}
```

Adding the `Identifier` case for `Credentials` is easy, just look up the user by the identifier.

```swift
let id = Identifier(id: 42)
try req.auth.log(id)
```

Now you can manually log users in with just their identifiers.

### Ephemeral

If you just want to log the user in for a single request, disable persistance. 

```swift
req.auth.login(credentials, persist: false)
```

## User

By default, `request.auth.user()` returns the authorized `Auth.User`. This will need to be casted to your internal user type if you want to access its values.

Adding a convenience method on `Request` is a great way to simplify this.

```swift
extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }

        return user
    }
}
```

Now you can get access to your `User` type with `try req.user()`.
