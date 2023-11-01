# Redis y Sesiones

Redis puede actuar como un proveedor de almacenamiento para el caché de [datos de sesión](../advanced/sessions.md#session-data) como las credenciales del usuario.

Si no se proporciona un [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) personalizado, se usará uno predeterminado.

## Comportamiento Predeterminado

### Creación de SessionID

A menos que implementes el método [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) en [tu propio RedisSessionsDelegate](#redissessionsdelegate), todos los valores de [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) se crearán haciendo lo siguiente:

1. Generar 32 bytes de caracteres aleatorios.
2. Codificar el valor en base64.

Por ejemplo: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### Almacenamiento de SessionData

La implementación predeterminada de `RedisSessionsDelegate` almacenará [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) como un simple valor de cadena JSON usando `Codable`.

A menos que implementes el método [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) en tu propio `RedisSessionsDelegate`, `SessionData` se almacenará en Redis con una clave que antepone el `SessionID` con `vrs-` (**V**apor **R**edis **S**essions).

Por ejemplo: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Registrando un Delegado Personalizado

Para personalizar cómo se lee y se escriben los datos en Redis, registra tu propio objeto `RedisSessionsDelegate` de la siguiente manera:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementación
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> Documentación de la API: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

Un objeto que cumple con este protocolo puede usarse para cambiar cómo `SessionData` se almacena en Redis.

Solo dos métodos son requeridos para ser implementados por un tipo que cumpla con el protocolo: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) y [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Ambos son obligatorios, ya que la forma en que personalizas la escritura de los datos de sesión en Redis está intrínsecamente vinculada a cómo se lee de Redis.

### Ejemplo de RedisSessionsDelegate Hash

Por ejemplo, si quisieras almacenar los datos de sesión como un [**Hash** en Redis](https://redis.io/topics/data-types-intro#redis-hashes), podrías implementar algo como lo siguiente:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // almacena cada campo de datos como un campo hash separado
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash es [String: RESPValue], por lo que necesitamos intentar desempaquetar el
            // valor como una cadena y almacenar cada valor en el contenedor de datos
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
