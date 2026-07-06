# Services

بُنيت `Application` و`Request` في Vapor لتوسيعها بواسطة تطبيقك والحزم الخارجية (third-party packages). غالبًا ما تُسمّى الوظائف الجديدة المضافة إلى هذه الأنواع بالخدمات (services).

## للقراءة فقط

أبسط نوع من الخدمات هو النوع المخصّص للقراءة فقط (read-only). تتكوّن هذه الخدمات من متغيرات محسوبة (computed variables) أو طرق مضافة إلى application أو request.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

يمكن للخدمات المخصّصة للقراءة فقط أن تعتمد على أي خدمات موجودة مسبقًا، مثل `client` في هذا المثال. بمجرد إضافة الامتداد (extension)، يمكن استخدام خدمتك المخصّصة مثل أي خاصية أخرى على request.

```swift
req.myAPI.foos()
```

## قابلة للكتابة

يمكن للخدمات التي تحتاج إلى حالة (state) أو إعداد استخدام مخزن (storage) `Application` و`Request` لتخزين البيانات. لنفترض أنك تريد إضافة البنية `MyConfiguration` التالية إلى تطبيقك.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

لاستخدام المخزن، يجب أن تُعلن عن `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

هذه بنية فارغة مع اسم مستعار (typealias) للنوع `Value` يحدّد النوع الذي يُخزَّن. باستخدام نوع فارغ كمفتاح، يمكنك التحكم في الشيفرة القادرة على الوصول إلى قيمة المخزن الخاصة بك. إذا كان النوع داخليًا (internal) أو خاصًا (private)، فلن تتمكّن سوى شيفرتك من تعديل القيمة المرتبطة في المخزن.

أخيرًا، أضف امتدادًا إلى `Application` لجلب وضبط البنية `MyConfiguration`.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

بمجرد إضافة الامتداد، يمكنك استخدام `myConfiguration` مثل خاصية عادية على `Application`.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## دورة الحياة

تتيح لك `Application` في Vapor تسجيل معالجات دورة الحياة (lifecycle handlers). تتيح لك هذه ربط شيفرتك بأحداث مثل الإقلاع (boot) والإيقاف (shutdown).

```swift
// Prints hello during boot.
struct Hello: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Called after application boots.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Called before application shutdown.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Add lifecycle handler.
app.lifecycle.use(Hello())
```

## الأقفال

تتضمّن `Application` في Vapor أدوات مريحة لمزامنة الشيفرة باستخدام الأقفال (locks). بالإعلان عن `LockKey`، يمكنك الحصول على قفل فريد ومشترك لمزامنة الوصول إلى شيفرتك.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

كل استدعاء لـ `lock(for:)` بنفس `LockKey` سيُرجع القفل نفسه. هذه الطريقة آمنة على مستوى الخيوط (thread-safe).

للحصول على قفل على مستوى التطبيق بأكمله، يمكنك استخدام `app.sync`.

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

الخدمات المخصّصة للاستخدام في معالجات المسار يجب إضافتها إلى `Request`. يجب أن تستخدم خدمات الطلب مُسجِّل الطلب (logger) وحلقة الأحداث (event loop) الخاصة به. من المهم أن يبقى الطلب على نفس حلقة الأحداث، وإلا فسيُصادَف تأكيد (assertion) عند إرجاع الاستجابة إلى Vapor.

إذا كان يتعيّن على خدمة أن تغادر حلقة أحداث الطلب لتنفيذ عمل ما، فيجب أن تتأكّد من العودة إلى حلقة الأحداث قبل الانتهاء. يمكن القيام بذلك باستخدام `hop(to:)` على `EventLoopFuture`.

يمكن لخدمات الطلب التي تحتاج إلى الوصول إلى خدمات التطبيق، مثل الإعدادات، استخدام `req.application`. احرص على مراعاة الأمان على مستوى الخيوط (thread-safety) عند الوصول إلى التطبيق من معالج المسار. عمومًا، ينبغي أن ينفّذ الطلب عمليات القراءة فقط. أما عمليات الكتابة فيجب حمايتها بالأقفال.
