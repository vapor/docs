# 트랜잭션

트랜잭션을 사용하면 데이터베이스에 데이터를 저장하기 전에 여러 작업이 성공적으로 완료되었는지 확인할 수 있습니다.
트랜잭션이 시작되면 평소와 같이 Fluent 쿼리를 실행할 수 있습니다. 하지만 트랜잭션이 완료될 때까지는 어떤 데이터도 데이터베이스에 저장되지 않습니다.
트랜잭션이 진행되는 도중 어느 시점에서든 (사용자에 의해서든 데이터베이스에 의해서든) 오류가 발생하면, 변경 사항은 전혀 적용되지 않습니다.

트랜잭션을 수행하려면 데이터베이스에 연결할 수 있는 무언가에 접근할 수 있어야 합니다. 이는 보통 들어오는 HTTP 요청입니다. 이를 위해 `req.db.transaction(_ :)`를 사용하세요.
```swift
req.db.transaction { database in
    // use database
}
```
트랜잭션 클로저 내부에서는 클로저 매개변수로 전달된 데이터베이스(예제에서는 `database`라는 이름)를 사용하여 쿼리를 수행해야 합니다.

이 클로저가 성공적으로 반환되면 트랜잭션이 커밋됩니다.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
위 예제는 트랜잭션을 완료하기 전에 `sun`을 저장하고 *그 다음* `sirius`를 저장합니다. 둘 중 하나라도 저장에 실패하면 어느 쪽도 저장되지 않습니다.

트랜잭션이 완료되면, 그 결과를 아래와 같이 완료를 나타내는 HTTP 상태 코드 등 다른 future로 변환할 수 있습니다.
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

`async`/`await`를 사용하고 있다면 코드를 다음과 같이 리팩토링할 수 있습니다.

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
