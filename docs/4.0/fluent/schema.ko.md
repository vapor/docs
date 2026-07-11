# 스키마

Fluent의 스키마 API를 사용하면 프로그래밍 방식으로 데이터베이스 스키마를 생성하고 업데이트할 수 있습니다. 이는 [모델](model.md)을 사용할 수 있도록 데이터베이스를 준비하기 위해 [마이그레이션](migration.md)과 함께 사용되는 경우가 많습니다.

```swift
// An example of Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

`SchemaBuilder`를 생성하려면 database의 `schema` 메서드를 사용하세요. 영향을 주고자 하는 테이블 또는 컬렉션의 이름을 전달합니다. 모델의 스키마를 편집하는 경우, 이 이름이 모델의 [`schema`](model.md#schema)와 일치하는지 확인하세요.

## 액션

스키마 API는 스키마의 생성, 업데이트, 삭제를 지원합니다. 각 액션은 API에서 사용 가능한 메서드 중 일부를 지원합니다.

### 생성

`create()`를 호출하면 데이터베이스에 새로운 테이블이나 컬렉션이 생성됩니다. 새로운 필드와 제약 조건을 정의하기 위한 모든 메서드가 지원됩니다. 업데이트나 삭제를 위한 메서드는 무시됩니다.

```swift
// An example schema creation.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

선택한 이름의 테이블이나 컬렉션이 이미 존재하는 경우, 에러가 발생합니다. 이를 무시하려면 `.ignoreExisting()`을 사용하세요.

### 업데이트

`update()`를 호출하면 데이터베이스에 있는 기존 테이블이나 컬렉션이 업데이트됩니다. 필드와 제약 조건을 생성, 업데이트, 삭제하기 위한 모든 메서드가 지원됩니다.

```swift
// An example schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### 삭제

`delete()`를 호출하면 데이터베이스에서 기존 테이블이나 컬렉션이 삭제됩니다. 추가적인 메서드는 지원되지 않습니다.

```swift
// An example schema deletion.
database.schema("planets").delete()
```

## 필드

스키마를 생성하거나 업데이트할 때 필드를 추가할 수 있습니다.

```swift
// Adds a new field
.field("name", .string, .required)
```

첫 번째 매개변수는 필드의 이름입니다. 이는 연관된 모델 프로퍼티에서 사용하는 키와 일치해야 합니다. 두 번째 매개변수는 필드의 [데이터 타입](#data-type)입니다. 마지막으로, 0개 이상의 [제약 조건](#field-constraint)을 추가할 수 있습니다.

### 데이터 타입

지원되는 필드 데이터 타입은 아래에 나열되어 있습니다.

|DataType|Swift Type|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (권장)|
|`.date`|`Date` (시간 부분 생략)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|[dictionary](#dictionary) 참고|
|`.array`|[array](#array) 참고|
|`.enum`|[enum](#enum) 참고|

### 필드 제약 조건

지원되는 필드 제약 조건은 아래에 나열되어 있습니다.

|FieldConstraint|설명|
|-|-|
|`.required`|`nil` 값을 허용하지 않습니다.|
|`.references`|이 필드의 값이 참조된 스키마에 있는 값과 일치해야 합니다. [foreign key](#foreign-key)를 참고하세요.|
|`.identifier`|기본 키를 나타냅니다. [identifier](#identifier)를 참고하세요.|
|`.sql(SQLColumnConstraintAlgorithm)`|지원되지 않는 제약 조건을 정의합니다 (예: `default`). [SQL](#sql)과 [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/)을 참고하세요.|

### Identifier

모델이 표준 `@ID` 프로퍼티를 사용하는 경우, `id()` 헬퍼를 사용하여 해당 필드를 생성할 수 있습니다. 이는 특별한 `.id` 필드 키와 `UUID` 값 타입을 사용합니다.

```swift
// Adds field for default identifier.
.id()
```

커스텀 식별자 타입의 경우, 필드를 직접 지정해야 합니다.

```swift
// Adds field for custom identifier.
.field("id", .int, .identifier(auto: true))
```

`identifier` 제약 조건은 단일 필드에만 사용할 수 있으며 기본 키를 나타냅니다. `auto` 플래그는 데이터베이스가 이 값을 자동으로 생성할지 여부를 결정합니다.

### 필드 업데이트

`updateField`를 사용하여 필드의 데이터 타입을 업데이트할 수 있습니다.

```swift
// Updates the field to `double` data type.
.updateField("age", .double)
```

고급 스키마 업데이트에 대한 더 자세한 내용은 [advanced](advanced.md#sql)를 참고하세요.

### 필드 삭제

`deleteField`를 사용하여 스키마에서 필드를 제거할 수 있습니다.

```swift
// Deletes the field "age".
.deleteField("age")
```

## 제약 조건

스키마를 생성하거나 업데이트할 때 제약 조건을 추가할 수 있습니다. [필드 제약 조건](#field-constraint)과 달리, 최상위 수준의 제약 조건은 여러 필드에 영향을 줄 수 있습니다.

### 유니크

유니크 제약 조건은 하나 이상의 필드에 중복된 값이 없어야 함을 요구합니다.

```swift
// Disallow duplicate email addresses.
.unique(on: "email")
```

여러 필드에 제약 조건이 설정된 경우, 각 필드 값의 특정 조합이 유일해야 합니다.

```swift
// Disallow users with the same full name.
.unique(on: "first_name", "last_name")
```

유니크 제약 조건을 삭제하려면 `deleteUnique`를 사용하세요.

```swift
// Removes duplicate email constraint.
.deleteUnique(on: "email")
```

### 제약 조건 이름

Fluent는 기본적으로 유일한 제약 조건 이름을 생성합니다. 하지만 커스텀 제약 조건 이름을 전달하고 싶을 수도 있습니다. `name` 매개변수를 사용하여 이를 수행할 수 있습니다.

```swift
// Disallow duplicate email addresses.
.unique(on: "email", name: "no_duplicate_emails")
```

이름이 지정된 제약 조건을 삭제하려면, `deleteConstraint(name:)`을 사용해야 합니다.

```swift
// Removes duplicate email constraint.
.deleteConstraint(name: "no_duplicate_emails")
```

## 외래 키

외래 키 제약 조건은 필드의 값이 참조된 필드에 있는 값 중 하나와 일치해야 함을 요구합니다. 이는 유효하지 않은 데이터가 저장되는 것을 방지하는 데 유용합니다. 외래 키 제약 조건은 필드 제약 조건 또는 최상위 수준의 제약 조건으로 추가할 수 있습니다.

필드에 외래 키 제약 조건을 추가하려면, `.references`를 사용하세요.

```swift
// Example of adding a field foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

위 제약 조건은 "star_id" 필드에 있는 모든 값이 Star의 "id" 필드에 있는 값 중 하나와 일치해야 함을 요구합니다.

이와 동일한 제약 조건을 `foreignKey`를 사용하여 최상위 수준의 제약 조건으로 추가할 수도 있습니다.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

필드 제약 조건과 달리, 최상위 수준의 제약 조건은 스키마 업데이트에서 추가할 수 있습니다. 또한 [이름을 지정](#constraint-name)할 수도 있습니다.

외래 키 제약 조건은 선택적으로 `onDelete`와 `onUpdate` 액션을 지원합니다.

|ForeignKeyAction|설명|
|-|-|
|`.noAction`|외래 키 위반을 방지합니다 (기본값).|
|`.restrict`|`.noAction`과 동일합니다.|
|`.cascade`|외래 키를 통해 삭제를 전파합니다.|
|`.setNull`|참조가 끊어지면 필드를 null로 설정합니다.|
|`.setDefault`|참조가 끊어지면 필드를 기본값으로 설정합니다.|

아래는 외래 키 액션을 사용하는 예제입니다.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    외래 키 액션은 Fluent를 거치지 않고 오직 데이터베이스 내에서만 발생합니다.
    이는 모델 미들웨어나 소프트 삭제와 같은 기능이 올바르게 동작하지 않을 수 있음을 의미합니다.

## SQL

`.sql` 매개변수를 사용하면 스키마에 임의의 SQL을 추가할 수 있습니다. 이는 특정 제약 조건이나 데이터 타입을 추가하는 데 유용합니다.
일반적인 사용 사례는 필드의 기본값을 정의하는 것입니다.

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

또는 타임스탬프의 기본값을 지정할 수도 있습니다.

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary

dictionary 데이터 타입은 중첩된 딕셔너리 값을 저장할 수 있습니다. 여기에는 `Codable`을 준수하는 구조체와 `Codable` 값을 가진 Swift 딕셔너리가 포함됩니다.

!!! note
    Fluent의 SQL 데이터베이스 드라이버는 중첩된 딕셔너리를 JSON 컬럼에 저장합니다.

다음과 같은 `Codable` 구조체를 살펴보겠습니다.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

이 `Pet` 구조체는 `Codable`이므로 `@Field`에 저장될 수 있습니다.

```swift
@Field(key: "pet")
var pet: Pet
```

이 필드는 `.dictionary(of:)` 데이터 타입을 사용하여 저장할 수 있습니다.

```swift
.field("pet", .dictionary, .required)
```

`Codable` 타입은 이종(heterogeneous) 딕셔너리이므로, `of` 매개변수를 지정하지 않습니다.

만약 딕셔너리 값이 `[String: Int]`처럼 동종(homogeneous)이라면, `of` 매개변수로 값 타입을 지정합니다.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

딕셔너리 키는 항상 문자열이어야 합니다.

## Array

array 데이터 타입은 중첩된 배열을 저장할 수 있습니다. 여기에는 `Codable` 값을 포함하는 Swift 배열과, unkeyed container를 사용하는 `Codable` 타입이 포함됩니다.

문자열 배열을 저장하는 다음 `@Field`를 살펴보겠습니다.

```swift
@Field(key: "tags")
var tags: [String]
```

이 필드는 `.array(of:)` 데이터 타입을 사용하여 저장할 수 있습니다.

```swift
.field("tags", .array(of: .string), .required)
```

배열이 동종(homogeneous)이므로, `of` 매개변수를 지정합니다.

Codable을 준수하는 Swift `Array`는 항상 동종의 값 타입을 가집니다. 이종(heterogeneous) 값을 unkeyed container로 직렬화하는 커스텀 `Codable` 타입은 예외이며, 이 경우 `.array` 데이터 타입을 사용해야 합니다.

## Enum

enum 데이터 타입은 문자열 기반의 Swift 열거형(enum)을 네이티브로 저장할 수 있습니다. 네이티브 데이터베이스 enum은 데이터베이스에 추가적인 타입 안전성 계층을 제공하며, 원시 enum보다 더 나은 성능을 보일 수 있습니다.

네이티브 데이터베이스 enum을 정의하려면, `Database`의 `enum` 메서드를 사용하세요. enum의 각 case를 정의하려면 `case`를 사용하세요.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

enum이 생성되고 나면, `read()` 메서드를 사용하여 스키마 필드에 사용할 데이터 타입을 생성할 수 있습니다.

```swift
// An example of reading an enum and using it to define a new field.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Or

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

enum을 업데이트하려면 `update()`를 호출하세요. 기존 enum에서 case를 삭제할 수 있습니다.

```swift
// An example of enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

enum을 삭제하려면 `delete()`를 호출하세요.

```swift
// An example of enum deletion.
database.enum("planet_type").delete()
```

## 모델과의 결합

스키마 빌딩은 의도적으로 모델과 분리되어 있습니다. 쿼리 빌딩과 달리, 스키마 빌딩은 key path를 사용하지 않으며 완전히 문자열 타입(stringly typed)으로 이루어집니다. 이는 스키마 정의, 특히 마이그레이션을 위해 작성된 스키마 정의가 더 이상 존재하지 않는 모델 프로퍼티를 참조해야 할 수도 있기 때문에 중요합니다.

이를 더 잘 이해하기 위해, 다음 마이그레이션 예제를 살펴보겠습니다.

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

이 마이그레이션이 이미 프로덕션에 배포되었다고 가정해봅시다. 이제 User 모델에 다음과 같은 변경을 해야 한다고 가정해봅시다.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

다음 마이그레이션을 통해 필요한 데이터베이스 스키마 조정을 할 수 있습니다.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // It is not currently possible to express this update without using custom SQL.
        // This also doesn't try to deal with splitting the name into first and last,
        // as that requires database-specific syntax.
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

이 마이그레이션이 동작하려면, 제거된 `name` 필드와 새로운 `firstName`, `lastName` 필드를 동시에 참조할 수 있어야 한다는 점에 유의하세요. 게다가, 기존 `UserMigration`도 계속 유효해야 합니다. 이는 key path로는 불가능한 일입니다.

## 모델 space 설정

[모델의 space](model.md#database-space)를 정의하려면, 테이블을 생성할 때 `schema(_:space:)`에 space를 전달하세요. 예를 들면 다음과 같습니다.

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
