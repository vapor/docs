# غير متزامن

## Async Await

قدّم Swift 5.5 التزامن إلى اللغة على شكل `async`/`await`. يوفّر هذا طريقة من الدرجة الأولى للتعامل مع الشيفرة غير المتزامنة في تطبيقات Swift وVapor.

بُني Vapor فوق [SwiftNIO](https://github.com/apple/swift-nio.git)، الذي يوفّر أنواعًا أوّلية للبرمجة غير المتزامنة منخفضة المستوى. وقد كانت هذه الأنواع (ولا تزال) مستخدمة في جميع أنحاء Vapor قبل وصول `async`/`await`. ومع ذلك، يمكن الآن كتابة معظم شيفرة التطبيق باستخدام `async`/`await` بدلاً من استخدام `EventLoopFuture`. سيؤدي هذا إلى تبسيط شيفرتك وجعل استيعابها أسهل بكثير.

تقدّم معظم واجهات Vapor البرمجية الآن كلًا من نسختي `EventLoopFuture` و`async`/`await` لتختار أيّهما أفضل. بوجه عام، ينبغي أن تستخدم نموذج برمجة واحدًا فقط لكل معالج مسار وألّا تخلط بينهما في شيفرتك. أما التطبيقات التي تحتاج إلى تحكّم صريح في حلقات الأحداث، أو التطبيقات عالية الأداء جدًا، فينبغي أن تستمر في استخدام `EventLoopFuture` حتى تُنفَّذ المُنفِّذات المخصّصة (custom executors). وبالنسبة إلى الجميع، ينبغي أن تستخدم `async`/`await` لأن فوائد سهولة القراءة وقابلية الصيانة تفوق بكثير أي عقوبة أداء بسيطة.

### الانتقال إلى async/await

هناك بضع خطوات لازمة للانتقال إلى async/await. بدايةً، إذا كنت تستخدم macOS فيجب أن تكون على macOS 12 Monterey أو أحدث وXcode 13.1 أو أحدث. أما بالنسبة إلى المنصّات الأخرى فتحتاج إلى تشغيل Swift 5.5 أو أحدث. بعد ذلك، تأكّد من أنك حدّثت جميع اعتمادياتك (dependencies).

في ملف Package.swift الخاص بك، اضبط إصدار الأدوات على 5.5 في أعلى الملف:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

بعد ذلك، اضبط إصدار المنصّة على macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

أخيرًا، حدّث الهدف `Run` لتمييزه كهدف قابل للتنفيذ:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

ملاحظة: إذا كنت تنشر على Linux فتأكّد من تحديث إصدار Swift هناك أيضًا، مثلًا على Heroku أو في ملف Dockerfile الخاص بك. على سبيل المثال، سيتغيّر ملف Dockerfile الخاص بك إلى:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

يمكنك الآن نقل الشيفرة الموجودة. بوجه عام، فإن الدوال التي كانت تُرجِع `EventLoopFuture` أصبحت الآن `async`. على سبيل المثال:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

تصبح الآن:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### التعامل مع الواجهات البرمجية القديمة والجديدة

إذا صادفت واجهات برمجية لا تقدّم بعد نسخة `async`/`await`، فيمكنك استدعاء `.get()` على دالة تُرجِع `EventLoopFuture` لتحويلها.

على سبيل المثال:

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

يمكن أن تصبح

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

وإذا احتجت إلى الاتجاه المعاكس، فيمكنك تحويل

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

إلى

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`

ربما لاحظت أن بعض الواجهات البرمجية في Vapor تتوقّع أو تُرجِع نوع `EventLoopFuture` العام. إذا كانت هذه هي المرة الأولى التي تسمع فيها عن الـ futures، فقد تبدو مربكة قليلًا في البداية. لكن لا تقلق، سيوضّح لك هذا الدليل كيفية الاستفادة من واجهاتها البرمجية القوية.

الـ promises والـ futures أنواع مترابطة لكنها متمايزة. تُستخدم الـ promises _لإنشاء_ الـ futures. في معظم الأوقات، ستعمل مع الـ futures التي تُرجِعها واجهات Vapor البرمجية ولن تحتاج إلى القلق بشأن إنشاء الـ promises.

|النوع|الوصف|قابلية التعديل|
|-|-|-|
|`EventLoopFuture`|مرجع إلى قيمة قد لا تكون متاحة بعد.|للقراءة فقط|
|`EventLoopPromise`|وعد بتوفير قيمة ما بشكل غير متزامن.|للقراءة/الكتابة|

الـ futures بديل للواجهات البرمجية غير المتزامنة القائمة على ردّ النداء (callback). يمكن ربط الـ futures وتحويلها بطرق لا تستطيعها المغلّفات (closures) البسيطة.

## التحويل

تمامًا مثل الأنواع الاختيارية (optionals) والمصفوفات في Swift، يمكن تطبيق `map` و`flat-map` على الـ futures. هذه هي أكثر العمليات شيوعًا التي ستجريها على الـ futures.

|الدالة|الوسيط|الوصف|
|-|-|-|
|[`map`](#map)|`(T) -> U`|تُطبِّق قيمة future على قيمة مختلفة.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|تُطبِّق قيمة future على قيمة مختلفة أو على خطأ.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|تُطبِّق قيمة future على قيمة _future_ مختلفة.|
|[`transform`](#transform)|`U`|تُطبِّق future على قيمة متاحة بالفعل.|

إذا نظرت إلى توقيعات الدوال `map` و`flatMap` على `Optional<T>` و`Array<T>`، فسترى أنها مشابهة جدًا للدوال المتاحة على `EventLoopFuture<T>`.

### map

تتيح لك الدالة `map` تحويل قيمة الـ future إلى قيمة أخرى. ولأن قيمة الـ future قد لا تكون متاحة بعد (قد تكون نتيجة مهمة غير متزامنة) فيجب أن نوفّر مغلّفًا (closure) لاستقبال القيمة.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

تتيح لك الدالة `flatMapThrowing` تحويل قيمة الـ future إلى قيمة أخرى _أو_ رمي خطأ.

!!! info "معلومة"
    لأن رمي خطأ يجب أن يُنشئ future جديدًا داخليًا، فإن هذه الدالة تحمل البادئة `flatMap` رغم أن المغلّف لا يقبل إرجاع future.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

تتيح لك الدالة `flatMap` تحويل قيمة الـ future إلى قيمة future أخرى. وقد سُمّيت "flat" map لأنها ما يتيح لك تجنّب إنشاء futures متداخلة (مثل `EventLoopFuture<EventLoopFuture<T>>`). بعبارة أخرى، تساعدك على إبقاء أنواعك العامة (generics) مسطّحة.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info "معلومة"
    لو استخدمنا `map` بدلًا من ذلك في المثال أعلاه، لانتهى بنا الأمر إلى: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

لاستدعاء دالة قابلة لرمي الأخطاء داخل `flatMap`، استخدم كلمتي `do` / `catch` المفتاحيتين في Swift وأنشئ [future مكتملًا](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

تتيح لك الدالة `transform` تعديل قيمة الـ future، متجاهلةً القيمة الموجودة. هذا مفيد بشكل خاص لتحويل نتائج `EventLoopFuture<Void>` حيث لا تكون القيمة الفعلية للـ future مهمة.

!!! tip "نصيحة"
    إن `EventLoopFuture<Void>`، الذي يُسمّى أحيانًا إشارة (signal)، هو future غرضه الوحيد إعلامك باكتمال عملية غير متزامنة ما أو بفشلها.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

رغم أننا زوّدنا `transform` بقيمة متاحة بالفعل، فإن هذا لا يزال _تحويلًا_. لن يكتمل الـ future حتى تكتمل (أو تفشل) جميع الـ futures السابقة.

### الربط المتسلسل

الجزء الرائع في التحويلات على الـ futures هو أنها يمكن ربطها متسلسلةً. يتيح لك هذا التعبير عن العديد من التحويلات والمهام الفرعية بسهولة.

لنعدّل الأمثلة السابقة لنرى كيف يمكننا الاستفادة من الربط المتسلسل.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

بعد الاستدعاء الأول لـ map، يُنشأ `EventLoopFuture<URL>` مؤقت. ثم يُطبَّق على هذا الـ future مباشرةً flat-map ليصبح `EventLoopFuture<Response>`.
    
## Future

لنلقِ نظرة على بعض الدوال الأخرى لاستخدام `EventLoopFuture<T>`.

### makeFuture

يمكنك استخدام حلقة أحداث لإنشاء future مكتمل مسبقًا إما بالقيمة وإما بخطأ.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


يمكنك استخدام `whenComplete` لإضافة ردّ نداء (callback) يُنفَّذ عند نجاح الـ future أو فشله.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note "ملاحظة"
    يمكنك إضافة أي عدد تريده من ردود النداء إلى future.

### Get

في حال عدم وجود بديل قائم على التزامن لواجهة برمجية، يمكنك انتظار قيمة الـ future باستخدام `try await future.get()`.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Wait for the string to be ready
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! warning "تحذير"
    الدالة `wait()` مهجورة، انظر [`Get`](#get) للاطّلاع على النهج الموصى به.

يمكنك استخدام `.wait()` للانتظار بشكل متزامن حتى يكتمل الـ future. ولأن الـ future قد يفشل، فإن هذا الاستدعاء قابل لرمي الأخطاء.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

يمكن استخدام `wait()` فقط على خيط في الخلفية أو على الخيط الرئيسي، أي في `configure.swift`. ولا يمكن استخدامها على خيط حلقة أحداث، أي في مغلّفات المسارات.

!!! warning "تحذير"
    محاولة استدعاء `wait()` على خيط حلقة أحداث ستؤدي إلى فشل توكيد (assertion failure).
    
## Promise

في معظم الأوقات، ستقوم بتحويل الـ futures التي تُرجِعها استدعاءات واجهات Vapor البرمجية. ومع ذلك، قد تحتاج في مرحلة ما إلى إنشاء promise خاص بك.

لإنشاء promise، ستحتاج إلى الوصول إلى `EventLoop`. يمكنك الوصول إلى حلقة أحداث من `Application` أو `Request` بحسب السياق.

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info "معلومة"
    يمكن إكمال الـ promise مرة واحدة فقط. أي عمليات إكمال لاحقة ستُتجاهَل.

يمكن إكمال الـ promises (`succeed` / `fail`) من أي خيط. لهذا السبب تتطلّب الـ promises تهيئة حلقة أحداث. تضمن الـ promises أن يُعاد فعل الإكمال إلى حلقة أحداثها للتنفيذ.

## Event Loop

عند إقلاع تطبيقك، سيُنشئ عادةً حلقة أحداث واحدة لكل نواة في وحدة المعالجة المركزية التي يعمل عليها. لكل حلقة أحداث خيط واحد بالضبط. إذا كنت معتادًا على حلقات الأحداث من Node.js، فإن الحلقات في Vapor مشابهة لها. الفرق الرئيسي هو أن Vapor يمكنه تشغيل عدة حلقات أحداث في عملية واحدة لأن Swift يدعم تعدّد الخيوط.

في كل مرة يتّصل فيها عميل بخادمك، سيُسنَد إلى إحدى حلقات الأحداث. من تلك اللحظة فصاعدًا، ستحدث جميع الاتصالات بين الخادم وذلك العميل على حلقة الأحداث نفسها (وبالتبعية، على خيط حلقة الأحداث تلك).

حلقة الأحداث مسؤولة عن تتبّع حالة كل عميل متّصل. إذا كان هناك طلب من العميل ينتظر القراءة، فإن حلقة الأحداث تُطلق إشعار قراءة، مما يؤدي إلى قراءة البيانات. وبمجرد قراءة الطلب بأكمله، ستكتمل أي futures تنتظر بيانات ذلك الطلب.

في مغلّفات المسارات، يمكنك الوصول إلى حلقة الأحداث الحالية عبر `Request`.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning "تحذير"
    يتوقّع Vapor أن تبقى مغلّفات المسارات على `req.eventLoop`. إذا انتقلت بين الخيوط، فيجب أن تضمن أن الوصول إلى `Request` وإلى future الاستجابة النهائية يحدث بالكامل على حلقة أحداث الطلب.

خارج مغلّفات المسارات، يمكنك الحصول على إحدى حلقات الأحداث المتاحة عبر `Application`.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

يمكنك تغيير حلقة أحداث future باستخدام `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## الحجب (Blocking)

استدعاء شيفرة حاجبة (blocking) على خيط حلقة أحداث يمكن أن يمنع تطبيقك من الاستجابة للطلبات الواردة في الوقت المناسب. مثال على الاستدعاء الحاجب هو شيء مثل `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

إن `sleep(_:)` أمر يحجب الخيط الحالي لعدد الثواني المزوَّد. إذا قمت بعمل حاجب كهذا مباشرةً على حلقة أحداث، فلن تتمكّن حلقة الأحداث من الاستجابة لأي عملاء آخرين مُسنَدين إليها طوال مدة العمل الحاجب. بعبارة أخرى، إذا قمت بـ `sleep(5)` على حلقة أحداث، فسيتأخّر جميع العملاء الآخرين المتّصلين بتلك الحلقة (ربما مئات أو آلاف) لمدة 5 ثوانٍ على الأقل.

تأكّد من تشغيل أي عمل حاجب في الخلفية. استخدم الـ promises لإعلام حلقة الأحداث عند انتهاء هذا العمل بطريقة غير حاجبة.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

ليست جميع الاستدعاءات الحاجبة بوضوح `sleep(_:)`. إذا اشتبهت في أن استدعاءً تستخدمه قد يكون حاجبًا، فابحث في الدالة نفسها أو اسأل أحدهم. تتناول الأقسام أدناه كيف يمكن للدوال أن تحجب بمزيد من التفصيل.

### مقيَّد بالإدخال/الإخراج (I/O Bound)

يعني الحجب المقيَّد بالإدخال/الإخراج الانتظار على مورد بطيء مثل الشبكة أو القرص الصلب، وهو ما قد يكون أبطأ بمراتب من وحدة المعالجة المركزية. حجب وحدة المعالجة المركزية بينما تنتظر هذه الموارد يؤدي إلى إهدار الوقت.

!!! danger "خطر"
    لا تُجرِ أبدًا استدعاءات حاجبة مقيَّدة بالإدخال/الإخراج مباشرةً على حلقة أحداث.

جميع حزم Vapor مبنية على SwiftNIO وتستخدم إدخالًا/إخراجًا غير حاجب. ومع ذلك، هناك العديد من حزم Swift ومكتبات C المنتشرة التي تستخدم إدخالًا/إخراجًا حاجبًا. من المرجّح أنه إذا كانت دالة تقوم بإدخال/إخراج على القرص أو الشبكة وتستخدم واجهة برمجية متزامنة (بلا ردود نداء أو futures) فإنها حاجبة.
    
### مقيَّد بوحدة المعالجة المركزية (CPU Bound)

يُقضى معظم الوقت أثناء الطلب في انتظار موارد خارجية مثل استعلامات قاعدة البيانات وطلبات الشبكة لتحميلها. ولأن Vapor وSwiftNIO غير حاجبين، فيمكن استخدام وقت التعطّل هذا لتلبية طلبات واردة أخرى. ومع ذلك، قد تحتاج بعض المسارات في تطبيقك إلى إجراء عمل ثقيل مقيَّد بوحدة المعالجة المركزية نتيجةً لطلب.

بينما تعالج حلقة أحداث عملًا مقيَّدًا بوحدة المعالجة المركزية، فلن تتمكّن من الاستجابة لطلبات واردة أخرى. هذا عادةً لا بأس به لأن وحدات المعالجة المركزية سريعة ومعظم عمل وحدة المعالجة المركزية الذي تقوم به تطبيقات الويب خفيف. لكن هذا قد يصبح مشكلة إذا كانت المسارات ذات عمل وحدة المعالجة المركزية طويل الأمد تمنع الاستجابة السريعة لطلبات المسارات الأسرع.

يمكن أن يساعد تحديد عمل وحدة المعالجة المركزية طويل الأمد في تطبيقك ونقله إلى خيوط في الخلفية على تحسين موثوقية خدمتك واستجابتها. العمل المقيَّد بوحدة المعالجة المركزية منطقة رمادية أكثر من العمل المقيَّد بالإدخال/الإخراج، ويعود إليك في نهاية المطاف تحديد أين تريد رسم الخط.

مثال شائع على العمل الثقيل المقيَّد بوحدة المعالجة المركزية هو تجزئة Bcrypt أثناء تسجيل المستخدم وتسجيل دخوله. Bcrypt بطيء جدًا ومكثّف لوحدة المعالجة المركزية عمدًا لأسباب أمنية. قد يكون هذا أكثر عمل مكثّف لوحدة المعالجة المركزية يقوم به تطبيق ويب بسيط فعليًا. يمكن أن يتيح نقل التجزئة إلى خيط في الخلفية لوحدة المعالجة المركزية تداخل عمل حلقة الأحداث أثناء حساب التجزئات، مما يؤدي إلى تزامن أعلى.
