# 暗号 {#crypto}

Vapor には [SwiftCrypto](https://github.com/apple/swift-crypto/) が含まれており、これは Apple の CryptoKit ライブラリの Linux 互換ポートです。SwiftCrypto がまだサポートしていない [Bcrypt](https://ja.wikipedia.org/wiki/Bcrypt) や [TOTP](https://ja.wikipedia.org/wiki/Time-based_One-time_Password) のような追加の暗号 API も公開されています。

## SwiftCrypto {#swiftcrypto}

Swift の `Crypto` ライブラリは Apple の CryptoKit API を実装しています。そのため、[CryptoKit ドキュメント](https://developer.apple.com/documentation/cryptokit) と [WWDC トーク](https://developer.apple.com/videos/play/wwdc2019/709) は API を学ぶための優れたリソースです。

これらの API は Vapor をインポートすると自動的に利用可能になります。

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit には以下のサポートが含まれています：

- ハッシュ化：`SHA512`、`SHA384`、`SHA256`
- メッセージ認証コード：`HMAC`
- 暗号：`AES`、`ChaChaPoly`
- 公開鍵暗号：`Curve25519`、`P521`、`P384`、`P256`
- 安全でないハッシュ化：`SHA1`、`MD5`

## Bcrypt {#bcrypt}

Bcrypt はランダム化されたソルトを使用して、同じパスワードを複数回ハッシュ化しても同じダイジェストにならないようにするパスワードハッシュアルゴリズムです。

Vapor はパスワードのハッシュ化と比較のための `Bcrypt` 型を提供しています。

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Bcrypt はソルトを使用するため、パスワードハッシュを直接比較することはできません。平文パスワードと既存のダイジェストの両方を一緒に検証する必要があります。

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// パスワードとダイジェストが一致します。
} else {
	// パスワードが間違っています。
}
```

Bcrypt パスワードでのログインは、まずメールアドレスまたはユーザー名でデータベースからユーザーのパスワードダイジェストを取得することで実装できます。その後、既知のダイジェストを提供された平文パスワードに対して検証できます。

## OTP {#otp}

Vapor は HOTP と TOTP の両方のワンタイムパスワードをサポートしています。OTP は SHA-1、SHA-256、SHA-512 ハッシュ関数で動作し、6 桁、7 桁、または 8 桁の出力を提供できます。OTP は、単一使用の人間が読めるパスワードを生成することで認証を提供します。これを行うために、両当事者はまず対称鍵に合意し、生成されたパスワードのセキュリティを維持するために常に秘密にしておく必要があります。

#### HOTP {#hotp}

HOTP は HMAC 署名に基づく OTP です。対称鍵に加えて、両当事者はパスワードの一意性を提供する数値であるカウンターにも合意します。各生成試行後、カウンターは増加します。

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// または静的 generate 関数を使用
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP {#totp}

TOTP は HOTP の時間ベースのバリエーションです。ほとんど同じように動作しますが、単純なカウンターの代わりに、現在の時刻を使用して一意性を生成します。非同期クロック、ネットワーク遅延、ユーザーの遅延、およびその他の混乱要因によって導入される避けられないずれを補償するために、生成された TOTP コードは指定された時間間隔（最も一般的には 30 秒）にわたって有効のままです。

```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// または静的 generate 関数を使用
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### 範囲 {#range}

OTP は検証での余裕と同期外れカウンターを提供するのに非常に便利です。両方の OTP 実装には、エラーのマージンを持って OTP を生成する能力があります。

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// 正しいカウンターのウィンドウを生成
let codes = hotp.generate(counter: 25, range: 2)
```

上記の例では 2 のマージンを許可しており、これは HOTP がカウンター値 `23 ... 27` に対して計算され、これらのコードすべてが返されることを意味します。

!!! warning "警告"
    注意：使用するエラーマージンが大きくなるほど、攻撃者が行動するための時間と自由度が増え、アルゴリズムのセキュリティが低下します。