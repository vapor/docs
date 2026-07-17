# Request

يُمرَّر الكائن [`Request`](https://api.vapor.codes/vapor/request) إلى كل [معالج مسار](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

إنه النافذة الرئيسية إلى بقية وظائف Vapor. يحتوي على واجهات لـ [جسم الطلب](../basics/content.md)، و[مُعامِلات الاستعلام (query parameters)](../basics/content.md#الاستعلام-query)، و[المُسجِّل (logger)](../basics/logging.md)، و[عميل HTTP](../basics/client.md)، و[المُصادِق (Authenticator)](../security/authentication.md)، والمزيد. يُبقي الوصول إلى هذه الوظائف عبر الطلب العمليات الحسابية على حلقة الأحداث (event loop) الصحيحة، ويتيح محاكاتها (mock) للاختبار. يمكنك حتى إضافة [خدماتك](../advanced/services.md) الخاصة إلى `Request` عبر الامتدادات (extensions).

يمكن العثور على وثائق الواجهة الكاملة لـ `Request` [هنا](https://api.vapor.codes/vapor/request).

## Application

تحمل الخاصية `Request.application` مرجعًا إلى [`Application`](https://api.vapor.codes/vapor/application). يحتوي هذا الكائن على كل الإعدادات والوظائف الأساسية للتطبيق. ينبغي ضبط معظمها فقط في `configure.swift`، قبل بدء التطبيق بالكامل، ولن تُحتاج العديد من الواجهات منخفضة المستوى في معظم التطبيقات. من أكثر الخصائص فائدة `Application.eventLoopGroup`، التي يمكن استخدامها للحصول على `EventLoop` للعمليات التي تحتاج إلى واحدة جديدة عبر الطريقة `any()`. كما يحتوي على [`Environment`](../basics/environment.md).

## Body

إذا كنت تريد وصولًا مباشرًا إلى جسم الطلب كـ `ByteBuffer`، يمكنك استخدام `Request.body.data`. يمكن استخدام هذا لبثّ (streaming) البيانات من جسم الطلب إلى ملف (رغم أنه ينبغي عليك استخدام الخاصية [`fileio`](../advanced/files.md) على الطلب لهذا بدلًا من ذلك) أو إلى عميل HTTP آخر.

## Cookies

بينما يكون أكثر تطبيقات ملفات تعريف الارتباط (cookies) فائدة عبر [الجلسات (sessions)](../advanced/sessions.md#الإعداد) المدمجة، يمكنك أيضًا الوصول إلى ملفات تعريف الارتباط مباشرة عبر `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

يمكن الوصول إلى الكائن `HTTPHeaders` عبر `Request.headers`. يحتوي هذا على جميع الترويسات المُرسَلة مع الطلب. يمكن استخدامه للوصول إلى ترويسة `Content-Type`، على سبيل المثال.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

راجع مزيدًا من الوثائق حول `HTTPHeaders` [هنا](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). يضيف Vapor أيضًا عدة امتدادات إلى `HTTPHeaders` لتسهيل التعامل مع الترويسات الأكثر شيوعًا؛ تتوفّر قائمة [هنا](https://api.vapor.codes/vapor/niohttp1/httpheaders#instance-properties)

## عنوان IP

يمكن الوصول إلى `SocketAddress` الذي يمثّل العميل عبر `Request.remoteAddress`، وقد يكون مفيدًا للتسجيل (logging) أو تحديد المعدّل (rate limiting) باستخدام التمثيل النصّي `Request.remoteAddress.ipAddress`. قد لا يمثّل عنوان IP الخاص بالعميل بدقّة إذا كان التطبيق خلف وكيل عكسي (reverse proxy).

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

راجع مزيدًا من الوثائق حول `SocketAddress` [هنا](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
