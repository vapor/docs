# Redis

[Redis](https://redis.io/) to jeden z najpopularniejszych magazynów struktur danych działających w pamięci, powszechnie używany jako cache lub broker wiadomości.

Ta biblioteka jest integracją Vapora z [**RediStack**](https://github.com/swift-server/RediStack), która stanowi bazowy sterownik komunikujący się z Redisem.

!!! note
    Większość możliwości Redisa jest dostarczana przez **RediStack**.
    Zdecydowanie polecamy zapoznanie się z jego dokumentacją.
    
    _W odpowiednich miejscach podane są odnośniki._

## Paczka

Pierwszym krokiem do korzystania z Redisa jest dodanie go jako zależności w manifeście Twojej paczki Swift.

> Ten przykład dotyczy istniejącej paczki. Aby uzyskać pomoc przy zakładaniu nowego projektu, zapoznaj się z głównym przewodnikiem [Jak zacząć](../getting-started/hello-world.md).

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

## Konfiguracja

Vapor wykorzystuje strategię pulowania dla instancji [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection), a dostępnych jest kilka opcji do konfigurowania zarówno pojedynczych połączeń, jak i samych puli.

Absolutnym minimum wymaganym do skonfigurowania Redisa jest podanie adresu URL, z którym ma się połączyć:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Konfiguracja Redisa

> Dokumentacja API: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Jeśli masz wiele punktów końcowych Redisa, na przykład klaster instancji Redis, będziesz musiał zamiast tego utworzyć kolekcję [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) i przekazać ją do inicjalizatora.

Najczęstszym sposobem tworzenia `SocketAddress` jest statyczna metoda [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Dla pojedynczego punktu końcowego Redisa łatwiej jest skorzystać z inicjalizatorów pomocniczych, ponieważ zajmą się one utworzeniem `SocketAddress` za Ciebie:

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (z `String` lub [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Jeśli Twoja instancja Redisa jest zabezpieczona hasłem, musisz przekazać je jako argument `password`.

Każde tworzone połączenie zostanie uwierzytelnione przy użyciu tego hasła.

#### database

Jest to indeks bazy danych, który chcesz wybrać przy tworzeniu każdego połączenia.

Dzięki temu nie musisz samodzielnie wysyłać do Redisa komendy `SELECT`.

!!! warning
    Wybór bazy danych nie jest utrzymywany. Zachowaj ostrożność przy samodzielnym wysyłaniu komendy `SELECT`.

### Opcje puli połączeń

> Dokumentacja API: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note
    Tutaj wyróżnione są tylko najczęściej zmieniane opcje. Wszystkie opcje znajdziesz w dokumentacji API.

#### minimumConnectionCount

Jest to wartość określająca, ile połączeń każda pula ma zawsze utrzymywać.

Jeśli ustawisz wartość `0`, to w przypadku utraty połączeń z dowolnego powodu, pula nie odtworzy ich, dopóki nie będą potrzebne.

Jest to znane jako połączenie typu „cold start” i wiąże się z pewnym narzutem w porównaniu do utrzymywania minimalnej liczby połączeń.

#### maximumConnectionCount

Ta opcja określa sposób utrzymywania maksymalnej liczby połączeń.

!!! seealso
    Zapoznaj się z API `RedisConnectionPoolSize`, aby poznać dostępne opcje.

## Wysyłanie komendy

Możesz wysyłać komendy za pomocą właściwości `.redis` na dowolnej instancji [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) lub [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request), która da Ci dostęp do [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

Każdy `RedisClient` posiada wiele rozszerzeń dla różnych [komend Redisa](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Nieobsługiwane komendy

Jeśli **RediStack** nie obsługuje jakiejś komendy za pomocą metody rozszerzającej, nadal możesz wysłać ją ręcznie.

```swift
// each value after the command is the positional argument that Redis expects
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// or

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Tryb Pub/Sub

Redis obsługuje możliwość wejścia w [tryb „Pub/Sub”](https://redis.io/topics/pubsub), w którym połączenie może nasłuchiwać konkretnych „kanałów” i uruchamiać określone domknięcia, gdy subskrybowane kanały opublikują „wiadomość” (jakąś wartość danych).

Subskrypcja ma zdefiniowany cykl życia:

1. **subscribe**: wywoływane raz, gdy subskrypcja się rozpoczyna
1. **message**: wywoływane 0 lub więcej razy, gdy wiadomości są publikowane na subskrybowanych kanałach
1. **unsubscribe**: wywoływane raz, gdy subskrypcja się kończy, na żądanie lub w wyniku utraty połączenia

Podczas tworzenia subskrypcji musisz podać przynajmniej [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver), aby obsłużyć wszystkie wiadomości publikowane przez subskrybowany kanał.

Opcjonalnie możesz podać `RedisSubscriptionChangeHandler` dla `onSubscribe` i `onUnsubscribe`, aby obsłużyć odpowiednie zdarzenia cyklu życia.

```swift
// creates 2 subscriptions, one for each given channel
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // do something with the message
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
