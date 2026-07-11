# Redis & Sessions

Redis kann als Speicheranbieter zum Cachen von [Session-Daten](../advanced/sessions.md#session-data) wie Nutzeranmeldedaten fungieren.

Wenn kein benutzerdefinierter [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) bereitgestellt wird, wird ein Standard verwendet.

## Standardverhalten

### SessionID-Erstellung

Sofern du die Methode [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) nicht in [deinem eigenen `RedisSessionsDelegate`](#redissessionsdelegate) implementierst, werden alle [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid)-Werte auf folgende Weise erzeugt:

1. Generiere 32 Bytes an zufälligen Zeichen
1. Kodiere den Wert base64

Zum Beispiel: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionData-Speicherung

Die Standardimplementierung von `RedisSessionsDelegate` speichert [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) mithilfe von `Codable` als einfachen JSON-String-Wert.

Sofern du die Methode [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) nicht in deinem eigenen `RedisSessionsDelegate` implementierst, wird `SessionData` in Redis mit einem Schlüssel gespeichert, der der `SessionID` das Präfix `vrs-` voranstellt (**V**apor **R**edis **S**essions)

Zum Beispiel: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Einen benutzerdefinierten Delegate registrieren

Um anzupassen, wie die Daten aus Redis gelesen und in Redis geschrieben werden, registriere dein eigenes `RedisSessionsDelegate`-Objekt wie folgt:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> API-Dokumentation: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

Ein Objekt, das diesem Protokoll entspricht, kann verwendet werden, um zu ändern, wie `SessionData` in Redis gespeichert wird.

Nur zwei Methoden müssen von einem Typ implementiert werden, der dem Protokoll entspricht: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) und [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Beide werden benötigt, da die Art und Weise, wie du das Schreiben der Session-Daten nach Redis anpasst, untrennbar damit verbunden ist, wie sie aus Redis gelesen werden.

### RedisSessionsDelegate-Hash-Beispiel

Wenn du zum Beispiel die Session-Daten als [**Hash** in Redis](https://redis.io/topics/data-types-intro#redis-hashes) speichern möchtest, würdest du etwa Folgendes implementieren:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // stores each data field as a separate hash field
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash is [String: RESPValue] so we need to try and unwrap the
            // value as a string and store each value in the data container
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
