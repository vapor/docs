# 고급 (Advanced)

Fluent는 여러분이 사용하는 데이터베이스를 다루기 위한 일반적이고 데이터베이스에 종속되지 않는 API를 만들고자 합니다. 이를 통해 어떤 데이터베이스 드라이버를 사용하든 상관없이 Fluent를 더 쉽게 배울 수 있습니다. 또한 이러한 일반화된 API를 만드는 것은 Swift 안에서 데이터베이스를 다루는 작업을 더욱 자연스럽게 느껴지도록 해줍니다.

하지만 아직 Fluent를 통해 지원되지 않는, 사용 중인 데이터베이스 드라이버의 기능을 사용해야 할 때도 있습니다. 이 가이드는 특정 데이터베이스에서만 동작하는 Fluent의 고급 패턴과 API를 다룹니다.

## SQL

Fluent의 모든 SQL 데이터베이스 드라이버는 [SQLKit](https://github.com/vapor/sql-kit) 위에 구축되어 있습니다. 이 일반적인 SQL 구현체는 `FluentSQL` 모듈로 Fluent와 함께 제공됩니다.

### SQL Database

모든 Fluent `Database`는 `SQLDatabase`로 캐스팅될 수 있습니다. 여기에는 `req.db`, `app.db`, `Migration`에 전달되는 `database` 등이 포함됩니다.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

이 캐스팅은 하위의 데이터베이스 드라이버가 SQL 데이터베이스인 경우에만 동작합니다. `SQLDatabase`의 메서드에 대해 더 알아보려면 [SQLKit의 README](https://github.com/vapor/sql-kit)를 참고하세요.

### 특정 SQL 데이터베이스

드라이버를 임포트하여 특정 SQL 데이터베이스로도 캐스팅할 수 있습니다.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

이 문서 작성 시점 기준으로, 다음과 같은 SQL 드라이버가 지원됩니다.

|데이터베이스|드라이버|라이브러리|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

데이터베이스별 API에 대한 더 자세한 정보는 해당 라이브러리의 README를 참고하세요.

### SQL Custom

Fluent의 거의 모든 쿼리 및 스키마 타입은 `.custom` 케이스를 지원합니다. 이를 통해 아직 Fluent가 지원하지 않는 데이터베이스 기능을 활용할 수 있습니다.

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE supported.
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE not supported.
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

SQL 데이터베이스는 모든 `.custom` 케이스에서 `String`과 `SQLExpression`을 모두 지원합니다. `FluentSQL` 모듈은 일반적인 사용 사례를 위한 편의 메서드를 제공합니다.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // The underlying database driver is SQL.
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // The underlying database driver is _not_ SQL.
}
```

다음은 스키마 빌더와 함께 `.sql(raw:)` 편의 메서드를 통해 `.custom`을 사용하는 예시입니다.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // The underlying database driver is MySQL.
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // The underlying database driver is _not_ MySQL.
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB는 [Fluent](../fluent/overview.md)와 [MongoKitten](https://github.com/OpenKitten/MongoKitten/) 드라이버 간의 통합입니다. Swift의 강력한 타입 시스템과 Fluent의 데이터베이스 독립적인 인터페이스를 MongoDB를 사용해 활용합니다.

MongoDB에서 가장 일반적으로 사용되는 식별자는 ObjectId입니다. `@ID(custom: .id)`를 사용해 프로젝트에서 이를 사용할 수 있습니다.
동일한 모델을 SQL과 함께 사용해야 한다면, `ObjectId`를 사용하지 마세요. 대신 `UUID`를 사용하세요.

```swift
final class User: Model {
    // Name of the table or collection.
    static let schema = "users"

    // Unique identifier for this User.
    // In this case, ObjectId is used
    // Fluent recommends using UUID by default, however ObjectId is also supported
    @ID(custom: .id)
    var id: ObjectId?

    // The User's email address
    @Field(key: "email")
    var email: String

    // The User's password stores as a BCrypt hash
    @Field(key: "password")
    var passwordHash: String

    // Creates a new, empty User instance, for use by Fluent
    init() { }

    // Creates a new User with all properties set.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### 데이터 모델링

MongoDB에서 모델은 다른 Fluent 환경에서와 동일한 방식으로 정의됩니다. SQL 데이터베이스와 MongoDB의 주요 차이점은 관계(relationship)와 구조(architecture)에 있습니다.

SQL 환경에서는 두 엔티티 간의 관계를 위해 조인 테이블을 만드는 것이 매우 일반적입니다. 하지만 MongoDB에서는 배열을 사용해 관련된 식별자를 저장할 수 있습니다. MongoDB의 설계 특성상, 중첩된 데이터 구조로 모델을 설계하는 것이 더 효율적이고 실용적입니다.

### 유연한 데이터

MongoDB에서는 유연한 데이터를 추가할 수 있지만, 이 코드는 SQL 환경에서는 동작하지 않습니다.
그룹화된 임의의 데이터 저장소를 만들려면 `Document`를 사용할 수 있습니다.

```swift
@Field(key: "document")
var document: Document
```

Fluent는 이러한 값에 대해 엄격하게 타입이 지정된 쿼리를 지원할 수 없습니다. 쿼리를 위해 점(dot) 표기법으로 표현된 키 경로를 쿼리에 사용할 수 있습니다.
이는 중첩된 값에 접근하기 위해 MongoDB에서 허용되는 방식입니다.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### 정규식 사용

`.custom()` 케이스를 사용하고 정규식을 전달하여 MongoDB를 쿼리할 수 있습니다. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/)는 Perl 호환 정규식을 허용합니다.

예를 들어, `name` 필드에서 대소문자를 구분하지 않는 문자를 쿼리할 수 있습니다.

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

이는 'e'와 'E'를 포함하는 planet을 반환합니다. MongoDB가 허용하는 다른 복잡한 정규식도 만들 수 있습니다.

### Raw 접근

원시 `MongoDatabase` 인스턴스에 접근하려면, 다음과 같이 데이터베이스 인스턴스를 `MongoDatabaseRepresentable`로 캐스팅하세요.

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

여기서부터 모든 MongoKitten API를 사용할 수 있습니다.
