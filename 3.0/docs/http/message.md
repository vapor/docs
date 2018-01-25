# Message

## URI

URIs or "Uniform Resource Identifiers" are used for defining a resource.

They consist of the following components:

- scheme
- authority
- path
- query
- fragment

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

## Method

Methods are used to indicate the type of operation requested for a route. They're part exclusively in HTTP Requests and are required.

Method  | Purpose
--------|---------
.get    | Used for retrieving content
.head   | Used for retrieving content metadata
.put    | Used for replacing content
.post   | Used for creating content
.delete | Used for deleting content

A [path](uri.md) is used for specifying a specific resource/content. The method influences the type of interaction with this resource/content.

## Status codes

Status codes are exclusively part of the HTTP Response and are required.

Status codes are a 3 digit number.

The first of the 3 numbers indicated the type of response.

\_xx | Meaning
-----|--------
1xx  | Informational response
2xx  | Success
3xx  | Redirection
4xx  | Client error
5xx  | Server error

The other 2 numbers in a status code are used to define a specific code.

### Selecting a status code

The enum `Status` has all supported status codes. It can be accessed using a `.` or created using an integer literal.

```swift
let ok = Status.ok
let notFound = Status.notFound
```

```swift
let ok: Status = 200
let notFound: Status = 404
```

The following HTTP status codes are most common.

**200 - OK**

200, "OK" is the most common status code. It's used to indicate successful processing of the Request.

**400 - Bad Request**

The error was caused by the client sending an invalid request.

For example an invalid message, malformed request syntax or too large request size.

**403 - Forbidden**

The client does not have the permissions to execute this operation on the specified resource.

**404 - Not found**

The requested resource does not exist.

**500 - Internal Server Error**

Internal server errors are almost exclusively used when an error occurred on the server.


## Headers

HTTP Headers are the metadata of a request/response. They can provide a wide variety of information.

`Headers` are an array of key-value pairs. As such it's possible, but not common for multiple pairs to have the same key.

### Creating Headers

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

### Accessing headers

There are two ways to access Headers. Either by accessing a single (the first) value, or all values.

Accessing a single value:

```swift
let headers: Headers = [
  .contentType: "text/html"
]

print(headers[.contentType]) // prints "text/html"
```

Accessing all values:

```swift
let headers: Headers = [
  .setCookie: "session=afasfwrw3qr241j4qwmdsijfo13k43",
  .setCookie: "awesome=true"
]

// prints ["session=afasfwrw3qr241j4qwmdsijfo13k43", "awesome=true"]
print(headers[valuesFor: .contentType])
```

## HTTPBody

`HTTPBody` is a type that contains the raw representation of a [Request or Response](message.md). It's contents are related to the `Content-Type` header.

Body can contain, but is not limited to `Data`, `String`, `DispatchData` or binary streams. Binary streams can be chunk-encoded.

Empty bodies can be created using the empty initializer `HTTPBody()`.
Alternatively you can provide `Data` or `DispatchData` as the content of the body.
