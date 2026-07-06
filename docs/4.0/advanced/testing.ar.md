# الاختبار

## VaporTesting

يتضمن Vapor وحدة تُسمى `VaporTesting` توفر مساعدات اختبار مبنية على `Swift Testing`. تتيح لك مساعدات الاختبار هذه إرسال طلبات اختبارية إلى تطبيق Vapor لديك برمجيًا أو عبر التشغيل على خادم HTTP.

!!! note "ملاحظة"
    للمشاريع الأحدث أو الفِرَق التي تتبنى التزامن (concurrency) في Swift، يُوصى بشدة باستخدام `Swift Testing` بدلًا من `XCTest`.

### البدء

لاستخدام وحدة `VaporTesting`، تأكد من إضافتها إلى هدف الاختبار (test target) في حزمتك.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning "تحذير"
    تأكد من استخدام وحدة الاختبار المقابلة، لأن عدم القيام بذلك قد يؤدي إلى عدم الإبلاغ بشكل صحيح عن إخفاقات اختبارات Vapor.

ثم، أضف `import VaporTesting` و`import Testing` في أعلى ملفات الاختبار لديك. أنشئ هياكل (structs) باسم `@Suite` لكتابة حالات الاختبار.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // Test here.
    }
}
```

ستُشغَّل كل دالة موسومة بـ `@Test` تلقائيًا عند اختبار تطبيقك.

لضمان تشغيل اختباراتك بطريقة تسلسلية (على سبيل المثال، عند الاختبار مع قاعدة بيانات)، ضمّن الخيار `.serialized` في تصريح مجموعة الاختبار:

```swift
@Suite("App Tests with DB", .serialized)
```

### تطبيق قابل للاختبار

لتوفير إعداد وتفكيك مبسّطين وموحّدين للاختبارات، تقدم `VaporTesting` الدالة المساعدة `withApp`. تُغلِّف هذه الطريقة إدارة دورة حياة نسخة `Application`، مما يضمن تهيئة التطبيق وإعداده وإيقاف تشغيله بشكل صحيح لكل اختبار.

مرّر طريقة `configure(_:)` الخاصة بتطبيقك إلى الدالة المساعدة `withApp` للتأكد من تسجيل جميع مساراتك بشكل صحيح:

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### إرسال طلب

لإرسال طلب اختباري إلى تطبيقك، استخدم الطريقة الخاصة `withApp` وداخلها استخدم الطريقة `app.testing().test()`:

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

المعاملان الأولان هما طريقة HTTP وعنوان URL المطلوب. تقبل المُغلِّفة الختامية (trailing closure) استجابة HTTP التي يمكنك التحقق منها باستخدام الماكرو `#expect`.

للطلبات الأكثر تعقيدًا، يمكنك تزويد مُغلِّفة `beforeRequest` لتعديل الترويسات (headers) أو ترميز المحتوى. تتوفر [واجهة برمجة تطبيقات المحتوى (Content API)](../basics/content.md) الخاصة بـ Vapor على كل من الطلب والاستجابة الاختباريين.

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### طريقة الاختبار

تدعم واجهة برمجة تطبيقات الاختبار في Vapor إرسال الطلبات الاختبارية برمجيًا وعبر خادم HTTP مباشر. يمكنك تحديد الطريقة التي ترغب في استخدامها من خلال الطريقة `testing`.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

يُستخدم الخيار `inMemory` افتراضيًا.

يدعم الخيار `running` تمرير منفذ (port) محدد لاستخدامه. يُستخدم `8080` افتراضيًا.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### اختبارات تكامل قاعدة البيانات

اضبط قاعدة البيانات خصيصًا للاختبار لضمان عدم استخدام قاعدة بياناتك المباشرة أبدًا أثناء الاختبارات. على سبيل المثال، عند استخدام SQLite، يمكنك ضبط قاعدة بياناتك في الدالة `configure(_:)` كما يلي:

```swift
public func configure(_ app: Application) async throws {
    // All other configurations...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning "تحذير"
    تأكد من تشغيل اختباراتك مقابل قاعدة البيانات الصحيحة، حتى تمنع الكتابة فوق بيانات لا تريد فقدانها عن طريق الخطأ.

ثم يمكنك تعزيز اختباراتك باستخدام `autoMigrate()` و`autoRevert()` لإدارة مخطط قاعدة البيانات ودورة حياة البيانات أثناء الاختبار. للقيام بذلك، يجب أن تنشئ دالتك المساعدة الخاصة `withAppIncludingDB` التي تتضمن دورات حياة مخطط قاعدة البيانات والبيانات:

```swift
private func withAppIncludingDB(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

ثم استخدم هذه المساعدة في اختباراتك:
```swift
@Test func myDatabaseIntegrationTest() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
} 
```

بالجمع بين هذه الطرق، يمكنك ضمان أن يبدأ كل اختبار بحالة قاعدة بيانات جديدة ومتسقة، مما يجعل اختباراتك أكثر موثوقية ويقلل من احتمالية النتائج الإيجابية أو السلبية الكاذبة الناتجة عن البيانات المتبقية.


## XCTVapor

يتضمن Vapor وحدة تُسمى `XCTVapor` توفر مساعدات اختبار مبنية على `XCTest`. تتيح لك مساعدات الاختبار هذه إرسال طلبات اختبارية إلى تطبيق Vapor لديك برمجيًا أو عبر التشغيل على خادم HTTP.

### البدء

لاستخدام وحدة `XCTVapor`، تأكد من إضافتها إلى هدف الاختبار (test target) في حزمتك.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

ثم، أضف `import XCTVapor` في أعلى ملفات الاختبار لديك. أنشئ أصنافًا (classes) تُوسِّع `XCTestCase` لكتابة حالات الاختبار.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

ستُشغَّل كل دالة تبدأ بـ `test` تلقائيًا عند اختبار تطبيقك.

### تطبيق قابل للاختبار

هيّئ نسخة من `Application` باستخدام البيئة `.testing`. يجب استدعاء `app.shutdown()` قبل أن تُلغى تهيئة هذا التطبيق.

الإيقاف ضروري للمساعدة في تحرير الموارد التي طالب بها التطبيق. على وجه الخصوص، من المهم تحرير الخيوط (threads) التي يطلبها التطبيق عند بدء التشغيل. إذا لم تستدعِ `shutdown()` على التطبيق بعد كل اختبار وحدة (unit test)، فقد تجد مجموعة اختباراتك تنهار مع فشل شرط مسبق (precondition failure) عند تخصيص الخيوط لنسخة جديدة من `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

مرّر `Application` إلى طريقة `configure(_:)` الخاصة بحزمتك لتطبيق إعدادك. يمكن تطبيق أي إعدادات خاصة بالاختبار فقط بعد ذلك.

#### إرسال طلب

لإرسال طلب اختباري إلى تطبيقك، استخدم الطريقة `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

المعاملان الأولان هما طريقة HTTP وعنوان URL المطلوب. تقبل المُغلِّفة الختامية (trailing closure) استجابة HTTP التي يمكنك التحقق منها باستخدام طرق `XCTAssert`.

للطلبات الأكثر تعقيدًا، يمكنك تزويد مُغلِّفة `beforeRequest` لتعديل الترويسات (headers) أو ترميز المحتوى. تتوفر [واجهة برمجة تطبيقات المحتوى (Content API)](../basics/content.md) الخاصة بـ Vapor على كل من الطلب والاستجابة الاختباريين.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### الطريقة القابلة للاختبار

تدعم واجهة برمجة تطبيقات الاختبار في Vapor إرسال الطلبات الاختبارية برمجيًا وعبر خادم HTTP مباشر. يمكنك تحديد الطريقة التي ترغب في استخدامها باستخدام الطريقة `testable`.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

يُستخدم الخيار `inMemory` افتراضيًا.

يدعم الخيار `running` تمرير منفذ (port) محدد لاستخدامه. يُستخدم `8080` افتراضيًا.

```swift
.running(port: 8123)
```
