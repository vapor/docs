# Tracing

التتبّع (Tracing) أداة قوية لمراقبة الأنظمة الموزّعة وتنقيح أخطائها. تتيح واجهة التتبّع في Vapor للمطوّرين تتبّع دورات حياة الطلبات بسهولة، ونشر البيانات الوصفية (metadata)، والتكامل مع الخلفيات (backends) الشائعة مثل OpenTelemetry.

واجهة التتبّع في Vapor مبنية على [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing)، ما يعني أنها متوافقة مع جميع [تطبيقات الخلفية](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) الخاصة بـ swift-distributed-tracing.

إذا لم تكن على دراية بالتتبّع والامتدادات الزمنية (spans) في Swift، فراجع [وثائق تتبّع OpenTelemetry](https://opentelemetry.io/docs/concepts/signals/traces/) و[وثائق swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

لإنشاء امتداد زمني (span) مُعلَّق بالكامل تلقائيًا لكل طلب، أضف `TracingMiddleware` إلى تطبيقك.

```swift
app.middleware.use(TracingMiddleware())
```

للحصول على قياسات دقيقة للامتدادات الزمنية والتأكّد من تمرير معرّفات التتبّع بشكل صحيح إلى الخدمات الأخرى، أضف هذه الوسيطة قبل الوسائط الأخرى.

## إضافة الامتدادات الزمنية

عند إضافة امتدادات زمنية إلى معالجات المسار، يُفضَّل أن ترتبط بالامتداد الزمني للطلب على المستوى الأعلى. يُشار إلى هذا بـ "نشر الامتداد الزمني" (span propagation) ويمكن التعامل معه بطريقتين مختلفتين: تلقائية أو يدوية.

### النشر التلقائي

يدعم Vapor النشر التلقائي للامتدادات الزمنية بين الوسيطة وردود نداء المسار (route callbacks). للقيام بذلك، اضبط الخاصية `Application.traceAutoPropagation` على true أثناء الإعداد.

```swift
app.traceAutoPropagation = true
```

!!! note "ملاحظة"
    قد يؤدي تفعيل النشر التلقائي إلى تدهور الأداء على واجهات API ذات الإنتاجية العالية والاحتياجات التتبّعية الدنيا، لأن البيانات الوصفية للامتداد الزمني للطلب يجب استعادتها لكل معالج مسار بغض النظر عمّا إذا كانت الامتدادات الزمنية تُنشأ أم لا.

بعد ذلك يمكن إنشاء الامتدادات الزمنية في إغلاق المسار (route closure) باستخدام صياغة التتبّع الموزّع العادية.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### النشر اليدوي

لتجنّب التداعيات على الأداء الناتجة عن النشر التلقائي، يمكنك استعادة البيانات الوصفية للامتداد الزمني يدويًا عند الحاجة. تضبط `TracingMiddleware` تلقائيًا الخاصية `Request.serviceContext` التي يمكن استخدامها مباشرة في مُعامِل `context` الخاص بـ `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

لاستعادة البيانات الوصفية للامتداد الزمني دون إنشاء امتداد زمني، استخدم `ServiceContext.withValue`. يكون هذا قيّمًا إذا كنت تعلم أن مكتبات async النهائية (downstream) تُصدر امتداداتها الزمنية الخاصة، وأن هذه يجب أن تتداخل تحت الامتداد الزمني الأصل للطلب.

```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## اعتبارات NIO

بما أن `swift-distributed-tracing` يستخدم [`TaskLocal properties`](https://developer.apple.com/documentation/swift/tasklocal) للنشر، فيجب عليك إعادة استعادة السياق يدويًا كلما عبرت حدود `NIO EventLoopFuture` للتأكّد من ربط الامتدادات الزمنية بشكل صحيح. **هذا ضروري بغض النظر عمّا إذا كان النشر التلقائي مفعّلًا أم لا**.

```swift
app.get("fetchAndProcessNIO") { req in
    withSpan("fetch", context: req.serviceContext) { span in
        fetchSomething().map { result in
            withSpan("process", context: span.context) { _ in
                process(result)
            }
        }
    }
}
```
