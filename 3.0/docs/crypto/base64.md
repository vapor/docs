# Base64

Base64 supports encoding and decoding. It uses an encoding and decoding lookup table, supporting `base64` and `base64url`-encoded tables by default.

`Base64Encoder` and `Base64Decoder` are used for encoding and decoding data (streams).

They require specifying an encoding.

```swift
let text = "Hello, world!"

let encoder = Base64Encoder(encoding: .base64)
let decoder = Base64Decoder(encoding: .base64)

let encodedData = encoder.encode(string: text)
let decodedData = decoder.decode(data: data)

let string = String(data: decodedData, encoding: .utf8) // "Hello, world!"
```

### Streams

You can use the Base64 en- and decoders as a stream for transforming any stream of `ByteBuffer` efficiently.

The following example echos the TCP data using Base64 encoding.

```swift
let encoder = Base64Encoder(encoding: .base64)

let encoderStream = encoder.stream()

tcpSocket.stream(to: encoderStream).output(to: tcpSocket)
```

And the following example does the inverse, echoing the TCP data after decoding Base64.

```swift
let decoder = Base64Decoder(encoding: .base64)

let decoderStream = decoder.stream()

tcpSocket.stream(to: decoderStream).output(to: tcpSocket)
```
