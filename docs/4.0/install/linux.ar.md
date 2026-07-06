# التثبيت على Linux

لاستخدام Vapor، ستحتاج إلى Swift 5.9 أو أحدث. يمكن تثبيت هذا باستخدام أداة سطر الأوامر [Swiftly](https://swiftlang.github.io/swiftly/) المقدّمة من Swift Server Workgroup (موصى بها)، أو سلاسل الأدوات المتاحة على [Swift.org](https://swift.org/download/).

## التوزيعات والإصدارات المدعومة

يدعم Vapor نفس إصدارات توزيعات Linux التي يدعمها Swift 5.9 أو الإصدارات الأحدث. يُرجى الرجوع إلى [صفحة الدعم الرسمية](https://www.swift.org/platform-support/) للعثور على معلومات محدّثة حول أنظمة التشغيل المدعومة رسمياً.

قد تعمل توزيعات Linux غير المدعومة رسمياً أيضاً مع Swift عن طريق تجميع الكود المصدري، لكن لا يمكن لـ Vapor إثبات الاستقرار. تعرّف على المزيد حول تجميع Swift من [مستودع Swift](https://github.com/apple/swift#getting-started).

## تثبيت Swift

### التثبيت الآلي باستخدام أداة سطر الأوامر Swiftly (موصى به)

قم بزيارة [موقع Swiftly](https://swiftlang.github.io/swiftly/) للحصول على تعليمات حول كيفية تثبيت Swiftly وSwift على Linux. بعد ذلك، ثبّت Swift باستخدام الأمر التالي:

#### الاستخدام الأساسي

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### التثبيت اليدوي باستخدام سلسلة الأدوات

قم بزيارة دليل [Using Downloads](https://swift.org/download/#using-downloads) من Swift.org للحصول على تعليمات حول كيفية تثبيت Swift على Linux.

### Fedora

يمكن لمستخدمي Fedora ببساطة استخدام الأمر التالي لتثبيت Swift:

```sh
sudo dnf install swift-lang
```

إذا كنت تستخدم Fedora 35، فستحتاج إلى إضافة EPEL 8 للحصول على Swift 5.9 أو الإصدارات الأحدث.

## Docker

يمكنك أيضاً استخدام صور Docker الرسمية لـ Swift التي تأتي مع المُصرّف (compiler) مثبّتاً مسبقاً. تعرّف على المزيد على [Swift's Docker Hub](https://hub.docker.com/_/swift).

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
