# Criptografía

Vapor incluye [SwiftCrypto](https://github.com/apple/swift-crypto/), que es un port compatible con Linux de la biblioteca CryptoKit de Apple. Se exponen algunas APIs criptográficas adicionales para funciones que SwiftCrypto aún no incluye, como [Bcrypt](https://es.wikipedia.org/wiki/Bcrypt) y [TOTP](https://es.wikipedia.org/wiki/Algoritmo_de_contraseña_de_un_solo_uso_basada_en_el_tiempo).

## SwiftCrypto

La biblioteca `Crypto` de Swift implementa la API de CryptoKit de Apple. Por lo tanto, la [documentación de CryptoKit](https://developer.apple.com/documentation/cryptokit) y la [charla de la WWDC](https://developer.apple.com/videos/play/wwdc2019/709) son excelentes recursos para aprender sobre la API.

Estas APIs estarán disponibles automáticamente cuando importes Vapor. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit incluye soporte para:

- Hashing: `SHA512`, `SHA384`, `SHA256`
- Códigos de autenticación de mensajes (MAC): `HMAC`
- Cifrados: `AES`, `ChaChaPoly`
- Criptografía de clave pública: `Curve25519`, `P521`, `P384`, `P256`
- Hashing no seguro: `SHA1`, `MD5`

## Bcrypt

Bcrypt es un algoritmo de hash para contraseñas que utiliza una sal aleatoria para garantizar que al hashear la misma contraseña varias veces no se obtenga el mismo resultado.

Vapor proporciona un tipo `Bcrypt` para hashear y comparar contraseñas.

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Debido a que Bcrypt utiliza una sal, los hashes de las contraseñas no se pueden comparar directamente. Se deben verificar juntos la contraseña en texto plano y el hash existente.

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// La contraseña y el hash coinciden.
} else {
	// Contraseña incorrecta.
}
```

El inicio de sesión con contraseñas Bcrypt se puede implementar primero obteniendo el hash de la contraseña del usuario desde la base de datos por email o nombre de usuario. Luego, el hash conocido se puede verificar con la contraseña en texto plano proporcionada.

## OTP

Vapor soporta contraseñas de un solo uso (OTP) tanto HOTP como TOTP. Las OTP funcionan con las funciones hash SHA-1, SHA-256 y SHA-512, y pueden generar seis, siete u ocho dígitos como resultado. Una OTP proporciona autenticación generando una contraseña de un solo uso legible para humanos. Para hacerlo, las partes primero acuerdan una clave simétrica, que debe mantenerse privada en todo momento para garantizar la seguridad de las contraseñas generadas.

#### HOTP

HOTP es una OTP basada en una firma HMAC. Además de la clave simétrica, ambas partes acuerdan también un contador, que es un número que proporciona unicidad a la contraseña. Después de cada intento de generación, el contador aumenta.

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// O utilizando la función estática generate.
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

A TOTP is a time-based variation of the HOTP. It works mostly the same, but instead of a simple counter, the current time is used to generate uniqueness. To compensate for the inevitable skew introduced by unsynchronized clocks, network latency, user delay, and other confounding factors, a generated TOTP code remains valid over a specified time interval (most commonly, 30 seconds).

TOTP es una variación basada en el tiempo de HOTP. Funciona de forma similar, pero en lugar de usar un contador simple, utiliza la hora actual para generar unicidad. Para compensar los inevitables desfases introducidos por relojes desincronizados, latencia de red, retrasos del usuario y otros factores, un código TOTP generado sigue siendo válido durante un intervalo de tiempo especificado (normalmente, 30 segundos).

```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// O utilizando la función estática generate.
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Margen (Range)

Las OTP son muy útiles para proporcionar flexibilidad en la validación y contadores desincronizados. Ambas implementaciones de OTP tienen la capacidad de generar una OTP con un margen de error.

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Generar un rango de contadores correctos.
let codes = hotp.generate(counter: 25, range: 2)
```

El ejemplo anterior permite un margen de 2, lo que significa que el HOTP se calculará para los valores de contador `23 ... 27`, y todos estos códigos serán devueltos.

!!! warning "Advertencia"
    Nota: Cuanto mayor sea el margen de error utilizado, más tiempo y libertad tendrá un atacante para actuar, reduciendo la seguridad del algoritmo.
