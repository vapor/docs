# العلاقات

تساعدك [واجهة برمجة النماذج](model.md) في Fluent على إنشاء المراجع بين نماذجك والحفاظ عليها من خلال العلاقات. يدعم Fluent ثلاثة أنواع من العلاقات:

- [Parent](#parent) / [Child](#optional-child) (واحد لواحد)
- [Parent](#parent) / [Children](#children) (واحد لمتعدد)
- [Siblings](#siblings) (متعدد لمتعدد)

## Parent

تُخزّن علاقة `@Parent` مرجعًا إلى خاصية `@ID` الخاصة بنموذج آخر.

```swift
final class Planet: Model {
    // Example of a parent relation.
    @Parent(key: "star_id")
    var star: Star
}
```

تحتوي `@Parent` على `@Field` باسم `id` يُستخدم لتعيين العلاقة وتحديثها.

```swift
// Set parent relation id
earth.$star.id = sun.id
```

على سبيل المثال، سيبدو مُهيّئ `Planet` كالتالي:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

يحدّد المُعامل `key` مفتاح الحقل الذي يُستخدم لتخزين مُعرّف النموذج الأب. بافتراض أن `Star` يمتلك مُعرّفًا من نوع `UUID`، فإن علاقة `@Parent` هذه متوافقة مع [تعريف الحقل](schema.md#الحقل) التالي.

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

لاحظ أن قيد [`.references`](schema.md#قيد-الحقل) اختياري. راجع [المخطط](schema.md) لمزيد من المعلومات.

### Optional Parent

تُخزّن علاقة `@OptionalParent` مرجعًا اختياريًا إلى خاصية `@ID` الخاصة بنموذج آخر. تعمل بشكل مماثل لـ `@Parent` لكنها تسمح بأن تكون العلاقة `nil`.

```swift
final class Planet: Model {
    // Example of an optional parent relation.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

تعريف الحقل مشابه لتعريف `@Parent` باستثناء أنه يجب حذف القيد `.required`.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### ترميز النماذج الأب وفك ترميزها

من الأمور التي يجب الانتباه إليها عند التعامل مع علاقات `@Parent` هي طريقة إرسالها واستقبالها. على سبيل المثال، في JSON، قد تبدو `@Parent` لنموذج `Planet` كالتالي:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

لاحظ كيف أن خاصية `star` هي كائن بدلًا من المُعرّف الذي قد تتوقعه. عند إرسال النموذج كجسم HTTP، يجب أن يطابق هذا الشكل حتى يعمل فك الترميز. لهذا السبب، نوصي بشدة باستخدام DTO لتمثيل النموذج عند إرساله عبر الشبكة. على سبيل المثال:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

بعد ذلك يمكنك فك ترميز الـ DTO وتحويله إلى نموذج:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

ينطبق الأمر نفسه عند إرجاع النموذج إلى العملاء. إما أن يكون عملاؤك قادرين على التعامل مع البنية المتداخلة، أو تحتاج إلى تحويل النموذج إلى DTO قبل إرجاعه. لمزيد من المعلومات حول الـ DTOs، راجع [توثيق النماذج](model.md#كائن-نقل-البيانات-data-transfer-object)

## Optional Child

تنشئ الخاصية `@OptionalChild` علاقة واحد لواحد بين النموذجين. لا تُخزّن أي قيم على النموذج الجذر.

```swift
final class Planet: Model {
    // Example of an optional child relation.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

يقبل المُعامل `for` مسار مفتاح إلى علاقة `@Parent` أو `@OptionalParent` تشير إلى النموذج الجذر.

يمكن إضافة نموذج جديد إلى هذه العلاقة باستخدام الطريقة `create`.

```swift
// Example of adding a new model to a relation.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

سيؤدي هذا إلى تعيين مُعرّف النموذج الأب على النموذج الابن تلقائيًا.

بما أن هذه العلاقة لا تُخزّن أي قيم، فلا يلزم وجود مُدخل في مخطط قاعدة البيانات للنموذج الجذر.

يجب فرض طبيعة العلاقة واحد لواحد في مخطط النموذج الابن باستخدام قيد `.unique` على العمود الذي يشير إلى النموذج الأب.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Example of unique constraint
    .unique(on: "planet_id")
    .create()
```
!!! warning "تحذير"
    قد يؤدي حذف قيد التفرّد على حقل مُعرّف النموذج الأب من مخطط العميل إلى نتائج غير متوقعة.
    في حال عدم وجود قيد تفرّد، قد ينتهي الأمر بجدول الابن إلى احتوائه على أكثر من صف ابن لأي نموذج أب معيّن؛ في هذه الحالة، لن تتمكن خاصية `@OptionalChild` إلا من الوصول إلى ابن واحد في كل مرة، دون أي وسيلة للتحكم في أي ابن يتم تحميله. إذا كنت قد تحتاج إلى تخزين صفوف أبناء متعددة لأي نموذج أب معيّن، فاستخدم `@Children` بدلًا من ذلك.

## Children

تنشئ الخاصية `@Children` علاقة واحد لمتعدد بين نموذجين. لا تُخزّن أي قيم على النموذج الجذر.

```swift
final class Star: Model {
    // Example of a children relation.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

يقبل المُعامل `for` مسار مفتاح إلى علاقة `@Parent` أو `@OptionalParent` تشير إلى النموذج الجذر. في هذه الحالة، نشير إلى علاقة `@Parent` من [المثال](#parent) السابق.

يمكن إضافة نماذج جديدة إلى هذه العلاقة باستخدام الطريقة `create`.

```swift
// Example of adding a new model to a relation.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

سيؤدي هذا إلى تعيين مُعرّف النموذج الأب على النموذج الابن تلقائيًا.

بما أن هذه العلاقة لا تُخزّن أي قيم، فلا يلزم وجود مُدخل في مخطط قاعدة البيانات.

## Siblings

تنشئ الخاصية `@Siblings` علاقة متعدد لمتعدد بين نموذجين. تفعل ذلك من خلال نموذج ثالث يُسمى المحور (pivot).

لنلقِ نظرة على مثال لعلاقة متعدد لمتعدد بين `Planet` و`Tag`.

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

يمكن استخدام أي نموذج يتضمّن علاقتين `@Parent` على الأقل، واحدة لكل نموذج تُراد ربطه، كمحور. قد يحتوي النموذج على خصائص إضافية، مثل مُعرّفه، وقد يحتوي حتى على علاقات `@Parent` أخرى.

يمكن أن تساعد إضافة قيد [التفرّد](schema.md#unique) إلى نموذج المحور في منع المُدخلات المكررة. راجع [المخطط](schema.md) لمزيد من المعلومات.

```swift
// Disallows duplicate relations.
.unique(on: "planet_id", "tag_id")
```

بمجرد إنشاء المحور، استخدم الخاصية `@Siblings` لإنشاء العلاقة.

```swift
final class Planet: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

تتطلّب الخاصية `@Siblings` ثلاثة مُعاملات:

- `through`: نوع نموذج المحور.
- `from`: مسار المفتاح من المحور إلى علاقة النموذج الأب التي تشير إلى النموذج الجذر.
- `to`: مسار المفتاح من المحور إلى علاقة النموذج الأب التي تشير إلى النموذج المرتبط.

تُكمِل خاصية `@Siblings` العكسية على النموذج المرتبط العلاقة.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### إرفاق النماذج الشقيقة

تمتلك الخاصية `@Siblings` طرقًا لإضافة النماذج إلى العلاقة وإزالتها منها.

استخدم الطريقة `attach()` لإضافة نموذج واحد أو مصفوفة من النماذج إلى العلاقة. تُنشأ نماذج المحور وتُحفظ تلقائيًا حسب الحاجة. يمكن تحديد إغلاق (closure) للاستدعاء الراجع لتعبئة خصائص إضافية لكل محور يُنشأ:

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

عند إرفاق نموذج واحد، يمكنك استخدام المُعامل `method` لاختيار ما إذا كان يجب التحقق من العلاقة قبل الحفظ أم لا.

```swift
// Only attaches if the relation doesn't already exist.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

استخدم الطريقة `detach` لإزالة نموذج من العلاقة. يؤدي هذا إلى حذف نموذج المحور المقابل.

```swift
// Removes the model from the relation.
try await earth.$tags.detach(inhabited, on: database)
```

يمكنك التحقق مما إذا كان النموذج مرتبطًا أم لا باستخدام الطريقة `isAttached`.

```swift
// Checks if the models are related.
earth.$tags.isAttached(to: inhabited)
```

## Get

استخدم الطريقة `get(on:)` لجلب قيمة علاقة.

```swift
// Fetches all of the sun's planets.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Or

let planets = try await sun.$planets.get(on: database)
print(planets)
```

استخدم المُعامل `reload` لاختيار ما إذا كان يجب إعادة جلب العلاقة من قاعدة البيانات إذا كانت قد حُمّلت بالفعل أم لا.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

استخدم الطريقة `query(on:)` على علاقة لإنشاء مُنشئ استعلام (query builder) للنماذج المرتبطة.

```swift
// Fetch all of the sun's planets that have a naming starting with M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

راجع [الاستعلام](query.md) لمزيد من المعلومات.

## التحميل المسبق

يسمح لك مُنشئ الاستعلام في Fluent بتحميل علاقات النموذج مسبقًا عند جلبه من قاعدة البيانات. يُسمى هذا التحميل المسبق ويتيح لك الوصول إلى العلاقات بشكل متزامن دون الحاجة إلى استدعاء [`get`](#get) أولًا.

للتحميل المسبق لعلاقة، مرّر مسار مفتاح إلى العلاقة عبر الطريقة `with` على مُنشئ الاستعلام.

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

في المثال أعلاه، يُمرّر مسار مفتاح إلى علاقة [`@Parent`](#parent) المُسمّاة `star` إلى `with`. يؤدي هذا إلى قيام مُنشئ الاستعلام بتنفيذ استعلام إضافي بعد تحميل جميع الكواكب لجلب جميع النجوم المرتبطة بها. تصبح النجوم بعد ذلك قابلة للوصول بشكل متزامن عبر خاصية `@Parent`.

تتطلّب كل علاقة يتم تحميلها مسبقًا استعلامًا إضافيًا واحدًا فقط، بغض النظر عن عدد النماذج المُرجعة. التحميل المسبق ممكن فقط مع طريقتي `all` و`first` في مُنشئ الاستعلام.


### التحميل المسبق المتداخل

تتيح لك الطريقة `with` في مُنشئ الاستعلام تحميل العلاقات مسبقًا على النموذج الذي يجري الاستعلام عنه. ومع ذلك، يمكنك أيضًا تحميل العلاقات مسبقًا على النماذج المرتبطة.

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

تقبل الطريقة `with` إغلاقًا (closure) اختياريًا كمُعامل ثانٍ. يقبل هذا الإغلاق مُنشئ تحميل مسبق للعلاقة المختارة. لا يوجد حد لمدى عمق تداخل التحميل المسبق.

## التحميل المسبق الكسول

في حال كنت قد استرجعت النموذج الأب بالفعل وأردت تحميل إحدى علاقاته، يمكنك استخدام الطريقة `get(reload:on:)` لهذا الغرض. سيجلب هذا النموذج المرتبط من قاعدة البيانات (أو من الذاكرة المؤقتة، إن وُجدت) ويتيح الوصول إليه كخاصية محلية.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Or

try await planet.$star.get(on: database)
print(planet.star.name)
```

في حال أردت التأكد من أن البيانات التي تتلقاها لا تُسحب من الذاكرة المؤقتة، استخدم المُعامل `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

للتحقق مما إذا كانت العلاقة قد حُمّلت أم لا، استخدم الخاصية `value`.

```swift
if planet.$star.value != nil {
    // Relation has been loaded.
    print(planet.star.name)
} else {
    // Relation has not been loaded.
    // Attempting to access planet.star will fail.
}
```

إذا كان لديك النموذج المرتبط بالفعل في متغيّر، فيمكنك تعيين العلاقة يدويًا باستخدام الخاصية `value` المذكورة أعلاه.

```swift
planet.$star.value = star
```

سيؤدي هذا إلى إرفاق النموذج المرتبط بالنموذج الأب كما لو كان قد حُمّل مسبقًا أو حُمّل بشكل كسول دون استعلام إضافي لقاعدة البيانات.
