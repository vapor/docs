# Crypto

Vapor는 Apple의 CryptoKit 라이브러리를 Linux에서도 사용할 수 있도록 포팅한 [SwiftCrypto](https://github.com/apple/swift-crypto/)를 포함하고 있습니다. [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt), [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm)와 같이 SwiftCrypto에 아직 없는 기능을 위한 추가적인 crypto API도 제공됩니다.

## SwiftCrypto

Swift의 `Crypto` 라이브러리는 Apple의 CryptoKit API를 구현합니다. 따라서 [CryptoKit 문서](https://developer.apple.com/documentation/cryptokit)와 [WWDC 발표 영상](https://developer.apple.com/videos/play/wwdc2019/709)이 이 API를 배우는 데 훌륭한 자료가 될 것입니다.

Vapor를 import하면 이 API들을 자동으로 사용할 수 있습니다.

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit은 다음을 지원합니다.

- 해싱: `SHA512`, `SHA384`, `SHA256`
- 메시지 인증 코드(Message Authentication Codes): `HMAC`
- 암호화(Ciphers): `AES`, `ChaChaPoly`
- 공개 키 암호화(Public-Key Cryptography): `Curve25519`, `P521`, `P384`, `P256`
- 안전하지 않은 해싱: `SHA1`, `MD5`

## Bcrypt

Bcrypt는 무작위 솔트(salt)를 사용하는 비밀번호 해싱 알고리즘으로, 같은 비밀번호를 여러 번 해싱하더라도 동일한 다이제스트(digest)가 나오지 않도록 보장합니다.

Vapor는 비밀번호를 해싱하고 비교하기 위한 `Bcrypt` 타입을 제공합니다.

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Bcrypt는 솔트를 사용하기 때문에 비밀번호 해시를 직접 비교할 수 없습니다. 평문 비밀번호와 기존 다이제스트를 함께 검증해야 합니다.

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // 비밀번호와 다이제스트가 일치합니다.
} else {
    // 비밀번호가 틀렸습니다.
}
```

Bcrypt 비밀번호를 이용한 로그인은 먼저 이메일이나 사용자 이름으로 데이터베이스에서 사용자의 비밀번호 다이제스트를 가져오는 방식으로 구현할 수 있습니다. 이렇게 알아낸 다이제스트를 입력받은 평문 비밀번호와 대조하여 검증합니다.

## OTP

Vapor는 HOTP와 TOTP 일회용 비밀번호(one-time password)를 모두 지원합니다. OTP는 SHA-1, SHA-256, SHA-512 해시 함수와 함께 동작하며 6자리, 7자리, 8자리의 출력을 제공할 수 있습니다. OTP는 일회용으로 사용할 수 있는, 사람이 읽을 수 있는 비밀번호를 생성하여 인증을 제공합니다. 이를 위해 당사자들은 먼저 대칭 키(symmetric key)에 합의하며, 생성되는 비밀번호의 보안을 유지하기 위해 이 키는 항상 비공개로 유지되어야 합니다.

#### HOTP

HOTP는 HMAC 서명을 기반으로 하는 OTP입니다. 대칭 키에 더해, 두 당사자는 비밀번호의 고유성을 제공하는 숫자인 카운터(counter)에도 합의합니다. 생성을 시도할 때마다 카운터가 증가합니다.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// 또는 정적 generate 함수를 사용할 수도 있습니다.
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

TOTP는 HOTP의 시간 기반 변형입니다. 대부분 동일하게 동작하지만, 단순한 카운터 대신 현재 시간을 사용하여 고유성을 생성합니다. 동기화되지 않은 시계, 네트워크 지연, 사용자 지연 등 여러 혼동 요인으로 인해 발생하는 불가피한 오차를 보완하기 위해, 생성된 TOTP 코드는 지정된 시간 간격(가장 흔하게는 30초) 동안 유효하게 유지됩니다.
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// 또는 정적 generate 함수를 사용할 수도 있습니다.
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### 범위(Range)
OTP는 검증 시 여유를 두거나 카운터가 동기화되지 않은 상황에 대응하는 데 매우 유용합니다. 두 OTP 구현 모두 오차 범위를 두고 OTP를 생성하는 기능을 갖추고 있습니다.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// 올바른 카운터 값들의 범위(window)를 생성합니다.
let codes = hotp.generate(counter: 25, range: 2)
```
위 예제는 2만큼의 오차 범위를 허용하는데, 이는 HOTP가 `23 ... 27`의 카운터 값에 대해 계산되며 이 코드들이 모두 반환된다는 것을 의미합니다.

!!! warning
    참고: 오차 범위를 크게 사용할수록 공격자가 행동할 수 있는 시간과 자유가 늘어나 알고리즘의 보안성이 낮아집니다.
