---
currentMenu: auth-user
---

# Auth

Authorization and authentication is focused around a the `Auth.User` protocol. Authorization is analagous with asking: "Who is this?", while authentication is analagous with asking: "What can they do?". Vapor includes an extensible authorization system that you can use as a base for more sophisticated authentication.

## User Protocol

Any type can conform to the `Auth.User` protocol, but they are commonly added onto Fluent `Model`s.

```swift
import Vapor
import Auth

final class User: Model, Auth.User {
    var id: Node?
    var name: String

	...

    static func authenticate(credentials: Credentials) throws -> Auth.User {

    }

    static func register(credentials: Credentials) throws -> Auth.User {

    }
}
```

Here is an example `User` class with the `Auth.User` protocol requirements stubbed. Note that the name of our class and the protocol are the same. This is why we use the `Auth.` prefix to differentiate the protocol from the `Auth` module from our `User` class.

### Authenticate

#### Credentials

The credentials protocol is an empty protocol that any type can conform to. This gives great flexibility to your authorization model, but also requires that you properly handle the case of unsupported credential types.

#### AccessToken

One of the simplest credential types included is `AccessToken`. It carries a `String` based token that will be used to authenticate the user.

Let's look at how we might support the access token type.

```swift
static func authenticate(credentials: Credentials) throws -> Auth.User {
	if let accessToken = credentials as? AccessToken {
		guard let user = try User.query().filter("access_token", accessToken.string).first() else {
			throw Abort.custom(status: .forbidden, message: "Invalid access token.")	
		}

		return user
	} else {
		let type = type(of: credentials)
		throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
	}
}
```

The first step is to cast the credentials to the type we want to support--in this case, `AccessToken`. If we do not have an access token, we will inform the client that the credentials are invalid.

Once we have the access token, we will use it to query the `User` model for an entry with a matching access token. This is assuming the `users` table or collection has the access tokens stored on it. You may opt to store them somewhere else.

Once we have found the user associated with the supplied access token, we simply return it.

#### Identifier

Vapor uses the `Identifier` credential type internally to lookup users from sessions. You can read more in the [Request](request.md) section.

### Register

Similar to the authenticate method, the register method takes credentials. But instead of fetching the user from the data store, it provides a convenient way to create the user. You are not required to register your users through this method.
