# Redis

[Redis](https://redis.io/) is een van de populairste in-memory data structuur opslagplaatsen die vaak gebruikt worden als een cache of message broker.

Deze bibliotheek is een integratie tussen Vapor en [**RediStack**](https://gitlab.com/mordil/redistack), wat de onderliggende driver is die communiceert met Redis.

!!! note
    De meeste mogelijkheden van Redis worden geleverd door **RediStack**.
    We raden ten zeerste aan om vertrouwd te zijn met de documentatie ervan.
    
    _Waar nodig zijn links opgenomen._

## Package

De eerste stap om Redis te gebruiken is het toevoegen als een dependency aan je project in je Swift package manifest.

> Dit voorbeeld is voor een bestaand pakket. Voor hulp bij het starten van een nieuw project, zie de hoofdgids [Getting Started](../getting-started/hello-world.md).

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

## Configuratie

Vapor gebruikt een pooling strategie voor [`RedisConnection`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisconnection) instanties, en er zijn verschillende opties om zowel individuele verbindingen als de pools zelf te configureren.

Het absolute minimum dat nodig is voor het configureren van Redis is het opgeven van een URL om verbinding mee te maken:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis Configuratie

> API Documentatie: [`RedisConfiguration`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/)

#### serverAddresses

Als u meerdere Redis eindpunten heeft, zoals een cluster van Redis instanties, dan kunt u beter een [`[SocketAddress]`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) verzameling maken om in plaats daarvan de initializer mee te geven.

De meest gebruikelijke manier om een `SocketAddress` aan te maken is met de [`makeAddressResolvingHost(_:port:)`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) statische methode.

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Voor een enkel Redis endpoint, kan het makkelijker zijn om met de convenience initializers te werken, omdat die het `SocketAddress` voor je aanmaken:

- [`.init(url:pool)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(url:pool:)) (met `String` of [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(hostname:port:password:database:pool:))

#### wachtwoord

Als uw Redis instance beveiligd is met een wachtwoord, moet u dit opgeven als `password` argument.

Elke verbinding die wordt gemaakt, zal worden geauthenticeerd met het wachtwoord.

#### database

Dit is de database index die u wenst te selecteren wanneer elke verbinding wordt gemaakt.

Dit bespaart u het `SELECT` commando zelf naar Redis te moeten sturen.

!!! warning "Waarschuwing"
    De database selectie wordt niet bijgehouden. Wees voorzichtig met zelfstandig versturen van het `SELECT` commando.

### Connection Pool Opties

> API Documentatie: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration_PoolOptions/)

!!! note
    Alleen de opties die het meest worden gewijzigd worden hier uitgelicht. Voor alle opties, raadpleeg de API documentatie.

#### minimumConnectionCount

Dit is de waarde om in te stellen hoeveel verbindingen je wilt dat elke pool te allen tijde onderhoudt.

Als de waarde `0` is, zullen verbindingen die om welke reden dan ook verloren gaan, niet opnieuw worden aangemaakt totdat ze nodig zijn.

Dit staat bekend als een "koude start" verbinding, en heeft wel enige overhead ten opzichte van het handhaven van een minimum aantal verbindingen.

#### maximumConnectionCount

Deze optie bepaalt het gedrag van hoe het maximum aantal verbindingen wordt bijgehouden.

!!! seealso "Zie ook"
    Raadpleeg de `RedisConnectionPoolSize` API om te weten welke mogelijkheden beschikbaar zijn.

## Een commando versturen

Je kunt commando's sturen met de `.redis` eigenschap op elke [`Application`](https://api.vapor.codes/vapor/main/Vapor/Application/) of [`Request`](https://api.vapor.codes/vapor/main/Vapor/Request/) instantie, die je toegang geeft tot een [`RedisClient`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisclient).

Elke `RedisClient` heeft verschillende extensies voor alle verschillende [Redis commando's](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// of

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Niet ondersteunde commando's

Als **RediStack** een commando met een extensiemethode niet ondersteunt, kunt u het nog steeds handmatig verzenden.

```swift
// elke waarde na het commando is het positionele argument dat Redis verwacht
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// of

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Pub/Sub Mode

Redis ondersteunt de mogelijkheid om een ["Pub/Sub" modus](https://redis.io/topics/pubsub) in te schakelen waarbij een verbinding kan luisteren naar specifieke "kanalen" en specifieke afsluitingen kan uitvoeren wanneer de geabonneerde kanalen een "bericht" publiceren (een of andere gegevenswaarde).

Er is een bepaalde levenscyclus voor een abonnement:

1. **subscribe**: eenmaal aangeroepen wanneer het abonnement voor het eerst start
1. **message**: 0+ keer aangeroepen als berichten worden gepubliceerd in de geabonneerde kanalen
1. **unsubscribe**: eenmaal aangeroepen wanneer het abonnement eindigt, hetzij door een verzoek, hetzij doordat de verbinding wordt verbroken

Wanneer je een abonnement aanmaakt, moet je minstens een [`messageReceiver`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redissubscriptionmessagereceiver) voorzien om alle berichten te behandelen die gepubliceerd worden door het geabonneerde kanaal.

U kunt optioneel een `RedisSubscriptionChangeHandler` opgeven voor `onSubscribe` en `onUnsubscribe` om hun respectievelijke lifecycle events af te handelen.

```swift
// creëert 2 abonnementen, een voor elk gegeven kanaal
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // doe iets met de boodschap
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
