# Contraseñas

Vapor incluye una API para el hashing de contraseñas que te ayuda a almacenarlas y verificarlas de forma segura. Esta API es configurable según el entorno y admite hashing asíncrono.

## Configuración

Para configurar el hasher de contraseñas de Application, utiliza `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Para usar la [API de Bcrypt](crypto.md#bcrypt) de Vapor para el hashing de contraseñas, especifica `.bcrypt`. Esta es la opción predeterminada.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt utilizará un coste de 12 a menos que se especifique lo contrario. Puedes configurar esto pasando el parámetro `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Texto plano

Vapor incluye un hasher de contraseñas inseguro que almacena y verifica contraseñas como texto plano. Esto no debe usarse en producción, pero puede ser útil para pruebas.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

Para hashear contraseñas, utiliza el helper `password` disponible en `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Los hashes de contraseñas se pueden verificar con la contraseña en texto plano utilizando el método `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

La misma API está disponible en `Application` para su uso durante el arranque.

```swift
let digest = try app.password.hash("vapor")
```

### Async 
Los algoritmos de hashing de contraseñas están diseñados para ser lentos y consumir muchos recursos de CPU. Por esta razón, es posible que desees evitar bloquear el event loop mientras haces el hashing de contraseñas. Vapor proporciona una API asíncrona para hashing de contraseñas que envía el proceso de hashing a un pool de hilos en segundo plano. Para usar la API asíncrona, utiliza la propiedad `async` en un hasher de contraseñas.

```swift
req.password.async.hash("vapor").map { digest in
    // Utiliza el digest.
}

// o

let digest = try await req.password.async.hash("vapor")
```

La verificación de hashes funciona de manera similar:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Utiliza el resultado.
}

// o

let result = try await req.password.async.verify("vapor", created: digest)
```

Calcular hashes en hilos en segundo plano puede liberar los event loops de tu aplicación para manejar más solicitudes entrantes.
