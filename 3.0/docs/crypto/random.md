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
let int8: Int8 = try random.makeInt8()
let uint8: UInt8 = try random.makeUInt8()
let int16: Int16 = try random.makeInt16()
let uint16: UInt16 = try random.makeUInt16()
let int32: Int32 = try random.makeInt32()
let uint32: UInt32 = try random.makeUInt32()
let int64: Int64 = try random.makeInt64()
let uint64: UInt64 = try random.makeUInt64()
let int: Int = try random.makeInt()
let uint: UInt = try random.makeUInt()
```

### Reading random data

Random buffers of data are useful when, for example, generating tokens or other unique strings/blobs.

To generate a buffer of random data:

```swift
// generates 20 random bytes
let data: Data = random.data(count: 20)
```
