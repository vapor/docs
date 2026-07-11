# Redis

[Redis](https://redis.io/)는 캐시나 메시지 브로커로 흔히 사용되는, 가장 인기 있는 인메모리 데이터 구조 저장소 중 하나입니다.

이 라이브러리는 Vapor와 [**RediStack**](https://github.com/swift-server/RediStack) 사이의 통합으로, RediStack은 Redis와 통신하는 기반 드라이버입니다.

!!! note
    Redis의 기능 대부분은 **RediStack**에 의해 제공됩니다.
    RediStack의 문서를 잘 숙지하는 것을 적극 권장합니다.

    _관련 링크는 적절한 위치에 제공됩니다._

## 패키지

Redis를 사용하는 첫 번째 단계는 Swift 패키지 매니페스트에 의존성으로 추가하는 것입니다.

> 이 예제는 기존 패키지를 대상으로 합니다. 새 프로젝트를 시작하는 방법은 메인 [시작하기](../getting-started/hello-world.md) 가이드를 참고하세요.

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

## 설정

Vapor는 [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection) 인스턴스에 대해 풀링 전략을 사용하며, 개별 연결뿐만 아니라 풀 자체를 설정할 수 있는 다양한 옵션을 제공합니다.

Redis를 설정하는 데 필요한 최소한의 사항은 연결할 URL을 제공하는 것입니다.

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis Configuration

> API 문서: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Redis 인스턴스 클러스터와 같이 여러 Redis 엔드포인트가 있는 경우, 대신 초기화 메서드에 전달할 [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) 컬렉션을 생성해야 합니다.

`SocketAddress`를 생성하는 가장 일반적인 방법은 [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)) 정적 메서드를 사용하는 것입니다.

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

단일 Redis 엔드포인트의 경우, 편의 초기화 메서드를 사용하는 것이 더 편할 수 있습니다. 이 메서드가 알아서 `SocketAddress`를 생성해주기 때문입니다.

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (`String` 또는 [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url) 사용)
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Redis 인스턴스가 비밀번호로 보호되어 있다면, 이를 `password` 인자로 전달해야 합니다.

각 연결은 생성될 때 이 비밀번호를 사용하여 인증됩니다.

#### database

이는 각 연결이 생성될 때 선택하고자 하는 데이터베이스 인덱스입니다.

이를 통해 직접 Redis에 `SELECT` 명령을 보내지 않아도 됩니다.

!!! warning
    데이터베이스 선택 상태는 유지되지 않습니다. 직접 `SELECT` 명령을 보낼 때는 주의하세요.

### 연결 풀 옵션

> API 문서: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note
    여기서는 가장 흔히 변경되는 옵션만 다룹니다. 전체 옵션은 API 문서를 참고하세요.

#### minimumConnectionCount

이는 각 풀이 항상 유지하기를 원하는 연결 개수를 설정하는 값입니다.

값이 `0`이면, 어떤 이유로든 연결이 끊어졌을 때 풀은 필요할 때까지 연결을 다시 생성하지 않습니다.

이를 "콜드 스타트(cold start)" 연결이라고 하며, 최소 연결 개수를 유지하는 것보다 약간의 오버헤드가 발생합니다.

#### maximumConnectionCount

이 옵션은 최대 연결 개수가 유지되는 방식을 결정합니다.

!!! seealso
    사용 가능한 옵션을 확인하려면 `RedisConnectionPoolSize` API를 참고하세요.

## 명령 보내기

모든 [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) 또는 [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) 인스턴스의 `.redis` 속성을 사용하여 명령을 보낼 수 있으며, 이를 통해 [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient)에 접근할 수 있습니다.

모든 `RedisClient`는 다양한 [Redis 명령](https://redis.io/commands)에 대한 여러 확장 기능을 제공합니다.

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### 지원되지 않는 명령

**RediStack**이 확장 메서드로 특정 명령을 지원하지 않더라도, 여전히 수동으로 보낼 수 있습니다.

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

## Pub/Sub 모드

Redis는 ["Pub/Sub" 모드](https://redis.io/topics/pubsub)에 진입할 수 있는 기능을 지원합니다. 이 모드에서는 연결이 특정 "채널"을 구독(listen)하고, 구독한 채널이 "메시지"(어떤 데이터 값)를 발행(publish)할 때 특정 클로저를 실행할 수 있습니다.

구독에는 정의된 생명주기가 있습니다.

1. **subscribe**: 구독이 처음 시작될 때 한 번 호출됩니다
1. **message**: 구독한 채널에 메시지가 발행될 때마다 0회 이상 호출됩니다
1. **unsubscribe**: 요청에 의해서든 연결 끊김에 의해서든, 구독이 종료될 때 한 번 호출됩니다

구독을 생성할 때는, 구독한 채널이 발행하는 모든 메시지를 처리할 [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver)를 최소한 제공해야 합니다.

선택적으로 각 생명주기 이벤트를 처리할 `onSubscribe` 및 `onUnsubscribe`를 위한 `RedisSubscriptionChangeHandler`를 제공할 수도 있습니다.

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
