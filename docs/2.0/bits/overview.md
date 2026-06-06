# Bits

The bits package is included in Vapor by default and provides a convenient API for working with bytes.

## Typealias

The bits package provides two type-aliases for bytes.

```swift
typealias Byte = UInt8
typealias Bytes = [Byte]
```

## BytesConvertible

It's quite often that we want to convert objects to and from byte arrays when we're working. The BytesConvertible helps define objects that have these capabilities. This is implemented already on most objects in Vapor that can/should be converted to and from byte arrays.

```Swift
let hello = String(bytes: [72, 101, 108, 108, 111])
let bytes = hello.makeBytes() 
```

## String

Converting from bytes to string using the UTF-8 encoding is easy.

```swift
let bytes = "hello".makeBytes()
let string = bytes.makeString()
print(string) // "hello"
```

## Byte

The upper and lowercase latin alphabet and some additional control characters are statically typed on the `Byte`.

```swift
let bytes: Bytes = [.h, .e, .l, .l, .o]
print(bytes.makeString()) // "hello"
```

This makes byte manipulation and comparison easy and is useful for building things like parsers and serializers.

```swift
let byte: Byte = 65
if byte == .A {
	print("found A!")
}
```
