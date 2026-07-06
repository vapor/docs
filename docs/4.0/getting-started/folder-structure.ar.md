# هيكل المجلدات

الآن وقد أنشأت أول تطبيق Vapor خاص بك وبنيته وشغّلته، لنأخذ لحظة للتعرّف على هيكل مجلدات Vapor. يستند الهيكل إلى هيكل مجلدات [SPM](spm.md)، لذا إذا كنت قد عملت مع SPM من قبل فينبغي أن يكون مألوفاً.

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

تشرح الأقسام أدناه كل جزء من هيكل المجلدات بمزيد من التفصيل.

## Public

يحتوي هذا المجلد على أي ملفات عامة سيقدّمها تطبيقك إذا كان `FileMiddleware` مُفعّلاً. عادةً ما تكون هذه صوراً وأوراق أنماط (style sheets) ونصوص متصفح. على سبيل المثال، سيتحقق طلب إلى `localhost:8080/favicon.ico` مما إذا كان `Public/favicon.ico` موجوداً ويعيده.

ستحتاج إلى تفعيل `FileMiddleware` في ملف `configure.swift` قبل أن يتمكن Vapor من تقديم الملفات العامة.

```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

يحتوي هذا المجلد على جميع ملفات مصدر Swift لمشروعك.
المجلد العلوي، `App`، يعكس وحدة حزمتك،
كما هو مُعلن في بيان [SwiftPM](spm.md).

### App

هذا هو المكان الذي يذهب إليه كل منطق تطبيقك.

#### Controllers

تُعد المتحكمات (Controllers) طريقة رائعة لتجميع منطق التطبيق معاً. تحتوي معظم المتحكمات على العديد من الدوال التي تقبل طلباً وتعيد نوعاً ما من الاستجابة.

#### Migrations

مجلد الهجرات (migrations) هو المكان الذي تذهب إليه هجرات قاعدة بياناتك إذا كنت تستخدم Fluent.

#### Models

مجلد النماذج (models) مكان رائع لتخزين هياكل `Content` أو نماذج `Model` الخاصة بـ Fluent.

#### configure.swift

يحتوي هذا الملف على الدالة `configure(_:)`. تُستدعى هذه الطريقة بواسطة `entrypoint.swift` لتكوين `Application` المُنشأ حديثاً. هذا هو المكان الذي يجب أن تسجّل فيه خدمات مثل المسارات وقواعد البيانات والمزوّدين والمزيد.

#### entrypoint.swift

يحتوي هذا الملف على نقطة الدخول `@main` للتطبيق التي تُعدّ تطبيق Vapor الخاص بك وتكوّنه وتشغّله.

#### routes.swift

يحتوي هذا الملف على الدالة `routes(_:)`. تُستدعى هذه الطريقة قرب نهاية `configure(_:)` لتسجيل المسارات في `Application` الخاص بك.

## Tests

يمكن أن يكون لكل وحدة غير تنفيذية في مجلد `Sources` مجلد مقابل في `Tests`. يحتوي هذا على كود مبني على وحدة `XCTest` لاختبار حزمتك. يمكن تشغيل الاختبارات باستخدام `swift test` في سطر الأوامر أو بالضغط على ⌘+U في Xcode.

### AppTests

يحتوي هذا المجلد على اختبارات الوحدة للكود الموجود في وحدة `App` الخاصة بك.

## Package.swift

وأخيراً، بيان الحزمة الخاص بـ [SPM](spm.md).
