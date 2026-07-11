# 비밀번호

Vapor는 비밀번호를 안전하게 저장하고 검증할 수 있도록 도와주는 비밀번호 해싱 API를 포함하고 있습니다. 이 API는 환경에 따라 설정할 수 있으며 비동기 해싱을 지원합니다.

## 설정

Application의 비밀번호 해셔(hasher)를 설정하려면 `app.passwords`를 사용하세요.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

비밀번호 해싱을 위해 Vapor의 [Bcrypt API](crypto.md#bcrypt)를 사용하려면 `.bcrypt`를 지정하세요. 이는 기본값입니다.

```swift
app.passwords.use(.bcrypt)
```

별도로 지정하지 않으면 Bcrypt는 비용(cost)으로 12를 사용합니다. `cost` 매개변수를 전달해서 이를 설정할 수 있습니다.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor는 비밀번호를 평문(plaintext)으로 저장하고 검증하는 안전하지 않은 비밀번호 해셔를 포함하고 있습니다. 이는 프로덕션에서 사용해서는 안 되지만 테스트에는 유용할 수 있습니다.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## 해싱

비밀번호를 해싱하려면 `Request`에서 사용할 수 있는 `password` 헬퍼를 사용하세요.

```swift
let digest = try req.password.hash("vapor")
```

비밀번호 다이제스트(digest)는 `verify` 메서드를 사용해서 평문 비밀번호와 대조하여 검증할 수 있습니다.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

동일한 API를 부팅(boot) 중에 사용할 수 있도록 `Application`에서도 제공합니다.

```swift
let digest = try app.password.hash("vapor")
```

### 비동기

비밀번호 해싱 알고리즘은 느리고 CPU를 많이 사용하도록 설계되어 있습니다. 이 때문에 비밀번호를 해싱하는 동안 이벤트 루프가 블로킹되는 것을 피하고 싶을 수 있습니다. Vapor는 해싱 작업을 백그라운드 스레드 풀로 디스패치하는 비동기 비밀번호 해싱 API를 제공합니다. 비동기 API를 사용하려면 비밀번호 해셔의 `async` 프로퍼티를 사용하세요.

```swift
req.password.async.hash("vapor").map { digest in
    // Handle digest.
}

// or

let digest = try await req.password.async.hash("vapor")
```

다이제스트를 검증하는 것도 비슷하게 동작합니다.

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Handle result.
}

// or

let result = try await req.password.async.verify("vapor", created: digest)
```

해시 계산을 백그라운드 스레드에서 수행하면 애플리케이션의 이벤트 루프가 더 많은 들어오는 요청을 처리할 수 있게 됩니다.
