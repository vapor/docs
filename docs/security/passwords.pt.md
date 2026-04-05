# Senhas

O Vapor inclui uma API de hashing de senhas para ajudar você a armazenar e verificar senhas de forma segura. Essa API é configurável com base no ambiente e suporta hashing assíncrono.

## Configuração

Para configurar o hasher de senhas da Application, use `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Para usar a [API Bcrypt](crypto.md#bcrypt) do Vapor para hashing de senhas, especifique `.bcrypt`. Este é o padrão.

```swift
app.passwords.use(.bcrypt)
```

O Bcrypt usará um custo de 12, a menos que seja especificado de outra forma. Você pode configurar isso passando o parâmetro `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

O Vapor inclui um hasher de senhas inseguro que armazena e verifica senhas como texto puro. Isso não deve ser usado em produção, mas pode ser útil para testes.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

Para fazer hash de senhas, use o helper `password` disponível no `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Os digests de senha podem ser verificados contra a senha em texto puro usando o método `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

A mesma API está disponível na `Application` para uso durante a inicialização.

```swift
let digest = try app.password.hash("vapor")
```

### Async

Os algoritmos de hashing de senha são projetados para serem lentos e intensivos em CPU. Por causa disso, você pode querer evitar bloquear o event loop durante o hashing de senhas. O Vapor fornece uma API assíncrona de hashing de senhas que despacha o hashing para um pool de threads em background. Para usar a API assíncrona, use a propriedade `async` em um hasher de senhas.

```swift
req.password.async.hash("vapor").map { digest in
    // Tratar digest.
}

// ou

let digest = try await req.password.async.hash("vapor")
```

A verificação de digests funciona de forma similar:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Tratar resultado.
}

// ou

let result = try await req.password.async.verify("vapor", created: digest)
```

Calcular hashes em threads de background pode liberar os event loops da sua aplicação para lidar com mais requisições.
