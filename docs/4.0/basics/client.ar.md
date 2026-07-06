# العميل (Client)

تتيح لك واجهة العميل (Client API) في Vapor إجراء استدعاءات HTTP إلى الموارد الخارجية. وهي مبنية على [async-http-client](https://github.com/swift-server/async-http-client) وتتكامل مع واجهة [المحتوى](content.md).

## نظرة عامة

يمكنك الوصول إلى العميل الافتراضي عبر `Application` أو داخل معالج مسار عبر `Request`.

```swift
app.client // Client

app.get("test") { req in
    req.client // Client
}
```

يُعَد عميل التطبيق مفيدًا لإجراء طلبات HTTP أثناء وقت التهيئة. إذا كنت تُجري طلبات HTTP داخل معالج مسار، فاستخدم دائمًا عميل الطلب.

### الدوال (Methods)

لإجراء طلب `GET`، مرِّر عنوان URL المطلوب إلى الدالة المريحة `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

هناك دوال لكل من أفعال HTTP مثل `get` و`post` و`delete`. تُرجَع استجابة العميل كـ future وتحتوي على حالة HTTP والترويسات والجسم.

### المحتوى (Content)

تتوفر واجهة [المحتوى](content.md) في Vapor للتعامل مع البيانات في طلبات واستجابات العميل. لترميز المحتوى أو معاملات الاستعلام أو إضافة ترويسات إلى الطلب، استخدم مُغلَّف `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
    // Encode query string to the request URL.
    try req.query.encode(["q": "test"])

    // Encode JSON to the request body.
    try req.content.encode(["hello": "world"])
    
    // Add auth header to the request
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Handle the response.
```

يمكنك أيضًا فك ترميز جسم الاستجابة باستخدام `Content` بطريقة مماثلة:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

إذا كنت تستخدم الـ futures، فيمكنك استخدام `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
    try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
    // Use JSON here
}
```

## التهيئة (Configuration)

يمكنك تهيئة عميل HTTP الأساسي عبر التطبيق.

```swift
// Disable automatic redirect following.
app.http.client.configuration.redirectConfiguration = .disallow
```

لاحظ أنه يجب عليك تهيئة العميل الافتراضي _قبل_ استخدامه للمرة الأولى.


