# Redis

[Redis](https://redis.io/) es uno de los motores de almacenamiento de base de datos en memoria más populares, comúnmente utilizado como caché o intermediario de mensajes.

Esta biblioteca es una integración entre Vapor y [**RediStack**](https://github.com/swift-server/RediStack), que es el controlador subyacente que se comunica con Redis.

!!! note "Nota"
    La mayoría de las capacidades de Redis son proporcionadas por **RediStack**.
    Recomendamos encarecidamente familiarizarse con su documentación.
    
    _Se proporcionan enlaces donde corresponda._

## Paquete

El primer paso para usar Redis es añadirlo como una dependencia a tu proyecto en tu manifiesto de paquete Swift.

> Este ejemplo es para un paquete existente. Para obtener ayuda sobre cómo iniciar un nuevo proyecto, consulta la guía [Comenzando](../getting-started/hello-world.md).

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
]
// ...
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "Redis", package: "redis")
    ])
]
```

## Configurar

Vapor emplea una estrategia de agrupación para instancias de [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection), y hay varias opciones para configurar las conexiones individuales así como los propios grupos.

El mínimo requerido para configurar Redis es proporcionar una URL para conectar:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Configuración de Redis

> Documentación de la API: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Si tienes varios puntos de conexión con Redis, como un grupo de instancias de Redis, querrás crear una colección de [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) para pasar en el inicializador.

La forma más común de crear un `SocketAddress` es con el método estático [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Para un único punto de conexión con Redis, puede ser más fácil trabajar con los inicializadores de conveniencia, ya que manejará la creación del `SocketAddress` por ti:

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (con `String` o [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Si tu instancia de Redis está asegurada con una contraseña, deberás pasarla como el argumento `password`.

Cada conexión, según se crea, será autenticada usando la contraseña.

#### database

Este es el índice de la base de datos que deseas seleccionar cuando se crea cada conexión.

Esto te ahorra tener que enviar el comando `SELECT` a Redis tú mismo.

!!! warning "Advertencia"
    La selección de la base de datos no se mantiene. Ten cuidado al enviar el comando `SELECT` por tu cuenta.

### Opciones del Grupo de Conexiones

> Documentación de la API: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note "Nota"
    Aquí solo se destacan las opciones que se cambian con más frecuencia. Para todas las opciones, consulta la documentación de la API.

#### minimumConnectionCount

Este es el valor que establece cuántas conexiones deseas que cada grupo mantenga en todo momento.

Si el valor es `0`, entonces si las conexiones se pierden por cualquier motivo, el grupo no las recreará hasta que sea necesario.

Esto se conoce como una conexión de "inicio en frío" ("cold start"), y tiene cierta sobrecarga sobre el mantenimiento de un recuento mínimo de conexiones.

#### maximumConnectionCount

Esta opción determina el comportamiento de cómo se mantiene el recuento máximo de conexiones.

!!! seealso "Ver También"
    Consulta la API `RedisConnectionPoolSize` para familiarizarte con las opciones disponibles.

## Enviando un Comando

Puedes enviar comandos usando la propiedad `.redis` en cualquier instancia de [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) o [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request), lo que te dará acceso a un [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

Cualquier `RedisClient` tiene varias extensiones para todos los diversos [comandos de Redis](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// o

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Comandos no soportados

Si **RediStack** no soporta un comando con un método de extensión, aún puedes enviarlo manualmente.

```swift
// cada valor después del comando es el argumento posicional que Redis espera
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// o

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Modo Pub/Sub

Redis admite la capacidad de entrar en un [modo "Pub/Sub"](https://redis.io/topics/pubsub) donde una conexión puede escuchar "canales" específicos y ejecutar closures (métodos) específicos cuando los canales suscritos publican un "mensaje" (algún valor de datos).

Hay un ciclo de vida definido para una suscripción:

1. **subscribe**: invocado una vez cuando la suscripción comienza por primera vez
2. **message**: invocado 0 o más veces a medida que se publican mensajes en los canales suscritos
3. **unsubscribe**: invocado una vez cuando la suscripción termina, ya sea por solicitud o por pérdida de conexión

Cuando creas una suscripción, debes proporcionar al menos un [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) para manejar todos los mensajes que son publicados por el canal suscrito.

Opcionalmente, puedes proporcionar un `RedisSubscriptionChangeHandler` para `onSubscribe` y `onUnsubscribe` para manejar sus respectivos eventos del ciclo de vida.

```swift
// crea 2 suscripciones, una para cada canal
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // haz algo con el mensaje
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
