# Crypto

Vapor zawiera [SwiftCrypto](https://github.com/apple/swift-crypto/), czyli kompatybilny z Linuksem port biblioteki CryptoKit firmy Apple. Udostępnione zostały również dodatkowe API kryptograficzne dla rzeczy, których SwiftCrypto jeszcze nie ma, takich jak [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) i [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

Biblioteka `Crypto` w Swifcie implementuje API CryptoKit firmy Apple. W związku z tym [dokumentacja CryptoKit](https://developer.apple.com/documentation/cryptokit) oraz [prezentacja z WWDC](https://developer.apple.com/videos/play/wwdc2019/709) są świetnymi źródłami wiedzy o tym API.

Te API będą dostępne automatycznie po zaimportowaniu Vapora. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit obejmuje wsparcie dla:

- Haszowania: `SHA512`, `SHA384`, `SHA256`
- Kodów uwierzytelniania wiadomości (Message Authentication Codes): `HMAC`
- Szyfrów: `AES`, `ChaChaPoly`
- Kryptografii klucza publicznego: `Curve25519`, `P521`, `P384`, `P256`
- Niebezpiecznego haszowania: `SHA1`, `MD5`

## Bcrypt

Bcrypt to algorytm haszowania haseł, który wykorzystuje losową sól (salt), aby zapewnić, że wielokrotne haszowanie tego samego hasła nie skutkuje takim samym skrótem (digest).

Vapor udostępnia typ `Bcrypt` do haszowania i porównywania haseł. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Ponieważ Bcrypt wykorzystuje sól, skrótów haseł nie można porównywać bezpośrednio. Zarówno hasło w postaci jawnej (plaintext), jak i istniejący skrót muszą zostać zweryfikowane razem. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // Hasło i skrót są zgodne.
} else {
    // Nieprawidłowe hasło.
}
```

Logowanie z użyciem haseł Bcrypt można zaimplementować, najpierw pobierając z bazy danych skrót hasła użytkownika na podstawie adresu e-mail lub nazwy użytkownika. Znany skrót można następnie zweryfikować względem podanego hasła w postaci jawnej.

## OTP

Vapor obsługuje jednorazowe hasła (one-time passwords) zarówno HOTP, jak i TOTP. OTP działają z funkcjami haszującymi SHA-1, SHA-256 i SHA-512 i mogą generować sześć, siedem lub osiem cyfr wyniku. OTP zapewnia uwierzytelnianie poprzez wygenerowanie jednorazowego, czytelnego dla człowieka hasła. Aby to zrobić, strony najpierw uzgadniają klucz symetryczny, który przez cały czas musi pozostać prywatny, aby zachować bezpieczeństwo generowanych haseł.

#### HOTP

HOTP to OTP oparte na podpisie HMAC. Oprócz klucza symetrycznego obie strony uzgadniają również licznik (counter), czyli liczbę zapewniającą unikalność hasła. Po każdej próbie generowania licznik jest zwiększany.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Lub przy użyciu statycznej funkcji generate
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

TOTP to oparta na czasie odmiana HOTP. Działa w większości tak samo, ale zamiast prostego licznika do generowania unikalności wykorzystywany jest aktualny czas. Aby zrekompensować nieuniknione przesunięcia wynikające z niezsynchronizowanych zegarów, opóźnień sieciowych, opóźnień użytkownika i innych czynników zakłócających, wygenerowany kod TOTP pozostaje ważny przez określony przedział czasu (najczęściej 30 sekund).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Lub przy użyciu statycznej funkcji generate
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Zakres
OTP są bardzo przydatne, gdy chodzi o zapewnienie marginesu tolerancji przy walidacji oraz niezsynchronizowanych licznikach. Obie implementacje OTP mają możliwość generowania OTP z marginesem błędu.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Wygeneruj okno poprawnych liczników
let codes = hotp.generate(counter: 25, range: 2)
```
Powyższy przykład pozwala na margines 2, co oznacza, że HOTP zostanie obliczone dla wartości liczników `23 ... 27`, a wszystkie te kody zostaną zwrócone. 

!!! warning
    Uwaga: Im większy zastosowany margines błędu, tym więcej czasu i swobody działania ma atakujący, co zmniejsza bezpieczeństwo algorytmu.
