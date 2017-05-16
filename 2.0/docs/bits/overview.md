# Bits

The bits package is included in Vapor by default and provides a convenient API for working with bytes.

!!! note
	Use `import Bits` to use this package.

## Typealias

The bits package provides two type-alises for bytes.

```swift
typealias Byte = UInt8
typealias Bytes = [Byte]
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
