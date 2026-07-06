# متقدم

يسعى Fluent إلى إنشاء واجهة برمجية عامة ومستقلة عن قاعدة البيانات للتعامل مع بياناتك. هذا يجعل تعلّم Fluent أسهل بغض النظر عن مشغّل قاعدة البيانات الذي تستخدمه. كما أن إنشاء واجهات برمجية معمّمة يمكن أن يجعل التعامل مع قاعدة بياناتك أكثر انسجامًا مع Swift.

ومع ذلك، قد تحتاج إلى استخدام ميزة من مشغّل قاعدة البيانات الأساسية لا يدعمها Fluent بعد. يغطي هذا الدليل الأنماط والواجهات البرمجية المتقدمة في Fluent التي تعمل فقط مع قواعد بيانات معينة.

## SQL

جميع مشغّلات قواعد بيانات SQL في Fluent مبنية على [SQLKit](https://github.com/vapor/sql-kit). يأتي هذا التنفيذ العام لـ SQL مع Fluent ضمن وحدة `FluentSQL`.

### قاعدة بيانات SQL

يمكن تحويل أي `Database` في Fluent إلى `SQLDatabase`. يشمل ذلك `req.db` و`app.db` و`database` الممرّرة إلى `Migration`، وما إلى ذلك.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

سينجح هذا التحويل فقط إذا كان مشغّل قاعدة البيانات الأساسية قاعدة بيانات SQL. تعرّف على المزيد حول دوال `SQLDatabase` في [ملف README الخاص بـ SQLKit](https://github.com/vapor/sql-kit).

### قاعدة بيانات SQL محددة

يمكنك أيضًا التحويل إلى قواعد بيانات SQL محددة عبر استيراد المشغّل.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

في وقت كتابة هذا النص، تكون مشغّلات SQL التالية مدعومة.

|قاعدة البيانات|المشغّل|المكتبة|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

قم بزيارة ملف README الخاص بالمكتبة لمزيد من المعلومات حول الواجهات البرمجية الخاصة بكل قاعدة بيانات.

### SQL مخصص

تدعم جميع أنواع الاستعلام والمخطط في Fluent تقريبًا الحالة `.custom`. يتيح لك ذلك الاستفادة من ميزات قاعدة البيانات التي لا يدعمها Fluent بعد.

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

تدعم قواعد بيانات SQL كلًا من `String` و`SQLExpression` في جميع حالات `.custom`. توفّر وحدة `FluentSQL` دوالًا مساعدة لحالات الاستخدام الشائعة.

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

فيما يلي مثال على `.custom` عبر الدالة المساعدة `.sql(raw:)` المستخدمة مع باني المخطط.

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

إن Fluent MongoDB هو تكامل بين [Fluent](../fluent/overview.md) ومشغّل [MongoKitten](https://github.com/OpenKitten/MongoKitten/). إنه يستفيد من نظام الأنواع القوي في Swift وواجهة Fluent المستقلة عن قاعدة البيانات باستخدام MongoDB.

المعرّف الأكثر شيوعًا في MongoDB هو ObjectId. يمكنك استخدامه في مشروعك عبر `@ID(custom: .id)`.
إذا كنت بحاجة إلى استخدام النماذج نفسها مع SQL، فلا تستخدم `ObjectId`. استخدم `UUID` بدلًا من ذلك.

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

### نمذجة البيانات

في MongoDB، تُعرّف النماذج بالطريقة نفسها كما في أي بيئة Fluent أخرى. يكمن الاختلاف الرئيسي بين قواعد بيانات SQL وMongoDB في العلاقات والبنية.

في بيئات SQL، من الشائع جدًا إنشاء جداول ربط للعلاقات بين كيانين. أما في MongoDB، فيمكن استخدام مصفوفة لتخزين المعرّفات المترابطة. نظرًا لتصميم MongoDB، من الأكثر كفاءة وعملية تصميم نماذجك بهياكل بيانات متداخلة.

### بيانات مرنة

يمكنك إضافة بيانات مرنة في MongoDB، لكن هذا الرمز لن يعمل في بيئات SQL.
لإنشاء تخزين بيانات اعتباطية مجمّعة يمكنك استخدام `Document`.

```swift
@Field(key: "document")
var document: Document
```

لا يمكن لـ Fluent دعم الاستعلامات ذات الأنواع الصارمة على هذه القيم. يمكنك استخدام مسار مفتاح بترقيم نقطي في استعلامك للاستعلام.
هذا مقبول في MongoDB للوصول إلى القيم المتداخلة.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```
### استخدام التعبيرات النمطية

يمكنك الاستعلام من MongoDB باستخدام الحالة `.custom()`، وتمرير تعبير نمطي. يقبل [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) تعبيرات نمطية متوافقة مع Perl.

على سبيل المثال، يمكنك الاستعلام عن أحرف غير حساسة لحالة الأحرف ضمن الحقل `name`:

```swift
import FluentMongoDriver
       
var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

سيؤدي هذا إلى إرجاع الكواكب التي تحتوي على 'e' و'E'. يمكنك أيضًا إنشاء أي تعبير نمطي معقد آخر يقبله MongoDB.

### الوصول الخام

للوصول إلى نسخة `MongoDatabase` الخام، حوّل نسخة قاعدة البيانات إلى `MongoDatabaseRepresentable` كالتالي:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

من هنا يمكنك استخدام جميع واجهات MongoKitten البرمجية.
