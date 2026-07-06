# عمليات الترحيل

عمليات الترحيل أشبه بنظام للتحكم بالإصدارات لقاعدة بياناتك. يعرّف كل ترحيل تغييرًا في قاعدة البيانات وكيفية التراجع عنه. من خلال تعديل قاعدة بياناتك عبر عمليات الترحيل، تنشئ طريقة متسقة وقابلة للاختبار وقابلة للمشاركة لتطوير قواعد بياناتك بمرور الوقت.

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

إذا كنت تستخدم `async`/`await` فينبغي أن تنفّذ بروتوكول `AsyncMigration`:

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

دالة `prepare` هي المكان الذي تُجري فيه التغييرات على `Database` المُمرّرة. قد تكون هذه تغييرات على مخطط قاعدة البيانات مثل إضافة أو إزالة جدول أو مجموعة أو حقل أو قيد. قد تعدّل أيضًا محتوى قاعدة البيانات، مثل إنشاء نسخ نماذج جديدة أو تحديث قيم الحقول أو إجراء عمليات تنظيف.

دالة `revert` هي المكان الذي تتراجع فيه عن هذه التغييرات، إن أمكن. إن القدرة على التراجع عن عمليات الترحيل يمكن أن تجعل النمذجة الأولية والاختبار أسهل. كما تمنحك خطة احتياطية إذا لم تسر عملية النشر إلى بيئة الإنتاج كما هو مخطط لها.

## التسجيل

تُسجَّل عمليات الترحيل في تطبيقك باستخدام `app.migrations`.

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

يمكنك إضافة ترحيل إلى قاعدة بيانات محددة باستخدام المعامل `to`، وإلا فستُستخدم قاعدة البيانات الافتراضية.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

ينبغي إدراج عمليات الترحيل بترتيب الاعتمادية. على سبيل المثال، إذا كان `MigrationB` يعتمد على `MigrationA`، فينبغي إضافته إلى `app.migrations` ثانيًا.

## الترحيل

لترحيل قاعدة بياناتك، شغّل أمر `migrate`.

```sh
swift run App migrate
```

يمكنك أيضًا تشغيل هذا [الأمر عبر Xcode](../advanced/commands.md#xcode). سيتحقق أمر migrate من قاعدة البيانات لمعرفة ما إذا كانت هناك أي عمليات ترحيل جديدة قد سُجّلت منذ آخر تشغيل له. إذا كانت هناك عمليات ترحيل جديدة، فسيطلب تأكيدًا قبل تشغيلها.

### التراجع

للتراجع عن ترحيل في قاعدة بياناتك، شغّل `migrate` مع الراية `--revert`.

```sh
swift run App migrate --revert
```

سيتحقق الأمر من قاعدة البيانات لمعرفة أي دفعة من عمليات الترحيل جرى تشغيلها آخر مرة ويطلب تأكيدًا قبل التراجع عنها.

### الترحيل التلقائي

إذا كنت ترغب في تشغيل عمليات الترحيل تلقائيًا قبل تشغيل أوامر أخرى، فيمكنك تمرير الراية `--auto-migrate`.

```sh
swift run App serve --auto-migrate
```

يمكنك أيضًا القيام بذلك برمجيًا.

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

يتوفر كلا هذين الخيارين للتراجع أيضًا: `--auto-revert` و`app.autoRevert()`.

## الخطوات التالية

ألقِ نظرة على دليلَي [باني المخطط](schema.md) و[باني الاستعلام](query.md) لمزيد من المعلومات حول ما تضعه داخل عمليات الترحيل.
