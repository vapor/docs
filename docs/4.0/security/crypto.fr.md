# Crypto

Vapor inclut [SwiftCrypto](https://github.com/apple/swift-crypto/), un portage compatible Linux de la bibliothèque CryptoKit d'Apple. Quelques API cryptographiques supplémentaires sont exposées pour des fonctionnalités que SwiftCrypto n'a pas encore, comme [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) et [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

La bibliothèque `Crypto` de Swift implémente l'API CryptoKit d'Apple. Ainsi, la [documentation CryptoKit](https://developer.apple.com/documentation/cryptokit) et la [conférence WWDC](https://developer.apple.com/videos/play/wwdc2019/709) sont d'excellentes ressources pour apprendre à utiliser cette API.

Ces API seront automatiquement disponibles lorsque vous importez Vapor. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit prend en charge :

- Le hachage : `SHA512`, `SHA384`, `SHA256`
- Les codes d'authentification de message : `HMAC`
- Les chiffrements : `AES`, `ChaChaPoly`
- La cryptographie à clé publique : `Curve25519`, `P521`, `P384`, `P256`
- Le hachage non sécurisé : `SHA1`, `MD5`

## Bcrypt

Bcrypt est un algorithme de hachage de mots de passe qui utilise un sel aléatoire pour garantir que le hachage d'un même mot de passe plusieurs fois ne produit pas le même condensé (digest).

Vapor fournit un type `Bcrypt` pour hacher et comparer des mots de passe. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Parce que Bcrypt utilise un sel, les condensés de mots de passe ne peuvent pas être comparés directement. Le mot de passe en clair et le condensé existant doivent tous les deux être vérifiés ensemble. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // Le mot de passe et le condensé correspondent.
} else {
    // Mauvais mot de passe.
}
```

La connexion avec des mots de passe Bcrypt peut être implémentée en récupérant d'abord le condensé du mot de passe de l'utilisateur depuis la base de données par email ou nom d'utilisateur. Le condensé connu peut ensuite être vérifié par rapport au mot de passe en clair fourni.

## OTP

Vapor prend en charge les mots de passe à usage unique HOTP et TOTP. Les OTP fonctionnent avec les fonctions de hachage SHA-1, SHA-256 et SHA-512 et peuvent fournir une sortie de six, sept ou huit chiffres. Un OTP fournit une authentification en générant un mot de passe à usage unique lisible par un humain. Pour ce faire, les parties conviennent d'abord d'une clé symétrique, qui doit rester privée en permanence pour maintenir la sécurité des mots de passe générés.

#### HOTP

HOTP est un OTP basé sur une signature HMAC. En plus de la clé symétrique, les deux parties conviennent également d'un compteur, qui est un nombre garantissant l'unicité du mot de passe. Après chaque tentative de génération, le compteur est incrémenté.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Ou en utilisant la fonction statique generate
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

Un TOTP est une variante temporelle du HOTP. Il fonctionne pratiquement de la même façon, mais au lieu d'un simple compteur, c'est le temps actuel qui est utilisé pour générer l'unicité. Pour compenser le décalage inévitable introduit par des horloges non synchronisées, la latence réseau, le délai utilisateur et d'autres facteurs perturbateurs, un code TOTP généré reste valide sur un intervalle de temps spécifié (le plus souvent, 30 secondes).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Ou en utilisant la fonction statique generate
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Marge

Les OTP sont très utiles pour offrir une marge de manœuvre lors de la validation et pour gérer des compteurs désynchronisés. Les deux implémentations d'OTP ont la capacité de générer un OTP avec une marge d'erreur.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Génère une fenêtre de compteurs valides
let codes = hotp.generate(counter: 25, range: 2)
```
L'exemple ci-dessus permet une marge de 2, ce qui signifie que le HOTP sera calculé pour les valeurs de compteur `23 ... 27`, et tous ces codes seront renvoyés. 

!!! warning
    Remarque : plus la marge d'erreur utilisée est grande, plus un attaquant dispose de temps et de liberté pour agir, ce qui diminue la sécurité de l'algorithme.
