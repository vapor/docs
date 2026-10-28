# Redis

[Redis](https://redis.io/) est l'un des moteurs de stockage de données structurées en mémoire les plus populaires, souvent utilisé comme cache ou pour gérer les messages entre services.

Cette librairie est une intégration entre Vapor et [**RediStack**](https://github.com/swift-server/RediStack), qui est le driver encapsulé communiquant avec Redis.

!!! Note
    La plupart des fonctionnalités de Redis sont fournies par **RediStack**.
    Nous vous recommandons donc fortement de vous familiariser avec sa documentation.
    
    _Nous indiquerons des liens aux endroits pertinents._

## Package

La première étape pour utiliser Redis consiste à l'ajouter aux dépendances de votre projet dans le manifeste Swift du package.

> Cet exemple est pour un package existant. Pour démarrer un nouveau projet, référez-vous au guide de démarrage [Premiers pas](../getting-started/hello-world.md).

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

## Configuration

Vapor utilise une stratégie de pooling pour les instances de [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection), et plusieurs options existent pour configurer des connexions individuelles ou des pools eux-mêmes.

Le strict minimum requis pour configurer Redis est de lui fournir une URL à laquelle se connecter :

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Configuration de Redis

> Documentation de l'API : [`RedisConfiguration`](https://api.vapor.codes/redis/redisconfiguration)

#### serverAddresses

Si vous avez plusieurs endpoints Redis, comme un cluster d'instances Redis, vous voudrez plutôt créer une collection de [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) à fournir à la méthode d'initialisation.

La façon la plus courante de créer des `SocketAddress` est via la méthode statique [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Pour un endpoint Redis unique, il peut être plus facile d'utiliser ces méthodes d'initialisation alternatives, qui créeront pour vous l'objet `SocketAddress` :

- [`.init(url:pool)`](https://api.vapor.codes/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (attend `String` ou [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### Mot de passe

Si votre instance Redis est sécurisée par mot de passe, vous devrez le lui transmettre via l'argument `password`.

Chaque connexion, au moment de sa création, sera authentifiée par ce mot de passe.

#### Base de données

Il s'agit de l'index de base de données que vous souhaitez sélectionner lors de chaque création d'une nouvelle connexion.

Cela vous évite d'envoyer vous-même la commande `SELECT` à Redis.

!!! Attention
    La sélection de base de données n'est pas maintenue. Soyez prudent si vous envoyez la commande `SELECT` vous-même.

### Options du pool de connexions

> Documentation de l'API : [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/redisconfiguration/pooloptions)

!!! Note
    Seules les options qui sont le plus fréquemment modifiées sont présentées ici. Pour voir toutes les options, veuillez vous référer à la documentation de l'API.

#### minimumConnectionCount

Cette valeur définit combien de connexions vous souhaitez que chaque pool maintienne ouvertes en permanence.

Si vous indiquez la valeur `0`, et que les connexions sont perdues pour quelque raison que ce soit, alors le pool ne re-créera pas de connexion tant qu'il n'en aura pas besoin d'une.

C'est ce qu'on appelle une connexion avec "démarrage à froid", et n'ajoute pas de surcharge pour maintenir un nombre minimum de connexions ouvertes.

#### maximumConnectionCount

Cette option définit le comportement à adopter concernant le maintien du nombre maximum de connexions.

!!! Voir aussi
    Référez-vous à l'API `RedisConnectionPoolSize` pour vous familiariser avec les options disponibles.

## Envoyer une commande

Vous pouvez envoyer des commandes grâce à la propriété `.redis` exposée par les instances des objets [`Application`](https://api.vapor.codes/vapor/application) ou [`Request`](https://api.vapor.codes/vapor/request), qui vous donne accès à une instance [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

Chaque `RedisClient` possède différentes extensions pour les différentes [commandes Redis](https://redis.io/commands) correspondantes.

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// ou

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Commandes non supportées

Si **RediStack** ne proposait pas une commande via une méthode de ses extensions, vous pouvez toujours l'envoyer manuellement.

```swift
// Chaque valeur qui suit la commande est un argument positionnel attendu par Redis.
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// ou

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Mode Pub/Sub

Redis a la capacité de fonctionner en mode ["Pub/Sub"](https://redis.io/topics/pubsub) où une connexion peut écouter un "canal" spécifique, et exécuter des closures spécifiques lorsque le canal de l'abonnement publie un "message" (des valeurs de données).

Un abonnement suit un cycle de vie défini :

1. **subscribe** : invoqué lorsque l'abonnement est déclaré.
1. **message** : invoqué 0 ou plusieurs fois en fonction de la publication de messages dans les canaux concernés par l'abonnement.
1. **unsubscribe** : invoqué lorsque l'abonnement prend fin, par requête explicite ou perte de connexion.

Quand vous créez un abonnement, vous devez au moins fournir un [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) pour gérer la réception de messages publiés dans les canaux souscrits.

Vous pouvez aussi fournir un `RedisSubscriptionChangeHandler` à `onSubscribe` et `onUnsubscribe` pour réagir aux évènements du cycle de vie de début et fin d'abonnement.

```swift
// Crée 2 abonnements, un pour chaque canal.
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // Traiter le message reçu ici.
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("Désabonné du canal \(channel)")
    print("Abonnements restant : \(subscriptionCount)")
  }
```
