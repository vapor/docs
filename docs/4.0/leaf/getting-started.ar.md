# Leaf

إن Leaf لغة قوالب قوية بصياغة مستوحاة من Swift. يمكنك استخدامها لإنشاء صفحات HTML ديناميكية لموقع واجهة أمامية أو إنشاء رسائل بريد إلكتروني غنية لإرسالها من واجهة برمجية.

## الحزمة

الخطوة الأولى لاستخدام Leaf هي إضافته كاعتمادية إلى مشروعك في ملف بيان حزمة SPM.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## التهيئة

بمجرد إضافة الحزمة إلى مشروعك، يمكنك تهيئة Vapor لاستخدامها. عادةً ما يُجرى ذلك في [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

يخبر هذا Vapor باستخدام `LeafRenderer` عند استدعاء `req.view` في رمزك.

!!! warning "تحذير"
    كي يتمكن Leaf من العثور على القوالب عند التشغيل من Xcode، يجب أن تضبط [دليل العمل المخصص](../getting-started/xcode.md#دليل-عمل-مخصّص-custom-working-directory) لمساحة عمل Xcode الخاصة بك.

### التخزين المؤقت لتصيير الصفحات

يملك Leaf ذاكرة تخزين مؤقت داخلية لتصيير الصفحات. عندما تُضبط بيئة `Application` على `.development`، تُعطَّل هذه الذاكرة المؤقتة، بحيث تسري التغييرات على القوالب فورًا. في `.production` وجميع البيئات الأخرى، تكون الذاكرة المؤقتة مفعّلة افتراضيًا. لن تسري أي تغييرات تُجرى على القوالب حتى تُعاد بدء تشغيل التطبيق.

لتعطيل ذاكرة Leaf المؤقتة، افعل ما يلي:

```swift
app.leaf.cache.isEnabled = false
```

!!! warning "تحذير"
    مع أن تعطيل الذاكرة المؤقتة مفيد لتصحيح الأخطاء، فإنه غير موصى به لبيئات الإنتاج لأنه قد يؤثر بشكل كبير على الأداء بسبب الحاجة إلى إعادة تجميع القوالب في كل طلب.

## هيكل المجلدات

بمجرد تهيئة Leaf، ستحتاج إلى التأكد من امتلاكك مجلد `Views` لتخزين ملفات `.leaf` الخاصة بك فيه. افتراضيًا، يتوقع Leaf أن يكون مجلد views في `./Resources/Views` نسبةً إلى جذر مشروعك.

من المرجح أيضًا أنك سترغب في تفعيل [`FileMiddleware`](https://api.vapor.codes/vapor/filemiddleware) في Vapor لتقديم الملفات من مجلد `/Public` إذا كنت تخطط لتقديم ملفات Javascript وCSS على سبيل المثال.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## تصيير عرض

الآن وقد جرت تهيئة Leaf، لنصيّر قالبك الأول. داخل مجلد `Resources/Views`، أنشئ ملفًا جديدًا باسم `hello.leaf` بالمحتويات التالية:

```leaf
Hello, #(name)!
```

!!! tip "نصيحة"
    إذا كنت تستخدم VSCode كمحرر رموز، فنوصي بتثبيت امتداد Vapor لتفعيل تمييز الصياغة: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

ثم سجّل مسارًا (يُجرى ذلك عادةً في `routes.swift` أو في متحكّم) لتصيير العرض.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

يستخدم هذا الخاصية العامة `view` على `Request` بدلًا من استدعاء Leaf مباشرةً. يتيح لك ذلك التبديل إلى مُصيّر مختلف في اختباراتك.


افتح متصفحك وزُر `/hello`. ينبغي أن ترى `Hello, Leaf!`. تهانينا على تصيير أول عرض Leaf لك!
