# JWT

رمز JSON على الويب (JWT) هو معيار مفتوح ([RFC 7519](https://tools.ietf.org/html/rfc7519)) يُعرّف طريقة مُدمجة ومكتفية ذاتيًا لنقل المعلومات بأمان بين الأطراف على هيئة كائن JSON. ويمكن التحقق من هذه المعلومات والوثوق بها لأنها موقّعة رقميًا.

تُعدّ رموز JWT مفيدة بشكل خاص في تطبيقات الويب، حيث تُستخدم عادةً للمصادقة/التفويض عديم الحالة (stateless) ولتبادل المعلومات. يمكنك الاطلاع على مزيد من المعلومات حول النظرية الكامنة وراء رموز JWT في المواصفة المرتبطة أعلاه أو على [jwt.io](https://jwt.io/introduction).

يوفّر Vapor دعمًا من الدرجة الأولى لرموز JWT من خلال وحدة `JWT`. وهذه الوحدة مبنية فوق مكتبة `JWTKit`، وهي تنفيذ بلغة Swift لمعيار JWT مبني على [SwiftCrypto](https://github.com/apple/swift-crypto). توفّر JWTKit موقّعين ومتحققين لمجموعة متنوعة من الخوارزميات، بما في ذلك HMAC وECDSA وEdDSA وRSA.

## البدء

الخطوة الأولى لاستخدام رموز JWT في تطبيق Vapor الخاص بك هي إضافة تبعية `JWT` إلى ملف `Package.swift` في مشروعك:

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "JWT", package: "jwt")
        ]),
        // Other targets...
    ]
)
```

### التهيئة

بعد إضافة التبعية، يمكنك البدء في استخدام وحدة `JWT` في تطبيقك. تُضيف وحدة JWT خاصية `jwt` جديدة إلى `Application` تُستخدم للتهيئة، وتُوفَّر تفاصيلها الداخلية من مكتبة [JWTKit](https://github.com/vapor/jwt-kit).

#### مجموعة المفاتيح

يأتي الكائن `jwt` مع خاصية `keys`، وهي نسخة من `JWTKeyCollection` الخاصة بـ JWTKit. تُستخدم هذه المجموعة لتخزين وإدارة المفاتيح المستخدمة لتوقيع رموز JWT والتحقق منها. إن `JWTKeyCollection` هو `actor`، مما يعني أن جميع العمليات على المجموعة تُنفَّذ بشكل متسلسل وآمن مع الخيوط (thread-safe).

لتوقيع رموز JWT أو التحقق منها، ستحتاج إلى إضافة مفتاح إلى المجموعة. ويتم ذلك عادةً في ملف `configure.swift` الخاص بك:

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

يؤدي هذا إلى إضافة مفتاح HMAC مع SHA-256 كخوارزمية تجزئة إلى سلسلة المفاتيح، أو HS256 بترميز JWA. اطّلع على قسم [الخوارزميات](#الخوارزميات) أدناه لمزيد من المعلومات حول الخوارزميات المتاحة.

!!! note "ملاحظة"
    تأكّد من استبدال `"secret"` بمفتاح سرّي فعلي. ينبغي الحفاظ على أمان هذا المفتاح، ويُفضّل في ملف تهيئة أو متغيّر بيئة.

### التوقيع

يمكن بعد ذلك استخدام المفتاح المُضاف لتوقيع رموز JWT. ولفعل ذلك، تحتاج أولًا إلى _شيء_ لتوقيعه، وهو "الحمولة" (payload).
هذه الحمولة هي ببساطة كائن JSON يحتوي على البيانات التي تريد نقلها. يمكنك إنشاء حمولتك المخصصة بجعل بنيتك مطابقة لبروتوكول `JWTPayload`:

```swift
// JWT payload structure.
struct TestPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim

    // Custom data.
    // If true, the user is an admin.
    var isAdmin: Bool

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

يتم توقيع الحمولة عن طريق استدعاء الدالة `sign` على وحدة `JWT`، على سبيل المثال داخل معالج مسار (route handler):

```swift
app.post("login") { req async throws -> [String: String] in
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    return try await ["token": req.jwt.sign(payload)]
}
```

عند إجراء طلب إلى هذه النقطة النهائية، ستُعيد رمز JWT الموقّع على هيئة `String` في متن الاستجابة، وإذا سار كل شيء وفق الخطة، فسترى شيئًا كهذا:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

يمكنك فك ترميز هذا الرمز والتحقق منه باستخدام [مُنقّح `jwt.io`](https://jwt.io/#debugger). سيعرض لك المُنقّح حمولة رمز JWT (والتي ينبغي أن تكون البيانات التي حددتها سابقًا) وترويسته، ويمكنك التحقق من التوقيع باستخدام المفتاح السرّي الذي استخدمته لتوقيع رمز JWT.

### التحقق

عندما يُرسَل رمز إلى تطبيقك بدلًا من ذلك، يمكنك التحقق من صحة الرمز عن طريق استدعاء الدالة `verify` على وحدة `JWT`:

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

سيفحص المساعد `req.jwt.verify` ترويسة `Authorization` بحثًا عن رمز حامل (bearer token). فإذا وُجد واحد، فسيحلّل رمز JWT ويتحقق من توقيعه ومطالباته. وإذا فشلت أيٌّ من هذه الخطوات، فسيُطرح خطأ 401 Unauthorized.

اختبر المسار بإرسال طلب HTTP التالي:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

إذا سار كل شيء بنجاح، فستُعاد استجابة `200 OK` وستُطبع الحمولة:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

يمكن العثور على تدفق المصادقة بالكامل في [المصادقة &rarr; JWT](authentication.md#jwt).

## الخوارزميات

يمكن توقيع رموز JWT باستخدام مجموعة متنوعة من الخوارزميات.

لإضافة مفتاح إلى سلسلة المفاتيح، تتوفّر نسخة محمّلة زائدًا (overload) من الدالة `add` لكل من الخوارزميات التالية:

### HMAC

إن HMAC (رمز مصادقة الرسائل المبني على التجزئة) هو خوارزمية متماثلة تستخدم مفتاحًا سرّيًا لتوقيع رمز JWT والتحقق منه. يدعم Vapor خوارزميات HMAC التالية:

- `HS256`: HMAC مع SHA-256
- `HS384`: HMAC مع SHA-384
- `HS512`: HMAC مع SHA-512

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

إن ECDSA (خوارزمية التوقيع الرقمي بالمنحنى الإهليلجي) هي خوارزمية غير متماثلة تستخدم زوج مفاتيح عام/خاص لتوقيع رمز JWT والتحقق منه. ويعتمد الاعتماد عليها على الرياضيات المحيطة بالمنحنيات الإهليلجية. يدعم Vapor خوارزميات ECDSA التالية:

- `ES256`: ECDSA مع منحنى P-256 وSHA-256
- `ES384`: ECDSA مع منحنى P-384 وSHA-384
- `ES512`: ECDSA مع منحنى P-521 وSHA-512

توفّر جميع الخوارزميات مفتاحًا عامًا ومفتاحًا خاصًا، مثل `ES256PublicKey` و`ES256PrivateKey`. يمكنك إضافة مفاتيح ECDSA باستخدام صيغة PEM:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialize an ECDSA key with public PEM.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

أو توليد مفاتيح عشوائية (مفيدة للاختبار):

```swift
let key = ES256PrivateKey()
```

لإضافة المفتاح إلى سلسلة المفاتيح:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

إن EdDSA (خوارزمية التوقيع الرقمي بمنحنى إدواردز) هي خوارزمية غير متماثلة تستخدم زوج مفاتيح عام/خاص لتوقيع رمز JWT والتحقق منه. وهي مشابهة لـ ECDSA من حيث اعتماد كلتيهما على خوارزمية DSA، لكن EdDSA مبنية على منحنى إدواردز، وهو عائلة مختلفة من المنحنيات الإهليلجية، وتتمتع بتحسينات طفيفة في الأداء. غير أنها أحدث أيضًا، وبالتالي أقل دعمًا على نطاق واسع. لا يدعم Vapor سوى خوارزمية `EdDSA` التي تستخدم منحنى `Ed25519`.

يمكنك إنشاء مفتاح EdDSA باستخدام إحداثيه (على هيئة `String` مُرمّز بترميز base-64)، وهو `x` إذا كان مفتاحًا عامًا و`d` إذا كان مفتاحًا خاصًا:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

يمكنك أيضًا توليد مفاتيح عشوائية:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

لإضافة المفتاح إلى سلسلة المفاتيح:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

إن RSA (ريفست-شامير-أدلمان) هي خوارزمية غير متماثلة تستخدم زوج مفاتيح عام/خاص لتوقيع رمز JWT والتحقق منه.

!!! warning "تحذير"
    كما سترى، فإن مفاتيح RSA محصورة خلف مجال أسماء `Insecure` لتثبيط المستخدمين الجدد عن استخدامها. وذلك لأن RSA تُعتبر أقل أمانًا من ECDSA وEdDSA، وينبغي استخدامها لأسباب التوافق فقط.
    إن أمكن، استخدم أيًّا من الخوارزميات الأخرى بدلًا منها.

يدعم Vapor خوارزميات RSA التالية:

- `RS256`: RSA مع SHA-256
- `RS384`: RSA مع SHA-384
- `RS512`: RSA مع SHA-512

يمكنك إنشاء مفتاح RSA باستخدام صيغته PEM:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialize an RSA key with public pem.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

أو باستخدام مكوّناته:

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning "تحذير"
    لا تدعم الحزمة مفاتيح RSA الأصغر من 2048 بت.

بعد ذلك يمكنك إضافة المفتاح إلى مجموعة المفاتيح:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

بالإضافة إلى خوارزمية RSA-PKCS1v1.5، يدعم Vapor أيضًا خوارزمية RSA-PSS. إن PSS (مخطط التوقيع الاحتمالي) هو مخطط حشو أكثر أمانًا لتوقيعات RSA. ويُوصى باستخدام PSS بدلًا من PKCS1v1.5 حيثما أمكن.

تختلف الخوارزمية فقط في مرحلة التوقيع، مما يعني أن المفاتيح هي نفسها مفاتيح RSA، إلا أنك تحتاج إلى تحديد مخطط الحشو عند إضافتها إلى مجموعة المفاتيح:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## معرّف المفتاح (kid)

عند إضافة مفتاح إلى مجموعة المفاتيح، يمكنك أيضًا تحديد معرّف مفتاح (kid). وهو معرّف فريد للمفتاح يمكن استخدامه للبحث عن المفتاح في المجموعة.

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

إذا لم تحدد `kid`، فسيُعيَّن المفتاح كمفتاح افتراضي.

!!! note "ملاحظة"
    سيُستبدل المفتاح الافتراضي إذا أضفت مفتاحًا آخر بدون `kid`.

عند توقيع رمز JWT، يمكنك تحديد `kid` المراد استخدامه:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

أما عند التحقق، فيُستخرج `kid` تلقائيًا من ترويسة رمز JWT ويُستخدم للبحث عن المفتاح في المجموعة. يوجد أيضًا معامل `iteratingKeys` في دالة التحقق يتيح لك تحديد ما إذا كان يجب المرور على جميع المفاتيح في المجموعة إذا لم يُعثر على `kid`.

## المطالبات

تتضمن حزمة JWT في Vapor عدة مساعدات لتنفيذ [مطالبات JWT](https://tools.ietf.org/html/rfc7519#section-4.1) الشائعة.

|المطالبة|النوع|دالة التحقق|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|غير متوفرة|
|`iat`|`IssuedAtClaim`|غير متوفرة|
|`iss`|`IssuerClaim`|غير متوفرة|
|`locale`|`LocaleClaim`|غير متوفرة|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|غير متوفرة|

ينبغي التحقق من جميع المطالبات في دالة `JWTPayload.verify`. إذا كانت المطالبة تمتلك دالة تحقق خاصة، فيمكنك استخدامها. وإلا، فاصل إلى قيمة المطالبة باستخدام `value` وتحقق من أنها صالحة.

## JWK

إن مفتاح JSON على الويب (JWK) هو بنية بيانات JSON تمثّل مفتاحًا تشفيريًا ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). وتُستخدم هذه المفاتيح عادةً لتزويد العملاء بمفاتيح للتحقق من رموز JWT.

على سبيل المثال، تستضيف Apple مجموعة مفاتيح JWKS الخاصة بميزة "تسجيل الدخول باستخدام Apple" على عنوان URL التالي.

```http
GET https://appleid.apple.com/auth/keys
```

يوفّر Vapor أدوات مساعدة لإضافة مفاتيح JWK إلى مجموعة المفاتيح:

```swift
let privateKey = """
{
    "kty": "RSA",
    "d": "\(rsaPrivateExponent)",
    "e": "AQAB",
    "use": "sig",
    "kid": "1234",
    "alg": "RS256",
    "n": "\(rsaModulus)"
}
"""

let jwk = try JWK(json: privateKey)
try await app.jwt.keys.use(jwk: jwk)
```

سيؤدي هذا إلى إضافة مفتاح JWK إلى مجموعة المفاتيح، ويمكنك استخدامه لتوقيع رموز JWT والتحقق منها كما تفعل مع أي مفتاح آخر.

### JWKs

إذا كان لديك عدة مفاتيح JWK، فيمكنك إضافتها بالطريقة نفسها:

```swift
let json = """
{
    "keys": [
        {"kty": "RSA", "alg": "RS256", "kid": "a", "n": "\(rsaModulus)", "e": "AQAB"},
        {"kty": "RSA", "alg": "RS512", "kid": "b", "n": "\(rsaModulus)", "e": "AQAB"},
    ]
}
"""

try await app.jwt.keys.use(jwksJSON: json)
```

## المزوّدون

يوفّر Vapor واجهات برمجة تطبيقات للتعامل مع رموز JWT من جهات الإصدار الشائعة أدناه.

### Apple

أولًا، هيّئ معرّف تطبيق Apple الخاص بك.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

ثم استخدم المساعد `req.jwt.apple` لجلب رمز JWT من Apple والتحقق منه.

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

أولًا، هيّئ معرّف تطبيق Google واسم نطاق G Suite الخاص بك.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

ثم استخدم المساعد `req.jwt.google` لجلب رمز JWT من Google والتحقق منه.

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

أولًا، هيّئ معرّف تطبيق Microsoft الخاص بك.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

ثم استخدم المساعد `req.jwt.microsoft` لجلب رمز JWT من Microsoft والتحقق منه.

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
