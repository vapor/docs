# Crypto

Vapor include [SwiftCrypto](https://github.com/apple/swift-crypto/), un'implementazione compatibile con Linux della libreria CryptoKit di Apple. Vengono fornite altre API di crittografia per cose che SwiftCrypto non ha ancora, come [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) e [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

La libreria di Swift `Crypto` implementa le API di CryptoKit di Apple. Pertanto, la [documentazione di CryptoKit](https://developer.apple.com/documentation/cryptokit) e il [video della WWDC](https://developer.apple.com/videos/play/wwdc2019/709) sono ottime risorse per conoscere l'API.

Queste API saranno disponibili automaticamente quando importi Vapor. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit include API per:

- Hashing: `SHA512`, `SHA384`, `SHA256`
- Message Authentication Codes: `HMAC`
- Cifrari: `AES`, `ChaChaPoly`
- Crittografia a Chiave Pubblica: `Curve25519`, `P521`, `P384`, `P256`
- Hashing insicuro: `SHA1`, `MD5`

## Bcrypt

Bcrypt è un algoritmo di hashing delle password che usa un "salt" randomico per assicurare che ogni volta che si calcola l'hash della stessa password non si ottiene mai come risultato lo stesso "digest".

Vapor fornisce un tipo `Bcrypt` per calcolare l'hash e verificare le password. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Dato che Bcrypt usa un salt, gli hash delle password non possono essere comparati direttamente. Devono essere verificate insieme la password in chiaro e il digest esistente. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// La password e il digest combaciano.
} else {
	// La password è sbagliata.
}
```

Il login con le password di Bcrypt può essere implementato cercando il digest della password di un utente nel database, tramite l'email o il nome utente forniti. Il digest può essere quindi verificato paragonandolo alla password in chiaro fornita in fase di login.

## OTP

Vapor supporta le password one-time HOTP e TOTP. Le OTP utilizzano le funzioni di hash SHA-1, SHA-256, e SHA-512 e possono fornire sei, sette o otto cifre di output. Una OTP fornisce autenticazione generando una password usa-e-getta facilmente leggibile. Per fare ciò, le parti prima si accordano su una chiave simmetrica, che deve sempre essere tenuta segreta per mantenere la sicurezza delle password generate.

#### HOTP

Le HOTP sono delle OTP basate su una firma HMAC. In aggiunta alla chiave simmetrica, entrambe le parti condividono anche un contatore, ossia un numero che fornisce unicità alla password. Dopo ogni tentativo di generazione, il contatore viene aumentato.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Oppure utilizzando la funzione statica generate
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

Le TOTP sono una variante basata sul tempo delle HOTP. Funzionano più o meno allo stesso modo, ma invece di un semplice contatore, per generare unicità viene usata l'ora corrente. Per compensare l'inevitabile errore introdotto da orologi non sincronizzati, latenze della rete e altri fattori di ritardo, un codice TOTP una volta generato rimane valido per un determinato intervallo di tempo (solitamente 30 secondi).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Oppure utilizzando la funzione statica generate
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Intervallo
Le OTP sono molto utili per fornire un margine di manovra nella convalida e nei contatori non sincronizzati. Entrambe le implementazioni delle OTP permettono di generare OTP con un margine di errore.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Genera una finestra di contatori corretti
let codes = hotp.generate(counter: 25, range: 2)
```
Nell'esempio qui sopra viene fornito un margine di 2, che significa che le HOTP saranno calcolate con i valori del contatore `23 ... 27`, e tutti questi codici verranno restituiti. 

!!! warning
    N.B.: Più grande è il margine di errore usato, maggiore è il tempo e la libertà che ha un attacante per agire, diminuendo la sicurezza dell'algoritmo.
