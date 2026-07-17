# المخطط

تتيح لك واجهة برمجة المخطط في Fluent إنشاء مخطط قاعدة بياناتك وتحديثه برمجيًا. غالبًا ما تُستخدم بالاقتران مع [الترحيلات](migration.md) لإعداد قاعدة البيانات للاستخدام مع [النماذج](model.md).

```swift
// An example of Fluent's schema API
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

لإنشاء `SchemaBuilder`، استخدم الطريقة `schema` على قاعدة البيانات. مرّر اسم الجدول أو المجموعة التي تريد التأثير عليها. إذا كنت تُحرّر المخطط لنموذج، فتأكد من أن هذا الاسم يطابق [`schema`](model.md#المخطط) الخاص بالنموذج.

## الإجراءات

تدعم واجهة برمجة المخطط إنشاء المخططات وتحديثها وحذفها. يدعم كل إجراء مجموعة فرعية من الطرق المتاحة في الواجهة.

### Create

يؤدي استدعاء `create()` إلى إنشاء جدول أو مجموعة جديدة في قاعدة البيانات. تُدعم جميع الطرق الخاصة بتعريف الحقول والقيود الجديدة. تُتجاهل طرق التحديثات أو الحذف.

```swift
// An example schema creation.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

إذا كان هناك جدول أو مجموعة بالاسم المختار موجودة بالفعل، فسيُطرح خطأ. لتجاهل هذا، استخدم `.ignoreExisting()`.

### Update

يؤدي استدعاء `update()` إلى تحديث جدول أو مجموعة موجودة في قاعدة البيانات. تُدعم جميع الطرق الخاصة بإنشاء الحقول والقيود وتحديثها وحذفها.

```swift
// An example schema update.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Delete

يؤدي استدعاء `delete()` إلى حذف جدول أو مجموعة موجودة من قاعدة البيانات. لا تُدعم أي طرق إضافية.

```swift
// An example schema deletion.
database.schema("planets").delete()
```

## الحقل

يمكن إضافة الحقول عند إنشاء مخطط أو تحديثه.

```swift
// Adds a new field
.field("name", .string, .required)
```

المُعامل الأول هو اسم الحقل. يجب أن يطابق هذا المفتاح المُستخدم على خاصية النموذج المرتبطة. المُعامل الثاني هو [نوع بيانات](#نوع-البيانات) الحقل. أخيرًا، يمكن إضافة صفر أو أكثر من [القيود](#قيد-الحقل).

### نوع البيانات

أنواع بيانات الحقول المدعومة مُدرجة أدناه.

|نوع البيانات|نوع Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (مُوصى به)|
|`.date`|`Date` (مع حذف وقت اليوم)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|راجع [dictionary](#القاموس-dictionary)|
|`.array`|راجع [array](#المصفوفة-array)|
|`.enum`|راجع [enum](#التعداد-enum)|

### قيد الحقل

قيود الحقل المدعومة مُدرجة أدناه.

|قيد الحقل|الوصف|
|-|-|
|`.required`|يمنع القيم `nil`.|
|`.references`|يتطلّب أن تطابق قيمة هذا الحقل قيمة في المخطط المُشار إليه. راجع [المفتاح الخارجي](#المفتاح-الخارجي).|
|`.identifier`|يشير إلى المفتاح الأساسي. راجع [المُعرّف](#المُعرّف).|
|`.sql(SQLColumnConstraintAlgorithm)`|يُعرّف أي قيد غير مدعوم (مثل `default`). راجع [SQL](#sql) و[SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/sqlcolumnconstraintalgorithm/).|

### المُعرّف

إذا كان نموذجك يستخدم خاصية `@ID` قياسية، فيمكنك استخدام المساعد `id()` لإنشاء حقله. يستخدم هذا مفتاح الحقل الخاص `.id` ونوع القيمة `UUID`.

```swift
// Adds field for default identifier.
.id()
```

بالنسبة إلى أنواع المُعرّفات المخصّصة، ستحتاج إلى تحديد الحقل يدويًا.

```swift
// Adds field for custom identifier.
.field("id", .int, .identifier(auto: true))
```

يمكن استخدام قيد `identifier` على حقل واحد ويشير إلى المفتاح الأساسي. تحدّد العلامة `auto` ما إذا كان يجب على قاعدة البيانات توليد هذه القيمة تلقائيًا أم لا.

### تحديث الحقل

يمكنك تحديث نوع بيانات الحقل باستخدام `updateField`.

```swift
// Updates the field to `double` data type.
.updateField("age", .double)
```

راجع [المتقدم](advanced.md#sql) لمزيد من المعلومات حول تحديثات المخطط المتقدمة.

### حذف الحقل

يمكنك إزالة حقل من مخطط باستخدام `deleteField`.

```swift
// Deletes the field "age".
.deleteField("age")
```

## القيد

يمكن إضافة القيود عند إنشاء مخطط أو تحديثه. على عكس [قيود الحقل](#قيد-الحقل)، يمكن للقيود عالية المستوى أن تؤثر على حقول متعددة.

### Unique

يتطلّب قيد التفرّد ألّا تكون هناك قيم مكررة في حقل واحد أو أكثر.

```swift
// Disallow duplicate email addresses.
.unique(on: "email")
```

إذا كانت هناك حقول متعددة مُقيّدة، فيجب أن يكون المزيج المحدّد من قيمة كل حقل فريدًا.

```swift
// Disallow users with the same full name.
.unique(on: "first_name", "last_name")
```

لحذف قيد تفرّد، استخدم `deleteUnique`.

```swift
// Removes duplicate email constraint.
.deleteUnique(on: "email")
```

### اسم القيد

سيولّد Fluent أسماء قيود فريدة افتراضيًا. ومع ذلك، قد ترغب في تمرير اسم قيد مخصّص. يمكنك فعل ذلك باستخدام المُعامل `name`.

```swift
// Disallow duplicate email addresses.
.unique(on: "email", name: "no_duplicate_emails")
```

لحذف قيد مُسمّى، يجب عليك استخدام `deleteConstraint(name:)`.

```swift
// Removes duplicate email constraint.
.deleteConstraint(name: "no_duplicate_emails")
```

## المفتاح الخارجي

تتطلّب قيود المفتاح الخارجي أن تطابق قيمة الحقل إحدى القيم في الحقل المُشار إليه. هذا مفيد لمنع حفظ بيانات غير صالحة. يمكن إضافة قيود المفتاح الخارجي إما كقيد على الحقل أو كقيد عالي المستوى.

لإضافة قيد مفتاح خارجي إلى حقل، استخدم `.references`.

```swift
// Example of adding a field foreign key constraint.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

يتطلّب القيد أعلاه أن تطابق جميع القيم في الحقل "star_id" إحدى القيم في حقل "id" الخاص بـ Star.

يمكن إضافة هذا القيد نفسه كقيد عالي المستوى باستخدام `foreignKey`.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id")
```

على عكس قيود الحقل، يمكن إضافة القيود عالية المستوى في تحديث المخطط. ويمكن أيضًا [تسميتها](#اسم-القيد).

تدعم قيود المفتاح الخارجي إجراءات `onDelete` و`onUpdate` الاختيارية.

|إجراء المفتاح الخارجي|الوصف|
|-|-|
|`.noAction`|يمنع انتهاكات المفتاح الخارجي (الافتراضي).|
|`.restrict`|مماثل لـ `.noAction`.|
|`.cascade`|ينشر عمليات الحذف عبر المفاتيح الخارجية.|
|`.setNull`|يعيّن الحقل إلى null إذا انقطع المرجع.|
|`.setDefault`|يعيّن الحقل إلى القيمة الافتراضية إذا انقطع المرجع.|

فيما يلي مثال باستخدام إجراءات المفتاح الخارجي.

```swift
// Example of adding a top-level foreign key constraint.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning "تحذير"
    تحدث إجراءات المفتاح الخارجي في قاعدة البيانات حصريًا، متجاوزةً Fluent.
    هذا يعني أن أمورًا مثل وسيط النموذج (middleware) والحذف الناعم (soft-delete) قد لا تعمل بشكل صحيح.

## SQL

يتيح لك المُعامل `.sql` إضافة أي SQL اعتباطي إلى مخططك. هذا مفيد لإضافة قيود أو أنواع بيانات محدّدة.
حالة استخدام شائعة هي تعريف قيمة افتراضية لحقل:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

أو حتى قيمة افتراضية لطابع زمني:

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## القاموس (Dictionary)

نوع بيانات القاموس قادر على تخزين قيم قاموس متداخلة. يشمل هذا البُنى (structs) المتوافقة مع `Codable` وقواميس Swift ذات القيمة المتوافقة مع `Codable`.

!!! note "ملاحظة"
    تُخزّن مُشغّلات قاعدة بيانات SQL في Fluent القواميس المتداخلة في أعمدة JSON.

خذ البنية `Codable` التالية.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

بما أن بنية `Pet` هذه متوافقة مع `Codable`، فيمكن تخزينها في `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

يمكن تخزين هذا الحقل باستخدام نوع البيانات `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

بما أن أنواع `Codable` هي قواميس غير متجانسة، فإننا لا نحدّد المُعامل `of`.

إذا كانت قيم القاموس متجانسة، على سبيل المثال `[String: Int]`، فسيحدّد المُعامل `of` نوع القيمة.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

يجب أن تكون مفاتيح القاموس دائمًا سلاسل نصية.

## المصفوفة (Array)

نوع بيانات المصفوفة قادر على تخزين مصفوفات متداخلة. يشمل هذا مصفوفات Swift التي تحتوي على قيم `Codable` وأنواع `Codable` التي تستخدم حاوية غير مُفتاحة (unkeyed container).

خذ `@Field` التالي الذي يخزّن مصفوفة من السلاسل النصية.

```swift
@Field(key: "tags")
var tags: [String]
```

يمكن تخزين هذا الحقل باستخدام نوع البيانات `.array(of:)`.

```swift
.field("tags", .array(of: .string), .required)
```

بما أن المصفوفة متجانسة، فإننا نحدّد المُعامل `of`.

سيكون لمصفوفات Swift المتوافقة مع `Codable` دائمًا نوع قيمة متجانس. أنواع `Codable` المخصّصة التي تُسلسل قيمًا غير متجانسة إلى حاويات غير مُفتاحة هي الاستثناء ويجب أن تستخدم نوع البيانات `.array`.

## التعداد (Enum)

نوع بيانات التعداد قادر على تخزين تعدادات Swift المدعومة بالسلاسل النصية بشكل أصلي. توفّر تعدادات قاعدة البيانات الأصلية طبقة إضافية من أمان الأنواع لقاعدة بياناتك وقد تكون أكثر كفاءة من التعدادات الخام.

لتعريف تعداد قاعدة بيانات أصلي، استخدم الطريقة `enum` على `Database`. استخدم `case` لتعريف كل حالة من حالات التعداد.

```swift
// An example of enum creation.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

بمجرد إنشاء تعداد، يمكنك استخدام الطريقة `read()` لتوليد نوع بيانات لحقل مخططك.

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

لتحديث تعداد، استدعِ `update()`. يمكن حذف الحالات من التعدادات الموجودة.

```swift
// An example of enum update.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

لحذف تعداد، استدعِ `delete()`.

```swift
// An example of enum deletion.
database.enum("planet_type").delete()
```

## اقتران النماذج

بناء المخطط مفصول عن النماذج عن قصد. على عكس بناء الاستعلام، لا يستخدم بناء المخطط مسارات المفاتيح وهو مكتوب بالكامل بالسلاسل النصية. هذا مهم لأن تعريفات المخطط، خاصة تلك المكتوبة للترحيلات، قد تحتاج إلى الإشارة إلى خصائص نموذج لم تعد موجودة.

لفهم هذا بشكل أفضل، ألقِ نظرة على مثال الترحيل التالي.

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

لنفترض أن هذا الترحيل قد دُفع بالفعل إلى بيئة الإنتاج. الآن لنفترض أننا بحاجة إلى إجراء التغيير التالي على نموذج User.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

يمكننا إجراء التعديلات اللازمة على مخطط قاعدة البيانات باستخدام الترحيل التالي.

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

لاحظ أنه لكي يعمل هذا الترحيل، نحتاج إلى أن نكون قادرين على الإشارة إلى كل من الحقل المحذوف `name` والحقلين الجديدين `firstName` و`lastName` في الوقت نفسه. علاوة على ذلك، يجب أن يظل الترحيل الأصلي `UserMigration` صالحًا. لن يكون من الممكن فعل هذا باستخدام مسارات المفاتيح.

## تعيين مساحة النموذج

لتعريف [المساحة الخاصة بنموذج](model.md#مساحة-قاعدة-البيانات-database-space)، مرّر المساحة إلى `schema(_:space:)` عند إنشاء الجدول. على سبيل المثال:

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
