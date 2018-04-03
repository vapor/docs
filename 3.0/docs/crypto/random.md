# Random

The `Random` module deals with random data generation including random number generation.

## Data Generator

The [`DataGenerator`]() class powers all of the random data generators.

### Implementations

- [`OSRandom`](https://api.vapor.codes/crypto/latest/Random/Classes/OSRandom.html): Provides a random data generator using a platform-specific method.


- [`URandom`](https://api.vapor.codes/crypto/latest/Random/Classes/URandom.html) provides random data generation based on the `/dev/urandom` file.


- [`CryptoRandom`](https://api.vapor.codes/crypto/latest/Crypto/Classes/CryptoRandom.html) from the `Crypto` module provides cryptographically-secure random data using OpenSSL.


```swift
let random: DataGenerator ...
let data = try random.generateData(bytes: 8)
```

### Generate

`DataGenerator`s are capable of generating random primitive types using the `generate(_:)` method.

```swift
let int = try OSRandom().generate(Int.self)
print(int) // Int
```
