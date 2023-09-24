# Redis

[Redis](https://redis.io/) è uno dei più popolari store di strutture dati residente in memoria comunemente usato come cache o broker di messaggi.

Questa libreria è un'integrazione tra Vapor e [**RediStack**](https://github.com/swift-server/RediStack), che è il driver sottostante che comunica con Redis.

!!! note
    La maggior parte delle funzionalità di Redis sono fornite da **RediStack**.
    Raccomandiamo fortemente di acquisire familiarità con la sua documentazione.
    
    _I link saranno forniti quando appropriato._

## Pacchetto

Il primo passo per usare Redis è aggiungerlo come dipendenza al tuo progetto nel tuo manifesto del pacchetto Swift.

> Questo esempio è per un pacchetto esistente. Per avere aiuto a iniziare un nuovo progetto, guarda la guida principale su [Inizio](../getting-started/hello-world.md).

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

## Configura

Vapor impiega una strategia di pooling per le istanze [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection), e ci sono varie opzioni per configurare connessioni singole come anche le pool stesse.

Il minimo indispensabile richiesto per configurare Redis è fornire un URL per connettersi:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Configurazione di Redis

> Documentazione dell'API: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Se hai più endpoint Redis, come un cluster di istanze Redis, vorrai invece creare una collezione di [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) da passare all'inizializzatore.

Il modo più comune di creare un `SocketAddress` è con il metodo statico [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Per un singolo endpoint Redis, potrebbe essere più facile lavorare con gli inizializzatori pratici, in quanto si occuperanno di creare il `SocketAddress` per te:

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (con `String` o [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Se la tua istanza Redis è protetta da una password, dovrai passarla come argomento `password`.

Ogni connessione, quando viene creata, sarà autenticata usando la password.

#### database

Questo è l'indice del database che intendi selezionare quando ogni connessione viene creata.

Questo ti evita di dover mandare il comando `SELECT` a Redis da te.

!!! warning
    La selezione del database non è mantenuta. Stai attento quando mandi il comando `SELECT` da te.

### Opzioni del Pool di Connessioni

> Documentazione dell'API: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note
    Solo le opzioni cambiate più comunemente sono evidenziate qui. Per tutte le altre opzioni, fai riferimento alla documentazione dell'API.

#### minimumConnectionCount

Questo è il valore che indica quante connessioni vuoi che ogni pool mantenga in ogni momento.

Se il tuo valore è `0` allora se le connessioni si perdono per qualsiasi motivo, la pool non le ricreerà fino a quando non sarà necessario.

Questa è conosciuta come connessione "cold start", e ha dell'overhead rispetto a mantenere un numero di connessioni minime.

#### maximumConnectionCount

Quest'opzione determina il comportamento di come il numero massimo di connessioni è mantenuto.

!!! seealso
    Fai riferimento all'API `RedisConnectionPoolSize` per familiarizzare con le opzioni disponibili.

## Inviare un Comando

Puoi inviare comandi usando la proprietà `.redis` su ogni istanza di [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) o di [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request), che ti darà accesso a [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

Ogni `RedisClient` ha diverse estensioni per tutti i vari [comandi Redis](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// oppure

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Comandi Non Supportati

Se **RediStack** non dovesse supportare un comando con un metodo di estensione, puoi comunque mandarlo manualmente.

```swift
// ogni valore dopo il comando è l'argomento di posizione che Redis si aspetta
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// oppure

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Modalità Pub/Sub

Redis supporta la possibilità di entrare in una [modalità "Pub/Sub"](https://redis.io/topics/pubsub) dove una connessione può ascoltare specifici "canali" ed eseguire specifiche closure quando i canali abbonati pubblicano un "messaggio" (qualche valore dei dati).

Un abbonamento ha un ciclo di vita ben definito:

1. **subscribe**: invocato una volta quando l'abbonamento inizia
1. **message**: invocato da 0 a più volte man mano che i messaggi sono pubbicati ai canali abbonati
1. **unsubscribe**: invocato una volta quando l'abbonamento finisce, o su richiesta o quando la connessione viene persa

Quando crei un abbonamento, devi fornire al meno un [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) per gestire tutti i messaggi che sono pubblicati dai canali abbonati.

Puoi facoltativamente fornire un `RedisSubscriptionChangeHandler` per `onSubscribe` e `onUnsubscribe` per gestire i loro rispettivi eventi di ciclo di vita.

```swift
// crea 2 abbonamenti, uno per ogni canale fornito
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // fai qualcosa col messaggio
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
