# الأخطاء (Errors)

يعتمد Vapor على بروتوكول `Error` في Swift لمعالجة الأخطاء. يمكن لمعالجات المسارات إما أن تطرح (`throw`) خطأً أو أن تُرجع `EventLoopFuture` فاشلًا. سيؤدي طرح أو إرجاع خطأ `Error` من Swift إلى استجابة بحالة `500`، وسيُسجَّل الخطأ. يمكن استخدام `AbortError` و`DebuggableError` لتغيير الاستجابة الناتجة والتسجيل على التوالي. تتم معالجة الأخطاء بواسطة `ErrorMiddleware`. تُضاف هذه الوسيطة إلى التطبيق افتراضيًا ويمكن استبدالها بمنطق مخصص إذا رغبت في ذلك.

## Abort

يوفر Vapor هيكل خطأ افتراضيًا اسمه `Abort`. يتوافق هذا الهيكل مع كل من `AbortError` و`DebuggableError`. يمكنك تهيئته بحالة HTTP وسبب فشل اختياري.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

في المواقف غير المتزامنة القديمة حيث لا يكون الطرح مدعومًا وعليك إرجاع `EventLoopFuture`، كما هو الحال في مُغلَّف `flatMap`، يمكنك إرجاع future فاشل.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

يتضمن Vapor امتدادًا مساعدًا لفك تغليف الـ futures ذات القيم الاختيارية: `unwrap(or:)`.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

إذا أرجعت `User.find` القيمة `nil`، فسيفشل الـ future بالخطأ المُقدَّم. وإلا، فسيُزوَّد `flatMap` بقيمة غير اختيارية. إذا كنت تستخدم `async`/`await`، فيمكنك التعامل مع القيم الاختيارية كالمعتاد:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## خطأ Abort

افتراضيًا، سيؤدي أي خطأ `Error` من Swift يُطرَح أو يُرجَع من مُغلَّف مسار إلى استجابة `500 Internal Server Error`. عند البناء في وضع التصحيح (debug)، سيتضمن `ErrorMiddleware` وصفًا للخطأ. تُحذف هذه التفاصيل لأسباب أمنية عند بناء المشروع في وضع الإصدار (release).

لتهيئة حالة استجابة HTTP الناتجة أو السبب لخطأ معين، اجعله متوافقًا مع `AbortError`.

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## خطأ قابل للتصحيح (Debuggable Error)

يستخدم `ErrorMiddleware` دالة `Logger.report(error:)` لتسجيل الأخطاء التي تطرحها مساراتك. ستتحقق هذه الدالة من التوافق مع بروتوكولات مثل `CustomStringConvertible` و`LocalizedError` لتسجيل رسائل قابلة للقراءة.

لتخصيص تسجيل الأخطاء، يمكنك جعل أخطائك متوافقة مع `DebuggableError`. يتضمن هذا البروتوكول عددًا من الخصائص المفيدة مثل مُعرِّف فريد، وموقع المصدر، وتتبُّع المكدس (stack trace). معظم هذه الخصائص اختيارية مما يجعل اعتماد التوافق سهلًا.

للتوافق مع `DebuggableError` على أفضل نحو، يجب أن يكون خطؤك هيكلًا (struct) حتى يتمكن من تخزين معلومات المصدر وتتبُّع المكدس عند الحاجة. فيما يلي مثال على تعداد `MyError` المذكور آنفًا وقد جرى تحديثه لاستخدام `struct` والتقاط معلومات مصدر الخطأ.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

يحتوي `DebuggableError` على عدة خصائص أخرى مثل `possibleCauses` و`suggestedFixes` التي يمكنك استخدامها لتحسين قابلية تصحيح أخطائك. ألقِ نظرة على البروتوكول نفسه لمزيد من المعلومات.

## وسيطة الأخطاء (Error Middleware)

`ErrorMiddleware` هي واحدة من الوسيطتين الوحيدتين اللتين تُضافان إلى تطبيقك افتراضيًا. تحوِّل هذه الوسيطة أخطاء Swift التي طُرحت أو أُرجعت من معالجات مساراتك إلى استجابات HTTP. بدون هذه الوسيطة، ستؤدي الأخطاء المطروحة إلى إغلاق الاتصال دون استجابة.

لتخصيص معالجة الأخطاء بما يتجاوز ما يوفره `AbortError` و`DebuggableError`، يمكنك استبدال `ErrorMiddleware` بمنطق معالجة الأخطاء الخاص بك. للقيام بذلك، أزِل أولًا وسيطة الأخطاء الافتراضية عن طريق تهيئة `app.middleware` يدويًا. ثم أضِف وسيطة معالجة الأخطاء الخاصة بك كأول وسيطة في تطبيقك.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

ينبغي لعدد قليل جدًا من الوسيطات أن يأتي _قبل_ وسيطة معالجة الأخطاء. الاستثناء الملحوظ لهذه القاعدة هو `CORSMiddleware`.
