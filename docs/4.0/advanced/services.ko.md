# 서비스(Services)

Vapor의 `Application`과 `Request`는 여러분의 애플리케이션과 서드파티 패키지에 의해 확장될 수 있도록 만들어졌습니다. 이러한 타입에 추가되는 새로운 기능을 흔히 서비스라고 부릅니다.

## 읽기 전용(Read Only)

가장 단순한 형태의 서비스는 읽기 전용입니다. 이러한 서비스는 application 또는 request에 추가된 계산 프로퍼티나 메서드로 구성됩니다.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

읽기 전용 서비스는 이 예제의 `client`처럼 기존에 존재하는 서비스에 의존할 수 있습니다. extension이 추가되고 나면, 여러분의 커스텀 서비스는 request의 다른 프로퍼티와 마찬가지로 사용할 수 있습니다.

```swift
req.myAPI.foos()
```

## 쓰기 가능(Writable)

상태나 설정이 필요한 서비스는 데이터를 저장하기 위해 `Application`과 `Request`의 storage를 활용할 수 있습니다. 다음과 같은 `MyConfiguration` 구조체를 애플리케이션에 추가하고 싶다고 가정해봅시다.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

storage를 사용하려면 `StorageKey`를 선언해야 합니다.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

이것은 어떤 타입이 저장되는지를 지정하는 `Value` typealias를 가진 빈 구조체입니다. 빈 타입을 키로 사용함으로써, 어떤 코드가 storage 값에 접근할 수 있는지를 제어할 수 있습니다. 타입이 internal이나 private이라면, 오직 여러분의 코드만이 storage에 있는 관련 값을 수정할 수 있습니다.

마지막으로, `MyConfiguration` 구조체를 가져오고 설정하기 위한 extension을 `Application`에 추가합니다.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

extension이 추가되고 나면, `myConfiguration`을 `Application`의 일반적인 프로퍼티처럼 사용할 수 있습니다.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## 라이프사이클(Lifecycle)

Vapor의 `Application`은 라이프사이클 핸들러를 등록할 수 있게 해줍니다. 이를 통해 boot, shutdown과 같은 이벤트에 개입할 수 있습니다.

```swift
// Prints hello during boot.
struct Hello: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Called after application boots.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Called before application shutdown.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Add lifecycle handler.
app.lifecycle.use(Hello())
```

## 락(Locks)

Vapor의 `Application`은 락을 사용해 코드를 동기화할 수 있는 편의 기능을 포함하고 있습니다. `LockKey`를 선언하면, 여러분의 코드에 대한 접근을 동기화하기 위한 고유한 공유 락을 얻을 수 있습니다.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

동일한 `LockKey`로 `lock(for:)`를 호출할 때마다 같은 락이 반환됩니다. 이 메서드는 스레드 안전(thread-safe)합니다.

애플리케이션 전역에서 사용할 락이 필요하다면 `app.sync`를 사용할 수 있습니다.

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

라우트 핸들러에서 사용하도록 의도된 서비스는 `Request`에 추가되어야 합니다. Request 서비스는 request의 logger와 event loop를 사용해야 합니다. request가 동일한 event loop에 계속 머물러 있는 것이 중요한데, 그렇지 않으면 응답이 Vapor로 반환될 때 assertion에 걸리게 됩니다.

서비스가 작업을 수행하기 위해 request의 event loop를 벗어나야 한다면, 종료되기 전에 반드시 해당 event loop로 되돌아와야 합니다. 이는 `EventLoopFuture`의 `hop(to:)`를 사용해서 할 수 있습니다.

설정(configuration)과 같이 애플리케이션 서비스에 대한 접근이 필요한 request 서비스는 `req.application`을 사용할 수 있습니다. 라우트 핸들러에서 애플리케이션에 접근할 때는 스레드 안전성(thread-safety)을 고려하도록 주의하세요. 일반적으로 request는 읽기 작업만 수행해야 합니다. 쓰기 작업은 반드시 락으로 보호되어야 합니다.
