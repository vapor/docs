# Request

The most common part of the `HTTP` library we'll be interacting with is the `Request` type. Here's a look at some of the most commonly used attributes in this type.

```swift
public var method: Method
public var uri: URI
public var parameters: Node
public var headers: [HeaderKey: String]
public var body: Body
public var data: Content
```

### Method

The HTTP `Method` associated with the `Request`, ie: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`.

### URI

The associated `URI` of the request. We will use this to access attributes about the `uri` the request was sent to.

For example, given the following uri: `http://vapor.codes/example?query=hi#fragments-too`

```swift
let scheme = request.uri.scheme // http
let host = request.uri.host // vapor.codes

let path = request.uri.path // /example
let query = request.uri.query // query=hi
let fragment = request.uri.fragment // fragments-too
```

### Route Parameters

The url parameters associated with the request. For example, if we have a path registered as `hello/:name/age/:age`, we would be able to access those in our request, like so:

```swift
let name = request.parameters["name"] // String?
let age = request.parameters["age"]?.int // Int?
```

Or, to automatically throw on `nil` or invalid variable, you can also `extract`

```swift
let name = try request.parameters.extract("name") as String
let age = try request.parameters.extract("age") as Int
```

These extract functions can cast to any `NodeInitializable` type, including your own custom types. Make sure to check out [Node](https://github.com/vapor/node) for more info.

> Note: Vapor also provides type safe routing in the routing section of our docs.


### Headers

These are the headers associated with the request. If you are preparing an outgoing request, this can be used to add your own keys.

```swift
let contentType = request.headers["Content-Type"]  
```

Or for outgoing requests:

```swift
let request = Request ...
request.headers["Content-Type"] = "application/json"
request.headers["Authorization"] = ... my auth token
```

#### Extending Headers

We generally seek to improve code bases by removing stringly typed code where possible. We can add variables to the headers using generic extensions.

```swift
extension HTTP.KeyAccessible where Key == HeaderKey, Value == String {
    var customKey: String? {
      get {
        return self["Custom-Key"]
      }
      set {
        self["Custom-Key"] = newValue
      }
    }
}
```

With this pattern implemented, our string `"Custom-Key"` is contained in one section of our code. We can now access like this:

```swift
let customKey = request.headers.customKey

// or

let request = ...
request.headers.customKey = "my custom value"
```

### Body

This is the body associated with the request and represents the general data payload. You can view more about body in the associated [docs](./body.md)

For incoming requests, we'll often pull out the associated bytes like so:

```swift
let rawBytes = request.body.bytes
```

## Content

Generally when we're sending or receiving requests, we're using them as a way to transport content. For this, Vapor provides a convenient `data` variable associated with the request that prioritizes content in a consistent way.

For example, say I receive a request to `http://vapor.codes?hello=world`.

```swift
let world = request.data["hello"]?.string
```

This same code will work if I receive a JSON request, for example:

```json
{
  "hello": "world"
}
```

Will still be accessible through data.

```swift
let world = request.data["hello"]?.string
```
> Note: Force unwrap should never be used.

This also applies to multi-part requests and can even be extended to new types such as XML or YAML through middleware.

If you'd prefer to access given types more explicitly, that's totally fine. The `data` variable is purely opt-in convenience for those who want it.

## Form Data

It is common in many applications to receive forms submitted from a Web browser. Vapor provides support for several common encodings:

```swift
// Node? from application/x-www-form-urlencoded
let formData = request.formURLEncoded

// [String:Field]? from multipart/form-data
let multipartFormData = request.formData

// [Part]? from multipart/mixed
let multipartMixedData = request.multipart
```

These accessors will return `nil` if the request's `Content-Type` does not match what they expect.

## JSON

To access JSON directly on a given request, use the following:

```swift
let json = request.json["hello"]
```

## Query Parameters

The same applies to query convenience:

```swift
let query = request.query?["hello"]  // String?
let name = request.query?["name"]?.string // String?
let age = request.query?["age"]?.int // Int?
let rating = request.query?["rating"]?.double // Double?
```

## Key Paths

Key paths work on most Vapor types that can have nested key value objects. Here's a couple examples of how to access given the following json:

```json
{
  "metadata": "some metadata",
  "artists" : {
    "href": "http://someurl.com",
    "items": [
      {
        "name": "Van Gogh",
      },
      {
        "name": "Mozart"
      }
    ]
  }
}
```

We could access the data in the following ways:

### Metadata

Access top level values

```swift
let type = request.data["metadata"].string // "some metadata"
```

### Items

Access nested values

```swift
let items = request.data["artists", "items"] // [["name": "Van Gogh"], ["name": "Mozart"]]
```

### Mixing Arrays and Objects

Get first artists

```swift
let first = request.data["artists", "items", 0] // ["name": "Van Gogh"]
```

### Array Item

Get key from array item

```swift
let firstName = request.data["artists", "items", 0, "name"] // "Van Gogh"
```

### Array Comprehension

We can also smartly map an array of keys, for example, to just get the names of all of the artists, we could use the following

```swift
let names = request.data["artists", "items", "name"] // ["Van Gogh", "Mozart"]
```
