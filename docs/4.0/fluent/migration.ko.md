# 마이그레이션

마이그레이션은 데이터베이스를 위한 버전 관리 시스템과 같습니다. 각 마이그레이션은 데이터베이스에 대한 변경 사항과 그것을 되돌리는 방법을 정의합니다. 마이그레이션을 통해 데이터베이스를 수정함으로써, 시간이 지남에 따라 데이터베이스를 일관되고, 테스트 가능하며, 공유 가능한 방식으로 발전시킬 수 있습니다.

```swift
// An example migration.
struct MyMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        // Make a change to the database.
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        // Undo the change made in `prepare`, if possible.
    }
}
```

`async`/`await`를 사용하고 있다면 `AsyncMigration` 프로토콜을 구현해야 합니다.

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Make a change to the database.
    }

    func revert(on database: any Database) async throws {
        // Undo the change made in `prepare`, if possible.
    }
}
```

`prepare` 메서드는 전달받은 `Database`에 변경 사항을 적용하는 곳입니다. 이러한 변경 사항은 테이블이나 컬렉션, 필드, 제약 조건을 추가하거나 제거하는 등 데이터베이스 스키마에 대한 변경일 수 있습니다. 또한 새로운 모델 인스턴스를 생성하거나, 필드 값을 업데이트하거나, 정리 작업을 수행하는 등 데이터베이스 콘텐츠에 대한 변경일 수도 있습니다.

`revert` 메서드는 가능한 경우 이러한 변경 사항을 되돌리는 곳입니다. 마이그레이션을 되돌릴 수 있다는 것은 프로토타이핑과 테스트를 더 쉽게 만들어줍니다. 또한 프로덕션 배포가 계획대로 진행되지 않았을 때를 위한 대비책이 되어줍니다.

## 등록

마이그레이션은 `app.migrations`를 사용하여 애플리케이션에 등록됩니다.

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

`to` 매개변수를 사용하여 특정 데이터베이스에 마이그레이션을 추가할 수 있으며, 그렇지 않으면 기본 데이터베이스가 사용됩니다.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

마이그레이션은 의존 관계 순서에 따라 나열되어야 합니다. 예를 들어, `MigrationB`가 `MigrationA`에 의존한다면, `MigrationA`가 `app.migrations`에 먼저 추가되고 `MigrationB`가 그 다음에 추가되어야 합니다.

## 마이그레이트

데이터베이스를 마이그레이트하려면 `migrate` 커맨드를 실행하세요.

```sh
swift run App migrate
```

이 [커맨드는 Xcode를 통해서도](../advanced/commands.md#xcode) 실행할 수 있습니다. migrate 커맨드는 마지막 실행 이후 새로 등록된 마이그레이션이 있는지 데이터베이스를 확인합니다. 새로운 마이그레이션이 있다면, 실행하기 전에 확인을 요청합니다.

### 되돌리기

데이터베이스에 적용된 마이그레이션을 되돌리려면, `--revert` 플래그와 함께 `migrate`를 실행하세요.

```sh
swift run App migrate --revert
```

이 커맨드는 마지막으로 실행된 마이그레이션 배치가 무엇인지 데이터베이스를 확인하고, 되돌리기 전에 확인을 요청합니다.

### 자동 마이그레이트

다른 커맨드를 실행하기 전에 마이그레이션이 자동으로 실행되기를 원한다면, `--auto-migrate` 플래그를 전달하면 됩니다.

```sh
swift run App serve --auto-migrate
```

이 작업은 프로그래밍 방식으로도 수행할 수 있습니다.

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

되돌리기를 위한 옵션도 마찬가지로 존재합니다: `--auto-revert`와 `app.autoRevert()`입니다.

## 다음 단계

마이그레이션 안에 무엇을 넣을지에 대한 더 자세한 내용은 [스키마 빌더](schema.md)와 [쿼리 빌더](query.md) 가이드를 참고하세요.
