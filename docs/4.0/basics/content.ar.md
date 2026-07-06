# المحتوى (Content)

تتيح لك واجهة المحتوى (Content API) في Vapor ترميز/فك ترميز هياكل Codable من/إلى رسائل HTTP بسهولة. يُستخدم ترميز [JSON](https://tools.ietf.org/html/rfc7159) افتراضيًا مع دعم جاهز لـ [النموذج المُرمَّز عبر URL (URL-Encoded Form)](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) و[Multipart](https://tools.ietf.org/html/rfc2388). كما أن الواجهة قابلة للتهيئة، مما يسمح لك بإضافة أو تعديل أو استبدال استراتيجيات الترميز لأنواع محتوى HTTP معينة.

## نظرة عامة

لفهم كيفية عمل واجهة المحتوى في Vapor، يجب أولًا أن تفهم بعض الأساسيات حول رسائل HTTP. ألقِ نظرة على مثال الطلب التالي.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

يشير هذا الطلب إلى أنه يحتوي على بيانات مُرمَّزة بصيغة JSON باستخدام ترويسة `content-type` ونوع الوسائط `application/json`. وكما هو متوقع، تأتي بعض بيانات JSON بعد الترويسات في جسم الطلب.

### هيكل المحتوى

الخطوة الأولى لفك ترميز رسالة HTTP هذه هي إنشاء نوع Codable يطابق البنية المتوقعة.

```swift
struct Greeting: Content {
    var hello: String
}
```

سيؤدي جعل النوع متوافقًا مع `Content` إلى إضافة التوافق مع `Codable` تلقائيًا إلى جانب أدوات مساعدة إضافية للعمل مع واجهة المحتوى.

بمجرد أن يكون لديك هيكل المحتوى، يمكنك فك ترميزه من الطلب الوارد باستخدام `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

تستخدم دالة فك الترميز نوع محتوى الطلب للعثور على مُفكِّك ترميز مناسب. إذا لم يُعثر على مُفكِّك ترميز، أو لم يحتوِ الطلب على ترويسة نوع المحتوى، فسيُطرَح خطأ `415`.

هذا يعني أن هذا المسار يقبل تلقائيًا جميع أنواع المحتوى المدعومة الأخرى، مثل النموذج المُرمَّز عبر URL:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

في حالة رفع الملفات، يجب أن تكون خاصية المحتوى لديك من النوع `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### أنواع الوسائط المدعومة

فيما يلي أنواع الوسائط التي تدعمها واجهة المحتوى افتراضيًا.

|الاسم|قيمة الترويسة|نوع الوسائط|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|النموذج المُرمَّز عبر URL|application/x-www-form-urlencoded|`.urlEncodedForm`|
|نص عادي|text/plain|`.plainText`|
|HTML|text/html|`.html`|

لا تدعم جميع أنواع الوسائط كل ميزات `Codable`. على سبيل المثال، لا يدعم JSON الشظايا (fragments) على المستوى الأعلى، ولا يدعم النص العادي البيانات المتداخلة.

## الاستعلام (Query)

تدعم واجهات المحتوى في Vapor التعامل مع البيانات المُرمَّزة عبر URL في سلسلة استعلام URL.

### فك الترميز

لفهم كيفية عمل فك ترميز سلسلة استعلام URL، ألقِ نظرة على مثال الطلب التالي.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

تمامًا مثل واجهات التعامل مع محتوى جسم رسالة HTTP، فإن الخطوة الأولى لتحليل سلاسل استعلام URL هي إنشاء `struct` يطابق البنية المتوقعة.

```swift
struct Hello: Content {
    var name: String?
}
```

لاحظ أن `name` هو `String` اختياري، لأن سلاسل استعلام URL يجب أن تكون دائمًا اختيارية. إذا كنت تريد جعل معامل ما إلزاميًا، فاستخدم معامل مسار بدلًا من ذلك.

الآن بعد أن أصبح لديك هيكل `Content` لسلسلة الاستعلام المتوقعة لهذا المسار، يمكنك فك ترميزه.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

سيؤدي هذا المسار إلى الاستجابة التالية عند إعطائه مثال الطلب أعلاه:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

إذا حُذفت سلسلة الاستعلام، كما في الطلب التالي، فسيُستخدم الاسم "Anonymous" بدلًا من ذلك.

```http
GET /hello HTTP/1.1
content-length: 0
```

### قيمة مفردة

بالإضافة إلى فك الترميز إلى هيكل `Content`، يدعم Vapor أيضًا جلب قيم مفردة من سلسلة الاستعلام باستخدام المؤشرات (subscripts).

```swift
let name: String? = req.query["name"]
```

## الخطافات (Hooks)

سيستدعي Vapor تلقائيًا `beforeEncode` و`afterDecode` على نوع `Content`. تُوفَّر تنفيذات افتراضية لا تقوم بأي شيء، لكن يمكنك استخدام هذه الدوال لتشغيل منطق مخصص.

```swift
// Runs after this Content is decoded. `mutating` is only required for structs, not classes.
mutating func afterDecode() throws {
    // Name may not be passed in, but if it is, then it can't be an empty string.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Runs before this Content is encoded. `mutating` is only required for structs, not classes.
mutating func beforeEncode() throws {
    // Have to *always* pass a name back, and it can't be an empty string.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## تجاوز الإعدادات الافتراضية

يمكن تهيئة المُرمِّزات ومُفكِّكات الترميز الافتراضية التي تستخدمها واجهات المحتوى في Vapor.

### عام (Global)

يتيح لك `ContentConfiguration.global` تغيير المُرمِّزات ومُفكِّكات الترميز التي يستخدمها Vapor افتراضيًا. هذا مفيد لتغيير كيفية تحليل تطبيقك بأكمله للبيانات وتسلسلها.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

عادةً ما يُجرى تعديل `ContentConfiguration` في `configure.swift`.

### لمرة واحدة (One-Off)

تدعم استدعاءات دوال الترميز وفك الترميز مثل `req.content.decode` تمرير مُرمِّزات مخصصة للاستخدامات لمرة واحدة.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## المُرمِّزات المخصصة

يمكن للتطبيقات والحزم الخارجية إضافة دعم لأنواع وسائط لا يدعمها Vapor افتراضيًا من خلال إنشاء مُرمِّزات مخصصة.

### المحتوى

يحدد Vapor بروتوكولين للمُرمِّزات القادرة على التعامل مع المحتوى في أجسام رسائل HTTP: `ContentDecoder` و`ContentEncoder`.

```swift
public protocol ContentEncoder {
    func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
}

public protocol ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
        where D: Decodable
}
```

يتيح لك التوافق مع هذه البروتوكولات تسجيل مُرمِّزاتك المخصصة في `ContentConfiguration` كما هو موضح أعلاه.

### استعلام URL

يحدد Vapor بروتوكولين للمُرمِّزات القادرة على التعامل مع المحتوى في سلاسل استعلام URL: `URLQueryDecoder` و`URLQueryEncoder`.

```swift
public protocol URLQueryDecoder {
    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D
        where D: Decodable
}

public protocol URLQueryEncoder {
    func encode<E>(_ encodable: E, to url: inout URI) throws
        where E: Encodable
}
```

يتيح لك التوافق مع هذه البروتوكولات تسجيل مُرمِّزاتك المخصصة في `ContentConfiguration` للتعامل مع سلاسل استعلام URL باستخدام دالتي `use(urlEncoder:)` و`use(urlDecoder:)`.

### `ResponseEncodable` مخصص

هناك نهج آخر يتضمن تنفيذ `ResponseEncodable` على أنواعك. تأمل نوع الغلاف `HTML` البسيط التالي:

```swift
struct HTML {
  let value: String
}
```

عندها سيبدو تنفيذ `ResponseEncodable` الخاص به هكذا:

```swift
extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}
```

إذا كنت تستخدم `async`/`await`، فيمكنك استخدام `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

لاحظ أن هذا يسمح بتخصيص ترويسة `Content-Type`. راجع [مرجع `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers) لمزيد من التفاصيل.

يمكنك بعد ذلك استخدام `HTML` كنوع استجابة في مساراتك:

```swift
app.get { _ in
  HTML(value: """
  <html>
    <body>
      <h1>Hello, World!</h1>
    </body>
  </html>
  """)
}
```
