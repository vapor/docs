# البيئة (Environment)

تساعدك واجهة البيئة (Environment API) في Vapor على تهيئة تطبيقك ديناميكيًا. افتراضيًا، سيستخدم تطبيقك بيئة `development`. يمكنك تعريف بيئات مفيدة أخرى مثل `production` أو `staging` وتغيير كيفية تهيئة تطبيقك في كل حالة. يمكنك أيضًا تحميل المتغيرات من بيئة العملية (process) أو من ملفات `.env` (dotenv) حسب احتياجاتك.

للوصول إلى البيئة الحالية، استخدم `app.environment`. يمكنك التبديل بناءً على هذه الخاصية في `configure(_:)` لتنفيذ منطق تهيئة مختلف.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## تغيير البيئة

افتراضيًا، سيعمل تطبيقك في بيئة `development`. يمكنك تغيير ذلك بتمرير الراية `--env` (`-e`) أثناء إقلاع التطبيق.

```swift
swift run App serve --env production
```

يتضمن Vapor البيئات التالية:

|الاسم|المختصر|الوصف|
|-|-|-|
|production|prod|منشور للمستخدمين.|
|development|dev|التطوير المحلي.|
|testing|test|لاختبار الوحدات.|

!!! info "معلومة"
    ستستخدم بيئة `production` مستوى تسجيل `notice` افتراضيًا ما لم يُحدَّد خلاف ذلك. أما جميع البيئات الأخرى فتستخدم `info` افتراضيًا.

يمكنك تمرير الاسم الكامل أو المختصر إلى الراية `--env` (`-e`).

```swift
swift run App serve -e prod
```

## متغيرات العملية

يقدم `Environment` واجهة بسيطة مبنية على السلاسل النصية للوصول إلى متغيرات بيئة العملية.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

بالإضافة إلى `get`، يقدم `Environment` واجهة بحث ديناميكي عن الأعضاء (dynamic member lookup) عبر `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

عند تشغيل تطبيقك في الطرفية (terminal)، يمكنك تعيين متغيرات البيئة باستخدام `export`.

```sh
export FOO=BAR
swift run App serve
```

عند تشغيل تطبيقك في Xcode، يمكنك تعيين متغيرات البيئة عن طريق تحرير مخطط (scheme) `App`.

## ‏.env (dotenv)

تحتوي ملفات dotenv على قائمة من أزواج المفتاح والقيمة التي تُحمَّل تلقائيًا إلى البيئة. تُسهِّل هذه الملفات تهيئة متغيرات البيئة دون الحاجة إلى تعيينها يدويًا.

سيبحث Vapor عن ملفات dotenv في دليل العمل الحالي. إذا كنت تستخدم Xcode، فتأكد من تعيين دليل العمل عن طريق تحرير مخطط `App`.

افترض ملف `.env` التالي موضوعًا في المجلد الجذري لمشاريعك:

```sh
FOO=BAR
```

عند إقلاع تطبيقك، ستتمكن من الوصول إلى محتويات هذا الملف مثل متغيرات بيئة العملية الأخرى.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info "معلومة"
    لن تحل المتغيرات المحددة في ملفات `.env` محل المتغيرات الموجودة بالفعل في بيئة العملية.

إلى جانب `.env`، سيحاول Vapor أيضًا تحميل ملف dotenv للبيئة الحالية. على سبيل المثال، عند وجودك في بيئة `development`، سيحمِّل Vapor ملف `.env.development`. ستكون لأي قيم في ملف البيئة المحددة الأسبقية على ملف `.env` العام.

من الأنماط الشائعة أن تتضمن المشاريع ملف `.env` كقالب بقيم افتراضية. تُتجاهل ملفات البيئة المحددة باستخدام النمط التالي في `.gitignore`:

```gitignore
.env.*
```

عند استنساخ المشروع إلى حاسوب جديد، يمكن نسخ ملف القالب `.env` وإدراج القيم الصحيحة فيه.

```sh
cp .env .env.development
vim .env.development
```

!!! warning "تحذير"
    ينبغي عدم إيداع ملفات dotenv التي تحتوي على معلومات حساسة مثل كلمات المرور في نظام التحكم بالإصدارات.

إذا واجهت صعوبة في تحميل ملفات dotenv، فحاول تفعيل تسجيل التصحيح باستخدام `--log debug` للحصول على مزيد من المعلومات.

## البيئات المخصصة

لتعريف اسم بيئة مخصص، وسِّع `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

عادةً ما تُضبَط بيئة التطبيق في `entrypoint.swift` باستخدام `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

تستخدم دالة `detect` معاملات سطر أوامر العملية وتحلل الراية `--env` تلقائيًا. يمكنك تجاوز هذا السلوك عن طريق تهيئة هيكل `Environment` مخصص.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

يجب أن تحتوي مصفوفة المعاملات على معامل واحد على الأقل يمثل اسم الملف التنفيذي. يمكن تقديم معاملات إضافية لمحاكاة تمرير المعاملات عبر سطر الأوامر. هذا مفيد بشكل خاص للاختبار.
