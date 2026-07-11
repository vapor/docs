# Redis i sesje

Redis może pełnić rolę dostawcy przechowywania danych do buforowania [danych sesji](../advanced/sessions.md#dane-sesji), takich jak dane uwierzytelniające użytkownika.

Jeśli niestandardowy [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) nie zostanie dostarczony, zostanie użyty domyślny.

## Domyślne zachowanie

### Tworzenie SessionID

Jeśli nie zaimplementujesz metody [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) we [własnym `RedisSessionsDelegate`](#redissessionsdelegate), wszystkie wartości [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) będą tworzone w następujący sposób:

1. Wygenerowanie 32 bajtów losowych znaków
1. Zakodowanie wartości w base64

Na przykład: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### Przechowywanie SessionData

Domyślna implementacja `RedisSessionsDelegate` przechowuje [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) jako prosty ciąg znaków JSON przy użyciu `Codable`.

Jeśli nie zaimplementujesz metody [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) we własnym `RedisSessionsDelegate`, `SessionData` będzie przechowywane w Redis pod kluczem, który poprzedza `SessionID` prefiksem `vrs-` (**V**apor **R**edis **S**essions)

Na przykład: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Rejestrowanie niestandardowego delegata

Aby dostosować sposób odczytu i zapisu danych w Redis, zarejestruj własny obiekt `RedisSessionsDelegate` w następujący sposób:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> Dokumentacja API: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

Obiekt zgodny z tym protokołem może być użyty do zmiany sposobu przechowywania `SessionData` w Redis.

Typ zgodny z protokołem musi implementować tylko dwie metody: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) oraz [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Obie są wymagane, ponieważ sposób, w jaki dostosowujesz zapis danych sesji do Redis, jest nierozerwalnie związany ze sposobem ich odczytu z Redis.

### Przykład RedisSessionsDelegate z użyciem Hash

Na przykład, jeśli chcesz przechowywać dane sesji jako [**Hash** w Redis](https://redis.io/topics/data-types-intro#redis-hashes), możesz zaimplementować coś w następujący sposób:

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
