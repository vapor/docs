# 비동기(Async)

## Async Await

Swift 5.5는 `async`/`await` 형태의 동시성(concurrency)을 언어에 도입했습니다. 이는 Swift와 Vapor 애플리케이션에서 비동기 코드를 처리하는 일급(first-class) 방법을 제공합니다.

Vapor는 저수준 비동기 프로그래밍을 위한 원시(primitive) 타입을 제공하는 [SwiftNIO](https://github.com/apple/swift-nio.git) 위에 구축되었습니다. `async`/`await`가 도입되기 전까지 Vapor 전반에서 이 타입들이 사용되어 왔으며(지금도 여전히 사용됩니다). 하지만 이제 대부분의 앱 코드는 `EventLoopFuture`를 사용하는 대신 `async`/`await`를 사용해서 작성할 수 있습니다. 이는 여러분의 코드를 단순화하고 이해하기 훨씬 쉽게 만들어 줄 것입니다.

Vapor의 대부분의 API는 이제 `EventLoopFuture`와 `async`/`await` 버전을 모두 제공하므로 여러분에게 가장 알맞는 것을 선택할 수 있습니다. 일반적으로 라우트 핸들러 하나당 하나의 프로그래밍 모델만 사용해야 하며, 코드 안에서 두 방식을 섞어 쓰지 않아야 합니다. 이벤트 루프에 대한 명시적인 제어가 필요하거나 매우 높은 성능이 요구되는 애플리케이션의 경우, 커스텀 executor가 구현될 때까지는 계속 `EventLoopFuture`를 사용해야 합니다. 그 외의 경우에는 가독성과 유지보수성이 주는 이점이 작은 성능 손실을 훨씬 능가하므로 `async`/`await`를 사용해야 합니다.

### async/await로 마이그레이션하기

async/await로 마이그레이션하기 위해서는 몇 가지 단계가 필요합니다. 먼저, macOS를 사용한다면 macOS 12 Monterey 이상과 Xcode 13.1 이상이어야 합니다. 다른 플랫폼의 경우에는 Swift 5.5 이상을 실행해야 합니다. 다음으로, 모든 의존성을 업데이트했는지 확인하세요.

Package.swift 파일 상단에서 도구(tools) 버전을 5.5로 설정하세요.

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

다음으로, 플랫폼 버전을 macOS 12로 설정하세요.

```swift
    platforms: [
       .macOS(.v12)
    ],
```

마지막으로 `Run` 타겟을 실행 가능한(executable) 타겟으로 표시하도록 업데이트하세요.

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

참고: Linux에 배포하는 경우 그곳의 Swift 버전도 업데이트해야 합니다. 예를 들어 Heroku나 Dockerfile에서 말이죠. 예를 들어 Dockerfile은 다음과 같이 변경됩니다.

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

이제 기존 코드를 마이그레이션할 수 있습니다. 일반적으로 `EventLoopFuture`를 반환하던 함수는 이제 `async`가 됩니다. 예를 들면,

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

이제 다음과 같이 바뀝니다.

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### 기존 API와 새로운 API 함께 사용하기

아직 `async`/`await` 버전을 제공하지 않는 API를 만난다면, `EventLoopFuture`를 반환하는 함수에 `.get()`을 호출해서 변환할 수 있습니다.

예를 들어,

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

는 다음과 같이 바뀔 수 있습니다.

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

반대 방향으로 변환해야 한다면 다음의

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

를 다음과 같이 변환할 수 있습니다.

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`

Vapor의 일부 API가 제네릭 `EventLoopFuture` 타입을 인자로 받거나 반환하는 것을 본 적이 있을 것입니다. 퓨처(future)에 대해 처음 듣는 것이라면 처음에는 다소 혼란스러울 수 있습니다. 하지만 걱정하지 마세요. 이 가이드는 퓨처의 강력한 API를 활용하는 방법을 보여줄 것입니다.

프로미스(promise)와 퓨처(future)는 서로 연관되어 있지만 별개의 타입입니다. 프로미스는 퓨처를 _생성_하는 데 사용됩니다. 대부분의 경우 여러분은 Vapor의 API가 반환하는 퓨처를 다루게 될 것이며, 프로미스를 직접 생성하는 것에 대해서는 걱정할 필요가 없습니다.

|타입|설명|가변성|
|-|-|-|
|`EventLoopFuture`|아직 사용할 수 없을지도 모르는 값에 대한 참조.|읽기 전용|
|`EventLoopPromise`|어떤 값을 비동기적으로 제공하겠다는 약속.|읽기/쓰기|

퓨처는 콜백 기반의 비동기 API에 대한 대안입니다. 퓨처는 단순한 클로저로는 불가능한 방식으로 체이닝(chain)되고 변형(transform)될 수 있습니다.

## 변형(Transforming)

Swift의 옵셔널(optional)이나 배열(array)과 마찬가지로 퓨처도 매핑(map)하거나 플랫 매핑(flat-map)할 수 있습니다. 이는 퓨처에 대해 가장 흔하게 수행하게 될 연산입니다.

|메서드|인자|설명|
|-|-|-|
|[`map`](#map)|`(T) -> U`|퓨처의 값을 다른 값으로 매핑합니다.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|퓨처의 값을 다른 값 또는 에러로 매핑합니다.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|퓨처의 값을 다른 _퓨처_ 값으로 매핑합니다.|
|[`transform`](#transform)|`U`|퓨처를 이미 사용 가능한 값으로 매핑합니다.|

`Optional<T>`와 `Array<T>`의 `map`, `flatMap` 메서드 시그니처를 보면 `EventLoopFuture<T>`에서 사용할 수 있는 메서드들과 매우 유사하다는 것을 알 수 있습니다.

### map

`map` 메서드는 퓨처의 값을 다른 값으로 변형할 수 있게 해줍니다. 퓨처의 값은 아직 사용할 수 없을 수도 있기 때문에(비동기 작업의 결과일 수 있으므로) 그 값을 받을 클로저를 제공해야 합니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

`flatMapThrowing` 메서드는 퓨처의 값을 다른 값으로 변형하거나 _또는_ 에러를 던질 수 있게 해줍니다.

!!! info
    에러를 던지려면 내부적으로 새로운 퓨처를 생성해야 하기 때문에, 클로저가 퓨처를 반환하지 않음에도 이 메서드에는 `flatMap` 접두사가 붙습니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

`flatMap` 메서드는 퓨처의 값을 다른 퓨처 값으로 변형할 수 있게 해줍니다. 이 메서드가 "flat" map이라는 이름을 가지는 이유는 중첩된 퓨처(예: `EventLoopFuture<EventLoopFuture<T>>`)를 만드는 것을 피할 수 있게 해주기 때문입니다. 다시 말해, 제네릭을 평평하게(flat) 유지하도록 도와줍니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    위 예시에서 `map`을 대신 사용했다면 `EventLoopFuture<EventLoopFuture<ClientResponse>>`를 얻게 되었을 것입니다.

`flatMap` 내부에서 에러를 던지는 메서드를 호출하려면 Swift의 `do` / `catch` 키워드를 사용하고 [완료된 퓨처](#makefuture)를 생성하세요.

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

`transform` 메서드는 기존 값을 무시하고 퓨처의 값을 수정할 수 있게 해줍니다. 이는 퓨처의 실제 값이 중요하지 않은 `EventLoopFuture<Void>`의 결과를 변형할 때 특히 유용합니다.

!!! tip
    `EventLoopFuture<Void>`는 시그널(signal)이라고도 불리며, 어떤 비동기 작업의 완료나 실패를 알리는 것만을 목적으로 하는 퓨처입니다.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

`transform`에 이미 사용 가능한 값을 제공했음에도 불구하고, 이는 여전히 하나의 _변형_ 입니다. 퓨처는 이전의 모든 퓨처가 완료(또는 실패)되기 전까지는 완료되지 않습니다.

### 체이닝(Chaining)

퓨처의 변형에서 가장 좋은 점은 체이닝될 수 있다는 것입니다. 이를 통해 다양한 변환과 하위 작업을 쉽게 표현할 수 있습니다.

체이닝을 어떻게 활용할 수 있는지 보기 위해 위의 예시들을 수정해 봅시다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

첫 번째 map 호출 이후에는 임시로 `EventLoopFuture<URL>`이 생성됩니다. 그리고 이 퓨처는 곧바로 `EventLoopFuture<Response>`로 flat-map됩니다.
    
## Future

`EventLoopFuture<T>`를 사용하기 위한 다른 몇 가지 메서드를 살펴보겠습니다.

### makeFuture

이벤트 루프를 사용해서 값 또는 에러로 미리 완료된(pre-completed) 퓨처를 생성할 수 있습니다.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

`whenComplete`를 사용해서 퓨처가 성공하거나 실패했을 때 실행될 콜백을 추가할 수 있습니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    퓨처에는 원하는 만큼 많은 콜백을 추가할 수 있습니다.

### Get

API에 동시성(concurrency) 기반의 대안이 없는 경우, `try await future.get()`을 사용해서 퓨처의 값을 기다릴(await) 수 있습니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Wait for the string to be ready
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! warning
    `wait()` 함수는 더 이상 사용되지 않습니다(obsolete). 권장되는 방법은 [`Get`](#get)을 참고하세요.

`.wait()`을 사용해서 퓨처가 완료될 때까지 동기적으로 기다릴 수 있습니다. 퓨처가 실패할 수도 있기 때문에 이 호출은 에러를 던질(throwing) 수 있습니다.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()`은 백그라운드 스레드 또는 메인 스레드, 즉 `configure.swift`에서만 사용할 수 있습니다. 이벤트 루프 스레드, 즉 라우트 클로저에서는 사용할 수 _없습니다_.

!!! warning
    이벤트 루프 스레드에서 `wait()`을 호출하려고 하면 assertion failure가 발생합니다.
    
## Promise

대부분의 경우 여러분은 Vapor의 API 호출이 반환하는 퓨처를 변형하게 될 것입니다. 하지만 때로는 직접 프로미스를 생성해야 할 수도 있습니다.

프로미스를 생성하려면 `EventLoop`에 접근해야 합니다. 상황에 따라 `Application`이나 `Request`로부터 이벤트 루프에 접근할 수 있습니다.

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    프로미스는 한 번만 완료될 수 있습니다. 이후에 발생하는 완료는 모두 무시됩니다.

프로미스는 어떤 스레드에서든 완료(`succeed` / `fail`)될 수 있습니다. 그렇기 때문에 프로미스는 초기화될 때 이벤트 루프가 필요합니다. 프로미스는 완료 작업이 실행을 위해 자신의 이벤트 루프로 반환되도록 보장합니다.

## 이벤트 루프(Event Loop)

애플리케이션이 부팅될 때, 보통 실행 중인 CPU의 코어 하나당 하나의 이벤트 루프가 생성됩니다. 각 이벤트 루프는 정확히 하나의 스레드를 가집니다. Node.js의 이벤트 루프에 익숙하다면, Vapor의 이벤트 루프도 이와 비슷합니다. 가장 큰 차이점은 Swift가 멀티 스레딩을 지원하기 때문에 Vapor는 하나의 프로세스 안에서 여러 개의 이벤트 루프를 실행할 수 있다는 것입니다.

클라이언트가 서버에 연결할 때마다 이벤트 루프 중 하나에 할당됩니다. 그 시점부터 서버와 해당 클라이언트 사이의 모든 통신은 같은 이벤트 루프(그리고 그와 연결된 스레드) 위에서 이루어집니다.

이벤트 루프는 연결된 각 클라이언트의 상태를 추적하는 역할을 합니다. 클라이언트로부터 읽기를 기다리는 요청이 있다면, 이벤트 루프는 읽기 알림을 발생시켜 데이터가 읽히도록 합니다. 요청 전체가 읽히고 나면, 해당 요청의 데이터를 기다리던 퓨처들이 완료됩니다.

라우트 클로저 안에서는 `Request`를 통해 현재 이벤트 루프에 접근할 수 있습니다.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor는 라우트 클로저가 `req.eventLoop`에 계속 머물러 있을 것을 기대합니다. 만약 스레드를 옮긴다면(hop), `Request`에 대한 접근과 최종 응답 퓨처가 모두 해당 요청의 이벤트 루프에서 이루어지도록 해야 합니다.

라우트 클로저 밖에서는 `Application`을 통해 사용 가능한 이벤트 루프 중 하나를 얻을 수 있습니다.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

`hop`을 사용해서 퓨처의 이벤트 루프를 변경할 수 있습니다.

```swift
futureString.hop(to: otherEventLoop)
```

## 블로킹(Blocking)

이벤트 루프 스레드에서 블로킹 코드를 호출하면 애플리케이션이 제때 들어오는 요청에 응답하지 못하게 될 수 있습니다. 블로킹 호출의 예로는 `libc.sleep(_:)` 같은 것이 있습니다.

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)`은 전달된 초(second) 수만큼 현재 스레드를 블로킹하는 명령입니다. 이벤트 루프에서 직접 이런 블로킹 작업을 수행한다면, 그 이벤트 루프는 블로킹 작업이 진행되는 동안 자신에게 할당된 다른 어떤 클라이언트에도 응답할 수 없게 됩니다. 다시 말해, 이벤트 루프에서 `sleep(5)`를 수행한다면 그 이벤트 루프에 연결된 다른 모든 클라이언트(수백, 수천 개일 수도 있는)가 최소 5초 동안 지연됩니다.

블로킹 작업은 반드시 백그라운드에서 실행하세요. 이 작업이 완료되었을 때 논블로킹 방식으로 이벤트 루프에 알리기 위해 프로미스를 사용하세요.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

모든 블로킹 호출이 `sleep(_:)`처럼 명확하지는 않습니다. 사용 중인 호출이 블로킹인지 의심스럽다면, 해당 메서드 자체를 조사하거나 다른 사람에게 물어보세요. 아래 섹션에서는 메서드가 어떻게 블로킹될 수 있는지 더 자세히 다룹니다.

### I/O 바운드(I/O Bound)

I/O 바운드 블로킹이란 네트워크나 하드 디스크처럼 CPU보다 몇 자릿수는 느릴 수 있는 느린 리소스를 기다리는 것을 의미합니다. 이런 리소스를 기다리는 동안 CPU를 블로킹하면 시간을 낭비하게 됩니다.

!!! danger
    이벤트 루프에서 직접 블로킹 I/O 바운드 호출을 절대 하지 마세요.

Vapor의 모든 패키지는 SwiftNIO 위에 구축되어 있으며 논블로킹 I/O를 사용합니다. 하지만 실제로는 블로킹 I/O를 사용하는 Swift 패키지와 C 라이브러리가 많이 존재합니다. 어떤 함수가 디스크나 네트워크 IO를 수행하면서 동기 API(콜백이나 퓨처가 없는)를 사용한다면 십중팔구 블로킹일 것입니다.
    
### CPU 바운드(CPU Bound)

요청을 처리하는 대부분의 시간은 데이터베이스 쿼리나 네트워크 요청 같은 외부 리소스가 로드되기를 기다리는 데 쓰입니다. Vapor와 SwiftNIO가 논블로킹이기 때문에, 이 대기 시간은 다른 들어오는 요청을 처리하는 데 사용될 수 있습니다. 하지만 여러분의 애플리케이션에 있는 일부 라우트는 요청의 결과로 무거운 CPU 바운드 작업을 수행해야 할 수도 있습니다.

이벤트 루프가 CPU 바운드 작업을 처리하는 동안에는 다른 들어오는 요청에 응답할 수 없습니다. 이는 일반적으로는 문제가 되지 않는데, CPU는 빠르고 대부분의 웹 애플리케이션이 수행하는 CPU 작업은 가볍기 때문입니다. 하지만 오래 실행되는 CPU 작업을 가진 라우트가 더 빠른 라우트에 대한 요청 응답을 지연시킨다면 문제가 될 수 있습니다.

애플리케이션에서 오래 실행되는 CPU 작업을 찾아내어 백그라운드 스레드로 옮기면 서비스의 안정성과 응답성을 개선하는 데 도움이 될 수 있습니다. CPU 바운드 작업은 I/O 바운드 작업보다는 더 모호한 영역이며, 결국 어디에 선을 그을지는 여러분에게 달려 있습니다.

무거운 CPU 바운드 작업의 흔한 예시는 사용자 가입과 로그인 시의 Bcrypt 해싱입니다. Bcrypt는 보안상의 이유로 의도적으로 매우 느리고 CPU 집약적입니다. 이는 단순한 웹 애플리케이션이 실제로 수행하는 것 중 가장 CPU 집약적인 작업일 수 있습니다. 해싱을 백그라운드 스레드로 옮기면 해시를 계산하는 동안 CPU가 이벤트 루프 작업을 인터리빙(interleave)할 수 있게 되어 더 높은 동시성을 얻을 수 있습니다.
