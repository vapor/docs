# Crypto

Vapor enthält [SwiftCrypto](https://github.com/apple/swift-crypto/), einen Linux-kompatiblen Port von Apples CryptoKit-Bibliothek. Einige zusätzliche Krypto-APIs werden für Dinge bereitgestellt, die SwiftCrypto noch nicht bietet, wie [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) und [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm).

## SwiftCrypto

Swifts `Crypto`-Bibliothek implementiert Apples CryptoKit-API. Daher sind die [CryptoKit-Dokumentation](https://developer.apple.com/documentation/cryptokit) und der [WWDC-Vortrag](https://developer.apple.com/videos/play/wwdc2019/709) großartige Ressourcen, um die API kennenzulernen.

Diese APIs stehen automatisch zur Verfügung, sobald du Vapor importierst. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit unterstützt unter anderem:

- Hashing: `SHA512`, `SHA384`, `SHA256`
- Message Authentication Codes: `HMAC`
- Chiffren: `AES`, `ChaChaPoly`
- Public-Key-Kryptographie: `Curve25519`, `P521`, `P384`, `P256`
- Unsicheres Hashing: `SHA1`, `MD5`

## Bcrypt

Bcrypt ist ein Passwort-Hashing-Algorithmus, der einen zufälligen Salt verwendet, um sicherzustellen, dass das mehrfache Hashen desselben Passworts nicht zum gleichen Digest führt.

Vapor stellt einen `Bcrypt`-Typ zum Hashen und Vergleichen von Passwörtern bereit. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Da Bcrypt einen Salt verwendet, können Passwort-Hashes nicht direkt verglichen werden. Sowohl das Klartext-Passwort als auch der vorhandene Digest müssen gemeinsam verifiziert werden. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // Passwort und Digest stimmen überein.
} else {
    // Falsches Passwort.
}
```

Der Login mit Bcrypt-Passwörtern kann implementiert werden, indem zunächst der Passwort-Digest des Benutzers anhand von E-Mail oder Benutzername aus der Datenbank abgerufen wird. Der bekannte Digest kann anschließend gegen das übermittelte Klartext-Passwort verifiziert werden.

## OTP

Vapor unterstützt sowohl HOTP- als auch TOTP-Einmalpasswörter. OTPs funktionieren mit den Hash-Funktionen SHA-1, SHA-256 und SHA-512 und können sechs-, sieben- oder achtstellige Ausgaben liefern. Ein OTP ermöglicht Authentifizierung, indem es ein nur einmal verwendbares, für Menschen lesbares Passwort generiert. Dazu einigen sich beide Parteien zunächst auf einen symmetrischen Schlüssel, der jederzeit privat gehalten werden muss, um die Sicherheit der generierten Passwörter zu gewährleisten.

#### HOTP

HOTP ist ein OTP, das auf einer HMAC-Signatur basiert. Zusätzlich zum symmetrischen Schlüssel einigen sich beide Parteien auch auf einen Zähler, eine Zahl, die für die Eindeutigkeit des Passworts sorgt. Nach jedem Generierungsversuch wird der Zähler erhöht.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Oder mit der statischen generate-Funktion
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

Ein TOTP ist eine zeitbasierte Variante des HOTP. Es funktioniert größtenteils genauso, aber anstelle eines einfachen Zählers wird die aktuelle Zeit verwendet, um Eindeutigkeit zu erzeugen. Um die unvermeidliche Abweichung auszugleichen, die durch nicht synchronisierte Uhren, Netzwerklatenz, Benutzerverzögerung und andere Störfaktoren entsteht, bleibt ein generierter TOTP-Code über ein festgelegtes Zeitintervall gültig (meist 30 Sekunden).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Oder mit der statischen generate-Funktion
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Bereich

OTPs sind sehr nützlich, um bei der Validierung und bei nicht synchronen Zählern einen Spielraum zu bieten. Beide OTP-Implementierungen können ein OTP mit einer Fehlermarge generieren.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Ein Fenster gültiger Zähler generieren
let codes = hotp.generate(counter: 25, range: 2)
```
Das obige Beispiel erlaubt eine Marge von 2, was bedeutet, dass das HOTP für die Zählerwerte `23 ... 27` berechnet wird und all diese Codes zurückgegeben werden. 

!!! warning
    Hinweis: Je größer die verwendete Fehlermarge, desto mehr Zeit und Freiraum hat ein Angreifer zum Handeln, was die Sicherheit des Algorithmus verringert.
