# Criptografia

O Vapor inclui o [SwiftCrypto](https://github.com/apple/swift-crypto/), que é um port compatível com Linux da biblioteca CryptoKit da Apple. Algumas APIs criptográficas adicionais são expostas para funcionalidades que o SwiftCrypto ainda não possui, como [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) e [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm).

## SwiftCrypto

A biblioteca `Crypto` do Swift implementa a API CryptoKit da Apple. Sendo assim, a [documentação do CryptoKit](https://developer.apple.com/documentation/cryptokit) e a [palestra da WWDC](https://developer.apple.com/videos/play/wwdc2019/709) são ótimos recursos para aprender a API.

Essas APIs estarão disponíveis automaticamente quando você importar o Vapor.

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

O CryptoKit inclui suporte para:

- Hashing: `SHA512`, `SHA384`, `SHA256`
- Message Authentication Codes: `HMAC`
- Ciphers: `AES`, `ChaChaPoly`
- Public-Key Cryptography: `Curve25519`, `P521`, `P384`, `P256`
- Hashing inseguro: `SHA1`, `MD5`

## Bcrypt

Bcrypt é um algoritmo de hashing de senhas que usa um salt aleatório para garantir que o hash da mesma senha múltiplas vezes não resulte no mesmo digest.

O Vapor fornece um tipo `Bcrypt` para hashing e comparação de senhas.

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Como o Bcrypt usa um salt, hashes de senha não podem ser comparados diretamente. Tanto a senha em texto puro quanto o digest existente devem ser verificados juntos.

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// Senha e digest correspondem.
} else {
	// Senha incorreta.
}
```

O login com senhas Bcrypt pode ser implementado buscando primeiro o digest da senha do usuário no banco de dados por e-mail ou nome de usuário. O digest conhecido pode então ser verificado contra a senha em texto puro fornecida.

## OTP

O Vapor suporta senhas de uso único HOTP e TOTP. OTPs funcionam com as funções de hash SHA-1, SHA-256 e SHA-512 e podem fornecer seis, sete ou oito dígitos de saída. Um OTP fornece autenticação gerando uma senha de uso único legível por humanos. Para isso, as partes primeiro concordam em uma chave simétrica, que deve ser mantida privada em todos os momentos para manter a segurança das senhas geradas.

#### HOTP

HOTP é um OTP baseado em uma assinatura HMAC. Além da chave simétrica, ambas as partes também concordam em um contador, que é um número que fornece unicidade para a senha. Após cada tentativa de geração, o contador é incrementado.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Ou usando a função estática generate
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

Um TOTP é uma variação baseada em tempo do HOTP. Funciona basicamente da mesma forma, mas em vez de um simples contador, o horário atual é usado para gerar unicidade. Para compensar a inevitável defasagem introduzida por relógios não sincronizados, latência de rede, atraso do usuário e outros fatores, um código TOTP gerado permanece válido por um intervalo de tempo especificado (mais comumente, 30 segundos).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Ou usando a função estática generate
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Range
OTPs são muito úteis para fornecer tolerância na validação e contadores fora de sincronização. Ambas as implementações de OTP têm a capacidade de gerar um OTP com uma margem de erro.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Gerar uma janela de contadores corretos
let codes = hotp.generate(counter: 25, range: 2)
```
O exemplo acima permite uma margem de 2, o que significa que o HOTP será calculado para os valores de contador `23 ... 27`, e todos esses códigos serão retornados.

!!! warning "Aviso"
    Nota: Quanto maior a margem de erro utilizada, mais tempo e liberdade um atacante tem para agir, diminuindo a segurança do algoritmo.
