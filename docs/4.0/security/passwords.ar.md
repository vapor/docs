# كلمات المرور

يتضمن Vapor واجهة API لتجزئة كلمات المرور لمساعدتك على تخزين كلمات المرور والتحقق منها بأمان. هذه الواجهة قابلة للتهيئة بناءً على البيئة وتدعم التجزئة غير المتزامنة.

## التهيئة

لتهيئة مُجزِّئ كلمات المرور الخاص بالتطبيق، استخدم `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

لاستخدام [Bcrypt API](crypto.md#bcrypt) الخاص بـ Vapor لتجزئة كلمات المرور، حدِّد `.bcrypt`. هذا هو الافتراضي.

```swift
app.passwords.use(.bcrypt)
```

سيستخدم Bcrypt تكلفة (cost) قدرها 12 ما لم يُحدَّد خلاف ذلك. يمكنك تهيئة هذا عبر تمرير المعامل `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### النص العادي

يتضمن Vapor مُجزِّئ كلمات مرور غير آمن يخزن كلمات المرور ويتحقق منها كنص عادي. لا ينبغي استخدام هذا في الإنتاج لكنه قد يكون مفيدًا للاختبار.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## التجزئة

لتجزئة كلمات المرور، استخدم مساعد `password` المتوفر على `Request`.

```swift
let digest = try req.password.hash("vapor")
```

يمكن التحقق من ملخصات كلمات المرور (digests) مقابل كلمة المرور بالنص العادي باستخدام دالة `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

الواجهة نفسها متوفرة على `Application` للاستخدام أثناء الإقلاع.

```swift
let digest = try app.password.hash("vapor")
```

### Async 

صُمِّمت خوارزميات تجزئة كلمات المرور لتكون بطيئة وكثيفة الاستهلاك لوحدة المعالجة المركزية. لهذا السبب، قد ترغب في تجنب حجب حلقة الأحداث (event loop) أثناء تجزئة كلمات المرور. يوفر Vapor واجهة API غير متزامنة لتجزئة كلمات المرور تُرسل التجزئة إلى مجمّع خيوط في الخلفية. لاستخدام الواجهة غير المتزامنة، استخدم خاصية `async` على مُجزِّئ كلمات المرور.

```swift
req.password.async.hash("vapor").map { digest in
    // Handle digest.
}

// or

let digest = try await req.password.async.hash("vapor")
```

يعمل التحقق من الملخصات (digests) بشكل مشابه:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Handle result.
}

// or

let result = try await req.password.async.verify("vapor", created: digest)
```

يمكن أن يؤدي حساب التجزئات على خيوط في الخلفية إلى تحرير حلقات الأحداث الخاصة بتطبيقك للتعامل مع مزيد من الطلبات الواردة.
