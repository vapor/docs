# 테스트

## VaporTesting

Vapor에는 `Swift Testing`을 기반으로 만들어진 테스트 헬퍼를 제공하는 `VaporTesting`이라는 모듈이 포함되어 있습니다. 이 테스트 헬퍼들을 사용하면 프로그래밍 방식으로 또는 HTTP 서버를 통해 실행되는 방식으로 애플리케이션에 테스트 요청을 보낼 수 있습니다.

!!! note
    새로운 프로젝트나 Swift 동시성을 도입하는 팀이라면 `XCTest`보다 `Swift Testing`을 사용하는 것을 적극 권장합니다.

### 시작하기

`VaporTesting` 모듈을 사용하려면 패키지의 테스트 타겟에 이를 추가했는지 확인하세요.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning
    이에 대응하는 테스트 모듈을 반드시 사용하세요. 그렇지 않으면 Vapor 테스트 실패가 제대로 보고되지 않을 수 있습니다.

그런 다음 테스트 파일 상단에 `import VaporTesting`과 `import Testing`을 추가하세요. `@Suite` 이름을 가진 구조체를 만들어 테스트 케이스를 작성합니다.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // Test here.
    }
}
```

`@Test`로 표시된 각 함수는 앱이 테스트될 때 자동으로 실행됩니다.

테스트가 (예를 들어 데이터베이스로 테스트할 때처럼) 직렬화된 방식으로 실행되도록 하려면, 테스트 스위트 선언에 `.serialized` 옵션을 포함하세요.

```swift
@Suite("App Tests with DB", .serialized)
```

### 테스트 가능한 애플리케이션

간소화되고 표준화된 테스트 설정 및 해제를 제공하기 위해, `VaporTesting`은 `withApp` 헬퍼 함수를 제공합니다. 이 메서드는 `Application` 인스턴스의 생명주기 관리를 캡슐화하여 각 테스트마다 애플리케이션이 올바르게 초기화, 구성, 종료되도록 보장합니다.

모든 라우트가 올바르게 등록되도록 하려면 애플리케이션의 `configure(_:)` 메서드를 `withApp` 헬퍼 함수에 전달하세요.

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### 요청 보내기

애플리케이션에 테스트 요청을 보내려면 `withApp` private 메서드를 사용하고, 그 안에서 `app.testing().test()` 메서드를 사용하세요.

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

처음 두 매개변수는 요청할 HTTP 메서드와 URL입니다. 마지막 트레일링 클로저는 HTTP 응답을 받아 `#expect` 매크로로 검증할 수 있게 해줍니다.

더 복잡한 요청의 경우, 헤더를 수정하거나 콘텐츠를 인코딩하기 위한 `beforeRequest` 클로저를 제공할 수 있습니다. Vapor의 [Content API](../basics/content.md)는 테스트 요청과 응답 양쪽 모두에서 사용할 수 있습니다.

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### 테스트 메서드

Vapor의 테스트 API는 프로그래밍 방식과 실제 HTTP 서버를 통한 테스트 요청 전송을 모두 지원합니다. `testing` 메서드를 통해 어떤 방식을 사용할지 지정할 수 있습니다.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

기본값으로는 `inMemory` 옵션이 사용됩니다.

`running` 옵션은 사용할 특정 포트를 전달할 수 있도록 지원합니다. 기본적으로는 `8080`이 사용됩니다.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### 데이터베이스 통합 테스트

실제 운영 데이터베이스가 테스트 중에 절대 사용되지 않도록 테스트 전용 데이터베이스를 별도로 구성하세요. 예를 들어 SQLite를 사용하는 경우 `configure(_:)` 함수에서 다음과 같이 데이터베이스를 구성할 수 있습니다.

```swift
public func configure(_ app: Application) async throws {
    // All other configurations...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning
    잃고 싶지 않은 데이터를 실수로 덮어쓰는 일이 없도록, 반드시 올바른 데이터베이스를 대상으로 테스트를 실행하세요.

그런 다음 `autoMigrate()`와 `autoRevert()`를 사용해 테스트 중 데이터베이스 스키마와 데이터의 생명주기를 관리함으로써 테스트를 개선할 수 있습니다. 이를 위해서는 데이터베이스 스키마와 데이터 생명주기를 포함하는 `withAppIncludingDB`라는 자체 헬퍼 함수를 만들어야 합니다.

```swift
private func withAppIncludingDB(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

그리고 테스트에서 이 헬퍼를 다음과 같이 사용합니다.
```swift
@Test func myDatabaseIntegrationTest() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
} 
```

이러한 메서드들을 조합하면 각 테스트가 항상 신선하고 일관된 데이터베이스 상태로 시작하도록 보장할 수 있으며, 이를 통해 테스트를 더 신뢰할 수 있게 만들고 남아있는 데이터로 인한 거짓 양성이나 거짓 음성의 가능성을 줄일 수 있습니다.


## XCTVapor

Vapor에는 `XCTest`를 기반으로 만들어진 테스트 헬퍼를 제공하는 `XCTVapor`라는 모듈이 포함되어 있습니다. 이 테스트 헬퍼들을 사용하면 프로그래밍 방식으로 또는 HTTP 서버를 통해 실행되는 방식으로 애플리케이션에 테스트 요청을 보낼 수 있습니다.

### 시작하기

`XCTVapor` 모듈을 사용하려면 패키지의 테스트 타겟에 이를 추가했는지 확인하세요.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

그런 다음 테스트 파일 상단에 `import XCTVapor`를 추가하세요. `XCTestCase`를 확장하는 클래스를 만들어 테스트 케이스를 작성합니다.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

`test`로 시작하는 각 함수는 앱이 테스트될 때 자동으로 실행됩니다.

### 테스트 가능한 애플리케이션

`.testing` 환경을 사용해 `Application` 인스턴스를 초기화하세요. 이 애플리케이션이 할당 해제되기 전에 반드시 `app.shutdown()`을 호출해야 합니다.

이 종료(shutdown) 과정은 앱이 확보한 리소스를 해제하는 데 꼭 필요합니다. 특히 애플리케이션이 시작 시 요청한 스레드를 해제하는 것이 중요합니다. 각 단위 테스트 이후에 앱에서 `shutdown()`을 호출하지 않으면, 새 `Application` 인스턴스를 위한 스레드를 할당할 때 precondition failure로 테스트 스위트가 크래시하는 것을 발견할 수 있습니다.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

`Application`을 패키지의 `configure(_:)` 메서드에 전달하여 구성을 적용하세요. 테스트 전용 구성은 이후에 적용할 수 있습니다.

#### 요청 보내기

애플리케이션에 테스트 요청을 보내려면 `test` 메서드를 사용하세요.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

처음 두 매개변수는 요청할 HTTP 메서드와 URL입니다. 마지막 트레일링 클로저는 HTTP 응답을 받아 `XCTAssert` 메서드로 검증할 수 있게 해줍니다.

더 복잡한 요청의 경우, 헤더를 수정하거나 콘텐츠를 인코딩하기 위한 `beforeRequest` 클로저를 제공할 수 있습니다. Vapor의 [Content API](../basics/content.md)는 테스트 요청과 응답 양쪽 모두에서 사용할 수 있습니다.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### 테스트 가능한 메서드

Vapor의 테스트 API는 프로그래밍 방식과 실제 HTTP 서버를 통한 테스트 요청 전송을 모두 지원합니다. `testable` 메서드를 사용해 어떤 방식을 사용할지 지정할 수 있습니다.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

기본값으로는 `inMemory` 옵션이 사용됩니다.

`running` 옵션은 사용할 특정 포트를 전달할 수 있도록 지원합니다. 기본적으로는 `8080`이 사용됩니다.

```swift
.running(port: 8123)
```
