# المصادقة

المصادقة هي عملية التحقق من هوية المستخدم. يتم ذلك عبر التحقق من بيانات اعتماد مثل اسم المستخدم وكلمة المرور أو رمز فريد. تختلف المصادقة (تُسمى أحيانًا auth/c) عن التفويض (auth/z) الذي هو عملية التحقق من صلاحيات مستخدم تمت مصادقته مسبقًا لأداء مهام معينة.

## مقدمة

يوفر Authentication API الخاص بـ Vapor دعمًا لمصادقة المستخدم عبر ترويسة `Authorization`، باستخدام [Basic](https://tools.ietf.org/html/rfc7617) و[Bearer](https://tools.ietf.org/html/rfc6750). كما يدعم مصادقة المستخدم عبر البيانات التي يتم فك ترميزها من [Content](../basics/content.md) API.

يتم تنفيذ المصادقة من خلال إنشاء `Authenticator` يحتوي على منطق التحقق. يمكن استخدام المُصادِق لحماية مجموعات مسارات فردية أو تطبيق بأكمله. تأتي المساعدات التالية للمُصادِقات مع Vapor:

|البروتوكول|الوصف|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|مُصادِق أساسي قادر على إنشاء وسيطة.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|يصادق ترويسة تفويض Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|يصادق ترويسة تفويض Bearer.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|يصادق حمولة بيانات اعتماد من جسم الطلب.|

في حال نجاح المصادقة، يضيف المُصادِق المستخدم الذي تم التحقق منه إلى `req.auth`. يمكن بعد ذلك الوصول إلى هذا المستخدم باستخدام `req.auth.get(_:)` في المسارات المحمية بواسطة المُصادِق. في حال فشل المصادقة، لا يُضاف المستخدم إلى `req.auth` وستفشل أي محاولات للوصول إليه.

## Authenticatable

لاستخدام Authentication API، تحتاج أولًا إلى نوع مستخدم يتوافق مع `Authenticatable`. يمكن أن يكون هذا `struct` أو `class` أو حتى `Model` من Fluent. تفترض الأمثلة التالية بنية `User` البسيطة هذه التي تحتوي على خاصية واحدة: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

سيستخدم كل مثال أدناه نسخة من مُصادِق قمنا بإنشائه. في هذه الأمثلة، أطلقنا عليه اسم `UserAuthenticator`.

### المسار

المُصادِقات هي وسيطة ويمكن استخدامها لحماية المسارات.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

يُستخدم `req.auth.require` لجلب `User` الذي تمت مصادقته. في حال فشل المصادقة، ستطلق هذه الدالة خطأً، مما يحمي المسار.

### Guard Middleware

يمكنك أيضًا استخدام `GuardMiddleware` في مجموعة مساراتك لضمان أن المستخدم قد تمت مصادقته قبل الوصول إلى معالج المسار الخاص بك.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

لا يتم اشتراط المصادقة بواسطة وسيطة المُصادِق للسماح بتركيب المُصادِقات. اقرأ المزيد عن [التركيب](#التركيب) أدناه.

## Basic

ترسل مصادقة Basic اسم المستخدم وكلمة المرور في ترويسة `Authorization`. يتم دمج اسم المستخدم وكلمة المرور بنقطتين رأسيتين (على سبيل المثال `test:secret`)، وترميزهما بـ base-64، وإضافة البادئة `"Basic "`. يقوم مثال الطلب التالي بترميز اسم المستخدم `test` مع كلمة المرور `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

تُستخدم مصادقة Basic عادةً مرة واحدة لتسجيل دخول المستخدم وإنشاء رمز. يقلل هذا من عدد مرات إرسال كلمة مرور المستخدم الحساسة. يجب ألا ترسل تفويض Basic أبدًا عبر اتصال نصي عادي أو اتصال TLS غير موثوق.

لتنفيذ مصادقة Basic في تطبيقك، أنشئ مُصادِقًا جديدًا يتوافق مع `BasicAuthenticator`. فيما يلي مثال لمُصادِق مُرمَّز بشكل ثابت للتحقق من الطلب أعلاه.


```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

إذا كنت تستخدم `async`/`await` يمكنك استخدام `AsyncBasicAuthenticator` بدلًا من ذلك:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

يتطلب هذا البروتوكول منك تنفيذ `authenticate(basic:for:)` الذي سيتم استدعاؤه عندما يحتوي طلب وارد على ترويسة `Authorization: Basic ...`. يتم تمرير بنية `BasicAuthorization` التي تحتوي على اسم المستخدم وكلمة المرور إلى الدالة.

في مُصادِق الاختبار هذا، يتم اختبار اسم المستخدم وكلمة المرور مقابل قيم مُرمَّزة بشكل ثابت. في مُصادِق حقيقي، قد تتحقق مقابل قاعدة بيانات أو واجهة API خارجية. لهذا السبب تسمح لك دالة `authenticate` بإرجاع future.

!!! tip "نصيحة"
    يجب ألا تُخزَّن كلمات المرور أبدًا في قاعدة بيانات كنص عادي. استخدم دائمًا تجزئات كلمات المرور للمقارنة.

إذا كانت معاملات المصادقة صحيحة، وفي هذه الحالة مطابقة للقيم المُرمَّزة بشكل ثابت، يتم تسجيل دخول `User` باسم Vapor. إذا لم تتطابق معاملات المصادقة، لا يتم تسجيل دخول أي مستخدم، مما يعني فشل المصادقة.

إذا أضفت هذا المُصادِق إلى تطبيقك، واختبرت المسار المُعرَّف أعلاه، يجب أن ترى الاسم `"Vapor"` مُرجَعًا لتسجيل دخول ناجح. إذا كانت بيانات الاعتماد غير صحيحة، يجب أن ترى خطأ `401 Unauthorized`.

## Bearer

ترسل مصادقة Bearer رمزًا في ترويسة `Authorization`. تتم إضافة البادئة `"Bearer "` إلى الرمز. يرسل مثال الطلب التالي الرمز `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

تُستخدم مصادقة Bearer بشكل شائع لمصادقة نقاط نهاية API. يطلب المستخدم عادةً رمز Bearer عبر إرسال بيانات اعتماد مثل اسم المستخدم وكلمة المرور إلى نقطة نهاية تسجيل الدخول. قد يستمر هذا الرمز دقائق أو أيامًا حسب احتياجات التطبيق.

ما دام الرمز صالحًا، يمكن للمستخدم استخدامه بدلًا من بيانات اعتماده للمصادقة مقابل API. إذا أصبح الرمز غير صالح، يمكن إنشاء رمز جديد باستخدام نقطة نهاية تسجيل الدخول.

لتنفيذ مصادقة Bearer في تطبيقك، أنشئ مُصادِقًا جديدًا يتوافق مع `BearerAuthenticator`. فيما يلي مثال لمُصادِق مُرمَّز بشكل ثابت للتحقق من الطلب أعلاه.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

إذا كنت تستخدم `async`/`await` يمكنك استخدام `AsyncBearerAuthenticator` بدلًا من ذلك:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

يتطلب هذا البروتوكول منك تنفيذ `authenticate(bearer:for:)` الذي سيتم استدعاؤه عندما يحتوي طلب وارد على ترويسة `Authorization: Bearer ...`. يتم تمرير بنية `BearerAuthorization` التي تحتوي على الرمز إلى الدالة.

في مُصادِق الاختبار هذا، يتم اختبار الرمز مقابل قيمة مُرمَّزة بشكل ثابت. في مُصادِق حقيقي، قد تتحقق من الرمز عبر التحقق مقابل قاعدة بيانات أو باستخدام تدابير تشفيرية، كما يحدث مع JWT. لهذا السبب تسمح لك دالة `authenticate` بإرجاع future.

!!! tip "نصيحة"
    عند تنفيذ التحقق من الرمز، من المهم مراعاة قابلية التوسع الأفقي. إذا كان تطبيقك بحاجة إلى التعامل مع العديد من المستخدمين في وقت واحد، فقد تكون المصادقة عنق زجاجة محتملًا. فكِّر في كيفية توسع تصميمك عبر نسخ متعددة من تطبيقك تعمل في آنٍ واحد.

إذا كانت معاملات المصادقة صحيحة، وفي هذه الحالة مطابقة للقيمة المُرمَّزة بشكل ثابت، يتم تسجيل دخول `User` باسم Vapor. إذا لم تتطابق معاملات المصادقة، لا يتم تسجيل دخول أي مستخدم، مما يعني فشل المصادقة.

إذا أضفت هذا المُصادِق إلى تطبيقك، واختبرت المسار المُعرَّف أعلاه، يجب أن ترى الاسم `"Vapor"` مُرجَعًا لتسجيل دخول ناجح. إذا كانت بيانات الاعتماد غير صحيحة، يجب أن ترى خطأ `401 Unauthorized`.

## التركيب

يمكن تركيب (دمج) عدة مُصادِقات معًا لإنشاء مصادقة أكثر تعقيدًا لنقطة النهاية. بما أن وسيطة المُصادِق لن ترفض الطلب في حال فشل المصادقة، يمكن ربط أكثر من واحدة من هذه الوسيطات معًا. يمكن تركيب المُصادِقات بطريقتين أساسيتين.

### تركيب الأساليب


الطريقة الأولى لتركيب المصادقة هي ربط أكثر من مُصادِق لنوع المستخدم نفسه. خذ المثال التالي:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Do something with user.
}
```

يفترض هذا المثال وجود مُصادِقين `UserPasswordAuthenticator` و`UserTokenAuthenticator` كلاهما يصادق `User`. تتم إضافة كلا هذين المُصادِقين إلى مجموعة المسارات. أخيرًا، تتم إضافة `GuardMiddleware` بعد المُصادِقات لاشتراط أن `User` قد تمت مصادقته بنجاح.

ينتج عن هذا التركيب للمُصادِقات مسار يمكن الوصول إليه عبر كلمة المرور أو الرمز. يمكن لمسار كهذا أن يسمح للمستخدم بتسجيل الدخول وإنشاء رمز، ثم الاستمرار في استخدام ذلك الرمز لإنشاء رموز جديدة.

### تركيب المستخدمين

الطريقة الثانية لتركيب المصادقة هي ربط مُصادِقات لأنواع مستخدمين مختلفة. خذ المثال التالي:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Do something.
}
```

يفترض هذا المثال وجود مُصادِقين `AdminAuthenticator` و`UserAuthenticator` يصادقان `Admin` و`User` على التوالي. تتم إضافة كلا هذين المُصادِقين إلى مجموعة المسارات. بدلًا من استخدام `GuardMiddleware`، تتم إضافة فحص في معالج المسار للتحقق مما إذا تمت مصادقة `Admin` أو `User`. إذا لم يحدث ذلك، يُطلق خطأ.

ينتج عن هذا التركيب للمُصادِقات مسار يمكن الوصول إليه من نوعين مختلفين من المستخدمين بأساليب مصادقة يُحتمل أن تكون مختلفة. يمكن لمسار كهذا أن يسمح بمصادقة المستخدم العادي مع منح الوصول لمستخدم متميز في الوقت نفسه.

## يدويًا

يمكنك أيضًا التعامل مع المصادقة يدويًا باستخدام `req.auth`. هذا مفيد بشكل خاص للاختبار.

لتسجيل دخول مستخدم يدويًا، استخدم `req.auth.login(_:)`. يمكن تمرير أي مستخدم `Authenticatable` إلى هذه الدالة.

```swift
req.auth.login(User(name: "Vapor"))
```

للحصول على المستخدم الذي تمت مصادقته، استخدم `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

يمكنك أيضًا استخدام `req.auth.get(_:)` إذا لم تكن تريد إطلاق خطأ تلقائيًا عند فشل المصادقة.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

لإلغاء مصادقة مستخدم، مرِّر نوع المستخدم إلى `req.auth.logout(_:)`.

```swift
req.auth.logout(User.self)
```

## Fluent

يُعرِّف [Fluent](../fluent/overview.md) بروتوكولين `ModelAuthenticatable` و`ModelTokenAuthenticatable` يمكن إضافتهما إلى نماذجك الموجودة. يسمح توافق نماذجك مع هذين البروتوكولين بإنشاء مُصادِقات لحماية نقاط النهاية.

يصادق `ModelTokenAuthenticatable` باستخدام رمز Bearer. هذا ما تستخدمه لحماية معظم نقاط نهايتك. يصادق `ModelAuthenticatable` باستخدام اسم المستخدم وكلمة المرور ويُستخدم بواسطة نقطة نهاية واحدة لإنشاء الرموز.

يفترض هذا الدليل أنك على دراية بـ Fluent وأنك قمت بتهيئة تطبيقك بنجاح لاستخدام قاعدة بيانات. إذا كنت جديدًا على Fluent، ابدأ بـ [النظرة العامة](../fluent/overview.md).

### User

للبدء، ستحتاج إلى نموذج يمثل المستخدم الذي ستتم مصادقته. لهذا الدليل، سنستخدم النموذج التالي، لكنك حر في استخدام نموذج موجود.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

يجب أن يكون النموذج قادرًا على تخزين اسم مستخدم، وهو في هذه الحالة بريد إلكتروني، وتجزئة كلمة مرور. كما نضبط `email` ليكون حقلًا فريدًا، لتجنب المستخدمين المكررين. عملية الترحيل المقابلة لهذا النموذج المثالي هنا:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

لا تنسَ إضافة عملية الترحيل إلى `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

!!! tip "نصيحة"
     بما أن عناوين البريد الإلكتروني ليست حساسة لحالة الأحرف، فقد ترغب في إضافة [`Middleware`](../fluent/model.md#دورة-الحياة-lifecycle) تحوِّل عنوان البريد الإلكتروني إلى أحرف صغيرة قبل حفظه في قاعدة البيانات. لكن كن على دراية بأن `ModelAuthenticatable` يستخدم مقارنة حساسة لحالة الأحرف، لذا إذا فعلت ذلك فستحتاج إلى التأكد من أن إدخال المستخدم كله بأحرف صغيرة، إما عبر تحويل الأحرف في العميل، أو عبر مُصادِق مخصص.

أول شيء ستحتاجه هو نقطة نهاية لإنشاء مستخدمين جدد. لنستخدم `POST /users`. أنشئ بنية [Content](../basics/content.md) تمثل البيانات التي تتوقعها هذه النقطة.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

إذا أردت، يمكنك جعل هذه البنية تتوافق مع [Validatable](../basics/validation.md) لإضافة متطلبات التحقق.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

الآن يمكنك إنشاء نقطة النهاية `POST /users`.

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

تتحقق هذه النقطة من الطلب الوارد، وتفك ترميز بنية `User.Create`، وتتحقق من تطابق كلمات المرور. ثم تستخدم البيانات المفكوكة لإنشاء `User` جديد وتحفظه في قاعدة البيانات. تُجزَّأ كلمة المرور بالنص العادي باستخدام `Bcrypt` قبل الحفظ في قاعدة البيانات.

قم ببناء المشروع وتشغيله، مع التأكد من ترحيل قاعدة البيانات أولًا، ثم استخدم الطلب التالي لإنشاء مستخدم جديد.

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Model Authenticatable

الآن بعد أن أصبح لديك نموذج مستخدم ونقطة نهاية لإنشاء مستخدمين جدد، لنجعل النموذج يتوافق مع `ModelAuthenticatable`. سيسمح هذا بمصادقة النموذج باستخدام اسم المستخدم وكلمة المرور.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

يضيف هذا الامتداد توافق `ModelAuthenticatable` إلى `User`. تحدد الخاصيتان الأوليان أي الحقول يجب استخدامها لتخزين اسم المستخدم وتجزئة كلمة المرور على التوالي. تنشئ صيغة `\` مسار مفتاح (key path) إلى الحقول يمكن لـ Fluent استخدامه للوصول إليها.

المتطلب الأخير هو دالة للتحقق من كلمات المرور بالنص العادي المرسلة في ترويسة مصادقة Basic. بما أننا نستخدم Bcrypt لتجزئة كلمة المرور أثناء التسجيل، سنستخدم Bcrypt للتحقق من أن كلمة المرور المُدخَلة تطابق تجزئة كلمة المرور المخزنة.

الآن بعد أن أصبح `User` يتوافق مع `ModelAuthenticatable`، يمكننا إنشاء مُصادِق لحماية مسار تسجيل الدخول.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

يضيف `ModelAuthenticatable` دالة ثابتة `authenticator` لإنشاء مُصادِق.

اختبر أن هذا المسار يعمل عبر إرسال الطلب التالي.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

يمرر هذا الطلب اسم المستخدم `test@vapor.codes` وكلمة المرور `secret42` عبر ترويسة مصادقة Basic. يجب أن ترى المستخدم الذي تم إنشاؤه سابقًا مُرجَعًا.

بينما يمكنك نظريًا استخدام مصادقة Basic لحماية جميع نقاط نهايتك، يُوصى باستخدام رمز منفصل بدلًا من ذلك. يقلل هذا من عدد مرات إرسال كلمة مرور المستخدم الحساسة عبر الإنترنت. كما يجعل المصادقة أسرع بكثير لأنك تحتاج فقط إلى إجراء تجزئة كلمة المرور أثناء تسجيل الدخول.

### User Token

أنشئ نموذجًا جديدًا لتمثيل رموز المستخدم.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

يجب أن يحتوي هذا النموذج على حقل `value` لتخزين السلسلة الفريدة للرمز. كما يجب أن يحتوي على [علاقة أب](../fluent/overview.md#الأصل-parent) بنموذج المستخدم. يمكنك إضافة خصائص إضافية إلى هذا الرمز كما تراه مناسبًا، مثل تاريخ انتهاء الصلاحية.

بعد ذلك، أنشئ عملية ترحيل لهذا النموذج.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

لاحظ أن عملية الترحيل هذه تجعل حقل `value` فريدًا. كما تنشئ مرجع مفتاح خارجي بين حقل `user_id` وجدول المستخدمين.

لا تنسَ إضافة عملية الترحيل إلى `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

أخيرًا، أضف دالة على `User` لإنشاء رمز جديد. ستُستخدم هذه الدالة أثناء تسجيل الدخول.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

هنا نستخدم `[UInt8].random(count:)` لإنشاء قيمة رمز عشوائية. في هذا المثال، يتم استخدام 16 بايت، أو 128 بت، من البيانات العشوائية. يمكنك تعديل هذا الرقم كما تراه مناسبًا. ثم تُرمَّز البيانات العشوائية بـ base-64 لتسهيل نقلها في ترويسات HTTP.

الآن بعد أن أصبح بإمكانك إنشاء رموز مستخدم، حدِّث مسار `POST /login` لإنشاء رمز وإرجاعه.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

اختبر أن هذا المسار يعمل باستخدام طلب تسجيل الدخول نفسه من الأعلى. يجب أن تحصل الآن على رمز عند تسجيل الدخول يبدو مثل:

```
8gtg300Jwdhc/Ffw784EXA==
```

احتفظ بالرمز الذي تحصل عليه لأننا سنستخدمه قريبًا.

#### Model Token Authenticatable

اجعل `UserToken` يتوافق مع `ModelTokenAuthenticatable`. سيسمح هذا للرموز بمصادقة نموذج `User` الخاص بك.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    var isValid: Bool {
        true
    }
}
```

يحدد متطلب البروتوكول الأول أي حقل يخزن قيمة الرمز الفريدة. هذه هي القيمة التي سترسل في ترويسة مصادقة Bearer. يحدد المتطلب الثاني علاقة الأب بنموذج `User`. هذه هي الطريقة التي سيبحث بها Fluent عن المستخدم الذي تمت مصادقته.

المتطلب الأخير هو قيمة منطقية `isValid`. إذا كانت هذه `false`، سيُحذَف الرمز من قاعدة البيانات ولن تتم مصادقة المستخدم. من أجل التبسيط، سنجعل الرموز أبدية عبر ترميز هذه القيمة بشكل ثابت إلى `true`.

الآن بعد أن أصبح الرمز يتوافق مع `ModelTokenAuthenticatable`، يمكنك إنشاء مُصادِق لحماية المسارات.

أنشئ نقطة نهاية جديدة `GET /me` للحصول على المستخدم الذي تمت مصادقته حاليًا.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

على غرار `User`، أصبح لدى `UserToken` الآن دالة ثابتة `authenticator()` يمكنها إنشاء مُصادِق. سيحاول المُصادِق العثور على `UserToken` مطابق باستخدام القيمة المُقدَّمة في ترويسة مصادقة Bearer. إذا وجد تطابقًا، سيجلب `User` المرتبط ويصادقه.

اختبر أن هذا المسار يعمل عبر إرسال طلب HTTP التالي حيث يكون الرمز هو القيمة التي حفظتها من طلب `POST /login`.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

يجب أن ترى `User` الذي تمت مصادقته مُرجَعًا.

## الجلسة

يمكن استخدام [Session API](../advanced/sessions.md) الخاص بـ Vapor للحفاظ تلقائيًا على مصادقة المستخدم بين الطلبات. يعمل هذا عبر تخزين معرِّف فريد للمستخدم في بيانات جلسة الطلب بعد تسجيل الدخول الناجح. في الطلبات اللاحقة، يُجلب معرِّف المستخدم من الجلسة ويُستخدم لمصادقة المستخدم قبل استدعاء معالج المسار الخاص بك.

الجلسات رائعة لتطبيقات الويب ذات الواجهة الأمامية المبنية في Vapor والتي تقدم HTML مباشرة إلى متصفحات الويب. بالنسبة لواجهات API، نوصي باستخدام مصادقة عديمة الحالة قائمة على الرمز للحفاظ على بيانات المستخدم بين الطلبات.

### Session Authenticatable

لاستخدام المصادقة القائمة على الجلسة، ستحتاج إلى نوع يتوافق مع `SessionAuthenticatable`. لهذا المثال، سنستخدم بنية بسيطة.

```swift
import Vapor

struct User {
    var email: String
}
```

للتوافق مع `SessionAuthenticatable`، ستحتاج إلى تحديد `sessionID`. هذه هي القيمة التي ستُخزَّن في بيانات الجلسة ويجب أن تحدد المستخدم بشكل فريد.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

بالنسبة لنوع `User` البسيط الخاص بنا، سنستخدم عنوان البريد الإلكتروني كمعرِّف جلسة فريد.

### Session Authenticator

بعد ذلك، سنحتاج إلى `SessionAuthenticator` للتعامل مع حل نسخ المستخدم الخاص بنا من معرِّف الجلسة المحفوظ.


```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

إذا كنت تستخدم `async`/`await` يمكنك استخدام `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

بما أن جميع المعلومات التي نحتاجها لتهيئة مستخدم `User` المثالي الخاص بنا موجودة في معرِّف الجلسة، يمكننا إنشاء المستخدم وتسجيل دخوله بشكل متزامن. في تطبيق واقعي، من المرجح أن تستخدم معرِّف الجلسة لإجراء بحث في قاعدة بيانات أو طلب API لجلب بقية بيانات المستخدم قبل المصادقة.

بعد ذلك، لننشئ مُصادِق bearer بسيطًا لإجراء المصادقة الأولية.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

سيصادق هذا المُصادِق مستخدمًا بالبريد الإلكتروني `hello@vapor.codes` عند إرسال رمز bearer المسمى `test`.

أخيرًا، لنجمع كل هذه القطع معًا في تطبيقك.

```swift
// Create protected route group which requires user auth.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Add GET /me route for reading user's email.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

تتم إضافة `SessionsMiddleware` أولًا لتمكين دعم الجلسة في التطبيق. يمكن العثور على مزيد من المعلومات حول تهيئة الجلسات في قسم [Session API](../advanced/sessions.md).

بعد ذلك، تتم إضافة `SessionAuthenticator`. يتولى هذا مصادقة المستخدم إذا كانت هناك جلسة نشطة.

إذا لم تُحفظ المصادقة في الجلسة بعد، سيُوجَّه الطلب إلى المُصادِق التالي. سيتحقق `UserBearerAuthenticator` من رمز bearer ويصادق المستخدم إذا كان يساوي `"test"`.

أخيرًا، ستضمن `User.guardMiddleware()` أن `User` قد تمت مصادقته بواسطة إحدى الوسيطات السابقة. إذا لم تتم مصادقة المستخدم، سيُطلق خطأ.

لاختبار هذا المسار، أرسل أولًا الطلب التالي:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

سيؤدي هذا إلى قيام `UserBearerAuthenticator` بمصادقة المستخدم. بمجرد المصادقة، ستحفظ `UserSessionAuthenticator` معرِّف المستخدم في تخزين الجلسة وتنشئ ملف تعريف ارتباط (cookie). استخدم ملف تعريف الارتباط من الاستجابة في طلب ثانٍ إلى المسار.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

هذه المرة، ستصادق `UserSessionAuthenticator` المستخدم ويجب أن ترى بريد المستخدم الإلكتروني مُرجَعًا مرة أخرى.

### Model Session Authenticatable

يمكن لنماذج Fluent إنشاء `SessionAuthenticator`s عبر التوافق مع `ModelSessionAuthenticatable`. سيستخدم هذا المعرِّف الفريد للنموذج كمعرِّف جلسة ويجري تلقائيًا بحثًا في قاعدة البيانات لاستعادة النموذج من الجلسة.

```swift
import Fluent

final class User: Model { ... }

// Allow this model to be persisted in sessions.
extension User: ModelSessionAuthenticatable { }
```

يمكنك إضافة `ModelSessionAuthenticatable` إلى أي نموذج موجود كتوافق فارغ. بمجرد إضافته، ستتوفر دالة ثابتة جديدة لإنشاء `SessionAuthenticator` لذلك النموذج.

```swift
User.sessionAuthenticator()
```

سيستخدم هذا قاعدة البيانات الافتراضية للتطبيق لحل المستخدم. لتحديد قاعدة بيانات، مرِّر المعرِّف.

```swift
User.sessionAuthenticator(.sqlite)
```

## مصادقة موقع الويب

المواقع الإلكترونية حالة خاصة للمصادقة لأن استخدام المتصفح يقيد كيفية إرفاق بيانات الاعتماد بالمتصفح. يؤدي هذا إلى سيناريوهين مختلفين للمصادقة:

* تسجيل الدخول الأولي عبر نموذج
* الاستدعاءات اللاحقة المُصادَق عليها بملف تعريف ارتباط الجلسة

يوفر Vapor وFluent عدة مساعدات لجعل هذا سلسًا.

### مصادقة الجلسة

تعمل مصادقة الجلسة كما هو موضح أعلاه. تحتاج إلى تطبيق وسيطة الجلسة ومُصادِق الجلسة على جميع المسارات التي سيصل إليها المستخدم. تشمل هذه أي مسارات محمية، وأي مسارات عامة لكن قد لا تزال ترغب في الوصول إلى المستخدم إذا كان قد سجل دخوله (لعرض زر حساب مثلًا) **و**مسارات تسجيل الدخول.

يمكنك تمكين هذا بشكل عام في تطبيقك في **configure.swift** كما يلي:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

تقوم هذه الوسيطات بما يلي:

* تأخذ وسيطة الجلسات ملف تعريف ارتباط الجلسة المُقدَّم في الطلب وتحوله إلى جلسة
* يأخذ مُصادِق الجلسة الجلسة ويرى ما إذا كان هناك مستخدم تمت مصادقته لتلك الجلسة. إذا كان الأمر كذلك، تصادق الوسيطة الطلب. في الاستجابة، يرى مُصادِق الجلسة ما إذا كان الطلب يحتوي على مستخدم تمت مصادقته ويحفظه في الجلسة بحيث تتم مصادقته في الطلب التالي.

!!! note "ملاحظة"
    لا يُضبط ملف تعريف ارتباط الجلسة على `secure` و`httpOnly` افتراضيًا. راجع [Session API](../advanced/sessions.md#الإعداد) الخاص بـ Vapor لمزيد من المعلومات حول كيفية تهيئة ملفات تعريف الارتباط.

### حماية المسارات

عند حماية المسارات لواجهة API، عادةً ما ترجع استجابة HTTP برمز حالة مثل **401 Unauthorized** إذا لم تتم مصادقة الطلب. لكن هذه ليست تجربة مستخدم جيدة جدًا لشخص يستخدم متصفحًا. يوفر Vapor `RedirectMiddleware` لأي نوع `Authenticatable` للاستخدام في هذا السيناريو:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

يدعم كائن `RedirectMiddleware` أيضًا تمرير closure يرجع مسار إعادة التوجيه كـ `String` أثناء الإنشاء لمعالجة عناوين URL المتقدمة. على سبيل المثال، تضمين المسار الذي أُعيد التوجيه منه كمعامل استعلام لهدف إعادة التوجيه لإدارة الحالة.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

يعمل هذا بشكل مشابه لـ `GuardMiddleware`. أي طلبات إلى المسارات المسجلة في `protectedRoutes` التي لم تتم مصادقتها ستُعاد توجيهها إلى المسار المُقدَّم. يتيح لك هذا إخبار مستخدميك بتسجيل الدخول، بدلًا من مجرد تقديم **401 Unauthorized**.

تأكد من تضمين مُصادِق جلسة قبل `RedirectMiddleware` لضمان تحميل المستخدم الذي تمت مصادقته قبل المرور عبر `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### تسجيل الدخول عبر النموذج

لمصادقة مستخدم والطلبات المستقبلية بجلسة، تحتاج إلى تسجيل دخول مستخدم. يوفر Vapor بروتوكول `ModelCredentialsAuthenticatable` للتوافق معه. يتولى هذا تسجيل الدخول عبر نموذج. أولًا اجعل `User` الخاص بك يتوافق مع هذا البروتوكول:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

هذا مطابق لـ `ModelAuthenticatable` وإذا كنت تتوافق معه بالفعل فلن تحتاج إلى فعل أي شيء آخر. بعد ذلك طبِّق وسيطة `ModelCredentialsAuthenticator` هذه على طلب POST الخاص بنموذج تسجيل دخولك:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

يستخدم هذا مُصادِق بيانات الاعتماد الافتراضي لحماية مسار تسجيل الدخول. يجب أن ترسل `username` و`password` في طلب POST. يمكنك إعداد نموذجك كما يلي:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

يستخرج `CredentialsAuthenticator` كلًا من `username` و`password` من جسم الطلب، ويعثر على المستخدم من اسم المستخدم ويتحقق من كلمة المرور. إذا كانت كلمة المرور صالحة، تصادق الوسيطة الطلب. ثم يصادق `SessionAuthenticator` الجلسة للطلبات اللاحقة.

## JWT

يوفر [JWT](jwt.md) مُصادِق `JWTAuthenticator` يمكن استخدامه لمصادقة رموز JSON Web Tokens في الطلبات الواردة. إذا كنت جديدًا على JWT، اطلع على [النظرة العامة](jwt.md).

أولًا، أنشئ نوعًا يمثل حمولة JWT.

```swift
// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constants
    let expirationTime: TimeInterval = 60 * 15
    
    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

بعد ذلك، يمكننا تعريف تمثيل للبيانات الموجودة في استجابة تسجيل دخول ناجحة. في الوقت الحالي ستحتوي الاستجابة على خاصية واحدة فقط وهي سلسلة تمثل JWT موقَّعًا.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

باستخدام نموذجنا لرمز JWT والاستجابة، يمكننا استخدام مسار تسجيل دخول محمي بكلمة مرور يرجع `ClientTokenResponse` ويتضمن `SessionToken` موقَّعًا.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

بدلًا من ذلك، إذا لم ترغب في استخدام مُصادِق، يمكن أن يكون لديك شيء يبدو كالتالي.
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Validate provided credential for user
    // Get userId for provided user
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

عبر جعل الحمولة تتوافق مع `Authenticatable` و`JWTPayload`، يمكنك إنشاء مُصادِق مسار باستخدام دالة `authenticator()`. أضف هذا إلى مجموعة مسارات لجلب JWT والتحقق منه تلقائيًا قبل استدعاء مسارك.

```swift
// Create a route group that requires the SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

ستؤدي إضافة [guard middleware](#guard-middleware) الاختيارية إلى اشتراط نجاح التفويض.

داخل المسارات المحمية، يمكنك الوصول إلى حمولة JWT التي تمت مصادقتها باستخدام `req.auth`.

```swift
// Return ok reponse if the user-provided token is valid.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
