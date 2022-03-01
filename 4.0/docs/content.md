# Content

Vapor's content API allows you to easily encode / decode Codable structs to / from HTTP messages. [JSON](https://tools.ietf.org/html/rfc7159) encoding is used by default with out-of-the-box support for [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) and [Multipart](https://tools.ietf.org/html/rfc2388). The API is also configurable, allowing for you to add, modify, or replace encoding strategies for certain HTTP content types.

## Overview

To understand how Vapor's content API works, you should first understand a few basics about HTTP messages. Take a look at the following example request.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

This request indicates that it contains JSON-encoded data using the `content-type` header and `application/json` media type. As promised, some JSON data follows after the headers in the body.

### Content Struct

The first step to decoding this HTTP message is creating a Codable type that matches the expected structure. 

```swift
struct Greeting: Content {
    var hello: String
}
```

Conforming the type to `Content` will automatically add conformance to `Codable` alongside additional utilities for working with the content API.

Once you have the content structure, you can decode it from the incoming request using `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

The decode method uses the request's content type to find an appropriate decoder. If there is no decoder found, or the request does not contain the content type header, a `415` error will be thrown.

That means that this route automatically accepts all of the other supported content types, such as url-encoded form:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

In the case of file uploads, your content property must be of type `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Supported Media Types

Below are the media types the content API supports by default.

|name|header value|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Not all media types support all `Codable` features. For example, JSON does not support top-level fragments and Plaintext does not support nested data.

## Query

Vapor's Content APIs support handling URL encoded data in the URL's query string. 

### Decoding

To understand how decoding a URL query string works, take a look at the following example request.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Just like the APIs for handling HTTP message body content, the first step for parsing URL query strings is to create a `struct` that matches the expected structure.

```swift
struct Hello: Content {
    var name: String?
}
```

Note that `name` is an optional `String` since URL query strings should always be optional. If you want to require a parameter, use a route parameter instead.

Now that you have a `Content` struct for this route's expected query string, you can decode it.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

This route would result in the following response given the example request from above:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

If the query string were omitted, like in the following request, the name "Anonymous" would be used instead.

```http
GET /hello HTTP/1.1
content-length: 0
```

### Single Value

In addition to decoding to a `Content` struct, Vapor also supports fetching single values from the query string using subscripts.

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor will automatically call `beforeEncode` and `afterDecode` on a `Content` type. Default implementations are provided which do nothing, but you can use these methods to run custom logic.

```swift
// Runs after this Content is decoded. `mutating` is only required for structs, not classes.
mutating func afterDecode() throws {
    // Name may not be passed in, but if it is, then it can't be an empty string.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Runs before this Content is encoded. `mutating` is only required for structs, not classes.
mutating func beforeEncode() throws {
    // Have to *always* pass a name back, and it can't be an empty string.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Override Defaults

The default encoders and decoders used by Vapor's Content APIs can be configured. 

### Global

`ContentConfiguration.global` lets you change the encoders and decoders Vapor uses by default. This is useful for changing how your entire application parses and serializes data.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Mutating `ContentConfiguration` is usually done in `configure.swift`. 

### One-Off

Calls to encoding and decoding methods like `req.content.decode` support passing in custom coders for one-off usages.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Custom Coders

Applications and third-party packages can add support for media types that Vapor does not support by default by creating custom coders.

### Content

Vapor specifies two protocols for coders capable of handling content in HTTP message bodies: `ContentDecoder` and `ContentEncoder`.

```swift
public protocol ContentEncoder {
    func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
}

public protocol ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
        where D: Decodable
}
```

Conforming to these protocols allows your custom coders to be registered to `ContentConfiguration` as specified above.

### URL Query

Vapor specifies two protocols for coders capable of handling content in URL query strings: `URLQueryDecoder` and `URLQueryEncoder`.

```swift
public protocol URLQueryDecoder {
    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D
        where D: Decodable
}

public protocol URLQueryEncoder {
    func encode<E>(_ encodable: E, to url: inout URI) throws
        where E: Encodable
}
```

Conforming to these protocols allows your custom coders to be registered to `ContentConfiguration` for handling URL query strings using the `use(urlEncoder:)` and `use(urlDecoder:)` methods.

### Custom `ResponseEncodable`

Another approach involves implementing `ResponseEncodable` on your types. Consider this trivial `HTML` wrapper type:

```swift
struct HTML {
  let value: String
}
```

Then its `ResponseEncodable` implementation would look like this:

```swift
extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}
```

If you're using `async`/`await` you can use `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Note that this allows customizing the `Content-Type` header. See [`HTTPHeaders` reference](https://api.vapor.codes/vapor/main/Vapor/) for more details.

You can then use `HTML` as a response type in your routes:

```swift
app.get { _ in
  HTML(value: """
  <html>
    <body>
      <h1>Hello, World!</h1>
    </body>
  </html>
  """)
}
```
