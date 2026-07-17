# Redis et les sessions

Redis peut agir en tant que stoquage pour mettre en cache les [données de session](../advanced/sessions.md#session-data) comme les identifiants utilisateurs.

Si une instance personnalisée de [`RedisSessionsDelegate`](https://api.vapor.codes/redis/redissessionsdelegate) n'est pas fournie, une instance par défaut sera utilisée.

## Comportement par défaut

### Création de SessionID

À moins que vous n'implémentiez la méthode [`makeNewID()`](https://api.vapor.codes/redis/redissessionsdelegate/makenewid()-3hyne) dans [votre propre `RedisSessionsDelegate`](#redissessionsdelegate), toutes les valeurs [`SessionID`](https://api.vapor.codes/vapor/sessionid) seront créées comme ceci :

1. Génération de caractères aléatoires sur 32 octets
1. Encodage en base64 de la valeur obtenue

Par exemple : `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### Stoquage de SessionData

L'implémentation par défaut de `RedisSessionsDelegate` stoquera les instances de [`SessionData`](https://api.vapor.codes/vapor/sessiondata) comme simple chaîne JSON en utilisant `Codable`.

À moins que vous n'implémentiez la méthode [`makeRedisKey(for:)`](https://api.vapor.codes/redis/redissessionsdelegate/makerediskey(for:)-5nfge) dans votre propre `RedisSessionsDelegate`, les données `SessionData` seront stoquées dans Redis avec une clé composée du préfixe `vrs-` (**V**apor **R**edis **S**essions) et de la valeur de `SessionID`.

Par exemple : `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Enregistrer un Delegate personnalisé

Pour personnaliser la façon dont les données de Redis sont lues et écrites, enregistrez votre propre objet `RedisSessionsDelegate` comme ceci :

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implémentation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> Documentation de l'API : [`RedisSessionsDelegate`](https://api.vapor.codes/redis/redissessionsdelegate)

On peut utiliser un objet conforme à ce protocole pour modifier la façon dont les objets `SessionData` sont stoqués dans Redis.

Il n'y a que deux méthodes à implémenter pour un type se conformant au protocole : [`redis(_:store:with:)`](https://api.vapor.codes/redis/redissessionsdelegate/redis(_:store:with:)) et [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Les deux sont nécessaires, car la façon dont l'écriture des données dans Redis sera personnalisée est intrinsèquement liée à la façon dont elles doivent être lues depuis Redis.

### Exemple de stoquage RedisSessionsDelegate en hash

Par exemple, si vous vouliez stoquer vos données de session sous forme de [**hash** dans Redis](https://redis.io/topics/data-types-intro#redis-hashes), vous implémenteriez quelque-chose similaire à ceci :

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // Stoque chaque champ de données en champ hash distinct
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // la variable hash est de type [String: RESPValue] donc nous devons tenter de déballer
            // la valeur sous le type string et stoquer chaque valeur du contenant.
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
