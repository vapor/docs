# Crypto

Vapor bevat [SwiftCrypto](https://github.com/apple/swift-crypto/) wat een Linux-compatibele port is van Apple's CryptoKit bibliotheek. Sommige extra crypto APIs zijn beschikbaar voor dingen die SwiftCrypto nog niet heeft, zoals [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) en [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

Swift's `Crypto` bibliotheek implementeert Apple's CryptoKit API. Als zodanig zijn de [CryptoKit documentatie](https://developer.apple.com/documentation/cryptokit) en de [WWDC talk](https://developer.apple.com/videos/play/wwdc2019/709) goede bronnen om de API te leren kennen.

Deze API's zullen automatisch beschikbaar zijn wanneer u Vapor importeert. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit bevat ondersteuning voor:

- Hashen: `SHA512`, `SHA384`, `SHA256`
- Bericht Authenticatie Codes: `HMAC`
- Ciphers: `AES`, `ChaChaPoly`
- Public-Key Cryptografie: `Curve25519`, `P521`, `P384`, `P256`
- Onveilig hashen: `SHA1`, `MD5`

## Bcrypt

Bcrypt is een hashing-algoritme voor wachtwoorden dat een willekeurige salt gebruikt om ervoor te zorgen dat het hashen van hetzelfde wachtwoord meerdere malen niet tot dezelfde digest leidt.

Vapor biedt een `Bcrypt` type voor het hashen en vergelijken van wachtwoorden. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Omdat Bcrypt een salt gebruikt, kunnen hashes van wachtwoorden niet direct vergeleken worden. Zowel het onbewerkte wachtwoord als de bestaande digest moeten samen worden geverifieerd. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// Wachtwoord en digest komen overeen.
} else {
	// Verkeerd wachtwoord.
}
```

Inloggen met Bcrypt wachtwoorden kan worden geïmplementeerd door eerst de wachtwoord digest van de gebruiker op te halen uit de database via email of gebruikersnaam. De gekende digest kan dan worden geverifieerd met het ingevulde wachtwoord in klare tekst.

## OTP

Vapor ondersteunt zowel HOTP als TOTP eenmalige wachtwoorden. OTP's werken met de SHA-1, SHA-256 en SHA-512 hash-functies en kunnen zes, zeven of acht cijfers als uitvoer geven. Een OTP zorgt voor authenticatie door een eenmalig te gebruiken, menselijk leesbaar wachtwoord te genereren. Daartoe komen de partijen eerst een symmetrische sleutel overeen, die te allen tijde privé moet worden gehouden om de veiligheid van de gegenereerde wachtwoorden te waarborgen.

#### HOTP

HOTP is een OTP op basis van een HMAC-handtekening. Naast de symmetrische sleutel komen beide partijen ook een teller overeen, die een getal is dat het wachtwoord uniek maakt. Na elke generatiepoging wordt de teller verhoogd.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Of met behulp van de statische genereer functie
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

Een TOTP is een op tijd gebaseerde variatie op de HOTP. Het werkt grotendeels hetzelfde, maar in plaats van een eenvoudige teller, wordt de huidige tijd gebruikt om uniciteit te genereren. Ter compensatie van de onvermijdelijke vertekening door niet gesynchroniseerde klokken, netwerklatentie, gebruikersvertraging, en andere verstorende factoren, blijft een gegenereerde TOTP code geldig over een gespecificeerd tijdsinterval (meestal 30 seconden).

```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Of met behulp van de statische genereer functie
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Range
OTP's zijn zeer nuttig voor het bieden van speelruimte bij validatie en "out of sync"-tellers. Beide OTP-implementaties kunnen een OTP met een foutmarge genereren.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Genereer een venster met correcte tellers
let codes = hotp.generate(counter: 25, range: 2)
```
Het bovenstaande voorbeeld laat een marge van 2 toe, wat betekent dat de HOTP zal worden berekend voor de tellerwaarden `23 ... 27`, en dat al deze codes zullen worden teruggegeven. 

!!! warning
    Opmerking: Hoe groter de gebruikte foutmarge, hoe meer tijd en vrijheid een aanvaller heeft om te handelen, waardoor de veiligheid van het algoritme afneemt.
