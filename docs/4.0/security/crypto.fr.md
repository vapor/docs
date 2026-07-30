# Crypto

Vapor contient [SwiftCrypto](https://github.com/apple/swift-crypto/), qui est un portage Apple compatible Linux de leur librairie CryptoKit. Quelques APIs crypto supplémentaires sont exposées pour les fonctionnalités que SwiftCrypto ne propose pas encore, comme [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) et [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

La librairie `Crypto` de Swift implémente l'API CryptoKit d'Apple. En conséquent, la [documentation CryptoKit](https://developer.apple.com/documentation/cryptokit) et la [présentation WWDC](https://developer.apple.com/videos/play/wwdc2019/709) sont de bonnes ressources pour découvrir l'API.

Ces APIs seront automatiquement disponibles en important Vapor. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit comprend le support pour :

- Hash : `SHA512`, `SHA384`, `SHA256`
- Codes d'authentification de messages : `HMAC`
- Chiffrement : `AES`, `ChaChaPoly`
- Cryptographie à clé publique : `Curve25519`, `P521`, `P384`, `P256`
- Hash non-sécurisé : `SHA1`, `MD5`

## Bcrypt

Bcrypt est un algorithme de hachage de mots de passe qui utilise un sel aléatoire afin que le hachage du même mot de passe plusieurs fois de suite ne donne pas le même résultat.

Vapor fournit un type `Bcrypt` pour hacher et comparer les mots de passe. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Comme Bcrypt utilise un sel, les hashs de mots de passe ne peuvent pas être directement comparés. Il faut à la fois le mot de passe en clair et son hash existant pour une vérification combinée. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // Le mot de passe et son hash correspondent.
} else {
    // Mauvais mot de passe
}
```

Une connexion par mot de passe Bcrypt peut s'implémenter en récupérant d'abord le hash du mot de passe utilisateur en base de données par son e-mail ou nom d'utilisateur. Le hash connu peut ensuite être comparé au mot de passe fourni en clair.

## OTP (One Time Password)

Vapor supporte les mots de passe à usage unique HOTP et TOTP. Ces mots de passe à usage unique fonctionnent avec les fonctions de hachage SHA-1, SHA-256, et SHA-512 et peuvent générer une sortie à six, sept, ou huit chiffres. Un mot de passe à usage unique permet une authentification en générant un mot de passe facilement lisible pour des humains et utilisable qu'une seule fois. Pour cela, les parties s'accordent sur l'usage d'une clé symétrique, qui doit rester privée en tout temps pour maintenir la sécurité des mots de passe générés.

### HOTP

HOTP est un OTP basé sur une signature HMAC. En plus de la clé symétrique, les parties s'accordent sur un compteur, qui est un nombre permettant de définir une unicité pour le mot de passe. Après chaque tentative de génération, le compteur est incrémenté.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Ou via la fonction de génération statique
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

### TOTP

TOTP est une variation de HOTP basée sur le temps. Son fonctionnement est essentiellement le même, mais au lieu d'un simple compteur, le temps actuel est utilisé pour générer de l'unicité. Pour compenser un décalage inévitable introduit par des horloges non-synchronisées, la latence du réseau, le retart utilisateur, et autres facteurs d'erreur, un code TOTP généré reste valide sur un intervale de temps défini (en général, 30 secondes).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Ou via la fonction de génération statique
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

### Marge d'erreur

Les OTPs sont très utiles pour donner de la marge de manoeuvre concernant la validation et la désyncrhonisation de compteurs. Les deux implémentations OTP peuvent générer des codes avec une marge d'erreur.

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Génère une fenêtre de compteurs corrects
let codes = hotp.generate(counter: 25, range: 2)
```
L'exemple ci-dessus permet une marge de 2, ce qui causera un calcul HOTP pour des valeurs de compteurs de `23 ... 27`, et chacun des codes générés sera retourné. 

!!! Avertissement
    Plus la marge d'erreur sera élevée, plus un attaquant aura de temps et de liberté pour agir, réduisant la sécurité de l'algorithme.
