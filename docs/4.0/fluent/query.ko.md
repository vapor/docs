# 쿼리

Fluent의 쿼리 API를 사용하면 데이터베이스에서 모델을 생성, 조회, 수정, 삭제할 수 있습니다. 결과 필터링, 조인, 청크 처리, 집계 등 다양한 기능을 지원합니다.

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

쿼리 빌더는 하나의 모델 타입에 종속되며, static [`query`](model.md#query) 메서드를 사용해서 생성할 수 있습니다. 또한 데이터베이스 객체의 `query` 메서드에 모델 타입을 전달해서 생성할 수도 있습니다.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note
    컴파일러가 Fluent의 헬퍼 함수를 확인할 수 있도록, 쿼리를 작성하는 파일에 `import Fluent`를 반드시 추가해야 합니다.

## All

`all()` 메서드는 모델의 배열을 반환합니다.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

`all` 메서드는 결과 집합에서 단일 필드만 가져오는 것도 지원합니다.

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

`first()` 메서드는 단일 옵셔널 모델을 반환합니다. 쿼리 결과가 두 개 이상의 모델을 반환하더라도, 첫 번째 모델만 반환됩니다. 쿼리 결과가 없다면 `nil`이 반환됩니다.

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    `EventLoopFuture`를 사용한다면, [`unwrap(or:)`](../basics/errors.md#중단abort)와 이 메서드를 함께 사용해서 논옵셔널 모델을 반환하거나 에러를 던질 수 있습니다.

## Filter

`filter` 메서드를 사용하면 결과 집합에 포함되는 모델을 제한할 수 있습니다. 이 메서드에는 여러 오버로드가 있습니다.

### 값 필터(Value Filter)

가장 흔히 사용되는 `filter` 메서드는 값과 함께 연산자 표현식을 받습니다.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

이 연산자 표현식은 왼쪽에 필드의 키 경로(key path)를, 오른쪽에 값을 받습니다. 전달되는 값은 필드가 예상하는 값 타입과 일치해야 하며, 결과 쿼리에 바인딩됩니다. 필터 표현식은 강타입(strongly typed)이므로 leading-dot 문법을 사용할 수 있습니다.

아래는 지원되는 모든 값 연산자의 목록입니다.

|연산자|설명|
|-|-|
|`==`|같음.|
|`!=`|같지 않음.|
|`>=`|크거나 같음.|
|`>`|큼.|
|`<`|작음.|
|`<=`|작거나 같음.|

### 필드 필터(Field Filter)

`filter` 메서드는 두 필드를 비교하는 것도 지원합니다.

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

필드 필터는 [값 필터](#값-필터value-filter)와 동일한 연산자를 지원합니다.

### 서브셋 필터(Subset Filter)

`filter` 메서드는 필드의 값이 주어진 값 집합에 존재하는지 확인하는 것도 지원합니다.

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

전달되는 값 집합은 `Element` 타입이 필드의 값 타입과 일치하는 어떤 Swift `Collection`이든 될 수 있습니다.

아래는 지원되는 모든 서브셋 연산자의 목록입니다.

|연산자|설명|
|-|-|
|`~~`|값이 집합에 존재.|
|`!~`|값이 집합에 존재하지 않음.|

### 포함 필터(Contains Filter)

`filter` 메서드는 문자열 필드의 값이 주어진 부분 문자열을 포함하는지 확인하는 것도 지원합니다.

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

이 연산자들은 문자열 값을 가진 필드에서만 사용할 수 있습니다.

아래는 지원되는 모든 포함 연산자의 목록입니다.

|연산자|설명|
|-|-|
|`~~`|부분 문자열을 포함.|
|`!~`|부분 문자열을 포함하지 않음.|
|`=~`|접두사와 일치.|
|`!=~`|접두사와 일치하지 않음.|
|`~=`|접미사와 일치.|
|`!~=`|접미사와 일치하지 않음.|

### Group

기본적으로 쿼리에 추가된 모든 필터는 모두 일치해야 합니다. 쿼리 빌더는 하나의 필터만 일치하면 되는 필터 그룹을 생성하는 것도 지원합니다.

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

`group` 메서드는 `and` 또는 `or` 로직으로 필터를 결합하는 것을 지원합니다. 이런 그룹들은 제한 없이 중첩될 수 있습니다. 최상위 필터는 `and` 그룹에 속한 것으로 생각할 수 있습니다.

## Aggregate

쿼리 빌더는 개수를 세거나 평균을 구하는 것과 같이, 값 집합에 대한 계산을 수행하는 여러 메서드를 지원합니다.

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

`count`를 제외한 모든 집계 메서드는 필드에 대한 키 경로를 전달해야 합니다.

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

아래는 사용 가능한 모든 집계 메서드의 목록입니다.

|집계|설명|
|-|-|
|`count`|결과의 개수.|
|`sum`|결과 값들의 합.|
|`average`|결과 값들의 평균.|
|`min`|결과 값들 중 최솟값.|
|`max`|결과 값들 중 최댓값.|

`count`를 제외한 모든 집계 메서드는 필드의 값 타입을 결과로 반환합니다. `count`는 항상 정수를 반환합니다.

## Chunk

쿼리 빌더는 결과 집합을 여러 개의 청크로 나누어 반환하는 것을 지원합니다. 이는 대규모 데이터베이스 읽기를 처리할 때 메모리 사용량을 제어하는 데 도움이 됩니다.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

전달된 클로저는 전체 결과 개수에 따라 0번 이상 호출됩니다. 반환되는 각 항목은 모델 또는 데이터베이스 항목을 디코딩하는 중 발생한 에러를 담고 있는 `Result`입니다.

## Field

기본적으로, 쿼리는 모델의 모든 필드를 데이터베이스에서 읽어옵니다. `field` 메서드를 사용하면 모델 필드의 일부만 선택하도록 선택할 수 있습니다.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

쿼리에서 선택되지 않은 모델 필드는 초기화되지 않은 상태가 됩니다. 초기화되지 않은 필드에 직접 접근하려고 하면 치명적인 오류(fatal error)가 발생합니다. 모델 필드 값이 설정되어 있는지 확인하려면 `value` 프로퍼티를 사용하세요.

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

쿼리 빌더의 `unique` 메서드는 중복 없이 고유한 결과만 반환하도록 합니다.

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

`unique`는 특히 `all`로 단일 필드를 가져올 때 유용합니다. 그러나 [`field`](#field) 메서드를 사용해서 여러 필드를 선택할 수도 있습니다. 모델 식별자는 항상 고유하므로, `unique`를 사용할 때는 식별자를 선택하지 않는 것이 좋습니다.

## Range

쿼리 빌더의 `range` 메서드를 사용하면 Swift 범위(range)를 사용해서 결과의 일부를 선택할 수 있습니다.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

범위 값은 0부터 시작하는 부호 없는 정수(unsigned integer)입니다. [Swift 범위](https://developer.apple.com/documentation/swift/range)에 대해 더 자세히 알아보세요.

```swift
// Skip the first 2 results.
.range(2...)
```

## Join

쿼리 빌더의 `join` 메서드를 사용하면 다른 모델의 필드를 결과 집합에 포함시킬 수 있습니다. 하나의 쿼리에 둘 이상의 모델을 조인할 수 있습니다.

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

`on` 매개변수는 두 필드 사이의 동등 표현식을 받습니다. 두 필드 중 하나는 현재 결과 집합에 이미 존재해야 합니다. 다른 필드는 조인 대상 모델에 존재해야 합니다. 이 필드들은 값 타입이 같아야 합니다.

`filter`와 `sort` 같은 대부분의 쿼리 빌더 메서드는 조인된 모델을 지원합니다. 어떤 메서드가 조인된 모델을 지원한다면, 첫 번째 매개변수로 조인된 모델 타입을 받습니다.

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

조인을 사용하는 쿼리는 여전히 기본 모델의 배열을 반환합니다. 조인된 모델에 접근하려면 `joined` 메서드를 사용하세요.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### 모델 별칭(Model Alias)

모델 별칭을 사용하면 같은 모델을 쿼리에 여러 번 조인할 수 있습니다. 모델 별칭을 선언하려면, `ModelAlias`를 준수하는 타입을 하나 이상 만드세요.

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

이 타입들은 `model` 프로퍼티를 통해 별칭이 지정되는 모델을 참조합니다. 생성한 후에는, 쿼리 빌더에서 일반 모델처럼 모델 별칭을 사용할 수 있습니다.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

모든 모델 필드는 `@dynamicMemberLookup`을 통해 모델 별칭 타입에서 접근할 수 있습니다.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

쿼리 빌더는 `update` 메서드를 사용해서 한 번에 둘 이상의 모델을 업데이트하는 것을 지원합니다.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update`는 `set`, `filter`, `range` 메서드를 지원합니다.

## Delete

쿼리 빌더는 `delete` 메서드를 사용해서 한 번에 둘 이상의 모델을 삭제하는 것을 지원합니다.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete`는 `filter` 메서드를 지원합니다.

## Paginate

Fluent의 쿼리 API는 `paginate` 메서드를 사용한 자동 결과 페이지네이션을 지원합니다.

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

`paginate(for:)` 메서드는 요청 URI에서 사용 가능한 `page`와 `per` 매개변수를 사용해서 원하는 결과 집합을 반환합니다. 현재 페이지와 전체 결과 수에 대한 메타데이터는 `metadata` 키에 포함됩니다.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

위 요청은 다음과 같은 구조의 응답을 만들어냅니다.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

페이지 번호는 `1`부터 시작합니다. 수동으로 페이지를 요청할 수도 있습니다.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

쿼리 결과는 `sort` 메서드를 사용해서 필드 값으로 정렬할 수 있습니다.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

동점(tie)이 발생할 경우를 대비해 추가적인 정렬을 폴백(fallback)으로 추가할 수 있습니다. 폴백은 쿼리 빌더에 추가된 순서대로 사용됩니다.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
