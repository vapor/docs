# 에러(Errors)

Vapor는 에러 핸들링을 위한 Swift’s의 `Error` 프로토콜을 기반으로 구현되었습니다. 라우트 핸들러는 error을 던지거나(`throw`) 실패한 `EventLoopFuture`를 반환할 수 있습니다. Swift Error를 반환 또는 던지는 것은 `500` 상태 코드를 발생시키고, 에러가 로그로 기록됩니다. `AbortError`와 `DebuggableError`는 각각 응답 객체와 로깅을 수정하는 데 사용될 수 있습니다. `ErrorMiddleware` 에러들의 처리를 담당합니다. 이 미들웨어는 기본으로 application에 추가되어있고, 원한다면 커스텀 로직으로 교체할 수 있습니다.

## 중단(Abort)

Vapor는 `Abort`라는 이름의 기본 에러 구조체를 제공합니다. 이 구조체는 `AbortError`와 `DebuggableError` 모두를 준수합니다. HTTP 상태와 선택적인(optional) 실패 원인를 인자로 사용하여 초기화할 수 있습니다.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

에러를 던지는 것이 지원되지 않고, 반드시 `EventLoopFuture`를 반환해야 하는 과거의 비동기 방식(`flatMap` 클로저처럼)에서는 실패한 future를 반환할 수 있습니다.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor는 옵셔널 값의 Future을 추출(Unwrapping) 하는 것을 위해 `unwrap(or:)` 메서드를 제공합니다.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

만약 `User.find`가 `nil`을 반환한다면 future는 제공한 error와 함께 실패할 것입니다. nil이 아니라면 `flatMap`은 non-optional 값을 제공받을 것입니다. 만약 `async`/`await`를 사용한다면 optional을 평소처럼 처리할 수 있습니다.

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## 중단 에러(Abort Error)

기본으로 라우트 클로저에 의해 던져지거나 반환되는 Swift `Error`는 `500 Internal Server Error` 응답을 발생시킵니다. 디버그 모드에서 빌드 될 때, `ErrorMiddleware`는 에러에 대한 설명을 포함시킵니다. 프로젝트가 릴리즈 모드로 빌드 됐다면, 보안 유지에 필요한 부분은 제거됩니다.

HTTP 응답 상태 코드나 특정 에러의 원인을 반환하도록 설정하기 위해서는 `AbortError`를 채택하세요.

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## 디버깅 가능한 에러(Debuggable Error)

`ErrorMiddleware`는 라우트에서 던지는 에러를 로깅하기 위해서 `Logger.report(error:)` 메서드를 사용합니다. 이 메서드는 읽을 수 있는 메시지로 로그를 기록하기 위해 `CustomStringConvertible`와 `LocalizedError` 같은 프로토콜을 준수하는지 체크합니다.

여러분의 에러에 `DebuggableError`를 채택함으로 에러 로깅을 커스터마이징 할 수 있습니다. 이 프로토콜은 고유 식별자(unique identifier), 소스 위치(source location), 스택 트레이스(stack trace) 같이 도움이 되는 다양한 프로퍼티를 포함하고 있습니다. 대부분의 프로퍼티가 옵셔널이기 때문에 프로토콜을 채택하는 것이 수월합니다.

`DebuggableError` 를 잘 준수하기 위해서, 여러분의 에러는 필요한 소스 위치와 스택 정보를 저장할 수 있는 구조체인 것이 좋습니다. 아래는 이전에 언급된 `MyError`를 `struct`로 업데이트한 예시입니다. 소스 정보를 저장할 수 있게 되었습니다.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError`는 `possibleCauses`와 `suggestedFixes`같은 다양한 프로퍼티를 가지고 있습니다. 이런 프로퍼티들을 사용한다면 디버깅을 향상시킬 수 있습니다. 더 많은 정보를 위해서 프로토콜을 참고해 보시길 바랍니다.

## 에러 미들웨어(Error Middleware)

`ErrorMiddleware`는 기본으로 application에 추가되어 있는 두 개의 미들웨어 중 하나입니다. 이 미들웨어는 라우트 핸들러가 던지거나 반환한 Swift 에러를 HTTP 응답으로 변환시킵니다. 미들웨어가 없다면, 던져진 에러는 응답 없이 연결이 종료되는 결과를 발생시킬 수 있습니다. 

`AbortError`와 `DebuggableError`이 제공하는 것 이상의 에러 처리를 구현하기 위해서 여러분의 에러 핸들링 로직이 있는 `ErrorMiddleware`로 교체할 수 있습니다. 이것을 위해 첫 번째로 `app.middleware`를 수동으로 초기화해서 기본 에러 미들웨어를 제거해야 합니다. 그다음, 여러분의 에러 처리 미들웨어를 어플리케이션에 첫 미들웨어로서 추가하세요.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

에러 처리 미들웨어는 다른 미들웨어보다 _최상단에_ 위치해야 합니다. 단, `CORSMiddleware`는 이 원칙의 예외입니다.
