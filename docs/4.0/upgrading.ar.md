# الترقية إلى 4.0

يوضح لك هذا الدليل كيفية ترقية مشروع Vapor 3.x موجود إلى 4.x. يحاول هذا الدليل تغطية جميع حزم Vapor الرسمية بالإضافة إلى بعض المزوّدين شائعي الاستخدام. إذا لاحظت أي شيء مفقود، فإن [محادثة فريق Vapor](https://discord.gg/vapor) مكان رائع لطلب المساعدة. كما أن المشكلات وطلبات السحب (pull requests) موضع تقدير أيضاً.

## الاعتماديات

لاستخدام Vapor 4، ستحتاج إلى Xcode 11.4 وmacOS 10.15 أو أحدث.

يتناول قسم التثبيت في الوثائق تثبيت الاعتماديات.

## Package.swift

الخطوة الأولى للترقية إلى Vapor 4 هي تحديث اعتماديات حزمتك. فيما يلي مثال على ملف Package.swift مُرقّى. يمكنك أيضاً الاطّلاع على [قالب Package.swift](https://github.com/vapor/template/blob/main/Package.swift) المحدّث.

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

جميع الحزم التي تمت ترقيتها لـ Vapor 4 سيزداد رقم إصدارها الرئيسي بمقدار واحد.

!!! warning "تحذير"
    يُستخدم مُعرّف الإصدار المسبق `-rc` لأن بعض حزم Vapor 4 لم تُصدر رسمياً بعد.

### الحزم القديمة

أُهملت بعض حزم Vapor 3، مثل:

- `vapor/auth`: مُضمّنة الآن في Vapor.
- `vapor/core`: استُوعبت في عدة وحدات.
- `vapor/crypto`: استُبدلت بـ SwiftCrypto (مُضمّنة الآن في Vapor).
- `vapor/multipart`: مُضمّنة الآن في Vapor.
- `vapor/url-encoded-form`: مُضمّنة الآن في Vapor.
- `vapor-community/vapor-ext`: مُضمّنة الآن في Vapor.
- `vapor-community/pagination`: أصبحت الآن جزءاً من Fluent.
- `IBM-Swift/LoggerAPI`: استُبدلت بـ SwiftLog.

### اعتمادية Fluent

يجب الآن إضافة `vapor/fluent` كاعتمادية منفصلة إلى قائمة اعتمادياتك وأهدافك. تمت إضافة اللاحقة `-driver` إلى جميع الحزم الخاصة بقواعد البيانات لتوضيح الاعتماد على `vapor/fluent`.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### المنصّات

تدعم بيانات حزمة Vapor الآن صراحةً macOS 10.15 وأحدث. وهذا يعني أن حزمتك ستحتاج أيضاً إلى تحديد دعم المنصّة.

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

قد يضيف Vapor منصّات مدعومة إضافية في المستقبل. قد تدعم حزمتك أي مجموعة فرعية من هذه المنصّات طالما أن رقم الإصدار يساوي أو يزيد على الحد الأدنى لمتطلبات إصدار Vapor.

### Xcode

يستخدم Vapor 4 دعم SPM الأصلي في Xcode 11. وهذا يعني أنك لن تحتاج بعد الآن إلى توليد ملفات `.xcodeproj`. سيؤدي فتح مجلد مشروعك في Xcode إلى التعرّف تلقائياً على SPM وسحب الاعتماديات.

يمكنك فتح مشروعك أصلياً في Xcode باستخدام `vapor xcode` أو `open Package.swift`.

بمجرد تحديث Package.swift، قد تحتاج إلى إغلاق Xcode ومسح المجلدات التالية من الدليل الجذري:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

بمجرد حل الحزم المحدّثة بنجاح، من المفترض أن ترى أخطاء المُصرّف (compiler)—على الأرجح عدداً كبيراً منها. لا تقلق! سنوضح لك كيفية إصلاحها.

## Run

أول ما يجب فعله هو تحديث ملف `main.swift` الخاص بوحدة Run إلى التنسيق الجديد.

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

يحل محتوى ملف `main.swift` محل ملف `app.swift` الخاص بوحدة App، لذا يمكنك حذف ذلك الملف.

## App 

لنلقِ نظرة على كيفية تحديث الهيكل الأساسي لوحدة App.

### configure.swift

يجب تغيير طريقة `configure` لقبول نسخة من `Application`.

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

فيما يلي مثال على طريقة configure محدّثة.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Serves files from `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure migrations
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

تُذكر أدناه تغييرات بناء الجملة لتكوين أشياء مثل التوجيه (routing) والبرمجيات الوسيطة (middleware) وfluent والمزيد.

### boot.swift

يمكن وضع محتوى `boot` في طريقة `configure` لأنها تقبل الآن نسخة التطبيق.

### routes.swift

يجب تغيير طريقة `routes` لقبول نسخة من `Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

يُذكر أدناه مزيد من المعلومات حول التغييرات في بناء جملة التوجيه.

## الخدمات (Services)

جرى تبسيط واجهات API الخاصة بخدمات Vapor 4 لتسهيل اكتشافك للخدمات واستخدامها. تُكشف الخدمات الآن كطرق وخصائص على `Application` و`Request`، مما يسمح للمُصرّف بمساعدتك في استخدامها.

لفهم هذا بشكل أفضل، لنلقِ نظرة على بعض الأمثلة.

```diff
// Change the server's default port to 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

بدلاً من تسجيل `NIOServerConfig` في الخدمات، يُكشف تكوين الخادم الآن كخصائص بسيطة على Application يمكن تجاوزها.

```diff
// Register cors middleware
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Create _empty_ middleware config
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

بدلاً من إنشاء `MiddlewareConfig` وتسجيلها في الخدمات، تُكشف البرمجيات الوسيطة الآن كخاصية على Application يمكن الإضافة إليها.

```diff
// Make a request in a route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

مثل Application، يكشف Request أيضاً الخدمات كخصائص وطرق بسيطة. يجب دائماً استخدام الخدمات الخاصة بالطلب عندما تكون داخل مُغلَّف مسار (route closure).

يحل نمط الخدمة الجديد هذا محل أنواع `Container` و`Service` و`Config` من Vapor 3.

### المزوّدون (Providers)

لم تعد المزوّدون مطلوبين لتكوين حزم الطرف الثالث. بدلاً من ذلك، تُوسّع كل حزمة Application وRequest بخصائص وطرق جديدة للتكوين.

اطّلع على كيفية تكوين Leaf في Vapor 4.

```diff
// Use Leaf for view rendering. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

لتكوين Leaf، استخدم الخاصية `app.leaf`.

```diff
// Disable Leaf view caching.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### البيئة (Environment)

يمكن الوصول إلى البيئة الحالية (production، development، إلخ) عبر `app.environment`.

### الخدمات المخصّصة (Custom Services)

يمكن الآن التعبير عن الخدمات المخصّصة المطابقة لبروتوكول `Service` والمسجّلة في الحاوية (container) في Vapor 3 كامتدادات لـ Application أو Request.

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

يمكن بعد ذلك الوصول إلى هذه الخدمة باستخدام الامتداد بدلاً من `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### المزوّدون المخصّصون (Custom Providers)

يمكن تنفيذ معظم الخدمات المخصّصة باستخدام الامتدادات كما هو موضّح في القسم السابق. ومع ذلك، قد تحتاج بعض المزوّدين المتقدمين إلى الارتباط بدورة حياة التطبيق أو استخدام خصائص مخزّنة.

يمكن استخدام مساعد `Lifecycle` الجديد الخاص بـ Application لتسجيل معالجات دورة الحياة.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

لتخزين قيم على Application، يمكنك استخدام مساعد `Storage` الجديد.

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

يمكن تغليف الوصول إلى `app.storage` في خاصية محسوبة قابلة للتعيين (settable computed property) لإنشاء واجهة API موجزة.

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

يكشف Vapor 4 الآن واجهات API غير المتزامنة (async) الخاصة بـ SwiftNIO مباشرةً ولا يحاول التحميل الزائد (overload) لطرق مثل `map` و`flatMap` أو إنشاء أسماء مستعارة (alias) لأنواع مثل `EventLoopFuture`. قدّم Vapor 3 تحميلات زائدة وأسماء مستعارة للتوافق العكسي مع إصدارات بيتا المبكرة التي صدرت قبل وجود SwiftNIO. أُزيلت هذه للحد من الالتباس مع الحزم الأخرى المتوافقة مع SwiftNIO ولاتّباع توصيات أفضل الممارسات الخاصة بـ SwiftNIO بشكل أفضل.

### تغييرات تسمية Async

التغيير الأكثر وضوحاً هو إزالة الاسم المستعار `Future` لـ `EventLoopFuture`. يمكن إصلاح هذا بسهولة إلى حد ما باستخدام البحث والاستبدال.

علاوةً على ذلك، لا يدعم NIO تسميات `to:` التي أضافها Vapor 3. نظراً لتحسّن استنتاج النوع (type inference) في Swift 5.2، أصبحت `to:` أقل ضرورة الآن على أي حال.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

الطرق المسبوقة بـ `new`، مثل `newPromise`، جرى تغييرها إلى `make` لتناسب أسلوب Swift بشكل أفضل.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

لم تعد `catchMap` متاحة، لكن طرق NIO مثل `mapError` و`flatMapErrorThrowing` ستعمل بدلاً منها.

لم تعد طريقة `flatMap` العامة (global) الخاصة بـ Vapor 3 لدمج عدة futures متاحة. يمكن استبدال هذا باستخدام طريقة `and` الخاصة بـ NIO لدمج العديد من futures معاً.

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

العديد من الطرق والخصائص التي كانت تستخدم `Data` سابقاً تستخدم الآن `ByteBuffer` الخاص بـ NIO. هذا النوع هو نوع تخزين بايت أكثر قوةً وأداءً. يمكنك قراءة المزيد حول واجهة API الخاصة به في [وثائق ByteBuffer الخاصة بـ SwiftNIO](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

لتحويل `ByteBuffer` مرة أخرى إلى `Data`، استخدم:

```swift
Data(buffer.readableBytesView)
```

### طرح الأخطاء في map / flatMap (Throwing map / flatMap)

التغيير الأصعب هو أن `map` و`flatMap` لم يعد بإمكانهما طرح الأخطاء (throw). تمتلك `map` نسخة قادرة على الطرح تُسمّى (بشكل مربك نوعاً ما) `flatMapThrowing`. أما `flatMap` فليس لها نظير قادر على الطرح. قد يتطلب هذا منك إعادة هيكلة بعض الكود غير المتزامن.

الطرق map التي _لا_ تطرح الأخطاء ينبغي أن تستمر في العمل بشكل جيد.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

يجب إعادة تسمية طرق map التي _تطرح_ الأخطاء إلى `flatMapThrowing`.

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

الطرق flat-map التي _لا_ تطرح الأخطاء ينبغي أن تستمر في العمل بشكل جيد.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

بدلاً من طرح خطأ داخل flat-map، أعِد future يحمل الخطأ. إذا نشأ الخطأ من طريقة أخرى قادرة على الطرح، فيمكن التقاط الخطأ في do / catch وإعادته كـ future.

```swift
// Returning a caught error as a future.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

يمكن أيضاً إعادة هيكلة استدعاءات الطرق القادرة على الطرح إلى `flatMapThrowing` وربطها باستخدام الصفوف (tuples).

```swift
// Refactored throwing method into flatMapThrowing with tuple-chaining.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result is the value of doSomething.
    return futureB
}
```

## التوجيه (Routing)

تُسجّل المسارات الآن مباشرةً في Application.

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

وهذا يعني أنك لم تعد بحاجة إلى تسجيل مُوجّه (router) في الخدمات. ما عليك سوى تمرير التطبيق إلى طريقة `routes` الخاصة بك والبدء في إضافة المسارات. جميع الطرق المتاحة على `RoutesBuilder` متاحة على `Application`.

### المحتوى المتزامن (Synchronous Content)

أصبح فك ترميز محتوى الطلب الآن متزامناً.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

يمكن تجاوز هذا السلوك بتسجيل المسارات باستخدام استراتيجية تجميع الجسم `.stream`.

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Request body is now asynchronous.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### المسارات المفصولة بفواصل (Comma-separated paths)

يجب الآن فصل المسارات بفواصل وألا تحتوي على `/` لأجل الاتساق.

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### معاملات المسار (Route parameters)

أُزيل بروتوكول `Parameter` لصالح المعاملات المسمّاة صراحةً. يمنع هذا مشاكل المعاملات المكرّرة والجلب غير المرتّب للمعاملات في البرمجيات الوسيطة ومعالجات المسارات.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

يُذكر استخدام معاملات المسار مع النماذج في قسم Fluent.

## البرمجيات الوسيطة (Middleware)

أُعيدت تسمية `MiddlewareConfig` إلى `MiddlewareConfiguration` وأصبحت الآن خاصية على Application. يمكنك إضافة برمجيات وسيطة إلى تطبيقك باستخدام `app.middleware`.

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

لم يعد بالإمكان تسجيل البرمجيات الوسيطة باسم النوع. هيّئ البرمجية الوسيطة أولاً قبل تسجيلها.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

لإزالة جميع البرمجيات الوسيطة الافتراضية، عيّن `app.middleware` إلى تكوين فارغ باستخدام:

```swift
app.middleware = .init()
```

## Fluent

أصبحت واجهة API الخاصة بـ Fluent الآن مستقلة عن قاعدة البيانات (database agnostic). يمكنك استيراد `Fluent` فقط.

```diff
- import FluentMySQL
+ import Fluent
```

### النماذج (Models)

تستخدم جميع النماذج الآن بروتوكول `Model` ويجب أن تكون أصنافاً (classes).

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

تُعلن جميع الحقول باستخدام مُغلِّفات الخصائص `@Field` أو `@OptionalField`.

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

يجب تعريف مُعرّف (ID) النموذج باستخدام مُغلِّف الخاصية `@ID`.

```diff
+ @ID(key: .id)
var id: UUID?
```

يجب على النماذج التي تستخدم مُعرّفاً بمفتاح أو نوع مخصّص استخدام `@ID(custom:)`.

يجب أن يكون لجميع النماذج اسم جدولها أو مجموعتها معرّفاً بشكل ثابت (statically).

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

يجب أن يكون لجميع النماذج الآن مُهيّئ فارغ. بما أن جميع الخصائص تستخدم مُغلِّفات الخصائص، فيمكن أن يكون هذا فارغاً.

```diff
final class Planet: Model {
+   init() { }
}
```

لم تعد طرق `save` و`update` و`create` الخاصة بالنموذج تعيد نسخة النموذج.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

لم يعد بالإمكان استخدام النماذج كمكوّنات مسار (route path components). استخدم `find` و`req.parameters.get` بدلاً من ذلك.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

أُعيدت تسمية `Model.ID` إلى `Model.IDValue`.

تُعلن طوابع النموذج الزمنية (timestamps) الآن باستخدام مُغلِّف الخاصية `@Timestamp`.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### العلاقات (Relations)

تُعرّف العلاقات الآن باستخدام مُغلِّفات الخصائص.

تستخدم علاقات الأصل (Parent) مُغلِّف الخاصية `@Parent` وتحتوي على خاصية الحقل داخلياً. يجب أن يكون المفتاح المُمرّر إلى `@Parent` هو اسم الحقل الذي يخزّن المُعرّف في قاعدة البيانات.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

تستخدم علاقات الأبناء (Children) مُغلِّف الخاصية `@Children` مع مسار مفتاح (key path) إلى `@Parent` المرتبط.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

تستخدم علاقات الأشقاء (Siblings) مُغلِّف الخاصية `@Siblings` مع مسارات مفاتيح إلى النموذج المحوري (pivot model).

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

النماذج المحورية (Pivots) هي الآن نماذج عادية تطابق `Model` مع علاقتَي `@Parent` وصفر أو أكثر من الحقول الإضافية.

### الاستعلام (Query)

يُوصل الآن إلى سياق قاعدة البيانات عبر `req.db` في معالجات المسارات.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

أُعيدت تسمية `DatabaseConnectable` إلى `Database`.

تُسبق مسارات المفاتيح إلى الحقول الآن بـ `$` لتحديد مُغلِّف الخاصية بدلاً من قيمة الحقل.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### الهجرات (Migrations)

لم تعد النماذج تدعم الهجرات التلقائية القائمة على الانعكاس (reflection). يجب كتابة جميع الهجرات يدوياً.

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

أصبحت الهجرات الآن ذات أنواع نصية (stringly typed) ومنفصلة عن النماذج وتستخدم بروتوكول `Migration`.

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

لم تعد طريقتا `prepare` و`revert` ثابتتين (static).

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

يُنشأ باني المخطط (schema builder) عبر طريقة نسخة (instance method) على `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

تُستدعى طرق `create` و`update` و`delete` الآن على باني المخطط بشكل مشابه لكيفية عمل باني الاستعلام (query builder).

أصبحت تعريفات الحقول الآن ذات أنواع نصية وتتّبع النمط:

```swift
field(<name>, <type>, <constraints>)
```

انظر المثال أدناه.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

يمكن الآن ربط بناء المخطط بشكل متسلسل مثل باني الاستعلام.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### تكوين Fluent (Fluent Configuration)

استُبدلت `DatabasesConfig` بـ `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

استُبدلت `MigrationsConfig` بـ `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### المستودعات (Repositories)

بما أن طريقة عمل الخدمات في Vapor 4 قد تغيّرت، فهذا يعني أيضاً أن طريقة عمل مستودعات قاعدة البيانات قد تغيّرت. لا تزال بحاجة إلى بروتوكول مثل `UserRepository`، لكن بدلاً من جعل `final class` يطابق ذلك البروتوكول، يجب أن تصنع `struct` بدلاً من ذلك.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

يجب عليك أيضاً إزالة المطابقة لـ `ServiceType` لأنه لم يعد موجوداً في Vapor 4.
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

بدلاً من ذلك، يجب عليك إنشاء `UserRepositoryFactory`:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
هذا المصنع (factory) مسؤول عن إعادة `UserRepository` لـ `Request`.

الخطوة التالية هي إضافة امتداد إلى `Application` لتحديد مصنعك:
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

لاستخدام المستودع الفعلي داخل `Request`، أضف هذا الامتداد إلى `Request`:
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

الخطوة الأخيرة هي تحديد المصنع داخل `configure.swift`
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

يمكنك الآن الوصول إلى مستودعك في معالجات المسارات باستخدام: `req.users.all()` واستبدال المصنع بسهولة داخل الاختبارات.
إذا كنت تريد استخدام مستودع محاكى (mocked) داخل الاختبارات، فأنشئ أولاً `TestUserRepository`
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

يمكنك الآن استخدام هذا المستودع المحاكى داخل اختباراتك على النحو التالي:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
