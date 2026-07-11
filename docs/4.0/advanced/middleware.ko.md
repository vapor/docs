# 미들웨어(Middleware)

미들웨어는 클라이언트와 Vapor 라우트 핸들러 사이에 위치하는 로직 체인입니다. 이를 이용하면 들어오는 요청이 라우트 핸들러에 도달하기 전에, 그리고 나가는 응답이 클라이언트에게 전달되기 전에 특정 작업을 수행할 수 있습니다.

## 설정

미들웨어는 `app.middleware`를 사용해 `configure(_:)`에서 전역으로(모든 라우트에 대해) 등록할 수 있습니다.

```swift
app.middleware.use(MyMiddleware())
```

라우트 그룹을 사용하면 개별 라우트에 미들웨어를 추가할 수도 있습니다.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
    // This request has passed through MyMiddleware.
}
```

### 순서

미들웨어가 추가되는 순서는 중요합니다. 애플리케이션으로 들어오는 요청은 미들웨어가 추가된 순서대로 통과합니다. 애플리케이션을 떠나는 응답은 그 반대 순서로 미들웨어를 다시 통과합니다. 라우트별 미들웨어는 항상 애플리케이션 미들웨어 다음에 실행됩니다. 다음 예제를 살펴보겠습니다.

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
    $0.get("hello") { req in
        "Hello, middleware."
    }
}
```

`GET /hello` 요청은 다음과 같은 순서로 미들웨어를 거치게 됩니다.

```
Request → A → B → C → Handler → C → B → A → Response
```

미들웨어는 _앞에 추가(prepend)_할 수도 있는데, 이는 Vapor가 자동으로 추가하는 기본 미들웨어 _전에_ 어떤 미들웨어를 추가하고 싶을 때 유용합니다.

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## 미들웨어 생성하기

Vapor는 몇 가지 유용한 미들웨어를 기본으로 제공하지만, 애플리케이션의 요구 사항에 따라 직접 미들웨어를 만들어야 할 수도 있습니다. 예를 들어 관리자가 아닌 사용자가 특정 라우트 그룹에 접근하지 못하도록 막는 미들웨어를 만들 수 있습니다.

> 코드를 체계적으로 정리하기 위해 `Sources/App` 디렉터리 안에 `Middleware` 폴더를 만들 것을 권장합니다

미들웨어는 Vapor의 `Middleware` 또는 `AsyncMiddleware` 프로토콜을 준수하는 타입입니다. 미들웨어는 응답자(responder) 체인에 삽입되어, 요청이 라우트 핸들러에 도달하기 전에 이를 접근하고 조작할 수 있으며, 응답이 반환되기 전에 이를 접근하고 조작할 수 있습니다.

위에서 언급한 예제를 활용해, 관리자가 아닌 사용자의 접근을 차단하는 미들웨어를 만들어 보겠습니다.

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

또는 `async`/`await`를 사용한다면 다음과 같이 작성할 수 있습니다.

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

예를 들어 커스텀 헤더를 추가하는 것처럼 응답을 수정하고 싶다면, 이때도 미들웨어를 사용할 수 있습니다. 미들웨어는 응답자 체인으로부터 응답을 받을 때까지 기다렸다가 응답을 조작할 수 있습니다.

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

또는 `async`/`await`를 사용한다면 다음과 같이 작성할 수 있습니다.

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## 파일 미들웨어

`FileMiddleware`를 사용하면 프로젝트의 Public 폴더에 있는 에셋을 클라이언트에 제공할 수 있습니다. 여기에 스타일시트나 비트맵 이미지와 같은 정적 파일을 포함시킬 수 있습니다.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

`FileMiddleware`가 등록되면, `Public/images/logo.png`와 같은 파일은 Leaf 템플릿에서 `<img src="/images/logo.png"/>`와 같이 연결할 수 있습니다.

서버가 iOS 앱과 같은 Xcode 프로젝트 안에 포함되어 있다면, 대신 다음과 같이 사용하세요.

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

또한 애플리케이션을 빌드한 후에도 리소스의 폴더 구조를 유지하려면 Xcode에서 Groups 대신 Folder References를 사용해야 합니다.

## CORS 미들웨어

Cross-origin resource sharing(CORS)은 웹 페이지의 제한된 리소스를 해당 리소스가 제공된 도메인이 아닌 다른 도메인에서 요청할 수 있도록 허용하는 메커니즘입니다. Vapor로 구축된 REST API는 최신 웹 브라우저에 안전하게 요청을 반환하기 위해 CORS 정책이 필요합니다.

설정 예시는 다음과 같습니다.

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware should come before default error middleware using `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

발생한 오류는 즉시 클라이언트에게 반환되므로, `CORSMiddleware`는 `ErrorMiddleware`보다 _앞에_ 나열되어야 합니다. 그렇지 않으면 CORS 헤더 없이 HTTP 오류 응답이 반환되며, 브라우저에서 이를 읽을 수 없게 됩니다.
