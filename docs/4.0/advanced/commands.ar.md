# Commands

تتيح لك واجهة الأوامر (Command API) في Vapor بناء دوال سطر أوامر مخصّصة والتفاعل مع الطرفية. وهي ما بُنيت عليه أوامر Vapor الافتراضية مثل `serve` و`routes` و`migrate`.

## الأوامر الافتراضية

يمكنك معرفة المزيد عن أوامر Vapor الافتراضية باستخدام الخيار `--help`.

```sh
swift run App --help
```

يمكنك استخدام `--help` على أمر معيّن لمعرفة المُعطيات (arguments) والخيارات (options) التي يقبلها.

```sh
swift run App serve --help
```

### Xcode

يمكنك تشغيل الأوامر في Xcode بإضافة مُعطيات إلى مخطّط (scheme) `App`. للقيام بذلك، اتبع هذه الخطوات:

- اختر مخطّط `App` (يمين أزرار التشغيل/الإيقاف)
- انقر "Edit Scheme"
- اختر منتج "App"
- حدّد علامة التبويب "Arguments"
- أضف اسم الأمر إلى "Arguments Passed On Launch" (أي `serve`)

## الأوامر المخصّصة

يمكنك إنشاء أوامرك الخاصة عبر إنشاء أنواع تتوافق مع `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

إضافة الأمر المخصّص إلى `app.asyncCommands` ستجعله متاحًا عبر `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

للتوافق مع `AsyncCommand`، يجب أن تنفّذ الطريقة `run`. يتطلّب هذا الإعلان عن `Signature`. يجب أيضًا أن تقدّم نص مساعدة افتراضيًا.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Hello, world!")
    }
}
```

هذا المثال البسيط للأمر ليس له مُعطيات أو خيارات، لذا اترك التوقيع (signature) فارغًا.

يمكنك الوصول إلى الطرفية (console) الحالية عبر السياق (context) المُقدَّم. تحتوي الطرفية على العديد من الطرق المفيدة لطلب إدخال المستخدم، وتنسيق المخرجات، والمزيد.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

اختبر أمرك بتشغيل:

```sh
swift run App hello
```

### Cowsay

ألقِ نظرة على إعادة إنشاء الأمر الشهير [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) كمثال على استخدام `@Argument` و`@Option`.

```swift
import Vapor

struct Cowsay: AsyncCommand {
    struct Signature: CommandSignature {
        @Argument(name: "message")
        var message: String

        @Option(name: "eyes", short: "e")
        var eyes: String?

        @Option(name: "tongue", short: "t")
        var tongue: String?
    }

    var help: String {
        "Generates ASCII picture of a cow with a message."
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let eyes = signature.eyes ?? "oo"
        let tongue = signature.tongue ?? "  "
        let cow = #"""
          < $M >
                  \   ^__^
                   \  ($E)\_______
                      (__)\       )\/\
                       $T ||----w |
                          ||     ||
        """#.replacingOccurrences(of: "$M", with: signature.message)
            .replacingOccurrences(of: "$E", with: eyes)
            .replacingOccurrences(of: "$T", with: tongue)
        context.console.print(cow)
    }
}
```

جرّب إضافة هذا إلى تطبيقك وتشغيله.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
