# Cookies

Cookies are used to store data on the client-side between multiple requests. They're often used for keeping track of a user for various reasons. One of the more important purposes is to store a session cookie containing identification of an account.

## Creating cookies

Vapor has three related objects for Cookies.

The `Cookies` object is an array of multiple Cookie objects.

The `Cookie` object is a single key-value pair. Where the key is the Cookie name.

The `Value` object contains a String representing the Cookie's Value and optional attributes with metadata such as the expiration date of the Cookie.

### Values

Values can be initialized with a String Literal.

```swift
var value: Cookie.Value = "String Literal"
```

They can be manipulated to add other properties.

```swift
// Expires in one day
value.expires = Date().addingTimeInterval(24 * 3600)
```

### A single Cookie

Creating a `Cookie` requires a name and a Value.

```swift
let cookie = Cookie(named: "session", value: value)
```

### Multiple cookies

`Cookies` can be initialized with a dictionary literal.

```swift
let cookies: Cookies = [
  "session": "String Literal"
]
```

The above will create a single cookie named "session" with a value of "String Literal".
