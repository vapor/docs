# 콘텐츠(Content)

Vapor의 콘텐츠 API를 사용하면 `Codable` 구조체를 HTTP 메시지로/에서 손쉽게 인코딩·디코딩할 수 있습니다. 기본적으로 [JSON](https://tools.ietf.org/html/rfc7159) 인코딩이 사용되며, [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type)과 [Multipart](https://tools.ietf.org/html/rfc2388)도 기본으로 지원합니다. 이 API는 설정도 가능해서, 특정 HTTP 콘텐츠 타입에 대한 인코딩 전략을 추가하거나 수정하거나 대체할 수 있습니다.

## 개요

Vapor의 콘텐츠 API가 어떻게 동작하는지 이해하기 위해서는 먼저 HTTP 메시지에 대한 몇 가지 기본 사항을 이해해야 합니다. 다음의 요청 예시를 참고해 주세요.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

이 요청은 `content-type` 헤더와 `application/json` 미디어 타입을 사용해서 JSON으로 인코딩된 데이터를 포함하고 있음을 나타냅니다. 예고된 대로, 헤더 다음 본문(Body)에 JSON 데이터가 이어집니다.

### 콘텐츠 구조체

이 HTTP 메시지를 디코딩하는 첫 번째 단계는 예상되는 구조와 일치하는 `Codable` 타입을 만드는 것입니다.

```swift
struct Greeting: Content {
    var hello: String
}
```

타입을 `Content`에 준수시키면 자동으로 `Codable`에 대한 준수성이 추가되며, 콘텐츠 API를 다루는 데 필요한 추가 유틸리티도 함께 제공됩니다.

콘텐츠 구조체를 정의했다면, `req.content`를 사용해서 들어오는 요청으로부터 이를 디코딩할 수 있습니다.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

`decode` 메서드는 요청의 콘텐츠 타입을 사용해서 적절한 디코더를 찾습니다. 디코더를 찾지 못하거나 요청에 콘텐츠 타입 헤더가 없다면, `415` 에러가 발생합니다.

즉, 이 라우트는 아래와 같은 url-encoded form을 포함해서 지원되는 다른 모든 콘텐츠 타입을 자동으로 받아들입니다.

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

파일 업로드의 경우, 콘텐츠 프로퍼티는 `Data` 타입이어야 합니다.

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### 지원하는 미디어 타입

아래는 콘텐츠 API가 기본으로 지원하는 미디어 타입입니다.

|이름|헤더 값|미디어 타입|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

모든 미디어 타입이 `Codable`의 모든 기능을 지원하는 것은 아닙니다. 예를 들어 JSON은 최상위 fragment를 지원하지 않으며, Plaintext는 중첩된 데이터를 지원하지 않습니다.

## 쿼리(Query)

Vapor의 콘텐츠 API는 URL의 쿼리 스트링에서 URL 인코딩 데이터를 다루는 것을 지원합니다.

### 디코딩

URL 쿼리 스트링을 디코딩하는 방법을 이해하기 위해, 다음의 요청 예시를 살펴보겠습니다.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

HTTP 메시지 본문의 콘텐츠를 다루는 API와 마찬가지로, URL 쿼리 스트링을 파싱하는 첫 번째 단계는 예상되는 구조와 일치하는 `struct`를 만드는 것입니다.

```swift
struct Hello: Content {
    var name: String?
}
```

`name`이 옵셔널(Optional) `String`인 이유는 URL 쿼리 스트링이 항상 옵셔널이어야 하기 때문입니다. 파라미터를 필수로 만들고 싶다면, 대신 라우트 파라미터를 사용하세요.

이제 이 라우트가 예상하는 쿼리 스트링에 대한 `Content` 구조체를 만들었으니, 이를 디코딩할 수 있습니다.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

이 라우트는 위 예시의 요청에 대해 다음과 같은 응답을 반환합니다.

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

다음 요청처럼 쿼리 스트링이 생략된 경우에는, 대신 "Anonymous"라는 이름이 사용됩니다.

```http
GET /hello HTTP/1.1
content-length: 0
```

### 단일 값

`Content` 구조체로 디코딩하는 것 외에도, Vapor는 서브스크립트를 사용해서 쿼리 스트링으로부터 단일 값을 가져오는 것도 지원합니다.

```swift
let name: String? = req.query["name"]
```

## 후크(Hooks)

Vapor는 `Content` 타입에 대해 `beforeEncode`와 `afterDecode`를 자동으로 호출합니다. 아무 동작도 하지 않는 기본 구현이 제공되지만, 이 메서드들을 사용해서 커스텀 로직을 실행할 수 있습니다.

```swift
// 이 Content가 디코딩된 후에 실행됩니다. `mutating`은 구조체에만 필요하며, 클래스에는 필요하지 않습니다.
mutating func afterDecode() throws {
    // name이 전달되지 않을 수도 있지만, 전달되었다면 빈 문자열일 수는 없습니다.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// 이 Content가 인코딩되기 전에 실행됩니다. `mutating`은 구조체에만 필요하며, 클래스에는 필요하지 않습니다.
mutating func beforeEncode() throws {
    // name은 *반드시* 다시 전달되어야 하며, 빈 문자열일 수는 없습니다.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## 기본값 재정의

Vapor의 콘텐츠 API가 사용하는 기본 인코더와 디코더는 설정할 수 있습니다.

### 전역

`ContentConfiguration.global`을 사용하면 Vapor가 기본으로 사용하는 인코더와 디코더를 변경할 수 있습니다. 애플리케이션 전체가 데이터를 파싱하고 직렬화하는 방식을 바꿀 때 유용합니다.

```swift
// unix-timestamp 형식의 날짜를 사용하는 새로운 JSON 인코더를 생성합니다
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// `.json` 미디어 타입에 사용되는 전역 인코더를 재정의합니다
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

`ContentConfiguration`을 변경하는 작업은 보통 `configure.swift`에서 이루어집니다.

### 일회성

`req.content.decode`와 같은 인코딩·디코딩 메서드 호출은 일회성 용도로 커스텀 코더를 전달하는 것을 지원합니다.

```swift
// unix-timestamp 형식의 날짜를 사용하는 새로운 JSON 디코더를 생성합니다
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// 커스텀 디코더를 사용해서 Hello 구조체를 디코딩합니다
let hello = try req.content.decode(Hello.self, using: decoder)
```

## 커스텀 코더

애플리케이션과 서드파티 패키지는 커스텀 코더를 만들어서 Vapor가 기본으로 지원하지 않는 미디어 타입에 대한 지원을 추가할 수 있습니다.

### 콘텐츠

Vapor는 HTTP 메시지 본문의 콘텐츠를 다룰 수 있는 코더를 위해 두 가지 프로토콜, `ContentDecoder`와 `ContentEncoder`를 정의합니다.

```swift
public protocol ContentEncoder {
    func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
}

public protocol ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
        where D: Decodable
}
```

이 프로토콜을 준수하면, 위에서 설명한 것처럼 커스텀 코더를 `ContentConfiguration`에 등록할 수 있습니다.

### URL 쿼리

Vapor는 URL 쿼리 스트링의 콘텐츠를 다룰 수 있는 코더를 위해 두 가지 프로토콜, `URLQueryDecoder`와 `URLQueryEncoder`를 정의합니다.

```swift
public protocol URLQueryDecoder {
    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D
        where D: Decodable
}

public protocol URLQueryEncoder {
    func encode<E>(_ encodable: E, to url: inout URI) throws
        where E: Encodable
}
```

이 프로토콜을 준수하면, `use(urlEncoder:)`와 `use(urlDecoder:)` 메서드를 사용해서 URL 쿼리 스트링을 다루기 위한 커스텀 코더를 `ContentConfiguration`에 등록할 수 있습니다.

### 커스텀 `ResponseEncodable`

또 다른 방법은 여러분의 타입에 `ResponseEncodable`을 구현하는 것입니다. 다음과 같은 간단한 `HTML` 래퍼 타입을 생각해 봅시다.

```swift
struct HTML {
  let value: String
}
```

그러면 `ResponseEncodable` 구현은 다음과 같은 모습이 될 것입니다.

```swift
extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}
```

`async`/`await`를 사용하고 있다면 `AsyncResponseEncodable`을 사용할 수 있습니다.

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

이렇게 하면 `Content-Type` 헤더를 커스터마이즈할 수 있습니다. 더 자세한 정보는 [`HTTPHeaders` reference](https://api.vapor.codes/vapor/documentation/vapor/response/headers)를 참고해 주세요.

이제 라우트에서 `HTML`을 응답 타입으로 사용할 수 있습니다.

```swift
app.get { _ in
  HTML(value: """
  <html>
    <body>
      <h1>Hello, World!</h1>
    </body>
  </html>
  """)
}
```
