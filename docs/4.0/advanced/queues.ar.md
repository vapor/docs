# قوائم الانتظار (Queues)

إن Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) هو نظام قوائم انتظار مكتوب بالكامل بلغة Swift يتيح لك نقل مسؤولية المهام إلى عامل جانبي.

بعض المهام التي يعمل معها هذا الحزمة (package) بشكل جيد:

- إرسال رسائل البريد الإلكتروني خارج خيط الطلب الرئيسي
- تنفيذ عمليات قاعدة بيانات معقدة أو طويلة الأمد
- ضمان سلامة المهام ومرونتها
- تسريع زمن الاستجابة عبر تأجيل المعالجة غير الحرجة
- جدولة المهام لتحدث في وقت محدد

هذه الحزمة مشابهة لـ [Ruby Sidekiq](https://github.com/mperham/sidekiq). وهي توفر الميزات التالية:

- معالجة آمنة لإشارات `SIGTERM` و`SIGINT` التي يرسلها مزودو الاستضافة للإشارة إلى إيقاف التشغيل أو إعادة التشغيل أو نشر جديد.
- أولويات مختلفة لقوائم الانتظار. على سبيل المثال، يمكنك تحديد مهمة قائمة انتظار لتُشغَّل على قائمة انتظار البريد الإلكتروني ومهمة أخرى لتُشغَّل على قائمة انتظار معالجة البيانات.
- تنفيذ عملية قائمة انتظار موثوقة للمساعدة في التعامل مع الأعطال غير المتوقعة.
- تتضمن ميزة `maxRetryCount` التي تُكرر المهمة حتى تنجح وصولًا إلى عدد محدد.
- تستخدم NIO للاستفادة من جميع الأنوية المتاحة وحلقات الأحداث (EventLoops) للمهام.
- تتيح للمستخدمين جدولة مهام متكررة

تمتلك Queues حاليًا مُشغِّلًا (driver) واحدًا مدعومًا رسميًا يتفاعل مع البروتوكول الرئيسي:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

كما تمتلك Queues مُشغِّلات مبنية من قِبل المجتمع:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip "نصيحة"
    يجب ألا تُثبّت حزمة `vapor/queues` مباشرةً إلا إذا كنت تبني مُشغِّلًا جديدًا. ثبّت إحدى حزم المُشغِّلات بدلًا من ذلك.

## البدء

لنلقِ نظرة على كيفية البدء في استخدام Queues.

### الحزمة

الخطوة الأولى لاستخدام Queues هي إضافة أحد المُشغِّلات كاعتمادية (dependency) لمشروعك في ملف بيان حزمة SwiftPM. في هذا المثال، سنستخدم مُشغِّل Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Other dependencies
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

إذا قمت بتحرير البيان مباشرةً داخل Xcode، فسيلتقط التغييرات تلقائيًا ويجلب الاعتمادية الجديدة عند حفظ الملف. وإلا، فمن الطرفية (Terminal)، شغّل `swift package resolve` لجلب الاعتمادية الجديدة.

### الإعداد

الخطوة التالية هي إعداد Queues في `configure.swift`. سنستخدم مكتبة Redis كمثال:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### تسجيل `Job`

بعد نمذجة مهمة، يجب إضافتها إلى قسم الإعداد لديك بهذا الشكل:

```swift
// Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### تشغيل العُمّال كعمليات (Processes)

لبدء عامل قائمة انتظار جديد، شغّل `swift run App queues`. يمكنك أيضًا تحديد نوع معين من العُمّال لتشغيله: `swift run App queues --queue emails`.

!!! tip "نصيحة"
    يجب أن يبقى العُمّال قيد التشغيل في بيئة الإنتاج. راجع مزود الاستضافة لديك لمعرفة كيفية إبقاء العمليات طويلة الأمد نشطة. تتيح لك Heroku، على سبيل المثال، تحديد وحدات "worker" (dynos) بهذا الشكل في ملف Procfile لديك: `worker: Run queues`. مع وجود هذا، يمكنك بدء العُمّال من تبويب Dashboard/Resources، أو باستخدام `heroku ps:scale worker=1` (أو أي عدد مفضل من الوحدات).

### تشغيل العُمّال داخل العملية (in-process)

لتشغيل عامل في العملية نفسها التي يعمل بها تطبيقك (بدلًا من بدء خادم منفصل بالكامل للتعامل معه)، استدعِ الطرق المساعدة على `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

لتشغيل المهام المجدولة داخل العملية، استدعِ الطريقة التالية:

```swift
try app.queues.startScheduledJobs()
```

!!! warning "تحذير"
    إذا لم تبدأ عامل قائمة الانتظار سواء عبر سطر الأوامر أو عبر العامل داخل العملية، فلن تُرسَل المهام.

## بروتوكول `Job`

تُعرَّف المهام عبر بروتوكول `Job` أو `AsyncJob`.

### نمذجة كائن `Job`:

```swift
import Vapor
import Foundation
import Queues

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // This is where you would send the email
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
        return context.eventLoop.future()
    }
}
```

إذا كنت تستخدم `async`/`await` فيجب أن تستخدم `AsyncJob`:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // This is where you would send the email
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // If you don't want to handle errors you can simply return. You can also omit this function entirely.
    }
}
```

!!! info "معلومة"
    تأكد من أن نوع `Payload` لديك يطبّق بروتوكول `Codable`.

!!! tip "نصيحة"
    لا تنسَ اتباع التعليمات في **البدء** لإضافة هذه المهمة إلى ملف الإعداد لديك.

## إرسال المهام (Dispatching Jobs)

لإرسال مهمة قائمة انتظار، تحتاج إلى الوصول إلى نسخة من `Application` أو `Request`. على الأرجح ستُرسل المهام داخل معالِج مسار (route handler):

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

إذا كنت بحاجة، بدلًا من ذلك، إلى إرسال مهمة من سياق لا يكون فيه كائن `Request` متاحًا (مثل، على سبيل المثال، من داخل `Command`)، فستحتاج إلى استخدام الخاصية `queues` داخل كائن `Application`، مثل:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message")
            )
    }
}
```

### ضبط `maxRetryCount`

ستُعيد المهام المحاولة تلقائيًا عند حدوث خطأ إذا حددت `maxRetryCount`. على سبيل المثال:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### تحديد تأخير

يمكن أيضًا ضبط المهام لتُشغَّل فقط بعد مرور تاريخ `Date` معين. لتحديد تأخير، مرّر `Date` إلى المعامل `delayUntil` في `dispatch`:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

إذا أُخرجت مهمة من قائمة الانتظار قبل معامل التأخير الخاص بها، فسيُعيد المُشغِّل وضع المهمة في قائمة الانتظار.

### تحديد أولوية

يمكن فرز المهام إلى أنواع/أولويات مختلفة من قوائم الانتظار وفقًا لاحتياجاتك. على سبيل المثال، قد ترغب في فتح قائمة انتظار `email` وقائمة انتظار `background-processing` لفرز المهام.

ابدأ بتوسيع `QueueName`:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

يمكنك أيضًا ضبط `workerCount` لكل قائمة انتظار عند إنشاء `QueueName`:

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

يؤدي ضبط `workerCount: 1` إلى جعل قائمة الانتظار تلك تعالج المهام على التوالي، وهو أمر مفيد عندما يكون ترتيب المهام مهمًا.

ثم، حدد نوع قائمة الانتظار عند استرجاع كائن `jobs`:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

عند الوصول من داخل كائن `Application` يجب أن تفعل كما يلي:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

إذا لم تحدد قائمة انتظار، فستُشغَّل المهمة على قائمة الانتظار `default`. تأكد من اتباع التعليمات في **البدء** لبدء العُمّال لكل نوع من أنواع قوائم الانتظار.

## جدولة المهام

تتيح لك حزمة Queues أيضًا جدولة المهام لتحدث في نقاط زمنية معينة.

!!! warning "تحذير"
    لا تعمل المهام المجدولة إلا عند إعدادها قبل إقلاع التطبيق، مثل في `configure.swift`. لن تعمل في معالِجات المسارات (route handlers).

### بدء عامل المُجدوِل (scheduler)

يتطلب المُجدوِل تشغيل عملية عامل منفصلة، على غرار عامل قائمة الانتظار. يمكنك بدء العامل بتشغيل هذا الأمر:

```sh
swift run App queues --scheduled
```

!!! tip "نصيحة"
    يجب أن يبقى العُمّال قيد التشغيل في بيئة الإنتاج. راجع مزود الاستضافة لديك لمعرفة كيفية إبقاء العمليات طويلة الأمد نشطة. تتيح لك Heroku، على سبيل المثال، تحديد وحدات "worker" (dynos) بهذا الشكل في ملف Procfile لديك: `worker: App queues --scheduled`

### إنشاء `ScheduledJob`

للبدء، ابدأ بإنشاء `ScheduledJob` أو `AsyncScheduledJob` جديد:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Do some work here, perhaps queue up another job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
    }
}
```

ثم، في كود الإعداد لديك، سجّل المهمة المجدولة:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

ستُشغَّل المهمة في المثال أعلاه كل عام في 23 مايو الساعة 12:00 ظهرًا.

!!! tip "نصيحة"
    يأخذ المُجدوِل المنطقة الزمنية لخادمك.

### طرق البناء المتاحة

هناك نمطان من واجهات برمجة تطبيقات المُجدوِل:

- بناة على نمط التقويم (Calendar-style) تُعيد كائنات بناء للتسلسل.
- بناة على نمط الفواصل (Interval-style) تُشغّل المهام كل مدة ثابتة.

يجب أن تستمر في بناء سلسلة مُجدوِل على نمط التقويم حتى لا يعطيك المُترجِم (compiler) تحذيرًا بشأن نتيجة غير مستخدمة. انظر أدناه لجميع الطرق المتاحة:

| الطريقة المساعدة | المُعدِّلات المتاحة                    | الوصف                                                                          |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | الشهر الذي تُشغَّل فيه المهمة. تُعيد كائن `Monthly` لمزيد من البناء.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | اليوم الذي تُشغَّل فيه المهمة. تُعيد كائن `Daily` لمزيد من البناء.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | يوم الأسبوع الذي تُشغَّل فيه المهمة. تُعيد كائن `Daily`.               |
| `daily()`       | `at(_ time: Time)`                    | الوقت الذي تُشغَّل فيه المهمة. الطريقة النهائية في السلسلة.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| الساعة والدقيقة اللتان تُشغَّل فيهما المهمة. الطريقة النهائية في السلسلة.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | الساعة والدقيقة والفترة التي تُشغَّل فيها المهمة. الطريقة النهائية في السلسلة |
| `hourly()`      | `at(_ minute: Minute)`                 | الدقيقة التي تُشغَّل فيها المهمة. الطريقة النهائية في السلسلة.                      |
| `minutely()`    | `at(_ second: Second)`                 | الثانية التي تُشغَّل فيها المهمة. الطريقة النهائية في السلسلة.                      |

### طرق بناء الفواصل (`.every(...)`)

يدعم المُجدوِل أيضًا الجدولة بفواصل ثابتة باستخدام طرق `.every(...)`:

| الطريقة المساعدة | الوصف                                                                          |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | تُشغّل المهمة كل عدد معطى من الثواني.                              |
| `every(minutes: Int)` | تُشغّل المهمة كل عدد معطى من الدقائق.                              |
| `every(hours: Int)`   | تُشغّل المهمة كل عدد معطى من الساعات.                                |
| `every(days: Int)`    | تُشغّل المهمة كل عدد معطى من الأيام.                                 |
| `every(weeks: Int)`   | تُشغّل المهمة كل عدد معطى من الأسابيع.                                |

مثال:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### المساعدات المتاحة

تأتي Queues مع بعض التعدادات المساعدة (helpers enums) لتسهيل الجدولة:

| الطريقة المساعدة | التعداد المساعد المتاح                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

لاستخدام التعداد المساعد، استدعِ المُعدِّل المناسب على الطريقة المساعدة ومرّر القيمة. على سبيل المثال:

```swift
// Every year in January
.yearly().in(.january)

// Every month on the first day
.monthly().on(.first)

// Every week on Sunday
.weekly().on(.sunday)

// Every day at midnight
.daily().at(.midnight)
```

## مُفوَّضو الأحداث (Event Delegates)

تتيح لك حزمة Queues تحديد كائنات `JobEventDelegate` التي ستتلقى إشعارات عندما يتخذ العامل إجراءً على مهمة. يمكن استخدام هذا لأغراض المراقبة، أو استخلاص الرؤى، أو التنبيه.

للبدء، اجعل كائنًا يتوافق مع `JobEventDelegate` وطبّق أي طرق مطلوبة

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Called when the job is dispatched to the queue worker from a route
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job is placed in the processing queue and work begins
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing and has been removed from the queue
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing but had an error
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

ثم، أضفه في ملف الإعداد لديك:

```swift
app.queues.add(MyEventDelegate())
```

هناك عدد من الحزم الخارجية (third-party) التي تستخدم وظيفة المُفوَّض لتوفير رؤية إضافية حول عُمّال قائمة الانتظار لديك:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## الاختبار

لتجنب مشكلات المزامنة وضمان اختبار حتمي، توفر حزمة Queues مكتبة `XCTQueue` ومُشغِّل `AsyncTestQueuesDriver` مخصصًا للاختبار يمكنك استخدامه كما يلي:

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Override the driver being used for testing
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

اطّلع على مزيد من التفاصيل في [تدوينة Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# استكشاف الأخطاء وإصلاحها

عند استخدام [queues-redis-driver](https://github.com/vapor/queues-redis-driver) مع خادم متوافق مع Redis قائم على عنقود (cluster)، مثل Redis أو Valkey على Amazon AWS، قد تصادف رسالة الخطأ هذه: `CROSSSLOT Keys in request don't hash to the same slot`.

يحدث هذا فقط في وضع العنقود، لأن Redis أو Valkey لا يمكنهما التأكد على أي عقدة عنقود (cluster node) سيُخزَّن بيانات المهمة.

لإصلاح هذا، أضف [وسم تجزئة (hash tag)](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) إلى أسماء إدخالات بيانات المهام لديك باستخدام الأقواس المعقوفة في الأسماء:

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
