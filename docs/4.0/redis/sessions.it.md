# Redis & Sessioni

Redis può fungere da provider di archiviazione per il caching dei [dati di sessione](../advanced/sessions.md#session-data) come le credenziali degli utenti.

Se non viene fornito un [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) personalizzato, sarà utilizzato quello di default.

## Comportamento di Default

### Creazione di SessionID

A meno che non implementi il metodo [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) nel [tuo `RedisSessionsDelegate` personale](#redissessionsdelegate), tutti i valori [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) saranno creati facendo quanto segue:

1. Generare 32 byte di caratteri casuali
1. Codificare il valore in base64

Per esempio: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### Archiviazione di SessionData

L'implementazione di default di `RedisSessionsDelegate` salverà [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) come una semplice stringa JSON usando `Codable`.

A meno che non implementi il metodo [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) nel tuo `RedisSessionsDelegate` personale, `SessionData` sarà salvato in Redis con una chiave che precede il `SessionID` con `vrs-` (**V**apor **R**edis **S**essions)

Per esempio: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Registrare un Delegato Modificato

Per modificare il modo in cui i dati vengono letti e scritti su Redis, registra il tuo oggetto `RedisSessionsDelegate` come segue:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementazione
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> Documentazione dell'API: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

Un oggetto che è conforme a questo protocollo può essere usato per cambiare come `SessionData` è salvato in Redis.

Viene richiesto di implementare solo due metodi a un tipo conforme al protocollo: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) e [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Entrambi sono necessari, in quanto il modo in cui tu personalizzi la scrittura dei dati di sessione su Redis è intrinsecamente legato a come deve essere letto da Redis.

### Esempio di Hash di RedisSessionsDelegate

Per esempio, se vuoi salvare i dati di sessione come un [**Hash** in Redis](https://redis.io/topics/data-types-intro#redis-hashes), dovresti implementare qualcosa simile a quanto segue:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // salva ogni campo dei dati come un campo hash separato
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash è [String: RESPValue] quindi dobbiamo provare e spacchettare il
            // valore come una stringa e salvare ogni valore nel container dei dati
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
