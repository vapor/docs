# الاستعلام

تتيح لك واجهة برمجة الاستعلام في Fluent إنشاء النماذج وقراءتها وتحديثها وحذفها من قاعدة البيانات. تدعم تصفية النتائج، وعمليات الضم، والتقسيم إلى كتل (chunking)، والتجميعات (aggregates)، والمزيد.

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

ترتبط مُنشئات الاستعلام بنوع نموذج واحد ويمكن إنشاؤها باستخدام الطريقة الساكنة [`query`](model.md#الاستعلام). يمكن أيضًا إنشاؤها بتمرير نوع النموذج إلى الطريقة `query` على كائن قاعدة البيانات.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note "ملاحظة"
    يجب عليك تضمين `import Fluent` في الملف الذي يحتوي على استعلاماتك حتى يتمكن المُترجم من رؤية الدوال المساعدة في Fluent.

## All

تُرجع الطريقة `all()` مصفوفة من النماذج.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

تدعم الطريقة `all` أيضًا جلب حقل واحد فقط من مجموعة النتائج.

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

تُرجع الطريقة `first()` نموذجًا واحدًا اختياريًا. إذا نتج عن الاستعلام أكثر من نموذج، فسيُرجع النموذج الأول فقط. إذا لم يكن للاستعلام أي نتائج، فسيُرجع `nil`.

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip "نصيحة"
    إذا كنت تستخدم `EventLoopFuture`، فيمكن دمج هذه الطريقة مع [`unwrap(or:)`](../basics/errors.md#abort) لإرجاع نموذج غير اختياري أو طرح خطأ.

## Filter

تتيح لك الطريقة `filter` تقييد النماذج المُضمّنة في مجموعة النتائج. هناك عدة تحميلات زائدة (overloads) لهذه الطريقة.

### تصفية القيمة

تقبل الطريقة `filter` الأكثر استخدامًا تعبير مُعامل (operator) مع قيمة.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

تقبل تعبيرات المُعامل هذه مسار مفتاح حقل على الجانب الأيسر وقيمة على الجانب الأيمن. يجب أن تطابق القيمة المُقدّمة نوع القيمة المتوقّع للحقل وتُربط بالاستعلام الناتج. تعبيرات التصفية مكتوبة بأنواع قوية مما يسمح باستخدام صياغة النقطة البادئة (leading-dot).

فيما يلي قائمة بجميع مُعاملات القيمة المدعومة.

|المُعامل|الوصف|
|-|-|
|`==`|يساوي.|
|`!=`|لا يساوي.|
|`>=`|أكبر من أو يساوي.|
|`>`|أكبر من.|
|`<`|أصغر من.|
|`<=`|أصغر من أو يساوي.|

### تصفية الحقل

تدعم الطريقة `filter` مقارنة حقلين.

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

تدعم تصفية الحقل المُعاملات نفسها التي تدعمها [تصفية القيمة](#تصفية-القيمة).

### تصفية المجموعة الفرعية

تدعم الطريقة `filter` التحقق مما إذا كانت قيمة الحقل موجودة ضمن مجموعة معيّنة من القيم.

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

يمكن أن تكون مجموعة القيم المُقدّمة أي `Collection` من Swift يطابق نوع `Element` الخاص بها نوع قيمة الحقل.

فيما يلي قائمة بجميع مُعاملات المجموعة الفرعية المدعومة.

|المُعامل|الوصف|
|-|-|
|`~~`|القيمة موجودة في المجموعة.|
|`!~`|القيمة غير موجودة في المجموعة.|

### تصفية الاحتواء

تدعم الطريقة `filter` التحقق مما إذا كانت قيمة حقل نصي تحتوي على سلسلة فرعية معيّنة.

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

هذه المُعاملات متاحة فقط على الحقول ذات القيم النصية.

فيما يلي قائمة بجميع مُعاملات الاحتواء المدعومة.

|المُعامل|الوصف|
|-|-|
|`~~`|يحتوي على سلسلة فرعية.|
|`!~`|لا يحتوي على سلسلة فرعية.|
|`=~`|يطابق البادئة.|
|`!=~`|لا يطابق البادئة.|
|`~=`|يطابق اللاحقة.|
|`!~=`|لا يطابق اللاحقة.|

### المجموعة

افتراضيًا، سيُشترط تطابق جميع عمليات التصفية المُضافة إلى استعلام. يدعم مُنشئ الاستعلام إنشاء مجموعة من عمليات التصفية حيث يجب أن تتطابق عملية تصفية واحدة فقط.

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

تدعم الطريقة `group` دمج عمليات التصفية بمنطق `and` أو `or`. يمكن تداخل هذه المجموعات إلى ما لا نهاية. يمكن اعتبار عمليات التصفية عالية المستوى موجودة ضمن مجموعة `and`.

## التجميع

يدعم مُنشئ الاستعلام عدة طرق لإجراء العمليات الحسابية على مجموعة من القيم مثل العدّ أو حساب المتوسط.

```swift
// Number of planets in database. 
Planet.query(on: database).count()
```

تتطلّب جميع طرق التجميع باستثناء `count` تمرير مسار مفتاح إلى حقل.

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

فيما يلي قائمة بجميع طرق التجميع المتاحة.

|التجميع|الوصف|
|-|-|
|`count`|عدد النتائج.|
|`sum`|مجموع قيم النتائج.|
|`average`|متوسط قيم النتائج.|
|`min`|أدنى قيمة نتيجة.|
|`max`|أعلى قيمة نتيجة.|

تُرجع جميع طرق التجميع باستثناء `count` نوع قيمة الحقل كنتيجة. تُرجع `count` دائمًا عددًا صحيحًا.

## Chunk

يدعم مُنشئ الاستعلام إرجاع مجموعة النتائج ككتل منفصلة. يساعدك هذا في التحكم في استخدام الذاكرة عند التعامل مع قراءات كبيرة من قاعدة البيانات.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

سيُستدعى الإغلاق (closure) المُقدّم صفر مرة أو أكثر اعتمادًا على العدد الإجمالي للنتائج. كل عنصر مُرجع هو `Result` يحتوي إما على النموذج أو على خطأ نتج عن محاولة فك ترميز مُدخل قاعدة البيانات.

## الحقل

افتراضيًا، ستُقرأ جميع حقول النموذج من قاعدة البيانات بواسطة استعلام. يمكنك اختيار تحديد مجموعة فرعية فقط من حقول النموذج باستخدام الطريقة `field`.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

ستكون أي حقول نموذج لم تُحدّد أثناء الاستعلام في حالة غير مُهيّأة. ستؤدي محاولة الوصول إلى الحقول غير المُهيّأة مباشرة إلى خطأ فادح (fatal error). للتحقق مما إذا كانت قيمة حقل النموذج مُعيّنة، استخدم الخاصية `value`.

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

تؤدي الطريقة `unique` في مُنشئ الاستعلام إلى إرجاع النتائج المميّزة فقط (بدون تكرار).

```swift
// Returns all unique user first names. 
User.query(on: database).unique().all(\.$firstName)
```

تكون `unique` مفيدة بشكل خاص عند جلب حقل واحد باستخدام `all`. ومع ذلك، يمكنك أيضًا تحديد حقول متعددة باستخدام الطريقة [`field`](#الحقل). بما أن مُعرّفات النماذج فريدة دائمًا، فيجب عليك تجنّب تحديدها عند استخدام `unique`.

## Range

تتيح لك طرق `range` في مُنشئ الاستعلام اختيار مجموعة فرعية من النتائج باستخدام نطاقات Swift.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

قيم النطاق هي أعداد صحيحة غير سالبة تبدأ من الصفر. تعرّف على المزيد حول [نطاقات Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
.range(2...)
```

## الضم

تتيح لك الطريقة `join` في مُنشئ الاستعلام تضمين حقول نموذج آخر في مجموعة نتائجك. يمكن ضم أكثر من نموذج واحد إلى استعلامك.

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

يقبل المُعامل `on` تعبير مساواة بين حقلين. يجب أن يكون أحد الحقلين موجودًا بالفعل في مجموعة النتائج الحالية. ويجب أن يكون الحقل الآخر موجودًا في النموذج الذي يجري ضمه. يجب أن يكون لهذه الحقول نوع القيمة نفسه.

تدعم معظم طرق مُنشئ الاستعلام، مثل `filter` و`sort`، النماذج المضمومة. إذا كانت الطريقة تدعم النماذج المضمومة، فستقبل نوع النموذج المضموم كمُعامل أول.

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

ستظل الاستعلامات التي تستخدم عمليات الضم تُرجع مصفوفة من النموذج الأساسي. للوصول إلى النموذج المضموم، استخدم الطريقة `joined`.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### الاسم المستعار للنموذج

تتيح لك الأسماء المستعارة للنماذج ضم النموذج نفسه إلى استعلام عدة مرات. لتعريف اسم مستعار لنموذج، أنشئ نوعًا واحدًا أو أكثر متوافقًا مع `ModelAlias`.

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

تشير هذه الأنواع إلى النموذج الذي يُستعار له الاسم عبر الخاصية `model`. بمجرد إنشائها، يمكنك استخدام الأسماء المستعارة للنماذج مثل النماذج العادية في مُنشئ الاستعلام.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

جميع حقول النموذج قابلة للوصول عبر نوع الاسم المستعار للنموذج بواسطة `@dynamicMemberLookup`.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

يدعم مُنشئ الاستعلام تحديث أكثر من نموذج واحد في المرة الواحدة باستخدام الطريقة `update`.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

تدعم `update` الطرق `set` و`filter` و`range`.

## Delete

يدعم مُنشئ الاستعلام حذف أكثر من نموذج واحد في المرة الواحدة باستخدام الطريقة `delete`.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

تدعم `delete` الطريقة `filter`.

## التصفّح بالصفحات (Paginate)

تدعم واجهة برمجة الاستعلام في Fluent التصفّح التلقائي بالصفحات للنتائج باستخدام الطريقة `paginate`.

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

ستستخدم الطريقة `paginate(for:)` المُعاملين `page` و`per` المتاحين في URI الخاص بالطلب لإرجاع مجموعة النتائج المطلوبة. تُضمّن البيانات الوصفية حول الصفحة الحالية والعدد الإجمالي للنتائج في المفتاح `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

سينتج عن الطلب أعلاه استجابة مُهيكلة كالتالي.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

تبدأ أرقام الصفحات من `1`. يمكنك أيضًا إجراء طلب صفحة يدوي.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

يمكن ترتيب نتائج الاستعلام حسب قيم الحقول باستخدام الطريقة `sort`.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

يمكن إضافة عمليات ترتيب إضافية كخيارات احتياطية في حال التعادل. ستُستخدم الخيارات الاحتياطية بالترتيب الذي أُضيفت به إلى مُنشئ الاستعلام.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
