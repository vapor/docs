# 라우팅(Routing)

라우팅은 유입되는 요청(Incomming Request)에 적합한 요청 핸들러(Request Handler)를 찾는 과정입니다. Vapor 라우팅의 핵심에는 [RoutingKit](https://github.com/vapor/routing-kit)의 고성능, 트라이 노드(trie-node) 라우터가 있습니다.

## 개요

Vapor에서 라우팅이 어떻게 동작하는지 이해하기 위해서는 먼저 HTTP 요청에 대한 몇 가지 기본 사항을 이해해야 합니다. 다음의 요청 예시를 참고해 주세요.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

이것은 `/hello/vapor` URL로 보내는 간단한 `GET` 형태의 HTTP 요청입니다. 브라우저 주소창에서 다음의 URL을 입력했을 때, 브라우저가 보내는 HTTP 요청과 같은 종류입니다.

```
http://vapor.codes/hello/vapor
```

### HTTP 메서드

요청의 첫 번째 파트는 HTTP 메서드입니다. 가장 보편적인 HTTP 메서드는 `GET`입니다. 그러나 여러분이 자주 사용하는 몇 개의 메서드가 더 있습니다. 이 HTTP 메서드들은 [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) 개념과 관계가 있습니다.

|Method|CRUD|
|-|-|
|`GET`|읽기|
|`POST`|생성|
|`PUT`|교체(덮어쓰기)|
|`PATCH`|부분 수정|
|`DELETE`|삭제|

### 요청 경로(Request Path)

HTTP 메서드 바로 뒤에는 요청의 URI가 있습니다. URI는 `/`로 시작하는 경로와 `?` 뒤에 따라오는 선택적인(Optional) 쿼리 스트링으로 구성됩니다. Vapor는 요청을 이 HTTP 메서드와 Path를 사용해서 라우팅합니다.

URI 다음에는 HTTP 버전이 표시됩니다. 그 뒤에는 헤더와 본문(Body)이 올 수 있습니다. `GET` 요청에는 본문(Body)이 없습니다.

### 라우터 메서드(Router Methods)

다음 요청을 Vapor가 어떻게 처리하는지 살펴보겠습니다.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

일반적인 모든 HTTP 메서드는 `Application`의 메서드로 사용 가능합니다. 이 메서드들은 `/`로 구분되는 하나 또는 그 이상의 문자열 인자의 경로를 받습니다.

참고로 `on` 뒤에 메서드를 명시하는 방식으로 사용할 수도 있습니다.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

경로가 등록되면, 예시의 HTTP 요청은 다음 HTTP 응답(response)을 반환할 것입니다.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### 경로 파라미터(Route Parameters)

HTTP 메서드와 경로를 기반으로 요청을 성공적으로 라우팅했습니다. 이제는 동적 경로를 만들어보겠습니다. 이전에는 “vapor”라는 이름이 경로와 응답 모두에 고정되어 있었습니다. 이것을 동적으로 바꿀 수 있습니다. `/hello/<any name>`으로 변경해서, 입력되는 name에 따라 응답을 받을 수 있습니다.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

경로 컴포넌트 앞에 `:`을 붙이면, 라우터에게 해당 컴포넌트가 동적 컴포넌트 경로임을 나타냅니다. 이 자리에 오는 어떤 문자열이든 이 라우트와 매칭됩니다. `req.parameters`를 사용해서 해당 문자열의 값에 접근할 수 있습니다.

만약 예시의 요청을 다시 실행한다면 여전히 “Hello, vapor!”라는 요청을 받을 것입니다. 그러나 이제는 `/hello/`뒤에 어떤 이름을 추가할 수 있고, 그 이름이 포함된 응답을 볼 수 있을 것입니다. `/hello/swift`로 요청을 보내보세요.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

이제 기본적인 것들을 살펴보았습니다. 각 섹션을 통해서 파라미터, 그룹 등 더 많은 것을 알아보세요.

## 라우트(Routes)

라우트는 주어진 HTTP 메서드와 URI 경로에 대한 요청 핸들러를 지정합니다. 또한, 추가적인 메타데이터를 저장할 수 있습니다.

### 메서드(Methods)

다양한 HTTP 메서드 헬퍼를 사용해서 `Application`에 라우트를 직접 등록할 수 있습니다.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

라우트 핸들러는 `ResponseEncodable`를 준수하는 모든 타입을 반환할 수 있습니다. 여기에는 `Content`, `async` 클로저, 그리고 미래의 결괏값이 `ResponseEncodable`을 준수하는 `EventLoopFuture`가 포함됩니다.

`in` 앞에 `-> T`를 사용해서 라우트의 반환 타입을 지정할 수 있습니다. 반환 타입을 컴파일러가 결정할 수 없는 상황에서 유용하게 사용할 수 있습니다.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

지원하는 라우트 헬퍼 메서드는 다음과 같습니다.

- `get`
- `post`
- `patch`
- `put`
- `delete`

HTTP 메서드 헬퍼 이외에 `on` 함수도 있습니다. on 함수는 HTTP 메서드를 인자로 전달할 수 있습니다.

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### 경로(Path Component)

각 라우트 등록 메서드는 `PathComponent` 리스트를 가변 인자 형태로 받습니다. 이 타입은 문자열 리터럴로 표현 가능하고, 네 가지 케이스가 있습니다.

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`*`)
- Catchall (`**`)

#### 상수(Constant)

상수는 정적 경로 컴포넌트입니다. 해당 위치에 문자열이 정확히 일치하는 요청만 허용됩니다.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### 파라미터(Parameter)

동적 경로 컴포넌트입니다. 해당 자리의 어떤 문자열이든 허용합니다. `:`를 접두사를 사용하여 파라미터 경로 컴포넌트를 명시합니다. `:`뒤의 문자열은 파라미터의 이름으로 사용됩니다. 해당 이름을 사용해서 요청의 파라미터 값을 가져올 수 있습니다.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Anything

Anything 컴포넌트는 파라미터 컴포넌트와 비슷합니다. 하지만, 값을 버린다는 점에서 차이가 있습니다. Anything 컴포넌트는 `*`로 명시할 수 있습니다.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Catchall

Catchall은 하나 또는 그 이상의 컴포넌트와 매치되는 동적 경로 컴포넌트입니다. `**`을 사용해서 명시할 수 있습니다. 해당 위치 또는, 그 이후 위치에 오는 모든 문자열이 이 요청에 매치됩니다.

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Parameters

(접두사 `:`와 함께) 파라미터 경로 컴포넌트를 사용할 때, 해당 위치의 URI 값이 `req.parameters`에 저장됩니다. 경로 컴포넌트의 이름을 사용해서 값에 접근할 수 있습니다.

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    라우트 경로에 :name이 포함되어 있다면 `req.parameters.get`에는 `nil`이 절대로 반환되지 않을 것입니다. 하지만, 만약 미들웨어나 여러 라우트들에서 공통적으로 사용하는 코드가 있다면, 라우트 파라미터에 접근할 때 `nil`이 반환될 가능성이 있습니다. 이를 고려한 작업이 필요합니다.

!!! tip
    예를 들어 `/hello/?name=foo` 같은 URL에서 쿼리 파라미터를 가져오려면, Vapor의 Content API를 사용해야 합니다. URL 쿼리 스트링 안에서 URL 인코딩 데이터를 처리할 수 있습니다. 더 자세한 정보를 위해서 [`Content` reference](content.md)를 살펴보세요.

`req.parameters.get`은 `LosslessStringConvertible` 타입을 준수하는 타입으로 자동 캐스팅합니다.

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

Catchall (`**`)로 매치된 URI 값은 `[String]`으로 `req.parameters`에 저장됩니다. `req.parameters.getCatchall`을 사용해서 이 컴포넌트들에 접근할 수 있습니다.

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### 본문 스트리밍(Body Streaming)

`on` 메서드를 사용해서 라우트를 등록할 때, 요청 본문(Body)을 어떻게 처리할지 지정할 수 있습니다. 요청 본문들은 핸들러를 요청하기 전에 기본적으로 메모리에 수집됩니다. 애플리케이션에 들어오는 요청이 비동기적으로 읽히더라도, 동기적으로 요청 콘텐츠 디코딩을 수행할 수 있게 해주는데 유용합니다.

Vapor는 기본적으로 스트리밍 본문을 16KB로 제한합니다. `app.routes`를 사용해서 설정할 수 있습니다.

```swift
// 스트리밍 본문 제한을 500kb로 증가시킵니다.
app.routes.defaultMaxBodySize = "500kb"
```

만약 수집된 스트리밍 본문이 설정된 제한을 초과하면 `413 Payload Too Large` 에러가 반환됩니다.

각각의 라우트마다 요청 본문 수집 전략을 설정하려면 `body` 파라미터를 사용하세요.

```swift
// 라우트가 실행되기 전, 스트리밍 본문을 최대 1mb로 수집합니다.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request. 
}
```

라우트에 `collect` 메서드로 `maxSize`를 전달하면 애플리케이션의 기본값보다 우선되어 적용됩니다. application의 기본값을 사용하려면 `maxSize` 인자를 생략하세요.

파일 업로드 같은 대용량 요청의 경우, 요청 본문을 버퍼에 수집하는 것은 잠재적으로 시스템 메모리에 부담을 줄 수 있습니다. 요청 본문이 수집되는 것을 막기 위해서는 `stream` 전략을 사용하세요.

```swift
// 요청 본문을 버퍼로 수집하지 않습니다.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

요청 본문이 스트리밍 될 때, `req.body.data`는 `nil`입니다. 경로로 보내지는 각 조각 데이터를 처리하기 위해서는 `req.body.drain`를 사용해야 합니다.  

### 대소문자를 구분하지 않는 라우팅(Case Insensitive Routing)

대소문자를 구분하고 유지하는 것은 라우팅의 기본 동작입니다. `Constant` 경로 컴포넌트는 라우팅의 목적에 따라 대소문자를 구분하지 않으면서 원래의 대소문자 형태를 유지하도록 처리할 수 있습니다. 이 동작을 사용하기 위해서는 application의 시작 전에 다음과 같이 설정하세요.  

```swift
app.routes.caseInsensitive = true
```

원래의 요청은 변경되지 않습니다. 라우트 핸들러는 수정되지 않은 요청 경로 컴포넌트를 수신할 것입니다.

### Viewing Routes

`app.routes`를 사용하거나 `Routes` 서비스를 생성해서 Application의 라우트에 접근할 수 있습니다.

```swift
print(app.routes.all) // [Route]
```

Vapor는 `routes`라는 명령어를 제공합니다. 이 명령어는 사용 가능한 모든 라우트들을 ASCII 형식의 테이블로 출력합니다.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### 메타데이터(Metadata)

모든 라우트 등록 메서드는 생성된 `Route`를 반환합니다. 이를 통해 라우트의 `userInfo` Dictionary에 메타데이터를 추가할 수 있습니다. 설명을 추가하는 것처럼 기본적으로 사용할 수 있는 몇 가지 메서드들이 있습니다.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## 라우트 그룹(Route Groups)

라우트를 그룹화해서 경로 접두사나 특정 미들웨어가 있는 라우트 집합을 생성할 수 있습니다. 그룹화는 빌더와 클로저 기반의 문법을 제공합니다.

모든 그룹화 메서드는 `RouteBuilder`를 반환합니다. `RouteBuilder`는 다른 라우트 빌딩 메서드와 함께 제한 없이 혼합, 매치, 중첩시킬 수 있습니다.

### 경로 접두사(Path Prefix)

라우트 그룹에 경로 접두사를 사용해서 하나 또는 그 이상의 경로 컴포넌트를 라우트의 그룹 앞에 추가할 수 있습니다. 

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

`get` 이나 `post` 같은 메서드에 전달할 수 있는 경로 컴포넌트는 `grouped`에도 전달할 수 있습니다. 클로저 기반의 문법으로 사용할 수도 있습니다.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

경로 접두사 라우트 그룹을 중첩해서 CRUD API를 간결히 정의할 수 있습니다.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### 미들웨어(Middleware)

경로 컴포넌트를 접두사로 붙이는 것 외에도, 미들웨어를 라우트 그룹에 추가할 수도 있습니다.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```

서로 다른 인증 미들웨어를 사용해서 라우트들의 일부 하위 부분들을 보호할 수 있습니다.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## 리다이렉션(Redirections)

리다이렉트는 다양한 시나리오에서 유용합니다. SEO를 위해서 옛날 주소를 새로운 주소로 이동시키거나, 인증이 되지 않은 사용자를 로그인 페이지로 이동시키거나, 새로운 API 버전에서 하위 호환성을 지원하기 위해 사용할 수 있습니다.

리다이렉트를 요청하기 위해서는 아래와 같이 사용하세요.

```swift
req.redirect(to: "/some/new/path")
```

리다이렉트의 유형을 지정할 수도 있습니다. (SEO가 적절하게 업데이트 되도록) 페이지를 영구적으로 리다이렉트 할 수 있습니다.

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

`Redirect`의 차이는 다음과 같습니다.

* `.permanent` - **301 Permanent** 리다이렉트를 반환합니다.
* `.normal` - **303 see other** 리다이렉트를 반환합니다. Vapor의 기본값은 303입니다. 클라이언트에게 **GET** 요청으로 리다이렉트를 지시합니다.
* `.temporary` - **307 Temporary** 리다이렉트를 반환합니다. 클라이언트에게 원래의 HTTP 요청을 유지하도록 합니다.

> 적절한 리다이렉션 상태 코드를 선택하기 위해서는 [전체 리스트](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)를 참고하세요.
