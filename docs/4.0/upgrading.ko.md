# 4.0으로 업그레이드하기

이 가이드는 기존 Vapor 3.x 프로젝트를 4.x로 업그레이드하는 방법을 보여줍니다. 이 가이드는 Vapor의 공식 패키지뿐만 아니라 일반적으로 사용되는 일부 프로바이더까지 모두 다루려고 시도합니다. 빠진 내용이 있다면, [Vapor의 팀 채팅](https://discord.gg/vapor)에서 도움을 요청하기 좋습니다. 이슈와 풀 리퀘스트도 환영합니다.

## 의존성

Vapor 4를 사용하려면 Xcode 11.4와 macOS 10.15 이상이 필요합니다.

문서의 설치 섹션에서 의존성 설치 방법을 다룹니다.

## Package.swift

Vapor 4로 업그레이드하는 첫 번째 단계는 패키지의 의존성을 업데이트하는 것입니다. 아래는 업그레이드된 Package.swift 파일의 예시입니다. 업데이트된 [템플릿 Package.swift](https://github.com/vapor/template/blob/main/Package.swift)도 확인해 보세요.

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

Vapor 4를 위해 업그레이드된 모든 패키지는 메이저 버전 번호가 1씩 증가합니다.

!!! warning
    Vapor 4의 일부 패키지가 아직 공식적으로 릴리즈되지 않았기 때문에 `-rc` 프리 릴리즈 식별자가 사용됩니다.

### 이전 패키지

일부 Vapor 3 패키지는 다음과 같이 더 이상 사용되지 않습니다(deprecated).

- `vapor/auth`: 이제 Vapor에 포함되어 있습니다.
- `vapor/core`: 여러 모듈로 흡수되었습니다.
- `vapor/crypto`: SwiftCrypto로 대체되었습니다(이제 Vapor에 포함됨).
- `vapor/multipart`: 이제 Vapor에 포함되어 있습니다.
- `vapor/url-encoded-form`: 이제 Vapor에 포함되어 있습니다.
- `vapor-community/vapor-ext`: 이제 Vapor에 포함되어 있습니다.
- `vapor-community/pagination`: 이제 Fluent의 일부입니다.
- `IBM-Swift/LoggerAPI`: SwiftLog로 대체되었습니다.

### Fluent 의존성

`vapor/fluent`는 이제 의존성 목록과 타겟에 별도의 의존성으로 추가되어야 합니다. `vapor/fluent`에 대한 요구 사항을 명확히 하기 위해 모든 데이터베이스별 패키지에는 `-driver` 접미사가 붙었습니다.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### 플랫폼

Vapor의 패키지 매니페스트는 이제 macOS 10.15 이상을 명시적으로 지원합니다. 즉, 여러분의 패키지도 플랫폼 지원을 명시해야 합니다.

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor는 향후 추가적인 지원 플랫폼을 추가할 수 있습니다. 버전 번호가 Vapor의 최소 버전 요구 사항과 같거나 그 이상인 한, 여러분의 패키지는 이러한 플랫폼 중 어떤 하위 집합이든 지원할 수 있습니다.

### Xcode

Vapor 4는 Xcode 11의 네이티브 SPM 지원을 활용합니다. 즉, 더 이상 `.xcodeproj` 파일을 생성할 필요가 없습니다. Xcode에서 프로젝트 폴더를 열면 자동으로 SPM을 인식하고 의존성을 가져옵니다.

`vapor xcode` 또는 `open Package.swift`를 사용하여 프로젝트를 Xcode에서 네이티브로 열 수 있습니다.

Package.swift를 업데이트한 후, Xcode를 닫고 루트 디렉토리에서 다음 폴더들을 정리해야 할 수도 있습니다.

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

업데이트된 패키지가 성공적으로 해결(resolve)되면, 아마도 꽤 많은 컴파일러 오류를 보게 될 것입니다. 걱정하지 마세요! 이를 수정하는 방법을 알려드리겠습니다.

## Run

가장 먼저 해야 할 일은 Run 모듈의 `main.swift` 파일을 새 형식으로 업데이트하는 것입니다.

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

`main.swift` 파일의 내용은 App 모듈의 `app.swift`를 대체하므로, 해당 파일은 삭제해도 됩니다.

## App 

기본 App 모듈 구조를 업데이트하는 방법을 살펴보겠습니다.

### configure.swift

`configure` 메서드는 `Application`의 인스턴스를 받도록 변경되어야 합니다.

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

아래는 업데이트된 configure 메서드의 예시입니다.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Serves files from `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure migrations
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

라우팅, 미들웨어, fluent 등을 구성하는 문법 변경 사항은 아래에서 설명합니다.

### boot.swift

`boot`의 내용은 이제 애플리케이션 인스턴스를 받으므로 `configure` 메서드 안에 넣을 수 있습니다.

### routes.swift

`routes` 메서드는 `Application`의 인스턴스를 받도록 변경되어야 합니다.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

라우팅 문법 변경 사항에 대한 자세한 내용은 아래에서 설명합니다.

## 서비스

Vapor 4의 서비스 API는 여러분이 서비스를 더 쉽게 발견하고 사용할 수 있도록 단순화되었습니다. 서비스는 이제 `Application`과 `Request`의 메서드와 프로퍼티로 노출되어 컴파일러가 서비스 사용을 도울 수 있습니다.

이를 더 잘 이해하기 위해 몇 가지 예시를 살펴보겠습니다.

```diff
// Change the server's default port to 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

서비스에 `NIOServerConfig`를 등록하는 대신, 서버 설정은 이제 오버라이드할 수 있는 Application의 간단한 프로퍼티로 노출됩니다.

```diff
// Register cors middleware
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Create _empty_ middleware config
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

서비스에 `MiddlewareConfig`를 생성하고 등록하는 대신, 미들웨어는 이제 추가할 수 있는 Application의 프로퍼티로 노출됩니다.

```diff
// Make a request in a route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Application과 마찬가지로 Request도 서비스를 간단한 프로퍼티와 메서드로 노출합니다. 라우트 클로저 내부에서는 항상 Request 전용 서비스를 사용해야 합니다.

이 새로운 서비스 패턴은 Vapor 3의 `Container`, `Service`, `Config` 타입을 대체합니다.

### 프로바이더

서드 파티 패키지를 구성하는 데 더 이상 프로바이더가 필요하지 않습니다. 각 패키지는 대신 설정을 위한 새로운 프로퍼티와 메서드로 Application과 Request를 확장합니다.

Vapor 4에서 Leaf가 어떻게 구성되는지 살펴보겠습니다.

```diff
// Use Leaf for view rendering. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Leaf를 구성하려면 `app.leaf` 프로퍼티를 사용하세요.

```diff
// Disable Leaf view caching.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### 환경

현재 환경(production, development 등)은 `app.environment`를 통해 접근할 수 있습니다.

### 커스텀 서비스

Vapor 3에서 `Service` 프로토콜을 준수하고 컨테이너에 등록되던 커스텀 서비스는 이제 Application 또는 Request의 익스텐션으로 표현될 수 있습니다.

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

이제 이 서비스는 `make` 대신 익스텐션을 사용하여 접근할 수 있습니다.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### 커스텀 프로바이더

대부분의 커스텀 서비스는 이전 섹션에서 보여준 것처럼 익스텐션을 사용하여 구현할 수 있습니다. 하지만 일부 고급 프로바이더는 애플리케이션 생명주기에 연결하거나 저장된 프로퍼티를 사용해야 할 수 있습니다.

Application의 새로운 `Lifecycle` 헬퍼를 사용하여 생명주기 핸들러를 등록할 수 있습니다.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Application에 값을 저장하려면 새로운 `Storage` 헬퍼를 사용할 수 있습니다.

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

`app.storage`에 대한 접근은 간결한 API를 만들기 위해 설정 가능한 계산 프로퍼티(computed property)로 감쌀 수 있습니다.

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4는 이제 SwiftNIO의 비동기 API를 직접 노출하며, `map`이나 `flatMap` 같은 메서드를 오버로드하거나 `EventLoopFuture` 같은 타입에 별칭(alias)을 붙이려고 하지 않습니다. Vapor 3는 SwiftNIO가 존재하기 전에 릴리즈된 초기 베타 버전과의 하위 호환성을 위해 오버로드와 별칭을 제공했습니다. 이는 다른 SwiftNIO 호환 패키지와의 혼란을 줄이고 SwiftNIO의 모범 사례 권장 사항을 더 잘 따르기 위해 제거되었습니다.

### 비동기 네이밍 변경

가장 눈에 띄는 변경 사항은 `EventLoopFuture`에 대한 `Future` 타입 별칭이 제거되었다는 것입니다. 이는 찾기 및 바꾸기로 비교적 쉽게 해결할 수 있습니다.

또한 NIO는 Vapor 3가 추가한 `to:` 레이블을 지원하지 않습니다. Swift 5.2의 향상된 타입 추론 덕분에 어차피 `to:`는 이제 덜 필요합니다.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

`newPromise`처럼 `new`가 접두사로 붙은 메서드는 Swift 스타일에 더 적합하도록 `make`로 변경되었습니다.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap`은 더 이상 사용할 수 없지만, NIO의 `mapError`와 `flatMapErrorThrowing` 같은 메서드가 대신 동작합니다.

여러 future를 결합하기 위한 Vapor 3의 전역 `flatMap` 메서드는 더 이상 사용할 수 없습니다. 이는 NIO의 `and` 메서드를 사용하여 여러 future를 함께 결합하는 것으로 대체할 수 있습니다.

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

이전에 `Data`를 사용하던 많은 메서드와 프로퍼티는 이제 NIO의 `ByteBuffer`를 사용합니다. 이 타입은 더 강력하고 성능이 뛰어난 바이트 저장 타입입니다. 이 API에 대해서는 [SwiftNIO의 ByteBuffer 문서](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer)에서 더 자세히 읽어볼 수 있습니다.

`ByteBuffer`를 다시 `Data`로 변환하려면 다음을 사용하세요.

```swift
Data(buffer.readableBytesView)
```

### Throwing map / flatMap

가장 어려운 변경 사항은 `map`과 `flatMap`이 더 이상 throw할 수 없다는 것입니다. `map`에는 (다소 헷갈리게도) `flatMapThrowing`이라는 throwing 버전이 있습니다. 그러나 `flatMap`에는 throwing 대응 메서드가 없습니다. 이로 인해 일부 비동기 코드를 재구성해야 할 수 있습니다.

throw하지 _않는_ map은 계속 정상적으로 동작해야 합니다.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

throw _하는_ map은 `flatMapThrowing`으로 이름을 바꿔야 합니다.

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

throw하지 _않는_ flat-map은 계속 정상적으로 동작해야 합니다.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

flat-map 내부에서 에러를 throw하는 대신, future 에러를 반환하세요. 에러가 다른 throwing 메서드에서 발생한 경우, do / catch로 에러를 잡아서 future로 반환할 수 있습니다.

```swift
// Returning a caught error as a future.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

throwing 메서드 호출은 `flatMapThrowing`으로 리팩터링하고 튜플을 사용하여 체이닝할 수도 있습니다.

```swift
// Refactored throwing method into flatMapThrowing with tuple-chaining.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result is the value of doSomething.
    return futureB
}
```

## 라우팅

라우트는 이제 Application에 직접 등록됩니다.

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

즉, 더 이상 서비스에 라우터를 등록할 필요가 없습니다. 애플리케이션을 `routes` 메서드에 전달하고 라우트 추가를 시작하기만 하면 됩니다. `RoutesBuilder`에서 사용 가능한 모든 메서드는 `Application`에서도 사용할 수 있습니다.

### 동기 콘텐츠

이제 요청 콘텐츠를 디코딩하는 것은 동기적으로 이루어집니다.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

이 동작은 `.stream` 본문 수집 전략을 사용하여 라우트를 등록하면 재정의할 수 있습니다.

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Request body is now asynchronous.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### 쉼표로 구분된 경로

일관성을 위해 경로는 이제 쉼표로 구분되어야 하며 `/`를 포함해서는 안 됩니다.

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### 라우트 파라미터

`Parameter` 프로토콜은 명시적으로 이름이 지정된 파라미터를 위해 제거되었습니다. 이는 미들웨어와 라우트 핸들러에서 중복된 파라미터와 순서 없는 파라미터 가져오기 문제를 방지합니다.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

모델과 함께 사용하는 라우트 파라미터 사용법은 Fluent 섹션에서 다룹니다.

## 미들웨어

`MiddlewareConfig`는 `MiddlewareConfiguration`으로 이름이 바뀌었고 이제 Application의 프로퍼티입니다. `app.middleware`를 사용하여 앱에 미들웨어를 추가할 수 있습니다.

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

미들웨어는 더 이상 타입 이름으로 등록할 수 없습니다. 등록하기 전에 먼저 미들웨어를 초기화하세요.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

모든 기본 미들웨어를 제거하려면, 다음을 사용하여 `app.middleware`를 빈 설정으로 지정하세요.

```swift
app.middleware = .init()
```

## Fluent

Fluent의 API는 이제 데이터베이스에 구애받지 않습니다(database agnostic). `Fluent`만 import하면 됩니다.

```diff
- import FluentMySQL
+ import Fluent
```

### 모델

이제 모든 모델은 `Model` 프로토콜을 사용해야 하며 클래스여야 합니다.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

모든 필드는 `@Field` 또는 `@OptionalField` 프로퍼티 래퍼를 사용하여 선언됩니다.

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

모델의 ID는 `@ID` 프로퍼티 래퍼를 사용하여 정의되어야 합니다.

```diff
+ @ID(key: .id)
var id: UUID?
```

커스텀 키나 타입을 가진 식별자를 사용하는 모델은 `@ID(custom:)`을 사용해야 합니다.

모든 모델은 테이블 또는 컬렉션 이름을 정적으로 정의해야 합니다.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

이제 모든 모델은 빈 이니셜라이저를 가져야 합니다. 모든 프로퍼티가 프로퍼티 래퍼를 사용하므로, 이는 비워둘 수 있습니다.

```diff
final class Planet: Model {
+   init() { }
}
```

모델의 `save`, `update`, `create`는 더 이상 모델 인스턴스를 반환하지 않습니다.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

모델은 더 이상 라우트 경로 구성 요소로 사용할 수 없습니다. 대신 `find`와 `req.parameters.get`을 사용하세요.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID`는 `Model.IDValue`로 이름이 바뀌었습니다.

모델 타임스탬프는 이제 `@Timestamp` 프로퍼티 래퍼를 사용하여 선언됩니다.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### 관계(Relations)

관계는 이제 프로퍼티 래퍼를 사용하여 정의됩니다.

Parent 관계는 `@Parent` 프로퍼티 래퍼를 사용하며 내부적으로 필드 프로퍼티를 포함합니다. `@Parent`에 전달되는 키는 데이터베이스에서 식별자를 저장하는 필드의 이름이어야 합니다.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Children 관계는 관련된 `@Parent`에 대한 키 경로(key path)와 함께 `@Children` 프로퍼티 래퍼를 사용합니다.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Siblings 관계는 피벗 모델에 대한 키 경로와 함께 `@Siblings` 프로퍼티 래퍼를 사용합니다.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

피벗은 이제 두 개의 `@Parent` 관계와 0개 이상의 추가 필드를 가진 `Model`을 준수하는 일반 모델입니다.

### 쿼리

이제 데이터베이스 컨텍스트는 라우트 핸들러에서 `req.db`를 통해 접근됩니다.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable`은 `Database`로 이름이 바뀌었습니다.

필드에 대한 키 경로는 이제 필드 값 대신 프로퍼티 래퍼를 지정하기 위해 `$`가 접두사로 붙습니다.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### 마이그레이션

모델은 더 이상 리플렉션 기반의 자동 마이그레이션을 지원하지 않습니다. 모든 마이그레이션은 수동으로 작성되어야 합니다.

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

마이그레이션은 이제 문자열 기반 타입(stringly typed)이며 모델과 분리되어 있고 `Migration` 프로토콜을 사용합니다.

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

`prepare`와 `revert` 메서드는 더 이상 static이 아닙니다.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

스키마 빌더 생성은 `Database`의 인스턴스 메서드를 통해 이루어집니다.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

`create`, `update`, `delete` 메서드는 이제 쿼리 빌더가 작동하는 방식과 유사하게 스키마 빌더에서 호출됩니다.

필드 정의는 이제 문자열 기반 타입이며 다음 패턴을 따릅니다.

```swift
field(<name>, <type>, <constraints>)
```

아래 예시를 참고하세요.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

스키마 빌딩은 이제 쿼리 빌더처럼 체이닝할 수 있습니다.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent 설정

`DatabasesConfig`는 `app.databases`로 대체되었습니다.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig`는 `app.migrations`로 대체되었습니다.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### 리포지토리

Vapor 4에서 서비스가 작동하는 방식이 변경되었기 때문에, 데이터베이스 리포지토리를 만드는 방식도 변경되었습니다. `UserRepository` 같은 프로토콜은 여전히 필요하지만, 해당 프로토콜을 준수하는 `final class`를 만드는 대신 `struct`를 만들어야 합니다.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

또한 Vapor 4에는 `ServiceType`이 더 이상 존재하지 않으므로 여기에 대한 준수도 제거해야 합니다.
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

대신 `UserRepositoryFactory`를 생성해야 합니다.
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
이 팩토리는 `Request`에 대한 `UserRepository`를 반환하는 역할을 합니다.

다음 단계는 팩토리를 지정하기 위해 `Application`에 익스텐션을 추가하는 것입니다.
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

`Request` 내부에서 실제 리포지토리를 사용하려면 `Request`에 다음 익스텐션을 추가하세요.
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

마지막 단계는 `configure.swift` 안에서 팩토리를 지정하는 것입니다.
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

이제 라우트 핸들러에서 `req.users.all()`로 리포지토리에 접근할 수 있으며, 테스트 안에서 팩토리를 쉽게 교체할 수 있습니다.
테스트 안에서 모킹된 리포지토리를 사용하고 싶다면, 먼저 `TestUserRepository`를 생성하세요.
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

이제 다음과 같이 테스트 안에서 이 모킹된 리포지토리를 사용할 수 있습니다.
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
