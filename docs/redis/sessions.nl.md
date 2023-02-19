# Redis & Sessies

Redis kan fungeren als een opslagprovider voor het cachen van [sessie-gegevens](../advanced/sessions.md#session-data) zoals gebruikersgegevens.

Als er geen aangepaste [`RedisSessionsDelegate`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/) is opgegeven, zal er een standaard worden gebruikt.

## Standaard Gedrag

### SessionID Creatie

Tenzij je de [`makeNewID()`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeNewID()) methode implementeert in [je eigen `RedisSessionsDelegate`](#RedisSessionsDelegate), zullen alle [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) waarden aangemaakt worden door het volgende te doen:

1. Genereer 32 bytes van willekeurige tekens
2. base64 codeer de waarde

Bijvoorbeeld: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionData Opslag

De standaard implementatie van `RedisSessionsDelegate` slaat [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) op als een eenvoudige JSON string waarde met behulp van `Codable`.

Tenzij u de [`makeRedisKey(for:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeRedisKey(for:)) methode implementeert in uw eigen `RedisSessionsDelegate`, zal `SessionData` worden opgeslagen in Redis met een sleutel die de `SessionID` voorvoegt met `vrs-` (**V**apor **R**edis **S**essions)

Bijvoorbeeld: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Registreren van een aangepaste delegatie

Om aan te passen hoe de data wordt gelezen van en geschreven naar Redis, registreer je je eigen `RedisSessionsDelegate` object als volgt:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementatie
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> API Documentatie: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/)

Een object dat voldoet aan dit protocol kan worden gebruikt om te veranderen hoe `SessionData` wordt opgeslagen in Redis.

Slechts twee methoden hoeven te worden geïmplementeerd door een type dat voldoet aan het protocol: [`redis(_:store:with:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:store:with:)) en [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:fetchDataFor:)).

Beide zijn nodig, want de manier waarop u de sessiegegevens naar Redis schrijft, is intrinsiek verbonden met de manier waarop ze uit Redis moeten worden gelezen.

### RedisSessionsDelegate Hash Voorbeeld

Als u bijvoorbeeld de sessiegegevens wilt opslaan als een [**Hash** in Redis](https://redis.io/topics/data-types-intro#redis-hashes), dan zou u iets als het volgende implementeren:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // slaat elk gegevensveld op als een afzonderlijk hash-veld
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash is [String: RESPValue] dus we moeten proberen de
            // waarde uit te pakken als een string en elke waarde in de data container op te slaan
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
