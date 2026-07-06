# التوجيه

التوجيه هو عملية إيجاد معالج الطلب المناسب لطلب وارد. في صميم توجيه Vapor يوجد موجّه عالي الأداء قائم على عقد الـ trie من [RoutingKit](https://github.com/vapor/routing-kit).

## نظرة عامة

لفهم كيفية عمل التوجيه في Vapor، ينبغي أن تفهم أولًا بعض الأساسيات حول طلبات HTTP. ألقِ نظرة على مثال الطلب التالي.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

هذا طلب HTTP بسيط من نوع `GET` إلى المسار `/hello/vapor`. هذا هو نوع طلب HTTP الذي سيُصدره متصفّحك إذا وجّهته إلى المسار التالي.

```
http://vapor.codes/hello/vapor
```

### طريقة HTTP

الجزء الأول من الطلب هو طريقة HTTP. `GET` هي أكثر طرق HTTP شيوعًا، لكن هناك عدة طرق ستستخدمها كثيرًا. غالبًا ما تُقرَن طرق HTTP هذه بدلالات [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|الطريقة|CRUD|
|-|-|
|`GET`|قراءة|
|`POST`|إنشاء|
|`PUT`|استبدال|
|`PATCH`|تحديث|
|`DELETE`|حذف|

### مسار الطلب

مباشرةً بعد طريقة HTTP يأتي معرّف URI للطلب. يتكوّن هذا من مسار يبدأ بـ `/` وسلسلة استعلام اختيارية بعد `?`. طريقة HTTP والمسار هما ما يستخدمه Vapor لتوجيه الطلبات.

بعد الـ URI يأتي إصدار HTTP يتبعه صفر أو أكثر من الترويسات (headers) وأخيرًا جسم (body). ولأن هذا طلب `GET`، فليس له جسم.

### دوال الموجّه

لنلقِ نظرة على كيفية معالجة هذا الطلب في Vapor.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

جميع طرق HTTP الشائعة متاحة كدوال على `Application`. تقبل هذه الدوال وسيطًا نصيًا واحدًا أو أكثر تمثّل مسار الطلب مفصولةً بـ `/`.

لاحظ أنه يمكنك أيضًا كتابة هذا باستخدام `on` متبوعةً بالطريقة.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

مع تسجيل هذا المسار، سيؤدي مثال طلب HTTP من الأعلى إلى استجابة HTTP التالية.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### مُعامِلات المسار

الآن بعد أن وجّهنا طلبًا بنجاح استنادًا إلى طريقة HTTP والمسار، لنجرّب جعل المسار ديناميكيًا. لاحظ أن الاسم "vapor" مُدمَج بشكل ثابت في كل من المسار والاستجابة. لنجعل هذا ديناميكيًا بحيث يمكنك زيارة `/hello/<any name>` والحصول على استجابة.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

باستخدام مكوّن مسار مسبوق بـ `:`، نُشير إلى الموجّه بأن هذا مكوّن ديناميكي. أي نص يُزوَّد هنا سيطابق الآن هذا المسار. يمكننا بعد ذلك استخدام `req.parameters` للوصول إلى قيمة النص.

إذا شغّلت مثال الطلب مرة أخرى، فسيظلّ يصلك ردّ يقول hello إلى vapor. ومع ذلك، يمكنك الآن تضمين أي اسم بعد `/hello/` ورؤيته مُضمَّنًا في الاستجابة. لنجرّب `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

الآن بعد أن فهمت الأساسيات، اطّلع على كل قسم لتتعلّم المزيد عن المُعامِلات والمجموعات وغيرها.

## المسارات

يحدّد المسار معالج طلب لطريقة HTTP ومسار URI معيّنين. يمكنه أيضًا تخزين بيانات وصفية (metadata) إضافية.

### الطرق

يمكن تسجيل المسارات مباشرةً في `Application` الخاص بك باستخدام مساعِدات طرق HTTP المتنوّعة.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

تدعم معالِجات المسارات إرجاع أي شيء يتوافق مع `ResponseEncodable`. يشمل هذا `Content`، ومغلّفًا (closure) من نوع `async`، وأي `EventLoopFuture` تكون فيه قيمة الـ future متوافقة مع `ResponseEncodable`.

يمكنك تحديد نوع الإرجاع لمسار باستخدام `-> T` قبل `in`. قد يكون هذا مفيدًا في الحالات التي لا يستطيع فيها المُصرِّف (compiler) تحديد نوع الإرجاع.

```swift
app.get("foo") { req -> String in
    return "bar"
}
```

هذه هي دوال مساعِدات المسارات المدعومة:

- `get`
- `post`
- `patch`
- `put`
- `delete`

بالإضافة إلى مساعِدات طرق HTTP، هناك دالة `on` تقبل طريقة HTTP كمُعامِل إدخال.

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
    ...
}
```

### مكوّن المسار

تقبل كل دالة تسجيل مسار قائمةً متغيّرة الطول (variadic) من `PathComponent`. يمكن التعبير عن هذا النوع بنص حرفي (string literal) وله أربع حالات:

- ثابت (`foo`)
- مُعامِل (`:foo`)
- أي شيء (`*`)
- مُلتقِط الكل (`**`)

#### ثابت

هذا مكوّن مسار ساكن. يُسمَح فقط للطلبات التي تحمل نصًا مطابقًا تمامًا في هذا الموضع.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

#### مُعامِل

هذا مكوّن مسار ديناميكي. يُسمَح بأي نص في هذا الموضع. يُحدَّد مكوّن المسار من نوع المُعامِل ببادئة `:`. سيُستخدم النص الذي يلي `:` كاسم للمُعامِل. يمكنك استخدام الاسم لاحقًا لجلب قيمة المُعامِل من الطلب.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
    ...
}
```

#### أي شيء

هذا مشابه جدًا للمُعامِل باستثناء أن القيمة تُهمَل. يُحدَّد مكوّن المسار هذا بـ `*` فقط.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
    ...
}
```

#### مُلتقِط الكل

هذا مكوّن مسار ديناميكي يطابق مكوّنًا واحدًا أو أكثر. يُحدَّد بـ `**` فقط. أي نص في هذا الموضع أو المواضع اللاحقة سيُطابَق في الطلب.

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### المُعامِلات

عند استخدام مكوّن مسار من نوع المُعامِل (مسبوق بـ `:`)، ستُخزَّن قيمة الـ URI في ذلك الموضع في `req.parameters`. يمكنك استخدام اسم مكوّن المسار للوصول إلى القيمة.

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip "نصيحة"
    يمكننا أن نكون متأكّدين من أن `req.parameters.get` لن يُرجِع أبدًا `nil` هنا لأن مسار مسارنا يتضمّن `:name`. ومع ذلك، إذا كنت تصل إلى مُعامِلات المسار في وسيطة أو في شيفرة تُشغَّل بواسطة عدة مسارات، فستحتاج إلى التعامل مع احتمال `nil`.

!!! tip "نصيحة"
    إذا أردت استرجاع مُعامِلات استعلام URL، مثل `/hello/?name=foo` فستحتاج إلى استخدام واجهات Content البرمجية في Vapor للتعامل مع البيانات المُرمَّزة بترميز URL في سلسلة استعلام الـ URL. انظر [مرجع `Content`](content.md) لمزيد من التفاصيل.

كما يدعم `req.parameters.get` تحويل المُعامِل تلقائيًا إلى الأنواع المتوافقة مع `LosslessStringConvertible`.

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
    guard let int = req.parameters.get("x", as: Int.self) else {
        throw Abort(.badRequest)
    }
    return "\(int) is a great number"
}
```

ستُخزَّن قيم الـ URI التي يطابقها مُلتقِط الكل (`**`) في `req.parameters` بصفتها `[String]`. يمكنك استخدام `req.parameters.getCatchall` للوصول إلى تلك المكوّنات.

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### بثّ الجسم (Body Streaming)

عند تسجيل مسار باستخدام الدالة `on`، يمكنك تحديد كيفية التعامل مع جسم الطلب. افتراضيًا، تُجمَّع أجسام الطلبات في الذاكرة قبل استدعاء معالجك. هذا مفيد لأنه يتيح فكّ ترميز محتوى الطلب بشكل متزامن رغم أن تطبيقك يقرأ الطلبات الواردة بشكل غير متزامن.

افتراضيًا، سيحدّ Vapor جمع جسم البثّ إلى حجم 16KB. يمكنك ضبط هذا باستخدام `app.routes`.

```swift
// Increases the streaming body collection limit to 500kb
app.routes.defaultMaxBodySize = "500kb"
```

إذا تجاوز جسم بثّ قيد الجمع الحدّ المضبوط، فسيُرمى خطأ `413 Payload Too Large`.

لضبط استراتيجية جمع جسم الطلب لمسار فردي، استخدم المُعامِل `body`.

```swift
// Collects streaming bodies (up to 1mb in size) before calling this route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request. 
}
```

إذا مُرِّر `maxSize` إلى `collect`، فسيتجاوز الإعداد الافتراضي للتطبيق لذلك المسار. لاستخدام الإعداد الافتراضي للتطبيق، احذف الوسيط `maxSize`.

بالنسبة إلى الطلبات الكبيرة، مثل رفع الملفات، فإن جمع جسم الطلب في مخزن مؤقت (buffer) قد يُجهِد ذاكرة نظامك. لمنع جمع جسم الطلب، استخدم استراتيجية `stream`.

```swift
// Request body will not be collected into a buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

عندما يُبَثّ جسم الطلب، ستكون `req.body.data` مساوية لـ `nil`. يجب أن تستخدم `req.body.drain` للتعامل مع كل جزء (chunk) أثناء إرساله إلى مسارك.

### التوجيه غير الحسّاس لحالة الأحرف

السلوك الافتراضي للتوجيه حسّاس لحالة الأحرف ومُحافِظ عليها في آنٍ واحد. يمكن بدلًا من ذلك التعامل مع مكوّنات المسار من نوع `Constant` بطريقة غير حسّاسة لحالة الأحرف ومُحافِظة عليها لأغراض التوجيه؛ لتفعيل هذا السلوك، اضبطه قبل بدء تشغيل التطبيق:
```swift
app.routes.caseInsensitive = true
```
لا تُجرى أي تغييرات على الطلب الأصلي؛ ستستقبل معالِجات المسارات مكوّنات مسار الطلب دون تعديل.


### عرض المسارات

يمكنك الوصول إلى مسارات تطبيقك عبر استخدام خدمة `Routes` أو باستخدام `app.routes`.

```swift
print(app.routes.all) // [Route]
```

يأتي Vapor أيضًا مع أمر `routes` يطبع جميع المسارات المتاحة في جدول مُنسَّق بترميز ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### البيانات الوصفية

تُرجِع جميع دوال تسجيل المسارات الـ `Route` المُنشأ. يتيح لك هذا إضافة بيانات وصفية إلى قاموس `userInfo` الخاص بالمسار. هناك بعض الدوال الافتراضية المتاحة، مثل إضافة وصف.

```swift
app.get("hello", ":name") { req in
    ...
}.description("says hello")
```

## مجموعات المسارات

يتيح لك تجميع المسارات إنشاء مجموعة من المسارات تحمل بادئة مسار أو وسيطة معيّنة. يدعم التجميع صياغةً قائمة على الباني (builder) وأخرى قائمة على المغلّف (closure).

تُرجِع جميع دوال التجميع `RouteBuilder` مما يعني أنه يمكنك المزج والمطابقة والتداخل بلا حدود بين مجموعاتك ودوال بناء المسارات الأخرى.

### بادئة المسار

تتيح لك مجموعات المسارات ذات بادئة المسار إضافة مكوّن مسار واحد أو أكثر في مقدمة مجموعة من المسارات.

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

يمكن تمرير أي مكوّن مسار قابل للتمرير إلى دوال مثل `get` أو `post` إلى `grouped`. هناك صياغة بديلة قائمة على المغلّف أيضًا.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

يتيح لك تداخل مجموعات المسارات ذات بادئة المسار تعريف واجهات CRUD البرمجية باختصار.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### الوسيطة

بالإضافة إلى إضافة مكوّنات مسار كبادئة، يمكنك أيضًا إضافة وسيطة إلى مجموعات المسارات.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


هذا مفيد بشكل خاص لحماية مجموعات فرعية من مساراتك بوسيطة مصادقة مختلفة.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## عمليات إعادة التوجيه

عمليات إعادة التوجيه مفيدة في عدد من السيناريوهات، مثل توجيه المواقع القديمة إلى الجديدة من أجل SEO، أو إعادة توجيه مستخدم غير مُصادَق عليه إلى صفحة تسجيل الدخول، أو الحفاظ على التوافق العكسي مع الإصدار الجديد من واجهتك البرمجية.

لإعادة توجيه طلب، استخدم:

```swift
req.redirect(to: "/some/new/path")
```

يمكنك أيضًا تحديد نوع إعادة التوجيه، على سبيل المثال لإعادة توجيه صفحة بشكل دائم (حتى يُحدَّث SEO الخاص بك بشكل صحيح) استخدم:

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

أنواع `Redirect` المختلفة هي:

* `.permanent` - تُرجِع إعادة توجيه **301 Permanent**.
* `.normal` - تُرجِع إعادة توجيه **303 see other**. هذا هو الافتراضي في Vapor ويُخبِر العميل باتّباع إعادة التوجيه بطلب **GET**.
* `.temporary` - تُرجِع إعادة توجيه **307 Temporary**. يُخبِر هذا العميل بالحفاظ على طريقة HTTP المستخدمة في الطلب.

> لاختيار رمز حالة إعادة التوجيه المناسب، اطّلع على [القائمة الكاملة](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
