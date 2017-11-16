# Headers

HTTP Headers are the metadata of a request/response. They can provide a wide variety of information.

`Headers` are an array of key-value pairs. As such it's possible, but not common for multiple pairs to have the same key.

## Creating a Headers object

The most common syntax for creating Headers is a dictionary literal.

```swift
let headers: Headers = [
  .contentType: "text/html"
]
```

The left hand side (key) is a `Header.Name`.

A name can also be initialized with a String literal.

```swift
let headers: Headers = [
  "Content-Type": "text/html"
]
```

## Accessing headers

There are two ways to access Headers. Either by accessing a single (the first) value, or all values.

### A single value example:

```swift
let headers: Headers = [
  .contentType: "text/html"
]

print(headers[.contentType]) // prints "text/html"
```

### Accessing all values example:

```swift
let headers: Headers = [
  .setCookie: "session=afasfwrw3qr241j4qwmdsijfo13k43",
  .setCookie: "awesome=true"
]

// prints ["session=afasfwrw3qr241j4qwmdsijfo13k43", "awesome=true"]
print(headers[valuesFor: .contentType])
```
