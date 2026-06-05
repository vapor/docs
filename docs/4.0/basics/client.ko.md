# 클라이언트(Client)

Vapor의 클라이언트는 외부 리소스에 HTTP 요청을 보낼 수 있습니다. 클라이언트는 [async-http-client](https://github.com/swift-server/async-http-client)을 기반으로 만들어졌으며, [content](content.md) API로 통합되어 있습니다.

## 개요

`Application`을 통해 기본 클라이언트에 접근할 수 있습니다. 또는, 라우터 핸들러 안에서 `Request`를 통해 접근할 수 있습니다.

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

애플리케이션의 클라이언트는 설정(Configuration)을 하는 동안에 HTTP 요청을 만드는데 유용합니다. 만약 라우터 핸들러 안에서 HTTP 요청을 만든다면, 항상 request의 클라이언트를 사용하세요.

### 메서드(Methods)

원하는 URL을 `GET` 메서드에 전달해서 `GET` 요청을 만들어보세요.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

`get`, `post`, 그리고 `delete` 같은 각각의 HTTP 메서드를 위한 메서드들이 있습니다. 클라이언트의 응답은 HTTP 상태 코드, 헤더, 본문을 포함하고, Future 형태로 반환됩니다.

### 컨텐츠(Content)

클라이언트의 요청과 응답에서 데이터를 처리하는 데 Vapor의 [content](content.md) API를 사용할 수 있습니다. 컨텐츠를 인코딩하거나, 쿼리 파라미터나 헤더를 요청에 추가하기 위해서는 `beforeSend` 클로저를 사용하세요.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Encode query string to the request URL.
	try req.query.encode(["q": "test"])

	// Encode JSON to the request body.
    try req.content.encode(["hello": "world"])
    
    // Add auth header to the request
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Handle the response.
```

비슷한 방식으로, `Content`를 사용해서 응답 본문을 디코딩 할 수 있습니다.

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

만약 future을 사용한다면, `flatMapThrowing`을 사용할 수 있습니다.

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Use JSON here
}
```

## 설정(Configuration)

애플리케이션을 통해 내부 HTTP 클라이언트를 설정할 수 있습니다.

```swift
// Disable automatic redirect following.
app.http.client.configuration.redirectConfiguration = .disallow
```

기본 클라이언트는 반드시 처음 _사용하기 전에_ 먼저 설정을 해야 합니다.


