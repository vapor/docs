# Fluent

إن Fluent هو إطار عمل [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) لـ Swift. يستفيد من نظام الأنواع القوي في Swift لتوفير واجهة سهلة الاستخدام لقاعدة بياناتك. يتمحور استخدام Fluent حول إنشاء أنواع النماذج التي تمثّل بِنى البيانات في قاعدة بياناتك. تُستخدم هذه النماذج بعد ذلك لتنفيذ عمليات الإنشاء والقراءة والتحديث والحذف بدلًا من كتابة استعلامات خام.

## الإعداد

عند إنشاء مشروع باستخدام `vapor new`، أجِب بـ "yes" لتضمين Fluent واختر محرّك قاعدة البيانات الذي تريد استخدامه. سيؤدي هذا تلقائيًا إلى إضافة التبعيات (dependencies) إلى مشروعك الجديد بالإضافة إلى كود إعداد نموذجي.

### مشروع موجود

إذا كان لديك مشروع موجود تريد إضافة Fluent إليه، فستحتاج إلى إضافة تبعيتين إلى [الحزمة](../getting-started/spm.md) الخاصة بك:

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- محرّك Fluent واحد (أو أكثر) من اختيارك

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

بمجرد إضافة الحزم كتبعيات، يمكنك إعداد قواعد بياناتك باستخدام `app.databases` في `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

يحتوي كل من محرّكات Fluent أدناه على تعليمات أكثر تحديدًا للإعداد.

### المحرّكات

يحتوي Fluent حاليًا على أربعة محرّكات مدعومة رسميًا. يمكنك البحث في GitHub عن الوسم [`fluent-driver`](https://github.com/topics/fluent-driver) للحصول على قائمة كاملة بمحرّكات قواعد بيانات Fluent الرسمية والتابعة لجهات خارجية.

#### PostgreSQL

إن PostgreSQL هي قاعدة بيانات SQL مفتوحة المصدر ومتوافقة مع المعايير. يمكن إعدادها بسهولة على معظم مزوّدي الاستضافة السحابية. هذا هو محرّك قاعدة البيانات **الموصى به** لـ Fluent.

لاستخدام PostgreSQL، أضف التبعيات التالية إلى حزمتك.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

بمجرد إضافة التبعيات، اضبط بيانات اعتماد قاعدة البيانات مع Fluent باستخدام `app.databases.use` في `configure.swift`.

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

يمكنك أيضًا تحليل بيانات الاعتماد من سلسلة اتصال قاعدة البيانات (connection string).

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

إن SQLite هي قاعدة بيانات SQL مفتوحة المصدر ومضمّنة (embedded). تجعلها طبيعتها البسيطة مرشّحًا رائعًا للنمذجة الأولية والاختبار.

لاستخدام SQLite، أضف التبعيات التالية إلى حزمتك.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

بمجرد إضافة التبعيات، اضبط قاعدة البيانات مع Fluent باستخدام `app.databases.use` في `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

يمكنك أيضًا إعداد SQLite لتخزين قاعدة البيانات بشكل مؤقت في الذاكرة.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

إذا كنت تستخدم قاعدة بيانات في الذاكرة، فتأكّد من ضبط Fluent للترحيل تلقائيًا باستخدام `--auto-migrate` أو تشغيل `app.autoMigrate()` بعد إضافة الترحيلات.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// or
try await app.autoMigrate()
```

!!! tip "نصيحة"
    يُفعِّل إعداد SQLite تلقائيًا قيود المفاتيح الخارجية على جميع الاتصالات المُنشأة، لكنه لا يغيّر إعدادات المفاتيح الخارجية في قاعدة البيانات نفسها. قد يؤدي حذف السجلات في قاعدة بيانات مباشرةً إلى انتهاك قيود المفاتيح الخارجية والمُشغِّلات (triggers).

#### MySQL

إن MySQL هي قاعدة بيانات SQL مفتوحة المصدر شائعة. وهي متاحة على العديد من مزوّدي الاستضافة السحابية. يدعم هذا المحرّك أيضًا MariaDB.

لاستخدام MySQL، أضف التبعيات التالية إلى حزمتك.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

بمجرد إضافة التبعيات، اضبط بيانات اعتماد قاعدة البيانات مع Fluent باستخدام `app.databases.use` في `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

يمكنك أيضًا تحليل بيانات الاعتماد من سلسلة اتصال قاعدة البيانات.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

لإعداد اتصال محلي دون شهادة SSL، ينبغي أن تعطّل التحقّق من الشهادة. قد تحتاج إلى القيام بهذا على سبيل المثال إذا كنت تتصل بقاعدة بيانات MySQL 8 في Docker.

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

!!! warning "تحذير"
    لا تعطّل التحقّق من الشهادة في بيئة الإنتاج. ينبغي أن تقدّم شهادة إلى `TLSConfiguration` للتحقّق منها.

#### MongoDB

إن MongoDB هي قاعدة بيانات NoSQL شائعة بلا مخطط (schemaless) مصمّمة للمبرمجين. يدعم المحرّك جميع مزوّدي الاستضافة السحابية والتثبيتات ذاتية الاستضافة من الإصدار 3.4 وما فوق.

!!! note "ملاحظة"
    يعمل هذا المحرّك بواسطة عميل MongoDB أنشأه وصانه المجتمع يُسمّى [MongoKitten](https://github.com/OpenKitten/MongoKitten). تصون MongoDB عميلًا رسميًا، [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver)، إلى جانب تكامل مع Vapor، [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

لاستخدام MongoDB، أضف التبعيات التالية إلى حزمتك.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

بمجرد إضافة التبعيات، اضبط بيانات اعتماد قاعدة البيانات مع Fluent باستخدام `app.databases.use` في `configure.swift`.

للاتصال، مرّر سلسلة اتصال بتنسيق [connection URI](https://docs.mongodb.com/docs/manual/reference/connection-string/) القياسي لـ MongoDB.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## النماذج

تمثّل النماذج بِنى بيانات ثابتة في قاعدة بياناتك، مثل الجداول أو المجموعات. تحتوي النماذج على حقل واحد أو أكثر لتخزين القيم القابلة للترميز. لكل النماذج أيضًا معرّف فريد. تُستخدم غلافات الخصائص للدلالة على المعرّفات والحقول بالإضافة إلى تعيينات أكثر تعقيدًا سيُذكر لاحقًا. ألقِ نظرة على النموذج التالي الذي يمثّل مجرّة (galaxy).

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

لإنشاء نموذج جديد، أنشئ صنفًا جديدًا يتوافق مع `Model`.

!!! tip "نصيحة"
    يُوصى بوسم أصناف النماذج بـ `final` لتحسين الأداء وتبسيط متطلّبات التوافق.

المتطلّب الأول لبروتوكول `Model` هو السلسلة النصية الثابتة `schema`.

```swift
static let schema = "galaxies"
```

تخبر هذه الخاصية Fluent بأي جدول أو مجموعة يتوافق النموذج. يمكن أن يكون هذا جدولًا موجودًا بالفعل في قاعدة البيانات أو جدولًا ستُنشئه باستخدام [ترحيل](#الترحيلات). عادةً ما يكون المخطط بصيغة `snake_case` وجمعًا.

### المعرّف

المتطلّب التالي هو حقل معرّف يُسمّى `id`.

```swift
@ID(key: .id)
var id: UUID?
```

يجب أن يستخدم هذا الحقل غلاف الخاصية `@ID`. يوصي Fluent باستخدام `UUID` ومفتاح الحقل الخاص `.id` لأن هذا متوافق مع جميع محرّكات Fluent.

إذا كنت تريد استخدام مفتاح أو نوع معرّف مخصّص، فاستخدم التحميل الزائد [`@ID(custom:)`](model.md#معرّف-مخصّص).

### الحقول

بعد إضافة المعرّف، يمكنك إضافة أي عدد تريده من الحقول لتخزين معلومات إضافية. في هذا المثال، الحقل الإضافي الوحيد هو اسم المجرّة.

```swift
@Field(key: "name")
var name: String
```

بالنسبة إلى الحقول البسيطة، يُستخدم غلاف الخاصية `@Field`. مثل `@ID`، يحدّد المُعامل `key` اسم الحقل في قاعدة البيانات. هذا مفيد بشكل خاص في الحالات التي قد يختلف فيها اصطلاح تسمية حقول قاعدة البيانات عنه في Swift، على سبيل المثال، استخدام `snake_case` بدلًا من `camelCase`.

بعد ذلك، تتطلّب جميع النماذج مُهيّئًا فارغًا. يتيح هذا لـ Fluent إنشاء نُسخ جديدة من النموذج.

```swift
init() { }
```

أخيرًا، يمكنك إضافة مُهيّئ ملائم لنموذجك يعيّن جميع خصائصه.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

استخدام المُهيّئات الملائمة مفيد بشكل خاص إذا أضفت خصائص جديدة إلى نموذجك، إذ يمكنك الحصول على أخطاء وقت التصريف (compile-time errors) إذا تغيّرت طريقة المُهيّئ.

## الترحيلات

إذا كانت قاعدة بياناتك تستخدم مخططات معرّفة مسبقًا، مثل قواعد بيانات SQL، فستحتاج إلى ترحيل لتجهيز قاعدة البيانات لنموذجك. الترحيلات مفيدة أيضًا لتعبئة قواعد البيانات بالبيانات. لإنشاء ترحيل، عرّف نوعًا جديدًا يتوافق مع بروتوكول `Migration` أو `AsyncMigration`. ألقِ نظرة على الترحيل التالي للنموذج `Galaxy` المُعرَّف سابقًا.

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

تُستخدم طريقة `prepare` لتجهيز قاعدة البيانات لتخزين نماذج `Galaxy`.

### المخطط

في هذه الطريقة، تُستخدم `database.schema(_:)` لإنشاء `SchemaBuilder` جديد. تُضاف بعد ذلك `field` واحدة أو أكثر إلى الباني قبل استدعاء `create()` لإنشاء المخطط.

لكل حقل يُضاف إلى الباني اسم ونوع وقيود اختيارية.

```swift
field(<name>, <type>, <optional constraints>)
```

توجد طريقة ملائمة `id()` لإضافة خصائص `@ID` باستخدام القيم الافتراضية الموصى بها من Fluent.

يؤدي عكس (revert) الترحيل إلى التراجع عن أي تغييرات أُجريت في طريقة prepare. في هذه الحالة، هذا يعني حذف مخطط Galaxy.

بمجرد تعريف الترحيل، يجب أن تخبر Fluent عنه بإضافته إلى `app.migrations` في `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### الترحيل (Migrate)

لتشغيل الترحيلات، استدعِ `swift run App migrate` من سطر الأوامر أو أضف `migrate` كوسيط إلى مخطط App في Xcode.


```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## الاستعلام

الآن بعد أن أنشأت نموذجًا ورحّلت قاعدة بياناتك بنجاح، أصبحت جاهزًا لإجراء استعلامك الأول.

### الكل (All)

ألقِ نظرة على المسار (route) التالي الذي سيُعيد مصفوفة بجميع المجرّات في قاعدة البيانات.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

لإعادة Galaxy مباشرةً في إغلاق مسار (route closure)، أضف التوافق مع `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

تُستخدم `Galaxy.query` لإنشاء باني استعلام جديد للنموذج. `req.db` هي مرجع إلى قاعدة البيانات الافتراضية لتطبيقك. أخيرًا، تُعيد `all()` جميع النماذج المخزّنة في قاعدة البيانات.

إذا صرّفت وشغّلت المشروع وطلبت `GET /galaxies`، فينبغي أن ترى مصفوفة فارغة مُعادة. لنضِف مسارًا لإنشاء مجرّة جديدة.

### الإنشاء (Create)


اتّباعًا لاصطلاح RESTful، استخدم نقطة النهاية `POST /galaxies` لإنشاء مجرّة جديدة. بما أن النماذج قابلة للترميز، يمكنك فك ترميز مجرّة مباشرةً من جسم الطلب.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso "انظر أيضًا"
    راجع [المحتوى ← نظرة عامة](../basics/content.md) لمزيد من المعلومات حول فك ترميز أجسام الطلبات.

بمجرد أن تحصل على نسخة من النموذج، يؤدي استدعاء `create(on:)` إلى حفظ النموذج في قاعدة البيانات. يُعيد هذا `EventLoopFuture<Void>` الذي يشير إلى اكتمال الحفظ. بمجرد اكتمال الحفظ، أعِد النموذج المُنشأ حديثًا باستخدام `map`.

إذا كنت تستخدم `async`/`await` فيمكنك كتابة كودك على النحو التالي:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

في هذه الحالة، لا تُعيد النسخة غير المتزامنة (async) أي شيء، لكنها ستعود بمجرد اكتمال الحفظ.

ابنِ المشروع وشغّله وأرسل الطلب التالي.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

ينبغي أن تستعيد النموذج المُنشأ مع معرّف كاستجابة.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

الآن، إذا استعلمت عن `GET /galaxies` مرة أخرى، فينبغي أن ترى المجرّة المُنشأة حديثًا مُعادة في المصفوفة.


## العلاقات

ما هي المجرّات بلا نجوم! لنلقِ نظرة سريعة على ميزات Fluent العلائقية القوية بإضافة علاقة واحد-إلى-متعدّد (one-to-many) بين `Galaxy` ونموذج `Star` جديد.

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

### الأصل (Parent)

النموذج `Star` الجديد مشابه جدًا لـ `Galaxy` باستثناء نوع حقل جديد: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

خاصية الأصل هي حقل يخزّن معرّف نموذج آخر. يُسمّى النموذج الذي يحمل المرجع "الابن" (child) ويُسمّى النموذج المُشار إليه "الأصل" (parent). يُعرف هذا النوع من العلاقات أيضًا بـ "واحد-إلى-متعدّد". يحدّد المُعامل `key` للخاصية اسم الحقل الذي ينبغي استخدامه لتخزين مفتاح الأصل في قاعدة البيانات.

في طريقة المُهيّئ، يُعيَّن معرّف الأصل باستخدام `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

 بإضافة البادئة `$` إلى اسم خاصية الأصل، تصل إلى غلاف الخاصية الأساسي. هذا مطلوب للوصول إلى `@Field` الداخلي الذي يخزّن قيمة المعرّف الفعلية.

!!! seealso "انظر أيضًا"
    اطّلع على مقترح Swift Evolution الخاص بغلافات الخصائص لمزيد من المعلومات: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

بعد ذلك، أنشئ ترحيلًا لتجهيز قاعدة البيانات للتعامل مع `Star`.


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

هذا مطابق في معظمه لترحيل galaxy باستثناء الحقل الإضافي لتخزين معرّف المجرّة الأصل.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

يحدّد هذا الحقل قيدًا اختياريًا يخبر قاعدة البيانات بأن قيمة الحقل تشير إلى الحقل "id" في المخطط "galaxies". يُعرف هذا أيضًا بالمفتاح الخارجي ويساعد في ضمان سلامة البيانات.

بمجرد إنشاء الترحيل، أضفه إلى `app.migrations` بعد ترحيل `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

بما أن الترحيلات تعمل بالترتيب، وأن `CreateStar` يشير إلى مخطط galaxies، فإن الترتيب مهم. أخيرًا، [شغّل الترحيلات](#الترحيل-migrate) لتجهيز قاعدة البيانات.

أضف مسارًا لإنشاء نجوم جديدة.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

أنشئ نجمًا جديدًا يشير إلى المجرّة المُنشأة سابقًا باستخدام طلب HTTP التالي.

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

ينبغي أن ترى النجم المُنشأ حديثًا مُعادًا مع معرّف فريد.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### الأبناء (Children)

الآن لنلقِ نظرة على كيفية الاستفادة من ميزة التحميل الحريص (eager-loading) في Fluent لإعادة نجوم المجرّة تلقائيًا في المسار `GET /galaxies`. أضف الخاصية التالية إلى النموذج `Galaxy`.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

غلاف الخاصية `@Children` هو عكس `@Parent`. يأخذ مسار مفتاح (key-path) إلى حقل `@Parent` الخاص بالابن كوسيط `for`. قيمته مصفوفة من الأبناء لأنه قد توجد صفر أو أكثر من نماذج الأبناء. لا حاجة إلى أي تغييرات على ترحيل galaxy لأن جميع المعلومات اللازمة لهذه العلاقة مخزّنة على `Star`.

### التحميل الحريص (Eager Load)

الآن بعد اكتمال العلاقة، يمكنك استخدام طريقة `with` على باني الاستعلام لجلب وتسلسل علاقة galaxy-star تلقائيًا.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

يُمرَّر مسار مفتاح إلى علاقة `@Children` إلى `with` لإخبار Fluent بتحميل هذه العلاقة تلقائيًا في جميع النماذج الناتجة. ابنِ وشغّل وأرسل طلبًا آخر إلى `GET /galaxies`. ينبغي أن ترى الآن النجوم مُضمَّنة تلقائيًا في الاستجابة.

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

## تسجيل الاستعلامات (Query Logging)

تسجّل محرّكات Fluent كود SQL المُولَّد على مستوى تسجيل التصحيح (debug). تتيح بعض المحرّكات، مثل FluentPostgreSQL، إعداد ذلك عند إعداد قاعدة البيانات.

لتعيين مستوى التسجيل، في **configure.swift** (أو حيثما تُعِدّ تطبيقك) أضِف:

```swift
app.logger.logLevel = .debug
```

يعيّن هذا مستوى التسجيل إلى debug. عند بناء وتشغيل تطبيقك في المرة القادمة، ستُسجَّل عبارات SQL المُولَّدة بواسطة Fluent إلى وحدة التحكم (console).

## الخطوات التالية

تهانينا على إنشاء نماذجك وترحيلاتك الأولى وتنفيذ عمليات الإنشاء والقراءة الأساسية. لمزيد من المعلومات المتعمّقة حول جميع هذه الميزات، اطّلع على أقسامها المعنية في دليل Fluent.
