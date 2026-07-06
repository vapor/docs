# التثبيت على macOS

لاستخدام Vapor على macOS، ستحتاج إلى Swift 5.9 أو أحدث. يأتي Swift وجميع اعتمادياته مُجمّعة مع Xcode.

## تثبيت Xcode

ثبّت [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) من Mac App Store.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

بعد تنزيل Xcode، يجب فتحه لإكمال التثبيت. قد يستغرق هذا بعض الوقت.

تحقق مرة أخرى للتأكد من نجاح التثبيت عن طريق فتح الطرفية وطباعة إصدار Swift.

```sh
swift --version
```

من المفترض أن ترى معلومات إصدار Swift مطبوعة.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

يتطلب Vapor 4 الإصدار Swift 5.9 أو أحدث.

## تثبيت Toolbox

الآن وقد ثبّت Swift، لنثبّت [Vapor Toolbox](https://github.com/vapor/toolbox). أداة سطر الأوامر هذه ليست مطلوبة لاستخدام Vapor، لكنها تساعد في إنشاء مشاريع Vapor جديدة.

### Homebrew

يُوزّع Toolbox عبر Homebrew. إذا لم يكن لديك Homebrew بعد، فقم بزيارة <a href="https://brew.sh" target="_blank">brew.sh</a> للحصول على تعليمات التثبيت.

```sh
brew install vapor
```

تحقق مرة أخرى للتأكد من نجاح التثبيت عن طريق طباعة المساعدة.

```sh
vapor --help
```

من المفترض أن ترى قائمة بالأوامر المتاحة.

### Makefile

إذا أردت، يمكنك أيضاً بناء Toolbox من المصدر. اطّلع على <a href="https://github.com/vapor/toolbox/releases" target="_blank">إصدارات</a> Toolbox على GitHub للعثور على أحدث إصدار.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

تحقق مرة أخرى من نجاح التثبيت عن طريق طباعة المساعدة.

```sh
vapor --help
```

من المفترض أن ترى قائمة بالأوامر المتاحة.

## التالي

الآن وقد ثبّت Swift وVapor Toolbox، أنشئ أول تطبيق لك في [البدء &rarr; مرحباً بالعالم](../getting-started/hello-world.md).
