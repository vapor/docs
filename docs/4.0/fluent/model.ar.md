# النماذج

تمثّل النماذج البيانات المخزّنة في الجداول أو المجموعات في قاعدة البيانات الخاصة بك. تحتوي النماذج على حقل واحد أو أكثر لتخزين القيم القابلة للترميز (codable). لكل النماذج معرّف فريد. تُستخدم غلافات الخصائص (property wrappers) للدلالة على المعرّفات والحقول والعلاقات.

في ما يلي مثال على نموذج بسيط بحقل واحد. لاحظ أن النماذج لا تصف مخطط قاعدة البيانات بالكامل، مثل القيود والفهارس والمفاتيح الخارجية. تُعرَّف المخططات في [الترحيلات](migration.md). تركّز النماذج على تمثيل البيانات المخزّنة في مخططات قاعدة البيانات الخاصة بك.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"

    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?

    // The Planet's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Planet.
    init() { }

    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## المخطط

تتطلّب جميع النماذج خاصية `schema` ثابتة وللقراءة فقط. تشير هذه السلسلة النصية إلى اسم الجدول أو المجموعة التي يمثّلها هذا النموذج.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"
}
```

عند الاستعلام عن هذا النموذج، سيتم جلب البيانات من المخطط المسمّى `"planets"` وتخزينها فيه.

!!! tip "نصيحة"
    عادةً ما يكون اسم المخطط هو اسم الصنف بصيغة الجمع وبأحرف صغيرة.

## المعرّف

يجب أن تحتوي جميع النماذج على خاصية `id` مُعرَّفة باستخدام غلاف الخاصية `@ID`. يميّز هذا الحقل نُسخ النموذج الخاص بك بشكل فريد.

```swift
final class Planet: Model {
    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?
}
```

بشكل افتراضي، ينبغي أن تستخدم خاصية `@ID` المفتاح الخاص `.id` الذي يُحلّل إلى مفتاح مناسب لمحرّك قاعدة البيانات الأساسي. بالنسبة إلى SQL يكون هذا `"id"` وبالنسبة إلى NoSQL يكون `"_id"`.

ينبغي أيضًا أن تكون `@ID` من النوع `UUID`. هذه هي قيمة المعرّف الوحيدة المدعومة حاليًا من قبل جميع محرّكات قواعد البيانات. سيقوم Fluent تلقائيًا بتوليد معرّفات UUID جديدة عند إنشاء النماذج.

تحتوي `@ID` على قيمة اختيارية لأن النماذج غير المحفوظة قد لا تملك معرّفًا بعد. للحصول على المعرّف أو رمي خطأ، استخدم `requireID`.

```swift
let id = try planet.requireID()
```

### الوجود (Exists)

تحتوي `@ID` على خاصية `exists` تمثّل ما إذا كان النموذج موجودًا في قاعدة البيانات أم لا. عند تهيئة نموذج، تكون القيمة `false`. بعد حفظ نموذج أو عند جلب نموذج من قاعدة البيانات، تكون القيمة `true`. هذه الخاصية قابلة للتغيير.

```swift
if planet.$id.exists {
    // This model exists in database.
}
```

### معرّف مخصّص

يدعم Fluent مفاتيح وأنواع معرّفات مخصّصة باستخدام التحميل الزائد `@ID(custom:)`.

```swift
final class Planet: Model {
    // Unique identifier for this Planet.
    @ID(custom: "foo")
    var id: Int?
}
```

يستخدم المثال أعلاه `@ID` بمفتاح مخصّص `"foo"` ونوع معرّف `Int`. هذا متوافق مع قواعد بيانات SQL التي تستخدم مفاتيح أساسية ذاتية الزيادة، لكنه غير متوافق مع NoSQL.

تتيح `@ID` المخصّصة للمستخدم تحديد كيفية توليد المعرّف باستخدام المُعامل `generatedBy`.

```swift
@ID(custom: "foo", generatedBy: .user)
```

يدعم المُعامل `generatedBy` الحالات التالية:

|مُولَّد بواسطة|الوصف|
|-|-|
|`.user`|يُتوقّع تعيين خاصية `@ID` قبل حفظ نموذج جديد.|
|`.random`|يجب أن يتوافق نوع قيمة `@ID` مع `RandomGeneratable`.|
|`.database`|يُتوقّع أن تولّد قاعدة البيانات قيمة عند الحفظ.|

إذا حُذف المُعامل `generatedBy`، فسيحاول Fluent استنتاج الحالة المناسبة بناءً على نوع قيمة `@ID`. على سبيل المثال، سيُعيَّن `Int` افتراضيًا إلى توليد `.database` ما لم يُحدَّد خلاف ذلك.

## المُهيّئ (Initializer)

يجب أن تحتوي النماذج على طريقة مُهيّئ فارغة.

```swift
final class Planet: Model {
    // Creates a new, empty Planet.
    init() { }
}
```

يتطلّب Fluent هذه الطريقة داخليًا لتهيئة النماذج التي تُعيدها الاستعلامات. تُستخدم أيضًا للانعكاس (reflection).

قد ترغب في إضافة مُهيّئ ملائم (convenience initializer) إلى نموذجك يقبل جميع الخصائص.

```swift
final class Planet: Model {
    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

يجعل استخدام المُهيّئات الملائمة من الأسهل إضافة خصائص جديدة إلى النموذج في المستقبل.

## الحقل

يمكن أن تحتوي النماذج على صفر أو أكثر من خصائص `@Field` لتخزين البيانات.

```swift
final class Planet: Model {
    // The Planet's name.
    @Field(key: "name")
    var name: String
}
```

تتطلّب الحقول تعريف مفتاح قاعدة البيانات بشكل صريح. ليس من الضروري أن يكون هذا مطابقًا لاسم الخاصية.

!!! tip "نصيحة"
    يوصي Fluent باستخدام `snake_case` لمفاتيح قاعدة البيانات و`camelCase` لأسماء الخصائص.

يمكن أن تكون قيم الحقول من أي نوع يتوافق مع `Codable`. تخزين البِنى المتداخلة والمصفوفات في `@Field` مدعوم، لكن عمليات التصفية محدودة. راجع [`@Group`](#المجموعة-group) للحصول على بديل.

بالنسبة إلى الحقول التي تحتوي على قيمة اختيارية، استخدم `@OptionalField`.

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! warning "تحذير"
    الحقل غير الاختياري الذي يحتوي على مراقب خاصية `willSet` يشير إلى قيمته الحالية أو مراقب خاصية `didSet` يشير إلى `oldValue` الخاص به سيؤدي إلى خطأ فادح (fatal error).

## العلاقات

يمكن أن تحتوي النماذج على صفر أو أكثر من خصائص العلاقات التي تشير إلى نماذج أخرى مثل `@Parent` و`@Children` و`@Siblings`. تعرّف على المزيد حول العلاقات في قسم [العلاقات](relations.md).

## الطابع الزمني (Timestamp)

`@Timestamp` هو نوع خاص من `@Field` يخزّن `Foundation.Date`. تُعيَّن الطوابع الزمنية تلقائيًا بواسطة Fluent وفقًا للمُشغِّل المختار.

```swift
final class Planet: Model {
    // When this Planet was created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // When this Planet was last updated.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

يدعم `@Timestamp` المُشغِّلات التالية.

|المُشغِّل|الوصف|
|-|-|
|`.create`|يُعيَّن عند حفظ نسخة نموذج جديدة في قاعدة البيانات.|
|`.update`|يُعيَّن عند حفظ نسخة نموذج موجودة في قاعدة البيانات.|
|`.delete`|يُعيَّن عند حذف نموذج من قاعدة البيانات. راجع [الحذف الناعم](#الحذف-الناعم-soft-delete).|

قيمة تاريخ `@Timestamp` اختيارية وينبغي تعيينها إلى `nil` عند تهيئة نموذج جديد.

### تنسيق الطابع الزمني

بشكل افتراضي، سيستخدم `@Timestamp` ترميز `datetime` فعّالًا بناءً على محرّك قاعدة البيانات الخاص بك. يمكنك تخصيص كيفية تخزين الطابع الزمني في قاعدة البيانات باستخدام المُعامل `format`.

```swift
// Stores an ISO 8601 formatted timestamp representing
// when this model was last updated.
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

لاحظ أن الترحيل المرتبط بهذا المثال `.iso8601` سيتطلّب التخزين بتنسيق `.string`.

```swift
.field("updated_at", .string)
```

تنسيقات الطوابع الزمنية المتاحة مدرجة أدناه.

|التنسيق|الوصف|النوع|
|-|-|-|
|`.default`|يستخدم ترميز `datetime` فعّالًا لقاعدة بيانات معيّنة.|Date|
|`.iso8601`|سلسلة نصية بتنسيق [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601). يدعم المُعامل `withMilliseconds`.|String|
|`.unix`|الثواني منذ حقبة Unix بما في ذلك الكسور.|Double|

يمكنك الوصول إلى قيمة الطابع الزمني الخام مباشرةً باستخدام الخاصية `timestamp`.

```swift
// Manually set the timestamp value on this ISO 8601
// formatted @Timestamp.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### الحذف الناعم (Soft Delete)

إضافة `@Timestamp` يستخدم المُشغِّل `.delete` إلى نموذجك ستُفعِّل الحذف الناعم.

```swift
final class Planet: Model {
    // When this Planet was deleted.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

لا تزال النماذج المحذوفة حذفًا ناعمًا موجودة في قاعدة البيانات بعد الحذف، لكنها لن تُعاد في الاستعلامات.

!!! tip "نصيحة"
    يمكنك تعيين طابع زمني للحذف يدويًا إلى تاريخ في المستقبل. يمكن استخدام هذا كتاريخ انتهاء صلاحية.

لإجبار نموذج قابل للحذف الناعم على أن يُزال من قاعدة البيانات، استخدم المُعامل `force` في `delete`.

```swift
// Deletes from the database even if the model 
// is soft deletable. 
model.delete(force: true, on: database)
```

لاستعادة نموذج محذوف حذفًا ناعمًا، استخدم طريقة `restore`.

```swift
// Clears the on delete timestamp allowing this 
// model to be returned in queries. 
model.restore(on: database)
```

لتضمين النماذج المحذوفة حذفًا ناعمًا في استعلام، استخدم `withDeleted`.

```swift
// Fetches all planets including soft deleted.
Planet.query(on: database).withDeleted().all()
```

## التعداد (Enum)

`@Enum` هو نوع خاص من `@Field` لتخزين الأنواع القابلة للتمثيل كسلسلة نصية بوصفها تعدادات قاعدة بيانات أصلية. توفّر تعدادات قاعدة البيانات الأصلية طبقة إضافية من أمان الأنواع لقاعدة بياناتك وقد تكون أكثر أداءً من التعدادات الخام.

```swift
// String representable, Codable enum for animal types.
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // Stores type of animal as a native database enum.
    @Enum(key: "type")
    var type: Animal
}
```

الأنواع التي تتوافق مع `RawRepresentable` حيث يكون `RawValue` من النوع `String` فقط هي المتوافقة مع `@Enum`. تستوفي التعدادات المدعومة بـ `String` هذا المتطلّب بشكل افتراضي.

لتخزين تعداد اختياري، استخدم `@OptionalEnum`.

يجب تجهيز قاعدة البيانات للتعامل مع التعدادات عبر ترحيل. راجع [enum](schema.md#التعداد-enum) لمزيد من المعلومات.

### التعدادات الخام

يمكن تخزين أي تعداد مدعوم بنوع `Codable`، مثل `String` أو `Int`، في `@Field`. سيُخزَّن في قاعدة البيانات كقيمة خام.

## المجموعة (Group)

تتيح لك `@Group` تخزين مجموعة متداخلة من الحقول كخاصية واحدة على نموذجك. على عكس بِنى Codable المخزّنة في `@Field`، تكون الحقول في `@Group` قابلة للاستعلام. يحقّق Fluent ذلك بتخزين `@Group` كبنية مسطّحة في قاعدة البيانات.

لاستخدام `@Group`، عرّف أولًا البنية المتداخلة التي ترغب في تخزينها باستخدام بروتوكول `Fields`. هذا مشابه جدًا لـ `Model` باستثناء عدم الحاجة إلى معرّف أو اسم مخطط. يمكنك تخزين العديد من الخصائص هنا التي يدعمها `Model` مثل `@Field` أو `@Enum` أو حتى `@Group` أخرى.

```swift
// A pet with name and animal type.
final class Pet: Fields {
    // The pet's name.
    @Field(key: "name")
    var name: String

    // The type of pet. 
    @Field(key: "type")
    var type: String

    // Creates a new, empty Pet.
    init() { }
}
```

بعد إنشاء تعريف الحقول، يمكنك استخدامه كقيمة لخاصية `@Group`.

```swift
final class User: Model {
    // The user's nested pet.
    @Group(key: "pet")
    var pet: Pet
}
```

يمكن الوصول إلى حقول `@Group` عبر صيغة النقطة (dot-syntax).

```swift
let user: User = ...
print(user.pet.name) // String
```

يمكنك الاستعلام عن الحقول المتداخلة كالمعتاد باستخدام صيغة النقطة على غلافات الخصائص.

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

في قاعدة البيانات، تُخزَّن `@Group` كبنية مسطّحة مع مفاتيح مدموجة بـ `_`. في ما يلي مثال على كيف سيبدو `User` في قاعدة البيانات.

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

تتوافق النماذج مع `Codable` بشكل افتراضي. هذا يعني أنه يمكنك استخدام نماذجك مع [واجهة برمجة المحتوى](../basics/content.md) الخاصة بـ Vapor بإضافة التوافق مع بروتوكول `Content`.

```swift
extension Planet: Content { }

app.get("planets") { req async throws in 
    // Return an array of all planets.
    try await Planet.query(on: req.db).all()
}
```

عند التسلسل من/إلى `Codable`، ستستخدم خصائص النموذج أسماء متغيّراتها بدلًا من المفاتيح. ستُسلسَل العلاقات كبِنى متداخلة وسيتم تضمين أي بيانات مُحمَّلة بشكل حريص (eager loaded).

!!! info "معلومة"
    نوصي في جميع الحالات تقريبًا باستخدام DTO بدلًا من نموذج لاستجابات الواجهة البرمجية وأجسام الطلبات. راجع [كائن نقل البيانات](#كائن-نقل-البيانات-data-transfer-object) لمزيد من المعلومات.

### كائن نقل البيانات (Data Transfer Object)

يمكن أن يجعل التوافق الافتراضي للنموذج مع `Codable` الاستخدام البسيط والنمذجة الأولية أسهل. ومع ذلك، فإنه يكشف معلومات قاعدة البيانات الأساسية للواجهة البرمجية. عادةً ما يكون هذا غير مرغوب فيه من الناحية الأمنية — إعادة حقول حسّاسة مثل تجزئة كلمة مرور المستخدم فكرة سيئة — ومن ناحية سهولة الاستخدام. فهو يجعل من الصعب تغيير مخطط قاعدة البيانات دون كسر الواجهة البرمجية، أو قبول أو إعادة البيانات بتنسيق مختلف، أو إضافة أو إزالة حقول من الواجهة البرمجية.

في معظم الحالات ينبغي أن تستخدم DTO، أو كائن نقل البيانات، بدلًا من نموذج (يُعرف هذا أيضًا بكائن نقل النطاق). إن DTO هو نوع `Codable` منفصل يمثّل بنية البيانات التي ترغب في ترميزها أو فك ترميزها. تفصل هذه الكائنات واجهتك البرمجية عن مخطط قاعدة البيانات وتتيح لك إجراء تغييرات على نماذجك دون كسر الواجهة البرمجية العامة لتطبيقك، وأن تكون لديك إصدارات مختلفة، وأن تجعل واجهتك البرمجية أفضل للاستخدام من قبل عملائك.

افترض النموذج `User` التالي في الأمثلة القادمة.

```swift
// Abridged user model for reference.
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

إحدى حالات الاستخدام الشائعة لكائنات DTO هي في تنفيذ طلبات `PATCH`. تتضمّن هذه الطلبات فقط قيمًا للحقول التي ينبغي تحديثها. ستفشل محاولة فك ترميز `Model` مباشرةً من مثل هذا الطلب إذا كان أي من الحقول المطلوبة مفقودًا. في المثال أدناه، يمكنك رؤية استخدام DTO لفك ترميز بيانات الطلب وتحديث نموذج.

```swift
// Structure of PATCH /users/:id request.
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in 
    // Decode the request data.
    let patch = try req.content.decode(PatchUser.self)
    // Fetch the desired user from the database.
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // If first name was supplied, update it.
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // If new last name was supplied, update it.
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // Save the user and return it.
    try await user.save(on: req.db)
    return user
}
```

حالة استخدام شائعة أخرى لكائنات DTO هي تخصيص تنسيق استجابات واجهتك البرمجية. يوضّح المثال أدناه كيف يمكن استخدام DTO لإضافة حقل محسوب إلى استجابة.

```swift
// Structure of GET /users response.
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in 
    // Fetch all users from the database.
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // Convert each user to GET return type.
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

حالة استخدام شائعة أخرى هي عند التعامل مع العلاقات، مثل علاقات الأصل (parent) أو علاقات الأبناء (children). راجع [توثيق Parent](relations.md#ترميز-النماذج-الأب-وفك-ترميزها) للحصول على مثال حول كيفية استخدام DTO لتسهيل فك ترميز نموذج بعلاقة `@Parent`.

حتى لو كانت بنية DTO مطابقة لتوافق النموذج مع `Codable`، فإن وجوده كنوع منفصل يمكن أن يساعد في الحفاظ على ترتيب المشاريع الكبيرة. إذا احتجت في أي وقت إلى إجراء تغيير على خصائص نماذجك، فلن تضطر إلى القلق بشأن كسر الواجهة البرمجية العامة لتطبيقك. قد تفكّر أيضًا في وضع كائنات DTO الخاصة بك في حزمة منفصلة يمكن مشاركتها مع مستهلكي واجهتك البرمجية وإضافة التوافق مع `Content` في تطبيق Vapor الخاص بك.

## الاسم المستعار (Alias)

يتيح لك بروتوكول `ModelAlias` تحديد نموذج يُدمج (join) عدة مرات في استعلام بشكل فريد. لمزيد من المعلومات، راجع [عمليات الدمج](query.md#الضم).

## الحفظ

لحفظ نموذج في قاعدة البيانات، استخدم طريقة `save(on:)`.

```swift
planet.save(on: database)
```

ستستدعي هذه الطريقة `create` أو `update` داخليًا اعتمادًا على ما إذا كان النموذج موجودًا بالفعل في قاعدة البيانات.

### الإنشاء (Create)

يمكنك استدعاء طريقة `create` لحفظ نموذج جديد في قاعدة البيانات.

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` متاحة أيضًا على مصفوفة من النماذج. يحفظ هذا جميع النماذج في قاعدة البيانات في دفعة/استعلام واحد.

```swift
// Example of batch create.
[earth, mars].create(on: database)
```

!!! warning "تحذير"
    النماذج التي تستخدم [`@ID(custom:)`](#معرّف-مخصّص) مع مُولِّد `.database` (عادةً أعداد `Int` ذاتية الزيادة) لن يمكن الوصول إلى معرّفاتها المُنشأة حديثًا بعد الإنشاء الدفعي. للحالات التي تحتاج فيها إلى الوصول إلى المعرّفات، استدعِ `create` على كل نموذج على حدة.

لإنشاء مصفوفة من النماذج بشكل منفصل، استخدم `map` + `flatten`.

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

إذا كنت تستخدم `async`/`await` فيمكنك استخدام:

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### التحديث (Update)

يمكنك استدعاء طريقة `update` لحفظ نموذج جُلب من قاعدة البيانات.

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

لتحديث مصفوفة من النماذج، استخدم `map` + `flatten`.

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TOOD
```

## الاستعلام

تكشف النماذج طريقة ثابتة `query(on:)` تُعيد بانيَ الاستعلام (query builder).

```swift
Planet.query(on: database).all()
```

تعرّف على المزيد حول الاستعلام في قسم [الاستعلام](query.md).

## البحث (Find)

تحتوي النماذج على طريقة ثابتة `find(_:on:)` للبحث عن نسخة نموذج بواسطة المعرّف.

```swift
Planet.find(req.parameters.get("id"), on: database)
```

تُعيد هذه الطريقة `nil` إذا لم يُعثر على أي نموذج بذلك المعرّف.

## دورة الحياة (Lifecycle)

تتيح لك وسائط النموذج (model middleware) الارتباط بأحداث دورة حياة نموذجك. أحداث دورة الحياة التالية مدعومة.

|الطريقة|الوصف|
|-|-|
|`create`|تُنفَّذ قبل إنشاء نموذج.|
|`update`|تُنفَّذ قبل تحديث نموذج.|
|`delete(force:)`|تُنفَّذ قبل حذف نموذج.|
|`softDelete`|تُنفَّذ قبل الحذف الناعم لنموذج.|
|`restore`|تُنفَّذ قبل استعادة نموذج (عكس الحذف الناعم).|

تُعلَن وسائط النموذج باستخدام بروتوكول `ModelMiddleware` أو `AsyncModelMiddleware`. لجميع طرق دورة الحياة تنفيذ افتراضي، لذا ما عليك سوى تنفيذ الطرق التي تحتاجها. تقبل كل طريقة النموذج المعني، ومرجعًا إلى قاعدة البيانات، والإجراء التالي في السلسلة. يمكن للوسيط اختيار الإرجاع مبكرًا، أو إرجاع future فاشل، أو استدعاء الإجراء التالي للمتابعة بشكل طبيعي.

باستخدام هذه الطرق يمكنك تنفيذ إجراءات قبل وبعد اكتمال الحدث المحدّد. يمكن تنفيذ الإجراءات بعد اكتمال الحدث من خلال تحويل (map) الـ future المُعاد من المستجيب التالي.

```swift
// Example middleware that capitalizes names.
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // The model can be altered here before it is created.
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // Once the planet has been created, the code 
            // here will be executed.
            print ("Planet \(model.name) was created")
        }
    }
}
```

أو إذا كنت تستخدم `async`/`await`:

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyAsyncModelResponder) async throws {
        // The model can be altered here before it is created.
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // Once the planet has been created, the code 
        // here will be executed.
        print ("Planet \(model.name) was created")
    }
}
```

بمجرد إنشاء الوسيط الخاص بك، يمكنك تفعيله باستخدام `app.databases.middleware`.

```swift
// Example of configuring model middleware.
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## مساحة قاعدة البيانات (Database Space)

يدعم Fluent تعيين مساحة (space) لنموذج، مما يتيح تقسيم نماذج Fluent الفردية بين مخططات PostgreSQL وقواعد بيانات MySQL وقواعد بيانات SQLite المتعددة المرفقة. لا يدعم MongoDB المساحات في وقت كتابة هذا. لوضع نموذج في مساحة غير الافتراضية، أضف خاصية ثابتة جديدة إلى النموذج:

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

سيستخدم Fluent هذا عند بناء جميع استعلامات قاعدة البيانات.
