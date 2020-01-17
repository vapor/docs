# Using Custom Encoders and Decoders

The default encoders and decoders used by Vapor's Content APIs can be configured. 

## Global

`ContentConfiguration.global` lets you change the encoders and decoders Vapor uses by default. This is useful for changing how your entire application parses and serializes data.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Mutating `ContentConfiguration` is usually done in `configure.swift`. 

## One-Off

Calls to encoding and decoding methods like `req.content.decode` support passing in custom coders for one-off usages.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Custom Coders

Application's and third-party packages can add support for media types that Vapor does not support by default by creating custom coders.

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