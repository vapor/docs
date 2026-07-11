# Request

[`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) 객체는 모든 [라우트 핸들러](../basics/routing.md)에 전달됩니다.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

이는 Vapor의 나머지 기능들로 향하는 주된 창구입니다. [요청 본문](../basics/content.md), [쿼리 매개변수](../basics/content.md#쿼리query), [로거](../basics/logging.md), [HTTP 클라이언트](../basics/client.md), [Authenticator](../security/authentication.md) 등에 대한 API를 포함하고 있습니다. request를 통해 이러한 기능에 접근하면 계산이 올바른 이벤트 루프에서 유지되며, 테스트를 위해 mocking하는 것도 가능해집니다. 익스텐션을 사용해 여러분만의 [서비스](../advanced/services.md)를 `Request`에 추가할 수도 있습니다.

`Request`에 대한 전체 API 문서는 [여기](https://api.vapor.codes/vapor/documentation/vapor/request)에서 확인할 수 있습니다.

## Application

`Request.application` 프로퍼티는 [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application)에 대한 참조를 가지고 있습니다. 이 객체는 애플리케이션의 모든 설정과 핵심 기능을 담고 있습니다. 대부분의 경우 애플리케이션이 완전히 시작되기 전인 `configure.swift`에서만 설정해야 하며, 하위 레벨의 API들은 대부분의 애플리케이션에서 필요하지 않을 것입니다. 가장 유용한 프로퍼티 중 하나는 `Application.eventLoopGroup`으로, `any()` 메서드를 통해 새로운 `EventLoop`가 필요한 프로세스에서 이를 얻는 데 사용할 수 있습니다. 여기에는 [`Environment`](../basics/environment.md)도 포함되어 있습니다.

## Body

요청 본문에 `ByteBuffer`로 직접 접근하고 싶다면 `Request.body.data`를 사용할 수 있습니다. 이는 요청 본문의 데이터를 파일로 스트리밍하거나(다만 이 경우 request의 [`fileio`](../advanced/files.md) 프로퍼티를 대신 사용해야 합니다) 다른 HTTP 클라이언트로 전달하는 데 사용될 수 있습니다.

## Cookies

쿠키를 가장 유용하게 활용하는 방법은 내장된 [세션](../advanced/sessions.md#설정) 기능을 통하는 것이지만, `Request.cookies`를 통해 쿠키에 직접 접근할 수도 있습니다.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

`HTTPHeaders` 객체는 `Request.headers`에서 접근할 수 있습니다. 여기에는 요청과 함께 전송된 모든 헤더가 담겨 있습니다. 예를 들어 `Content-Type` 헤더에 접근하는 데 사용할 수 있습니다.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

`HTTPHeaders`에 대한 추가 문서는 [여기](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders)에서 확인하세요. Vapor는 가장 흔히 사용되는 헤더들을 더 쉽게 다룰 수 있도록 `HTTPHeaders`에 여러 익스텐션을 추가했으며, 그 목록은 [여기](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)에서 확인할 수 있습니다.

## IP Address

클라이언트를 나타내는 `SocketAddress`는 `Request.remoteAddress`를 통해 접근할 수 있으며, 문자열 표현인 `Request.remoteAddress.ipAddress`는 로깅이나 rate limiting에 유용할 수 있습니다. 애플리케이션이 리버스 프록시 뒤에 있는 경우 클라이언트의 실제 IP 주소를 정확히 나타내지 못할 수 있습니다.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

`SocketAddress`에 대한 추가 문서는 [여기](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress)에서 확인하세요.
