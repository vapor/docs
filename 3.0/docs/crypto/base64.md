# Encoding

`Base64Encoder` is used to encode Base64 data. It works either as a stream or as a bulk decoder.

## Bulk

Base64 can be bulk-encoded using a static method `encode`. This throws an error if the base64 is invalid.

You can encode `String`, `Data` or `ByteBuffer` input.

```swift
let encodedData: Data = Base64Encoder.encode(input)
```

## Stream

To use the Base64 streaming encoder, you first need to initialize the `Base64Encoder`.

```swift
let encoder = Base64Encoder()
```

The input of the `Base64Encoder` is the raw data. The output is Base64 encoded data. The final Base64-padding will be applied only when the input stream closes.

# Decoding

`Base64Decoder` is used to decode Base64 data. It works either as a stream or as a bulk decoder.

## Bulk

Base64 can be bulk-decoded using a static method `decode`. This throws an error if the base64 is invalid.

You can decode `String`, `Data` or `ByteBuffer` input.

```swift
let decodedData: Data = try Base64Decoder.decode(input)
```

## Stream

To use the Base64 streaming decoder, you first need to initialize the `Base64Decoder`.

```swift
let encoder = Base64Decoder()
```

The input of the `Base64Decoder` is the Base64 encoded data. The output is raw data.

# Optimization

Both `Base64Encoder` as well as `Base64Decoder` accept the `decodedCapacity`. This is the expected amount of decoded bytes you expect to input or receive.

If you expect to receive (a maximum of) `100_000` bytes of input to encode per event on the stream, you should make that the `decodedCapacity`. By default it's set to `UInt16.max`, which is sensible for TCP sockets.
