# URI

URIs or "Uniform Resource Identifiers" are used for defining a resource.

They consist of the following components:

- scheme
- authority
- path
- query
- fragment

## Creating an URI

URIs can be created from it's initializer or from a String literal.

```swift
let stringLiteralURI: URI = "http://localhost:8080/path"
let manualURI: URI = URI(
    scheme: "http",
    hostname: "localhost",
    port: 8080,
    path: "/path"
)
```
