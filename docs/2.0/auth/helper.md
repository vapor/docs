# Auth Helper

The Auth package adds a convenience property on every request that makes it 
easy to authenticate, persist, and unauthenticate users.


## Authentication

### Checking

You can get the currently authenticated user.

```swift
let user = req.auth.authenticated(User.self)
```

You can check to see if the user is authenticated.

```swift
if req.auth.isAuthenticated(User.self) {
    ...	
}
```

You can also assert that the user is authenticated.

```swift
let user = try req.auth.assertAuthenticated(User.self)

```

!!! note:
	A 403 Forbidden error will be thrown if the user is not authenticated.

### Manual

You can manually authenticate a user.

```swift
if let user = try User.find(1) {
	req.auth.authenticate(user)	
}
```

You can also unauthenticate the currently authenticated user.


```swift
try req.auth.unauthenticate()
```

!!! note:
	If the user is `Persistable`, they will also be unpersisted.


## Headers

The helper can be used to access common authorization headers.

```swift
print(req.auth.header)
```

### Token

The header has additional conveniences for parsing out bearer tokens.

```swift
print(req.auth.header?.bearer)
```

!!! tip
	You can use `_authorizationBasic` and `_authorizationBearer` to send tokens in the URL string.

### Password

And basic auth username + password.

```swift
print(req.auth.header?.basic)
```