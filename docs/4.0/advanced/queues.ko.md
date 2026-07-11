# 큐(Queues)

Vapor Queues([vapor/queues](https://github.com/vapor/queues))는 작업 처리를 사이드 워커(side worker)에게 위임할 수 있게 해주는 순수 Swift 큐잉 시스템입니다.

이 패키지가 잘 작동하는 작업의 예시는 다음과 같습니다.

- 메인 요청 스레드 외부에서 이메일 전송하기
- 복잡하거나 오래 걸리는 데이터베이스 작업 수행하기
- 작업(job)의 무결성과 복원력 보장하기
- 중요하지 않은 처리를 지연시켜 응답 시간 단축하기
- 특정 시간에 실행되도록 작업 예약하기

이 패키지는 [Ruby Sidekiq](https://github.com/mperham/sidekiq)와 유사합니다. 다음과 같은 기능을 제공합니다.

- 호스팅 제공업체가 종료, 재시작, 새로운 배포를 나타내기 위해 보내는 `SIGTERM` 및 `SIGINT` 시그널의 안전한 처리
- 서로 다른 큐 우선순위. 예를 들어, 이메일 큐에서 실행할 큐 작업 하나와 데이터 처리 큐에서 실행할 또 다른 작업을 지정할 수 있습니다
- 예기치 못한 실패에 대응하기 위한 신뢰할 수 있는 큐 프로세스 구현
- 성공할 때까지 지정된 횟수만큼 작업을 반복하는 `maxRetryCount` 기능 포함
- 사용 가능한 모든 코어와 EventLoop를 작업에 활용하기 위해 NIO 사용
- 사용자가 반복 작업을 예약할 수 있도록 허용

Queues는 현재 메인 프로토콜과 연동되는 공식 지원 드라이버를 하나 가지고 있습니다.

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues는 커뮤니티 기반 드라이버도 가지고 있습니다.

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip
    새로운 드라이버를 만드는 경우가 아니라면 `vapor/queues` 패키지를 직접 설치해서는 안 됩니다. 대신 드라이버 패키지 중 하나를 설치하세요.

## 시작하기

Queues를 사용하기 시작하는 방법을 살펴보겠습니다.

### 패키지

Queues를 사용하는 첫 번째 단계는 SwiftPM 패키지 매니페스트 파일에 프로젝트 의존성으로 드라이버 중 하나를 추가하는 것입니다. 이 예제에서는 Redis 드라이버를 사용하겠습니다.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Other dependencies
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Xcode에서 매니페스트를 직접 편집하는 경우, 파일이 저장되면 Xcode가 자동으로 변경 사항을 감지하고 새로운 의존성을 가져옵니다. 그렇지 않다면 터미널에서 `swift package resolve`를 실행해서 새로운 의존성을 가져오세요.

### 설정

다음 단계는 `configure.swift`에서 Queues를 설정하는 것입니다. 예제로 Redis 라이브러리를 사용하겠습니다.

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### `Job` 등록하기

작업을 모델링한 후에는 다음과 같이 설정 부분에 추가해야 합니다.

```swift
// Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### 프로세스로 워커 실행하기

새로운 큐 워커를 시작하려면 `swift run App queues`를 실행하세요. 특정 유형의 워커를 실행하도록 지정할 수도 있습니다. `swift run App queues --queue emails`.

!!! tip
    프로덕션에서는 워커가 계속 실행 중이어야 합니다. 오래 실행되는 프로세스를 유지하는 방법은 호스팅 제공업체에 문의하세요. 예를 들어 Heroku는 Procfile에서 다음과 같이 "worker" dyno를 지정할 수 있습니다. `worker: Run queues`. 이렇게 설정하면 Dashboard/Resources 탭에서 워커를 시작하거나, `heroku ps:scale worker=1`(또는 원하는 개수의 dyno)로 시작할 수 있습니다.

### 프로세스 내에서 워커 실행하기

(별도의 서버 전체를 시작해서 처리하는 대신) 애플리케이션과 같은 프로세스에서 워커를 실행하려면 `Application`의 편의 메서드를 호출하세요.

```swift
try app.queues.startInProcessJobs(on: .default)
```

예약된 작업을 프로세스 내에서 실행하려면 다음 메서드를 호출하세요.

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    커맨드 라인이나 인프로세스 워커를 통해 큐 워커를 시작하지 않으면 작업이 디스패치되지 않습니다.

## `Job` 프로토콜

작업은 `Job` 또는 `AsyncJob` 프로토콜로 정의됩니다.

### `Job` 객체 모델링하기

```swift
import Vapor
import Foundation
import Queues

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // This is where you would send the email
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
        return context.eventLoop.future()
    }
}
```

`async`/`await`를 사용하는 경우 `AsyncJob`을 사용해야 합니다.

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // This is where you would send the email
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // If you don't want to handle errors you can simply return. You can also omit this function entirely.
    }
}
```

!!! info
    `Payload` 타입이 `Codable` 프로토콜을 준수하는지 확인하세요.

!!! tip
    **시작하기**의 안내를 따라 이 작업을 설정 파일에 추가하는 것을 잊지 마세요.

## 작업 디스패치하기

큐 작업을 디스패치하려면 `Application` 또는 `Request`의 인스턴스에 접근할 수 있어야 합니다. 대부분의 경우 라우트 핸들러 내부에서 작업을 디스패치하게 될 것입니다.

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

만약 `Request` 객체를 사용할 수 없는 컨텍스트(예를 들어 `Command` 내부)에서 작업을 디스패치해야 하는 경우, 다음과 같이 `Application` 객체 내부의 `queues` 프로퍼티를 사용해야 합니다.

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message")
            )
    }
}
```

### `maxRetryCount` 설정하기

`maxRetryCount`를 지정하면 오류 발생 시 작업이 자동으로 재시도됩니다. 예를 들면 다음과 같습니다.

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### 지연 시간 지정하기

작업이 특정 `Date`가 지난 후에만 실행되도록 설정할 수도 있습니다. 지연 시간을 지정하려면 `dispatch`의 `delayUntil` 매개변수에 `Date`를 전달하세요.

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

작업이 지연 매개변수보다 먼저 디큐(dequeue)되면, 드라이버에 의해 작업이 다시 큐에 등록됩니다.

### 우선순위 지정하기

작업은 필요에 따라 다양한 큐 유형/우선순위로 분류될 수 있습니다. 예를 들어 작업을 분류하기 위해 `email` 큐와 `background-processing` 큐를 열고 싶을 수 있습니다.

먼저 `QueueName`을 확장하세요.

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

`QueueName`을 생성할 때 큐별로 `workerCount`를 설정할 수도 있습니다.

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

`workerCount: 1`을 설정하면 해당 큐가 작업을 순차적으로 처리하게 되며, 이는 작업 순서가 중요한 경우에 유용합니다.

그런 다음, `jobs` 객체를 가져올 때 큐 유형을 지정하세요.

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

`Application` 객체 내부에서 접근할 때는 다음과 같이 해야 합니다.

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

큐를 지정하지 않으면 작업은 `default` 큐에서 실행됩니다. **시작하기**의 안내를 따라 각 큐 유형에 대한 워커를 시작하는 것을 잊지 마세요.

## 작업 예약하기

Queues 패키지를 사용하면 특정 시점에 작업이 실행되도록 예약할 수도 있습니다.

!!! warning
    예약된 작업은 `configure.swift`와 같이 애플리케이션이 부팅되기 전에 설정된 경우에만 작동합니다. 라우트 핸들러에서는 작동하지 않습니다.

### 스케줄러 워커 시작하기

스케줄러는 큐 워커와 마찬가지로 별도의 워커 프로세스가 실행 중이어야 합니다. 다음 명령을 실행해서 워커를 시작할 수 있습니다.

```sh
swift run App queues --scheduled
```

!!! tip
    프로덕션에서는 워커가 계속 실행 중이어야 합니다. 오래 실행되는 프로세스를 유지하는 방법은 호스팅 제공업체에 문의하세요. 예를 들어 Heroku는 Procfile에서 다음과 같이 "worker" dyno를 지정할 수 있습니다. `worker: App queues --scheduled`

### `ScheduledJob` 만들기

먼저 새로운 `ScheduledJob` 또는 `AsyncScheduledJob`을 만드는 것부터 시작하세요.

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Do some work here, perhaps queue up another job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
    }
}
```

그런 다음, 설정 코드에서 예약된 작업을 등록하세요.

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

위 예제의 작업은 매년 5월 23일 정오 12시에 실행됩니다.

!!! tip
    스케줄러는 서버의 타임존을 사용합니다.

### 사용 가능한 빌더 메서드

스케줄러 API에는 두 가지 스타일이 있습니다.

- 체이닝을 위한 빌더 객체를 반환하는 캘린더 스타일 빌더
- 고정된 시간 간격마다 작업을 실행하는 인터벌 스타일 빌더

컴파일러가 사용되지 않은 결과(unused result)에 대한 경고를 표시하지 않을 때까지 캘린더 스타일 스케줄러 체인을 계속 빌드해야 합니다. 사용 가능한 모든 메서드는 아래를 참고하세요.

| Helper Function | Available Modifiers                   | Description                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | The month to run the job in. Returns a `Monthly` object for further building.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | The day to run the job in. Returns a `Daily` object for further building.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | The day of the week to run the job on. Returns a `Daily` object.               |
| `daily()`       | `at(_ time: Time)`                    | The time to run the job on. Final method in the chain.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| The hour and minute to run the job on. Final method in the chain.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | The hour, minute, and period to run the job on. Final method of the chain |
| `hourly()`      | `at(_ minute: Minute)`                 | The minute to run the job at. Final method of the chain.                      |
| `minutely()`    | `at(_ second: Second)`                 | The second to run the job at. Final method of the chain.                      |

### 인터벌 빌더 메서드 (`.every(...)`)

스케줄러는 `.every(...)` 메서드를 사용한 고정 간격 스케줄링도 지원합니다.

| Helper Function | Description                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | Runs the job every given number of seconds.                              |
| `every(minutes: Int)` | Runs the job every given number of minutes.                              |
| `every(hours: Int)`   | Runs the job every given number of hours.                                |
| `every(days: Int)`    | Runs the job every given number of days.                                 |
| `every(weeks: Int)`   | Runs the job every given number of weeks.                                |

예제:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### 사용 가능한 헬퍼

Queues는 스케줄링을 더 쉽게 만들어주는 몇 가지 헬퍼 enum을 제공합니다.

| Helper Function | Available Helper Enum                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

헬퍼 enum을 사용하려면 헬퍼 함수의 적절한 수정자(modifier)를 호출하고 값을 전달하세요. 예를 들면 다음과 같습니다.

```swift
// Every year in January
.yearly().in(.january)

// Every month on the first day
.monthly().on(.first)

// Every week on Sunday
.weekly().on(.sunday)

// Every day at midnight
.daily().at(.midnight)
```

## 이벤트 델리게이트

Queues 패키지를 사용하면 워커가 작업에 대해 조치를 취할 때 알림을 받는 `JobEventDelegate` 객체를 지정할 수 있습니다. 이는 모니터링, 인사이트 표면화, 또는 알림 용도로 사용할 수 있습니다.

시작하려면 객체가 `JobEventDelegate`를 준수하도록 만들고 필요한 메서드를 구현하세요.

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Called when the job is dispatched to the queue worker from a route
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job is placed in the processing queue and work begins
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing and has been removed from the queue
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing but had an error
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

그런 다음, 설정 파일에 이를 추가하세요.

```swift
app.queues.add(MyEventDelegate())
```

델리게이트 기능을 사용해서 큐 워커에 대한 추가적인 인사이트를 제공하는 여러 서드파티 패키지가 있습니다.

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## 테스트

동기화 문제를 방지하고 결정론적인 테스트를 보장하기 위해, Queues 패키지는 테스트 전용 `XCTQueue` 라이브러리와 `AsyncTestQueuesDriver` 드라이버를 제공하며, 다음과 같이 사용할 수 있습니다.

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Override the driver being used for testing
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

자세한 내용은 [Romain Pouclet의 블로그 게시글](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/)을 참고하세요.

# 문제 해결

Amazon AWS의 Redis나 Valkey와 같이 클러스터 기반 Redis 호환 서버와 함께 [queues-redis-driver](https://github.com/vapor/queues-redis-driver)를 사용하는 경우, 다음과 같은 오류 메시지가 발생할 수 있습니다. `CROSSSLOT Keys in request don't hash to the same slot`.

이는 클러스터 모드에서만 발생하는데, Redis나 Valkey가 작업 데이터를 어느 클러스터 노드에 저장해야 할지 확실히 알 수 없기 때문입니다.

이 문제를 해결하려면, 이름에 중괄호를 사용해서 작업 데이터 항목의 이름에 [해시 태그(hash tag)](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags)를 추가하세요.

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
