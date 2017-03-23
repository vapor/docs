---
currentMenu: http-response
---

> Module: `import HTTP`

# Response

When building endpoints, we'll often be returning responses for requests. If we're making outgoing requests, we'll be receiving them.

```swift
public let status: Status
public var headers: [HeaderKey: String]
public var body: Body
public var data: Content
```

#### Status

The http status associated with the event, for example `.ok` == 200 ok.

#### Headers

These are the headers associated with the request. If you are preparing an outgoing response, this can be used to add your own keys.

```swift
let contentType = response.headers["Content-Type"]  
```

Or for outgoing response:

```swift
let response = response ...
response.headers["Content-Type"] = "application/json"
response.headers["Authorization"] = ... my auth token
```

##### Extending Headers

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
let customKey = response.headers.customKey

// or

let request = ...
response.headers.customKey = "my custom value"
```

#### Body

This is the body associated with the response and represents the general data payload. You can view more about body in the associated [docs](./body.md)

For responses, the body is most commonly set at initialization. With two main types.

##### BodyRepresentable

Things that can be converted to bytes, ie:

```swift
let response = Response(status: .ok, body: "some string")
```

In the above example, the `String` will be automatically converted to a body. Your own types can do this as well.

##### Bytes Directly

If we already have our bytes array, we can pass it into the body like so:

```swift
let response = Response(status: .ok, body: .data(myArrayOfBytes))
```

##### Chunked

To send an `HTTP.Response` in chunks, we can pass a closure that we'll use to send our response body in parts.

```swift
let response = Response(status: .ok) { chunker in
  for name in ["joe", "pam", "cheryl"] {
      sleep(1)
      try chunker.send(name)
  }

  try chunker.close()
}
```

> Make sure to call `close()` before the chunker leaves scope.

## Content

We can access content the same we do in a [request](./request.md). This most commonly applies to outgoing requests.

```swift
let pokemonResponse = try drop.client.get("http://pokeapi.co/api/v2/pokemon/")
let names = pokemonResponse.data["results", "name"]?.array
```

## JSON

To access JSON directly on a given response, use the following:

```swift
let json = request.response["hello"]
```

## Key Paths

For more on KeyPaths, visit [here](./request.md#key-paths)
