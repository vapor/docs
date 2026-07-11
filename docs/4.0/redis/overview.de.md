# Redis

[Redis](https://redis.io/) ist einer der beliebtesten In-Memory-Datenstrukturspeicher, der häufig als Cache oder Message-Broker verwendet wird.

Diese Bibliothek ist eine Integration zwischen Vapor und [**RediStack**](https://github.com/swift-server/RediStack), dem zugrunde liegenden Treiber, der mit Redis kommuniziert.

!!! note
    Die meisten Funktionen von Redis werden durch **RediStack** bereitgestellt.
    Wir empfehlen dringend, dich mit dessen Dokumentation vertraut zu machen.
    
    _Wo passend, sind Links angegeben._

## Package

Der erste Schritt zur Nutzung von Redis besteht darin, es als Abhängigkeit in deinem Swift-Package-Manifest hinzuzufügen.

> Dieses Beispiel bezieht sich auf ein bestehendes Package. Hilfe zum Starten eines neuen Projekts findest du im Hauptleitfaden [Erste Schritte](../getting-started/hello-world.md).

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

## Konfiguration

Vapor verwendet eine Pooling-Strategie für [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection)-Instanzen, und es gibt mehrere Optionen, um sowohl einzelne Verbindungen als auch die Pools selbst zu konfigurieren.

Das absolute Minimum zur Konfiguration von Redis besteht darin, eine URL anzugeben, mit der eine Verbindung hergestellt werden soll:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis-Konfiguration

> API-Dokumentation: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Wenn du mehrere Redis-Endpunkte hast, etwa einen Cluster von Redis-Instanzen, möchtest du stattdessen eine [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress)-Sammlung erstellen, die du an den Initialisierer übergibst.

Die gängigste Art, eine `SocketAddress` zu erstellen, ist die statische Methode [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Bei einem einzelnen Redis-Endpunkt kann es einfacher sein, mit den praktischen Initialisierern zu arbeiten, da diese die Erstellung der `SocketAddress` für dich übernehmen:

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (mit `String` oder [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Wenn deine Redis-Instanz durch ein Passwort gesichert ist, musst du es als Argument `password` übergeben.

Jede Verbindung wird bei ihrer Erstellung mit dem Passwort authentifiziert.

#### database

Dies ist der Datenbankindex, den du beim Erstellen jeder Verbindung auswählen möchtest.

Dadurch ersparst du dir, den Befehl `SELECT` selbst an Redis senden zu müssen.

!!! warning
    Die Datenbankauswahl wird nicht dauerhaft beibehalten. Sei vorsichtig, wenn du den Befehl `SELECT` selbst sendest.

### Optionen für den Connection-Pool

> API-Dokumentation: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note
    Hier werden nur die am häufigsten geänderten Optionen hervorgehoben. Alle Optionen findest du in der API-Dokumentation.

#### minimumConnectionCount

Dies ist der Wert, mit dem festgelegt wird, wie viele Verbindungen jeder Pool jederzeit aufrechterhalten soll.

Wenn dieser Wert `0` ist, werden verlorene Verbindungen aus irgendeinem Grund vom Pool nicht neu erstellt, bis sie benötigt werden.

Dies wird als "Kaltstart"-Verbindung bezeichnet und verursacht im Vergleich zur Aufrechterhaltung einer Mindestanzahl an Verbindungen einen gewissen Mehraufwand.

#### maximumConnectionCount

Diese Option bestimmt das Verhalten, wie die maximale Verbindungsanzahl aufrechterhalten wird.

!!! seealso
    Sieh dir die `RedisConnectionPoolSize`-API an, um dich mit den verfügbaren Optionen vertraut zu machen.

## Einen Befehl senden

Du kannst Befehle über die Eigenschaft `.redis` auf jeder [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application)- oder [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request)-Instanz senden, die dir Zugriff auf einen [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient) gewährt.

Jeder `RedisClient` verfügt über mehrere Erweiterungen für alle möglichen [Redis-Befehle](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Nicht unterstützte Befehle

Sollte **RediStack** einen Befehl nicht mit einer Erweiterungsmethode unterstützen, kannst du ihn dennoch manuell senden.

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

## Pub/Sub-Modus

Redis unterstützt die Möglichkeit, in einen ["Pub/Sub"-Modus](https://redis.io/topics/pubsub) zu wechseln, in dem eine Verbindung bestimmten "Kanälen" zuhören und bestimmte Closures ausführen kann, wenn die abonnierten Kanäle eine "Nachricht" (einen Datenwert) veröffentlichen.

Es gibt einen definierten Lebenszyklus für ein Abonnement:

1. **subscribe**: wird einmalig aufgerufen, wenn das Abonnement zum ersten Mal beginnt
1. **message**: wird 0 oder mehrmals aufgerufen, während Nachrichten an die abonnierten Kanäle veröffentlicht werden
1. **unsubscribe**: wird einmalig aufgerufen, wenn das Abonnement endet, entweder auf Anfrage oder weil die Verbindung verloren geht

Wenn du ein Abonnement erstellst, musst du mindestens einen [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) angeben, um alle Nachrichten zu verarbeiten, die vom abonnierten Kanal veröffentlicht werden.

Optional kannst du einen `RedisSubscriptionChangeHandler` für `onSubscribe` und `onUnsubscribe` angeben, um die jeweiligen Lebenszyklus-Ereignisse zu behandeln.

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
