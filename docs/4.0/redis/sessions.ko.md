# Redis & 세션

Redis는 사용자 자격 증명과 같은 [세션 데이터](../advanced/sessions.md#session-data)를 캐싱하기 위한 저장소 제공자 역할을 할 수 있습니다.

사용자 정의 [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)가 제공되지 않으면, 기본 델리게이트가 사용됩니다.

## 기본 동작

### SessionID 생성

[여러분만의 `RedisSessionsDelegate`](#redissessionsdelegate)에 [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) 메서드를 구현하지 않는 한, 모든 [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) 값은 다음과 같은 방식으로 생성됩니다.

1. 32바이트의 무작위 문자를 생성합니다
1. 이 값을 base64로 인코딩합니다

예를 들어: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionData 저장

`RedisSessionsDelegate`의 기본 구현은 [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata)를 `Codable`을 사용하여 단순한 JSON 문자열 값으로 저장합니다.

여러분만의 `RedisSessionsDelegate`에 [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) 메서드를 구현하지 않는 한, `SessionData`는 `SessionID` 앞에 `vrs-`(**V**apor **R**edis **S**essions) 접두사가 붙은 키로 Redis에 저장됩니다.

예를 들어: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## 사용자 정의 델리게이트 등록하기

데이터가 Redis에서 읽히고 쓰이는 방식을 사용자 정의하려면, 다음과 같이 여러분만의 `RedisSessionsDelegate` 객체를 등록하십시오.

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> API 문서: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

이 프로토콜을 준수하는 객체는 `SessionData`가 Redis에 저장되는 방식을 변경하는 데 사용할 수 있습니다.

이 프로토콜을 준수하는 타입이 구현해야 하는 메서드는 [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:))와 [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)) 두 가지뿐입니다.

세션 데이터를 Redis에 쓰는 방식을 사용자 정의하는 것은 Redis에서 그것을 읽는 방식과 본질적으로 연결되어 있기 때문에, 두 메서드 모두 반드시 구현해야 합니다.

### RedisSessionsDelegate 해시(Hash) 예제

예를 들어, 세션 데이터를 [Redis의 **Hash**](https://redis.io/topics/data-types-intro#redis-hashes)로 저장하고 싶다면, 다음과 같이 구현할 수 있습니다.

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
