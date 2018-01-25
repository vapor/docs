# Random

Crypto has two primary random number generators.

OSRandom generates random numbers by calling the operating system's random number generator.

URandom generates random numbers by reading from `/dev/urandom`.

## Accessing random numbers

First, create an instance of the preferred random number generator:

```swift
let random = OSRandom()
```

or

```swift
let random = try URandom()
```

### Reading integers

For every Swift integer a random number function exists.

```swift
let int8 = try random.makeInt8() // Int8
let uint8 = try random.makeUInt8() // UInt8
let int16 = try random.makeInt16() // Int16
let uint16 = try random.makeUInt16() // UInt16
let int32 = try random.makeInt32() // Int32
let uint32 = try random.makeUInt32() // UInt32
let int64 = try random.makeInt64() // Int64
let uint64 = try random.makeUInt64() // UInt64
let int = try random.makeInt() // Int
let uint: = try random.makeUInt() // UInt
```

### Reading random data

Random buffers of data are useful when, for example, generating tokens or other unique strings/blobs.

To generate a buffer of random data:

```swift
// generates 20 random bytes
let data: Data = random.data(count: 20)
```
