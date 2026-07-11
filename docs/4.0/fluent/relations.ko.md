# 관계

Fluent의 [모델 API](model.md)를 사용하면 관계를 통해 모델 간의 참조를 생성하고 유지할 수 있습니다. 세 가지 유형의 관계가 지원됩니다:

- [Parent](#parent) / [Child](#optional-child) (일대일)
- [Parent](#parent) / [Children](#children) (일대다)
- [Siblings](#siblings) (다대다)

## Parent

`@Parent` 관계는 다른 모델의 `@ID` 프로퍼티에 대한 참조를 저장합니다.

```swift
final class Planet: Model {
    // Example of a parent relation.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent`는 관계를 설정하고 업데이트하는 데 사용되는 `id`라는 이름의 `@Field`를 포함합니다.

```swift
// Set parent relation id
earth.$star.id = sun.id
```

예를 들어, `Planet`의 초기화 메서드는 다음과 같습니다:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

`key` 매개변수는 부모의 식별자를 저장하는 데 사용할 필드 키를 정의합니다. `Star`가 `UUID` 식별자를 가지고 있다고 가정하면, 이 `@Parent` 관계는 다음 [필드 정의](schema.md#field)와 호환됩니다.

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

[`.references`](schema.md#field-constraint) 제약 조건은 선택 사항이라는 점에 유의하세요. 자세한 내용은 [스키마](schema.md)를 참고하세요.

### Optional Parent

`@OptionalParent` 관계는 다른 모델의 `@ID` 프로퍼티에 대한 옵셔널 참조를 저장합니다. `@Parent`와 비슷하게 동작하지만, 관계가 `nil`이 될 수 있다는 점이 다릅니다.

```swift
final class Planet: Model {
    // Example of an optional parent relation.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

필드 정의는 `.required` 제약 조건을 생략해야 한다는 점을 제외하면 `@Parent`의 것과 유사합니다.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Parent 인코딩과 디코딩

`@Parent` 관계를 다룰 때 주의해야 할 점 중 하나는 이를 주고받는 방식입니다. 예를 들어, JSON에서 `Planet` 모델의 `@Parent`는 다음과 같은 형태일 수 있습니다:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

`star` 프로퍼티가 예상했던 ID가 아니라 객체로 되어 있다는 점에 주목하세요. 모델을 HTTP 본문으로 보낼 때는 디코딩이 동작하도록 이 형식과 일치해야 합니다. 이러한 이유로, 네트워크를 통해 모델을 전송할 때는 이를 표현하기 위한 DTO를 사용하는 것을 강력히 권장합니다. 예를 들면:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

그런 다음 DTO를 디코딩하고 이를 모델로 변환할 수 있습니다:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

모델을 클라이언트에 반환할 때도 마찬가지입니다. 클라이언트가 중첩된 구조를 처리할 수 있어야 하거나, 반환하기 전에 모델을 DTO로 변환해야 합니다. DTO에 대한 자세한 내용은 [모델 문서](model.md#data-transfer-object)를 참고하세요.

## Optional Child

`@OptionalChild` 프로퍼티는 두 모델 사이에 일대일 관계를 생성합니다. 루트 모델에는 어떠한 값도 저장하지 않습니다.

```swift
final class Planet: Model {
    // Example of an optional child relation.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

`for` 매개변수는 루트 모델을 참조하는 `@Parent` 또는 `@OptionalParent` 관계에 대한 키 경로를 받습니다.

`create` 메서드를 사용해서 이 관계에 새로운 모델을 추가할 수 있습니다.

```swift
// Example of adding a new model to a relation.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

이렇게 하면 자식 모델에 부모 id가 자동으로 설정됩니다.

이 관계는 어떠한 값도 저장하지 않으므로, 루트 모델에 대한 데이터베이스 스키마 항목이 필요하지 않습니다.

관계의 일대일 특성은 부모 모델을 참조하는 컬럼에 `.unique` 제약 조건을 사용해서 자식 모델의 스키마에서 강제되어야 합니다.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Example of unique constraint
    .unique(on: "planet_id")
    .create()
```
!!! warning
    클라이언트 스키마에서 부모 ID 필드에 대한 유니크 제약 조건을 생략하면 예측할 수 없는 결과로 이어질 수 있습니다.
    유일성 제약 조건이 없다면, 자식 테이블에는 특정 부모에 대해 두 개 이상의 자식 행이 존재하게 될 수 있습니다. 이 경우 `@OptionalChild` 프로퍼티는 여전히 한 번에 하나의 자식에만 접근할 수 있으며, 어떤 자식이 로드되는지 제어할 방법이 없습니다. 특정 부모에 대해 여러 자식 행을 저장해야 할 수도 있다면, 대신 `@Children`을 사용하세요.

## Children

`@Children` 프로퍼티는 두 모델 사이에 일대다 관계를 생성합니다. 루트 모델에는 어떠한 값도 저장하지 않습니다.

```swift
final class Star: Model {
    // Example of a children relation.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

`for` 매개변수는 루트 모델을 참조하는 `@Parent` 또는 `@OptionalParent` 관계에 대한 키 경로를 받습니다. 이 경우, 이전 [예제](#parent)의 `@Parent` 관계를 참조하고 있습니다.

`create` 메서드를 사용해서 이 관계에 새로운 모델을 추가할 수 있습니다.

```swift
// Example of adding a new model to a relation.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

이렇게 하면 자식 모델에 부모 id가 자동으로 설정됩니다.

이 관계는 어떠한 값도 저장하지 않으므로, 데이터베이스 스키마 항목이 필요하지 않습니다.

## Siblings

`@Siblings` 프로퍼티는 두 모델 사이에 다대다 관계를 생성합니다. 이는 피벗(pivot)이라고 하는 세 번째 모델을 통해 이루어집니다.

`Planet`과 `Tag` 사이의 다대다 관계 예제를 살펴보겠습니다.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Example of a pivot model.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

관계를 맺을 각 모델에 대해 하나씩, 최소 두 개의 `@Parent` 관계를 포함하는 모델이라면 어떤 모델이든 피벗으로 사용할 수 있습니다. 이 모델은 ID와 같은 추가 프로퍼티를 포함할 수 있으며, 심지어 다른 `@Parent` 관계를 포함할 수도 있습니다.

피벗 모델에 [유니크](schema.md#unique) 제약 조건을 추가하면 중복된 항목을 방지하는 데 도움이 됩니다. 자세한 내용은 [스키마](schema.md)를 참고하세요.

```swift
// Disallows duplicate relations.
.unique(on: "planet_id", "tag_id")
```

피벗이 생성되면, `@Siblings` 프로퍼티를 사용해서 관계를 생성하세요.

```swift
final class Planet: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

`@Siblings` 프로퍼티는 세 개의 매개변수를 필요로 합니다:

- `through`: 피벗 모델의 타입.
- `from`: 루트 모델을 참조하는 부모 관계로 향하는, 피벗으로부터의 키 경로.
- `to`: 관련 모델을 참조하는 부모 관계로 향하는, 피벗으로부터의 키 경로.

관련 모델에 있는 반대 방향의 `@Siblings` 프로퍼티가 관계를 완성합니다.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

`@Siblings` 프로퍼티는 관계에서 모델을 추가하거나 제거하기 위한 메서드를 가지고 있습니다.

`attach()` 메서드를 사용해서 하나의 모델 또는 모델 배열을 관계에 추가하세요. 피벗 모델은 필요에 따라 자동으로 생성되고 저장됩니다. 생성되는 각 피벗의 추가 프로퍼티를 채우기 위해 콜백 클로저를 지정할 수 있습니다:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Adds the model to the relation.
try await earth.$tags.attach(inhabited, on: database)
// Populate pivot attributes when establishing the relation.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Add multiple models with attributes to the relation.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

단일 모델을 연결(attach)할 때, `method` 매개변수를 사용해서 저장하기 전에 관계를 확인할지 여부를 선택할 수 있습니다.

```swift
// Only attaches if the relation doesn't already exist.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

`detach` 메서드를 사용해서 관계에서 모델을 제거하세요. 이렇게 하면 해당하는 피벗 모델이 삭제됩니다.

```swift
// Removes the model from the relation.
try await earth.$tags.detach(inhabited, on: database)
```

`isAttached` 메서드를 사용해서 모델이 연결되어 있는지 여부를 확인할 수 있습니다.

```swift
// Checks if the models are related.
earth.$tags.isAttached(to: inhabited)
```

## Get

`get(on:)` 메서드를 사용해서 관계의 값을 가져오세요.

```swift
// Fetches all of the sun's planets.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Or

let planets = try await sun.$planets.get(on: database)
print(planets)
```

이미 로드된 관계를 데이터베이스에서 다시 가져올지 여부를 선택하려면 `reload` 매개변수를 사용하세요.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

관계에서 `query(on:)` 메서드를 사용해서 관련 모델에 대한 쿼리 빌더를 생성하세요.

```swift
// Fetch all of the sun's planets that have a naming starting with M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

자세한 내용은 [쿼리](query.md)를 참고하세요.

## 즉시 로딩(Eager Loading)

Fluent의 쿼리 빌더를 사용하면 모델을 데이터베이스에서 가져올 때 모델의 관계를 미리 로드할 수 있습니다. 이를 즉시 로딩(eager loading)이라고 하며, 먼저 [`get`](#get)을 호출하지 않고도 관계에 동기적으로 접근할 수 있게 해줍니다.

관계를 즉시 로딩하려면, 쿼리 빌더의 `with` 메서드에 관계에 대한 키 경로를 전달하세요.

```swift
// Example of eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` is accessible synchronously here 
        // since it has been eager loaded.
        print(planet.star.name)
    }
}

// Or

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` is accessible synchronously here 
    // since it has been eager loaded.
    print(planet.star.name)
}
```

위 예제에서는 `star`라는 이름의 [`@Parent`](#parent) 관계에 대한 키 경로가 `with`에 전달됩니다. 이렇게 하면 쿼리 빌더는 모든 행성을 로드한 후, 관련된 모든 별을 가져오기 위한 추가 쿼리를 수행합니다. 이후 별은 `@Parent` 프로퍼티를 통해 동기적으로 접근할 수 있습니다.

즉시 로딩되는 각 관계는 반환되는 모델의 개수와 상관없이 단 하나의 추가 쿼리만 필요로 합니다. 즉시 로딩은 쿼리 빌더의 `all`과 `first` 메서드에서만 가능합니다.


### 중첩 즉시 로딩(Nested Eager Load)

쿼리 빌더의 `with` 메서드를 사용하면 쿼리 대상 모델의 관계를 즉시 로딩할 수 있습니다. 하지만 관련 모델의 관계도 즉시 로딩할 수 있습니다.

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` is accessible synchronously here 
    // since it has been eager loaded.
    print(planet.star.galaxy.name)
}
```

`with` 메서드는 두 번째 매개변수로 옵셔널 클로저를 받습니다. 이 클로저는 선택한 관계에 대한 즉시 로딩 빌더를 받습니다. 즉시 로딩을 중첩할 수 있는 깊이에는 제한이 없습니다.

## 지연 즉시 로딩(Lazy Eager Loading)

이미 부모 모델을 가져온 상태에서 해당 모델의 관계 중 하나를 로드하고 싶다면, `get(reload:on:)` 메서드를 사용할 수 있습니다. 이는 관련 모델을 데이터베이스(또는 가능하다면 캐시)에서 가져와 로컬 프로퍼티로 접근할 수 있게 해줍니다.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Or

try await planet.$star.get(on: database)
print(planet.star.name)
```

받는 데이터가 캐시에서 가져온 것이 아님을 보장하고 싶다면, `reload:` 매개변수를 사용하세요.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

관계가 로드되었는지 여부를 확인하려면, `value` 프로퍼티를 사용하세요.

```swift
if planet.$star.value != nil {
    // Relation has been loaded.
    print(planet.star.name)
} else {
    // Relation has not been loaded.
    // Attempting to access planet.star will fail.
}
```

관련 모델을 이미 변수에 가지고 있다면, 위에서 언급한 `value` 프로퍼티를 사용해서 관계를 수동으로 설정할 수 있습니다.

```swift
planet.$star.value = star
```

이렇게 하면 추가적인 데이터베이스 쿼리 없이, 마치 즉시 로딩되거나 지연 로딩된 것처럼 관련 모델이 부모에 연결됩니다.
