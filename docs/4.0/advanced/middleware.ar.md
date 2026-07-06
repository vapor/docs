# Middleware

الوسيطة (Middleware) هي سلسلة منطقية بين العميل ومعالج المسار في Vapor. إنها تتيح لك إجراء عمليات على الطلبات الواردة قبل وصولها إلى معالج المسار، وعلى الاستجابات الصادرة قبل ذهابها إلى العميل.

## الإعداد

يمكن تسجيل الوسيطة عالميًا (على كل مسار) داخل `configure(_:)` باستخدام `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

يمكنك أيضًا إضافة وسيطة إلى مسارات فردية باستخدام مجموعات المسارات.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
    // This request has passed through MyMiddleware.
}
```

### الترتيب

الترتيب الذي تُضاف به الوسيطة مهم. الطلبات القادمة إلى تطبيقك ستمر عبر الوسيطة بالترتيب الذي أُضيفت به. الاستجابات المغادرة لتطبيقك ستعود عبر الوسيطة بالترتيب المعكوس. الوسيطة الخاصة بمسار معيّن تُنفَّذ دائمًا بعد وسيطة التطبيق. لنأخذ المثال التالي:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
    $0.get("hello") { req in
        "Hello, middleware."
    }
}
```

سيمرّ الطلب إلى `GET /hello` عبر الوسيطة بالترتيب التالي:

```
Request → A → B → C → Handler → C → B → A → Response
```

يمكن أيضًا _إضافة_ الوسيطة في البداية (prepend)، وهو أمر مفيد عندما تريد إضافة وسيطة _قبل_ الوسيطة الافتراضية التي يضيفها Vapor تلقائيًا:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## إنشاء وسيطة

يأتي Vapor مع بعض الوسائط المفيدة، لكنك قد تحتاج إلى إنشاء وسيطتك الخاصة بسبب متطلبات تطبيقك. على سبيل المثال، يمكنك إنشاء وسيطة تمنع أي مستخدم غير مسؤول (non-admin) من الوصول إلى مجموعة من المسارات.

> نوصي بإنشاء مجلد `Middleware` داخل دليل `Sources/App` لإبقاء شيفرتك منظّمة

الوسائط هي أنواع تتوافق مع بروتوكول `Middleware` أو `AsyncMiddleware` في Vapor. تُدرَج ضمن سلسلة المُستجيبات (responder chain)، ويمكنها الوصول إلى الطلب والتعامل معه قبل وصوله إلى معالج المسار، والوصول إلى الاستجابة والتعامل معها قبل إرجاعها.

باستخدام المثال المذكور أعلاه، أنشئ وسيطة لمنع وصول المستخدم إذا لم يكن مسؤولًا (admin):

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

أو إذا كنت تستخدم `async`/`await` يمكنك كتابة:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

إذا كنت تريد تعديل الاستجابة، على سبيل المثال لإضافة ترويسة مخصّصة، يمكنك استخدام وسيطة لهذا أيضًا. يمكن للوسائط أن تنتظر حتى تُستقبَل الاستجابة من سلسلة المُستجيبات ثم تتعامل مع الاستجابة:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

أو إذا كنت تستخدم `async`/`await` يمكنك كتابة:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

تُمكّن `FileMiddleware` من تقديم الأصول (assets) من مجلد Public في مشروعك إلى العميل. قد تضع هنا ملفات ثابتة مثل أوراق الأنماط (stylesheets) أو الصور النقطية (bitmap images).

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

بمجرد تسجيل `FileMiddleware`، يمكن ربط ملف مثل `Public/images/logo.png` من قالب Leaf باستخدام `<img src="/images/logo.png"/>`.

إذا كان خادمك مضمّنًا في مشروع Xcode، مثل تطبيق iOS، استخدم هذا بدلًا من ذلك:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

تأكّد أيضًا من استخدام مراجع المجلدات (Folder References) بدلًا من المجموعات (Groups) في Xcode للحفاظ على بنية المجلدات في الموارد بعد بناء التطبيق.

## CORS Middleware

مشاركة الموارد عبر المصادر (Cross-origin resource sharing، أو CORS) هي آلية تتيح طلب موارد مقيّدة على صفحة ويب من نطاق آخر خارج النطاق الذي قُدّم منه المورد الأول. ستتطلّب واجهات REST API المبنية في Vapor سياسة CORS من أجل إرجاع الطلبات بأمان إلى متصفحات الويب الحديثة.

قد يبدو مثال على الإعداد كالتالي:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware should come before default error middleware using `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

بما أن الأخطاء المُطلَقة تُعاد فورًا إلى العميل، يجب إدراج `CORSMiddleware` _قبل_ `ErrorMiddleware`. وإلا، ستُعاد استجابة خطأ HTTP دون ترويسات CORS، ولن يتمكّن المتصفح من قراءتها.
