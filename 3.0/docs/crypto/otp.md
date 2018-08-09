# TOTP and HOTP

One-time passwords (OTPs) are commonly used as a form of [two-factor authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication). Crypto can be used to generate both TOTP and HOTP in accordance with [RFC 6238](https://tools.ietf.org/html/rfc6238) and [RFC 4226](https://tools.ietf.org/html/rfc4226
) respectively.

- **TOTP**: Time-based One-Time Password. Generates password by combining shared secret with unix timestamp.
- **HOTP**: HMAC-Based One-Time Password. Similar to TOTP, except an incrementing counter is used instead of a timestamp. Each time a new OTP is generated, the counter increments.

## Generating OTP

OTP generation is similar for both TOTP and HOTP. The only difference is that HOTP requires the current counter to be passed.

```swift
import Crypto

// Generate TOTP
let code = TOTP.SHA1.generate(secret: "hi")
print(code) "123456"

// Generate HOTP
let code = HOTP.SHA1.generate(secret: "hi", counter: 0)
print(code) "208503"
```

View the API docs for [`TOTP`](#fixme) and [`HOTP`](#fixme) for more information.

## Base 32

TOTP and HOTP shared secrets are commonly transferred using Base32 encoding. Crypto provides conveniences for converting to/from Base32.

```swift
import Crypto

// shared secret
let secret: Data = ...

// base32 encoded secret
let encodedSecret = secret.base32EncodedString()
```

See Crypto's [`Data`](#fixme) extensions for more information. 
