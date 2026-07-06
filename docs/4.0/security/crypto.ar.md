# Crypto

يتضمن Vapor مكتبة [SwiftCrypto](https://github.com/apple/swift-crypto/)، وهي نسخة متوافقة مع Linux من مكتبة CryptoKit الخاصة بـ Apple. وتُتاح بعض واجهات برمجة التطبيقات التشفيرية الإضافية لأشياء لا تمتلكها SwiftCrypto بعد، مثل [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) و[TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm).

## SwiftCrypto

تُنفّذ مكتبة `Crypto` الخاصة بـ Swift واجهة برمجة تطبيقات CryptoKit من Apple. ولذلك، فإن [توثيق CryptoKit](https://developer.apple.com/documentation/cryptokit) و[محاضرة WWDC](https://developer.apple.com/videos/play/wwdc2019/709) موردان رائعان لتعلّم هذه الواجهة.

ستتوفّر واجهات برمجة التطبيقات هذه تلقائيًا عند استيراد Vapor.

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

تتضمن CryptoKit دعمًا لما يلي:

- التجزئة: `SHA512` و`SHA384` و`SHA256`
- رموز مصادقة الرسائل: `HMAC`
- التشفير: `AES` و`ChaChaPoly`
- تشفير المفتاح العام: `Curve25519` و`P521` و`P384` و`P256`
- التجزئة غير الآمنة: `SHA1` و`MD5`

## Bcrypt

إن Bcrypt هي خوارزمية تجزئة لكلمات المرور تستخدم مِلحًا عشوائيًا (salt) لضمان ألّا ينتج عن تجزئة كلمة المرور نفسها عدة مرات نفس ناتج التجزئة.

يوفّر Vapor نوع `Bcrypt` لتجزئة كلمات المرور ومقارنتها.

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

لأن Bcrypt تستخدم مِلحًا، لا يمكن مقارنة تجزئات كلمات المرور مباشرةً. يجب التحقق من كلمة المرور النصية الصريحة وناتج التجزئة الموجود معًا.

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
    // Password and digest match.
} else {
    // Wrong password.
}
```

يمكن تنفيذ تسجيل الدخول بكلمات مرور Bcrypt عن طريق جلب ناتج تجزئة كلمة مرور المستخدم أولًا من قاعدة البيانات بواسطة البريد الإلكتروني أو اسم المستخدم. ثم يمكن التحقق من ناتج التجزئة المعروف مقابل كلمة المرور النصية الصريحة المُقدَّمة.

## OTP

يدعم Vapor كلا نوعي كلمات المرور لمرة واحدة HOTP وTOTP. تعمل كلمات المرور لمرة واحدة (OTP) مع دوال التجزئة SHA-1 وSHA-256 وSHA-512، ويمكنها توفير ناتج مكوّن من ستة أو سبعة أو ثمانية أرقام. توفّر كلمة المرور لمرة واحدة مصادقةً عن طريق توليد كلمة مرور مقروءة للإنسان تُستخدم مرة واحدة. ولفعل ذلك، تتفق الأطراف أولًا على مفتاح متماثل، يجب أن يبقى خاصًا في جميع الأوقات للحفاظ على أمان كلمات المرور المولَّدة.

#### HOTP

إن HOTP هي كلمة مرور لمرة واحدة مبنية على توقيع HMAC. بالإضافة إلى المفتاح المتماثل، يتفق الطرفان أيضًا على عدّاد، وهو رقم يوفّر تفرّدًا لكلمة المرور. وبعد كل محاولة توليد، يُزاد العدّاد.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Or using the static generate function
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

إن TOTP هي تنويعة مبنية على الوقت من HOTP. وهي تعمل بالطريقة نفسها في معظمها، لكن بدلًا من عدّاد بسيط، يُستخدم الوقت الحالي لتوليد التفرّد. وللتعويض عن الانحراف الحتمي الناتج عن الساعات غير المتزامنة، وزمن استجابة الشبكة، وتأخير المستخدم، وعوامل مُربِكة أخرى، يبقى رمز TOTP المولَّد صالحًا خلال فترة زمنية محددة (30 ثانية في أغلب الأحيان).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Or using the static generate function
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### النطاق
تُعدّ كلمات المرور لمرة واحدة مفيدة جدًا لإتاحة هامش في التحقق ومع العدّادات غير المتزامنة. يمتلك كلا تنفيذي كلمة المرور لمرة واحدة القدرة على توليد كلمة مرور لمرة واحدة مع هامش للخطأ.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Generate a window of correct counters
let codes = hotp.generate(counter: 25, range: 2)
```
يسمح المثال أعلاه بهامش قدره 2، مما يعني أن HOTP ستُحسب لقيم العدّاد `23 ... 27`، وستُعاد جميع هذه الرموز.

!!! warning "تحذير"
    ملاحظة: كلما زاد هامش الخطأ المستخدم، زاد الوقت والحرية المتاحان للمهاجم للتصرف، مما يقلّل من أمان الخوارزمية.
