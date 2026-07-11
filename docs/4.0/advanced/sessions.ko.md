# 세션(Sessions)

세션을 사용하면 여러 요청 사이에서 사용자의 데이터를 유지할 수 있습니다. 세션은 새로운 세션이 초기화될 때 HTTP 응답과 함께 고유한 쿠키를 생성하여 반환하는 방식으로 동작합니다. 브라우저는 이 쿠키를 자동으로 감지하여 이후 요청에 포함시킵니다. 이를 통해 Vapor는 요청 핸들러에서 특정 사용자의 세션을 자동으로 복원할 수 있습니다.

세션은 HTML을 웹 브라우저에 직접 제공하는, Vapor로 만든 프런트엔드 웹 애플리케이션에 매우 유용합니다. API의 경우, 요청 간에 사용자 데이터를 유지하기 위해 상태를 갖지 않는(stateless) [토큰 기반 인증](../security/authentication.md)을 사용하는 것을 권장합니다.

## 설정

라우트에서 세션을 사용하려면 요청이 `SessionsMiddleware`를 거쳐야 합니다. 이를 구현하는 가장 쉬운 방법은 이 미들웨어를 전역으로 추가하는 것입니다. 쿠키 팩토리를 선언한 이후에 이 미들웨어를 추가하는 것이 좋습니다. Sessions는 구조체이므로 참조 타입이 아니라 값 타입이기 때문입니다. 값 타입이므로 `SessionsMiddleware`를 사용하기 전에 값을 설정해야 합니다.

```swift
app.middleware.use(app.sessions.middleware)
```

일부 라우트에서만 세션을 사용하는 경우, 대신 라우트 그룹에 `SessionsMiddleware`를 추가할 수 있습니다.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

세션에 의해 생성되는 HTTP 쿠키는 `app.sessions.configuration`을 사용하여 설정할 수 있습니다. 쿠키 이름을 변경하거나 쿠키 값을 생성하는 사용자 정의 함수를 선언할 수 있습니다.

```swift
// 쿠키 이름을 "foo"로 변경합니다.
app.sessions.configuration.cookieName = "foo"

// 쿠키 값 생성을 설정합니다.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

기본적으로 Vapor는 `vapor_session`을 쿠키 이름으로 사용합니다.

## 드라이버

세션 드라이버는 식별자를 기준으로 세션 데이터를 저장하고 조회하는 역할을 담당합니다. `SessionDriver` 프로토콜을 준수하도록 만들어 사용자 정의 드라이버를 만들 수 있습니다.

!!! warning
    세션 드라이버는 애플리케이션에 `app.sessions.middleware`를 추가하기 _전에_ 설정해야 합니다.

### 인메모리(In-Memory)

Vapor는 기본적으로 인메모리 세션을 사용합니다. 인메모리 세션은 별도의 설정이 필요 없으며 애플리케이션이 재실행되어도 유지되지 않기 때문에 테스트에 매우 유용합니다. 인메모리 세션을 수동으로 활성화하려면 `.memory`를 사용하십시오.

```swift
app.sessions.use(.memory)
```

프로덕션에서 사용하려면, 여러 애플리케이션 인스턴스 간에 세션을 유지하고 공유하기 위해 데이터베이스를 활용하는 다른 세션 드라이버를 살펴보십시오.

### Fluent

Fluent는 애플리케이션의 데이터베이스에 세션 데이터를 저장하는 기능을 지원합니다. 이 섹션에서는 여러분이 이미 [Fluent를 설정](../fluent/overview.md)했고 데이터베이스에 연결할 수 있다고 가정합니다. 첫 번째 단계는 Fluent 세션 드라이버를 활성화하는 것입니다.

```swift
import Fluent

app.sessions.use(.fluent)
```

이렇게 하면 애플리케이션의 기본 데이터베이스를 사용하도록 세션이 설정됩니다. 특정 데이터베이스를 지정하려면 해당 데이터베이스의 식별자를 전달하십시오.

```swift
app.sessions.use(.fluent(.sqlite))
```

마지막으로, `SessionRecord`의 마이그레이션을 데이터베이스의 마이그레이션 목록에 추가하십시오. 이렇게 하면 `_fluent_sessions` 스키마에 세션 데이터를 저장할 수 있도록 데이터베이스가 준비됩니다.

```swift
app.migrations.add(SessionRecord.migration)
```

새 마이그레이션을 추가한 후에는 애플리케이션의 마이그레이션을 반드시 실행하십시오. 이제 세션은 애플리케이션의 데이터베이스에 저장되어 재시작 후에도 유지되며 애플리케이션의 여러 인스턴스 간에 공유될 수 있습니다.

### Redis

Redis는 설정된 Redis 인스턴스에 세션 데이터를 저장하는 기능을 지원합니다. 이 섹션에서는 여러분이 이미 [Redis를 설정](../redis/overview.md)했고 Redis 인스턴스에 명령을 보낼 수 있다고 가정합니다.

세션에 Redis를 사용하려면, 애플리케이션을 설정할 때 이를 선택하십시오.

```swift
import Redis

app.sessions.use(.redis)
```

이렇게 하면 기본 동작으로 Redis 세션 드라이버를 사용하도록 세션이 설정됩니다.

!!! seealso
    Redis와 세션에 대한 더 자세한 정보는 [Redis &rarr; 세션](../redis/sessions.md)을 참고하십시오.

## 세션 데이터

이제 세션이 설정되었으니, 요청 간에 데이터를 유지할 준비가 되었습니다. 새로운 세션은 `req.session`에 데이터가 추가될 때 자동으로 초기화됩니다. 아래 예제 라우트 핸들러는 동적 라우트 매개변수를 받아 그 값을 `req.session.data`에 추가합니다.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

다음 요청을 사용하여 이름이 vapor인 세션을 초기화하십시오.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

다음과 유사한 응답을 받게 될 것입니다.

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

`req.session`에 데이터를 추가한 후 응답에 `set-cookie` 헤더가 자동으로 추가된 것을 확인하십시오. 이후 요청에 이 쿠키를 포함시키면 세션 데이터에 접근할 수 있습니다.

세션에서 name 값을 가져오는 다음 라우트 핸들러를 추가하십시오.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

이전 응답에서 받은 쿠키 값을 반드시 전달하면서, 다음 요청을 사용하여 이 라우트에 접근하십시오.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

응답에서 이름 vapor가 반환되는 것을 볼 수 있습니다. 필요에 따라 세션에서 데이터를 추가하거나 제거할 수 있습니다. 세션 데이터는 HTTP 응답을 반환하기 전에 세션 드라이버와 자동으로 동기화됩니다.

세션을 종료하려면 `req.session.destroy`를 사용하십시오. 이렇게 하면 세션 드라이버에서 데이터를 삭제하고 세션 쿠키를 무효화합니다.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
