# Fluent

Fluent는 Swift를 위한 [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) 프레임워크입니다. Swift의 강력한 타입 시스템을 활용하여 데이터베이스를 위한 사용하기 쉬운 인터페이스를 제공합니다. Fluent를 사용하는 것은 데이터베이스의 데이터 구조를 나타내는 모델 타입을 만드는 것을 중심으로 이루어집니다. 이러한 모델은 원시 쿼리를 작성하는 대신 생성, 조회, 수정, 삭제 작업을 수행하는 데 사용됩니다.

## 설정

`vapor new`를 사용해 프로젝트를 생성할 때, Fluent를 포함할지 묻는 질문에 "yes"라고 답하고 사용할 데이터베이스 드라이버를 선택하세요. 그러면 새 프로젝트에 의존성과 예제 설정 코드가 자동으로 추가됩니다.

### 기존 프로젝트

Fluent를 추가하고 싶은 기존 프로젝트가 있다면, [패키지](../getting-started/spm.md)에 두 개의 의존성을 추가해야 합니다.

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- 원하는 Fluent 드라이버 하나(또는 그 이상)

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

패키지가 의존성으로 추가되면, `configure.swift`에서 `app.databases`를 사용해 데이터베이스를 설정할 수 있습니다.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

아래의 각 Fluent 드라이버는 설정을 위한 더 구체적인 안내를 제공합니다.

### 드라이버

Fluent는 현재 네 개의 공식 지원 드라이버를 가지고 있습니다. GitHub에서 [`fluent-driver`](https://github.com/topics/fluent-driver) 태그를 검색하면 공식 및 서드파티 Fluent 데이터베이스 드라이버의 전체 목록을 볼 수 있습니다.

#### PostgreSQL

PostgreSQL은 오픈 소스이며 표준을 준수하는 SQL 데이터베이스입니다. 대부분의 클라우드 호스팅 제공업체에서 쉽게 설정할 수 있습니다. 이는 Fluent가 **권장**하는 데이터베이스 드라이버입니다.

PostgreSQL을 사용하려면, 패키지에 다음 의존성을 추가하세요.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

의존성이 추가되면, `configure.swift`에서 `app.databases.use`를 사용해 Fluent에 데이터베이스의 자격 증명을 설정하세요.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

데이터베이스 연결 문자열로부터 자격 증명을 파싱할 수도 있습니다.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite는 오픈 소스이며 내장(embedded)형 SQL 데이터베이스입니다. 단순한 특성 덕분에 프로토타이핑과 테스트에 아주 적합합니다.

SQLite를 사용하려면, 패키지에 다음 의존성을 추가하세요.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

의존성이 추가되면, `configure.swift`에서 `app.databases.use`를 사용해 Fluent에 데이터베이스를 설정하세요.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

SQLite가 데이터베이스를 메모리에 임시로 저장하도록 설정할 수도 있습니다.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

인메모리 데이터베이스를 사용하는 경우, `--auto-migrate` 플래그를 사용하거나 마이그레이션을 추가한 뒤 `app.autoMigrate()`를 실행하여 Fluent가 자동으로 마이그레이션하도록 설정해야 합니다.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip
    SQLite 설정은 생성되는 모든 연결에서 자동으로 외래 키 제약 조건(foreign key constraints)을 활성화하지만, 데이터베이스 자체의 외래 키 설정을 변경하지는 않습니다. 데이터베이스에서 직접 레코드를 삭제하면 외래 키 제약 조건과 트리거를 위반할 수 있습니다.

#### MySQL

MySQL은 인기 있는 오픈 소스 SQL 데이터베이스입니다. 많은 클라우드 호스팅 제공업체에서 사용할 수 있습니다. 이 드라이버는 MariaDB도 지원합니다.

MySQL을 사용하려면, 패키지에 다음 의존성을 추가하세요.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

의존성이 추가되면, `configure.swift`에서 `app.databases.use`를 사용해 Fluent에 데이터베이스의 자격 증명을 설정하세요.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

데이터베이스 연결 문자열로부터 자격 증명을 파싱할 수도 있습니다.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

SSL 인증서 없이 로컬 연결을 설정하려면, 인증서 검증을 비활성화해야 합니다. 예를 들어 Docker에서 실행 중인 MySQL 8 데이터베이스에 연결할 때 이 작업이 필요할 수 있습니다.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none
    
app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning
    프로덕션 환경에서는 인증서 검증을 비활성화하지 마세요. 검증에 사용할 인증서를 `TLSConfiguration`에 제공해야 합니다.

#### MongoDB

MongoDB는 프로그래머를 위해 설계된 인기 있는 스키마리스(schemaless) NoSQL 데이터베이스입니다. 이 드라이버는 모든 클라우드 호스팅 제공업체와 3.4 버전 이상의 자체 호스팅 설치 환경을 지원합니다.

!!! note
    이 드라이버는 커뮤니티에서 만들고 유지 관리하는 MongoDB 클라이언트인 [MongoKitten](https://github.com/OpenKitten/MongoKitten)을 기반으로 합니다. MongoDB는 공식 클라이언트인 [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver)와 이를 위한 Vapor 통합 패키지 [mongodb-vapor](https://github.com/mongodb/mongodb-vapor)를 함께 관리하고 있습니다.

MongoDB를 사용하려면, 패키지에 다음 의존성을 추가하세요.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

의존성이 추가되면, `configure.swift`에서 `app.databases.use`를 사용해 Fluent에 데이터베이스의 자격 증명을 설정하세요.

연결하려면, 표준 MongoDB [연결 URI 형식](https://docs.mongodb.com/docs/manual/reference/connection-string/)의 연결 문자열을 전달하세요.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## 모델

모델은 테이블이나 컬렉션처럼 데이터베이스의 고정된 데이터 구조를 나타냅니다. 모델은 코드화 가능한(codable) 값을 저장하는 하나 이상의 필드를 가집니다. 모든 모델은 고유 식별자(unique identifier)도 가지고 있습니다. 프로퍼티 래퍼(property wrapper)는 식별자와 필드를 나타내는 데 사용되며, 뒤에서 다룰 좀 더 복잡한 매핑을 나타내는 데도 사용됩니다. 은하(galaxy)를 나타내는 다음 모델을 살펴봅시다.

```swift
final class Galaxy: Model {
    // Name of the table or collection.
    static let schema = "galaxies"

    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?

    // The Galaxy's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Galaxy.
    init() { }

    // Creates a new Galaxy with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

새 모델을 만들려면, `Model`을 준수하는 새 클래스를 만드세요.

!!! tip
    성능을 향상시키고 준수 요구 사항을 단순화하기 위해 모델 클래스를 `final`로 표시하는 것이 권장됩니다.

`Model` 프로토콜의 첫 번째 요구 사항은 정적(static) 문자열 `schema`입니다.

```swift
static let schema = "galaxies"
```

이 프로퍼티는 모델이 어떤 테이블이나 컬렉션에 대응하는지 Fluent에 알려줍니다. 이는 데이터베이스에 이미 존재하는 테이블일 수도 있고, [마이그레이션](#migrations)으로 생성할 테이블일 수도 있습니다. 스키마는 보통 `snake_case`이고 복수형입니다.

### 식별자

다음 요구 사항은 `id`라는 이름의 식별자 필드입니다.

```swift
@ID(key: .id)
var id: UUID?
```

이 필드는 `@ID` 프로퍼티 래퍼를 사용해야 합니다. Fluent는 모든 Fluent 드라이버와 호환되므로 `UUID`와 특별한 `.id` 필드 키를 사용할 것을 권장합니다.

커스텀 ID 키나 타입을 사용하고 싶다면, [`@ID(custom:)`](model.md#custom-identifier) 오버로드를 사용하세요.

### 필드

식별자를 추가한 후에는, 원하는 만큼 필드를 추가하여 추가 정보를 저장할 수 있습니다. 이 예제에서는 은하의 이름만이 추가 필드입니다.

```swift
@Field(key: "name")
var name: String
```

단순한 필드에는 `@Field` 프로퍼티 래퍼가 사용됩니다. `@ID`와 마찬가지로, `key` 매개변수는 데이터베이스에서의 필드 이름을 지정합니다. 이는 데이터베이스 필드 명명 규칙이 Swift에서와 다른 경우, 예를 들어 `camelCase` 대신 `snake_case`를 사용하는 경우에 특히 유용합니다.

다음으로, 모든 모델에는 빈 init이 필요합니다. 이는 Fluent가 모델의 새 인스턴스를 생성할 수 있도록 해줍니다.

```swift
init() { }
```

마지막으로, 모델의 모든 프로퍼티를 설정하는 편의 init을 추가할 수 있습니다.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

편의 init을 사용하는 것은 모델에 새 프로퍼티를 추가할 때 특히 유용한데, init 메서드가 바뀌면 컴파일 타임 오류를 얻을 수 있기 때문입니다.

## 마이그레이션

SQL 데이터베이스처럼 사전에 정의된 스키마를 사용하는 데이터베이스라면, 모델을 위해 데이터베이스를 준비하는 마이그레이션이 필요합니다. 마이그레이션은 데이터베이스에 시드(seed) 데이터를 채우는 데도 유용합니다. 마이그레이션을 만들려면, `Migration` 또는 `AsyncMigration` 프로토콜을 준수하는 새 타입을 정의하세요. 앞서 정의한 `Galaxy` 모델에 대한 다음 마이그레이션을 살펴봅시다.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

`prepare` 메서드는 `Galaxy` 모델을 저장하기 위해 데이터베이스를 준비하는 데 사용됩니다.

### 스키마

이 메서드에서는 `database.schema(_:)`를 사용해 새 `SchemaBuilder`를 생성합니다. 그런 다음 `create()`를 호출해 스키마를 생성하기 전에 하나 이상의 `field`를 빌더에 추가합니다.

빌더에 추가되는 각 필드는 이름, 타입, 그리고 선택적인 제약 조건을 가집니다.

```swift
field(<name>, <type>, <optional constraints>)
```

Fluent가 권장하는 기본값을 사용하여 `@ID` 프로퍼티를 추가하기 위한 편의 메서드 `id()`가 있습니다.

마이그레이션을 되돌리면 prepare 메서드에서 이루어진 모든 변경 사항이 취소됩니다. 이 경우에는 Galaxy의 스키마를 삭제하는 것을 의미합니다.

마이그레이션을 정의했다면, `configure.swift`의 `app.migrations`에 추가하여 Fluent에 알려주어야 합니다.

```swift
app.migrations.add(CreateGalaxy())
```

### 마이그레이션 실행

마이그레이션을 실행하려면, 커맨드 라인에서 `swift run App migrate`를 호출하거나 Xcode의 App scheme에 인자로 `migrate`를 추가하세요.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## 쿼리

이제 모델을 성공적으로 만들고 데이터베이스를 마이그레이션했으니, 첫 번째 쿼리를 만들 준비가 되었습니다.

### 전체 조회

데이터베이스에 있는 모든 은하의 배열을 반환하는 다음 라우트를 살펴봅시다.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

라우트 클로저에서 Galaxy를 직접 반환하려면, `Content`에 대한 준수성을 추가하세요.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query`는 이 모델을 위한 새 쿼리 빌더를 생성하는 데 사용됩니다. `req.db`는 애플리케이션의 기본 데이터베이스에 대한 참조입니다. 마지막으로, `all()`은 데이터베이스에 저장된 모든 모델을 반환합니다.

프로젝트를 컴파일하고 실행한 뒤 `GET /galaxies`를 요청하면, 빈 배열이 반환되는 것을 볼 수 있습니다. 새 은하를 생성하는 라우트를 추가해 봅시다.

### 생성

RESTful 컨벤션에 따라, 새 은하를 생성하기 위해 `POST /galaxies` 엔드포인트를 사용하세요. 모델은 코드화 가능(codable)하므로, 요청 본문으로부터 은하를 직접 디코딩할 수 있습니다.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso
    요청 본문을 디코딩하는 방법에 대한 자세한 내용은 [Content &rarr; 개요](../basics/content.md)를 참고하세요.

모델의 인스턴스를 갖게 되면, `create(on:)`을 호출해 모델을 데이터베이스에 저장합니다. 이는 저장이 완료되었음을 알리는 `EventLoopFuture<Void>`를 반환합니다. 저장이 완료되면, `map`을 사용해 새로 생성된 모델을 반환합니다.

`async`/`await`를 사용하고 있다면, 다음과 같이 코드를 작성할 수 있습니다.

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

이 경우, async 버전은 아무것도 반환하지 않지만, 저장이 완료되면 반환됩니다.

프로젝트를 빌드하고 실행한 뒤 다음 요청을 보내세요.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

응답으로 식별자가 포함된 생성된 모델을 받아야 합니다.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

이제 다시 `GET /galaxies`를 쿼리하면, 배열에 새로 생성된 은하가 반환되는 것을 볼 수 있습니다.


## 관계(Relations)

별(star) 없는 은하라니! `Galaxy`와 새로운 `Star` 모델 사이에 일대다(one-to-many) 관계를 추가하여 Fluent의 강력한 관계형 기능을 간단히 살펴봅시다.

```swift
final class Star: Model, Content {
    // Name of the table or collection.
    static let schema = "stars"

    // Unique identifier for this Star.
    @ID(key: .id)
    var id: UUID?

    // The Star's name.
    @Field(key: "name")
    var name: String

    // Reference to the Galaxy this Star is in.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Creates a new, empty Star.
    init() { }

    // Creates a new Star with all properties set.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

새 `Star` 모델은 새로운 필드 타입 `@Parent`를 제외하고는 `Galaxy`와 매우 유사합니다.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

parent 프로퍼티는 다른 모델의 식별자를 저장하는 필드입니다. 참조를 가지고 있는 모델을 "자식(child)"이라고 하고, 참조되는 모델을 "부모(parent)"라고 합니다. 이러한 유형의 관계는 "일대다(one-to-many)"라고도 알려져 있습니다. 프로퍼티의 `key` 매개변수는 데이터베이스에서 부모의 키를 저장하는 데 사용할 필드 이름을 지정합니다.

init 메서드에서, `$galaxy`를 사용해 parent 식별자를 설정합니다.

```swift
self.$galaxy.id = galaxyID
```

parent 프로퍼티 이름 앞에 `$`를 붙이면, 내부의 프로퍼티 래퍼에 접근할 수 있습니다. 이는 실제 식별자 값을 저장하는 내부의 `@Field`에 접근하는 데 필요합니다.

!!! seealso
    프로퍼티 래퍼에 대한 자세한 내용은 Swift Evolution 제안서를 확인하세요: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

다음으로, `Star`를 다루기 위해 데이터베이스를 준비하는 마이그레이션을 만드세요.


```swift
struct CreateStar: AsyncMigration {
    // Prepares the database for storing Star models.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

이는 부모 은하의 식별자를 저장하기 위한 추가 필드를 제외하면 galaxy의 마이그레이션과 대부분 동일합니다.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

이 필드는 필드의 값이 "galaxies" 스키마의 "id" 필드를 참조한다는 것을 데이터베이스에 알려주는 선택적 제약 조건을 지정합니다. 이는 외래 키(foreign key)라고도 하며, 데이터 무결성을 보장하는 데 도움이 됩니다.

마이그레이션이 생성되면, `CreateGalaxy` 마이그레이션 다음에 `app.migrations`에 추가하세요.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

마이그레이션은 순서대로 실행되고 `CreateStar`가 galaxies 스키마를 참조하므로, 순서가 중요합니다. 마지막으로, 데이터베이스를 준비하기 위해 [마이그레이션을 실행하세요](#migrate).

새 별을 생성하는 라우트를 추가하세요.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

다음 HTTP 요청을 사용해 이전에 생성한 은하를 참조하는 새 별을 생성하세요.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

고유 식별자와 함께 새로 생성된 별이 반환되는 것을 볼 수 있습니다.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

이제 `GET /galaxies` 라우트에서 은하의 별들을 자동으로 반환하기 위해 Fluent의 즉시 로딩(eager-loading) 기능을 어떻게 활용할 수 있는지 살펴봅시다. `Galaxy` 모델에 다음 프로퍼티를 추가하세요.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

`@Children` 프로퍼티 래퍼는 `@Parent`의 반대입니다. `for` 인자로 자식의 `@Parent` 필드에 대한 key-path를 받습니다. 값은 배열인데, 자식 모델이 0개 이상 존재할 수 있기 때문입니다. 이 관계에 필요한 모든 정보가 `Star`에 저장되므로, galaxy의 마이그레이션은 변경할 필요가 없습니다.

### 즉시 로딩(Eager Load)

이제 관계가 완성되었으니, 쿼리 빌더의 `with` 메서드를 사용해 galaxy-star 관계를 자동으로 가져오고 직렬화할 수 있습니다.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

결과로 나오는 모든 모델에서 이 관계를 자동으로 로드하도록 Fluent에 알리기 위해, `@Children` 관계에 대한 key-path가 `with`에 전달됩니다. 빌드하고 실행한 뒤 `GET /galaxies`로 또 다른 요청을 보내세요. 이제 응답에 별들이 자동으로 포함된 것을 볼 수 있습니다.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## 쿼리 로깅

Fluent 드라이버는 생성된 SQL을 디버그 로그 레벨로 기록합니다. FluentPostgreSQL과 같은 일부 드라이버는 데이터베이스를 설정할 때 이를 설정할 수 있게 해줍니다.

로그 레벨을 설정하려면, **configure.swift**(또는 애플리케이션을 설정하는 곳)에 다음을 추가하세요.

```swift
app.logger.logLevel = .debug
```

이는 로그 레벨을 debug로 설정합니다. 다음에 앱을 빌드하고 실행하면, Fluent가 생성한 SQL 구문이 콘솔에 기록됩니다.

## 다음 단계

첫 번째 모델과 마이그레이션을 만들고 기본적인 생성 및 조회 작업을 수행한 것을 축하합니다. 이러한 기능들에 대한 더 자세한 정보는, Fluent 가이드의 해당 섹션을 확인하세요.
