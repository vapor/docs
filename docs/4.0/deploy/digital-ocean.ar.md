# النشر على DigitalOcean

سيرشدك هذا الدليل خطوة بخطوة خلال نشر تطبيق Vapor بسيط من نوع "مرحباً بالعالم" على [Droplet](https://www.digitalocean.com/products/droplets/). ولاتّباع هذا الدليل، يجب أن يكون لديك حساب [DigitalOcean](https://www.digitalocean.com) مع إعداد الفوترة.

## إنشاء الخادم

لنبدأ بتثبيت Swift على خادم Linux. استخدم قائمة الإنشاء لإنشاء Droplet جديد.

![إنشاء Droplet](../images/digital-ocean-create-droplet.png)

ضمن التوزيعات، اختر Ubuntu 22.04 LTS. سيستخدم الدليل التالي هذا الإصدار كمثال.

![توزيعة Ubuntu](../images/digital-ocean-distributions-ubuntu.png)

!!! note "ملاحظة"
    يمكنك اختيار أي توزيعة Linux بإصدار يدعمه Swift. يمكنك التحقق من أنظمة التشغيل المدعومة رسمياً في صفحة [إصدارات Swift](https://swift.org/download/#releases).

بعد اختيار التوزيعة، اختر أي خطة ومنطقة مركز بيانات تفضّلها. ثم أعِدّ مفتاح SSH للوصول إلى الخادم بعد إنشائه. وأخيراً، انقر على إنشاء Droplet وانتظر حتى يبدأ الخادم الجديد بالعمل.

بمجرد أن يصبح الخادم الجديد جاهزاً، مرّر المؤشر فوق عنوان IP الخاص بـ Droplet وانقر على نسخ.

![قائمة Droplet](../images/digital-ocean-droplet-list.png)

## الإعداد الأولي

افتح الطرفية واتصل بالخادم بوصفك المستخدم root باستخدام SSH.

```sh
ssh root@your_server_ip
```

يوفّر DigitalOcean دليلاً مفصّلاً حول [الإعداد الأولي للخادم على Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). سيغطي هذا الدليل الأساسيات بسرعة.

### إعداد الجدار الناري

اسمح بمرور OpenSSH عبر الجدار الناري وفعّله.

```sh
ufw allow OpenSSH
ufw enable
```

### إضافة مستخدم

أنشئ مستخدماً جديداً بخلاف `root`. يُسمّي هذا الدليل المستخدم الجديد `vapor`.

```sh
adduser vapor
```

اسمح للمستخدم المُنشأ حديثاً باستخدام `sudo`.

```sh
usermod -aG sudo vapor
```

انسخ مفاتيح SSH المُصرّح بها للمستخدم root إلى المستخدم المُنشأ حديثاً. سيسمح لك هذا بالاتصال عبر SSH بوصفك المستخدم الجديد.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

وأخيراً، اخرج من جلسة SSH الحالية وسجّل الدخول بوصفك المستخدم المُنشأ حديثاً.

```sh
exit
ssh vapor@your_server_ip
```

## تثبيت Swift

الآن وبعد أن أنشأت خادم Ubuntu جديداً وسجّلت الدخول بمستخدم غير root، يمكنك تثبيت Swift.

### التثبيت المؤتمت باستخدام أداة Swiftly CLI (موصى به)

زُر [موقع Swiftly](https://swiftlang.github.io/swiftly/) للاطّلاع على تعليمات تثبيت Swiftly و Swift على Linux. بعد ذلك، ثبّت Swift بالأمر التالي:

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

## تثبيت Vapor باستخدام Vapor Toolbox

الآن وبعد تثبيت Swift، لنثبّت Vapor باستخدام Vapor Toolbox. ستحتاج إلى بناء الـ toolbox من المصدر. اطّلع على [إصدارات](https://github.com/vapor/toolbox/releases) الـ toolbox على GitHub للعثور على أحدث إصدار. في هذا المثال، نستخدم الإصدار 18.6.0.

### استنساخ وبناء Vapor

استنسخ مستودع Vapor Toolbox.

```sh
git clone https://github.com/vapor/toolbox.git
```

تحقّق من أحدث إصدار.

```sh
cd toolbox
git checkout 18.6.0
```

ابنِ Vapor وانقل الملف التنفيذي إلى مسارك.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### إنشاء مشروع Vapor

استخدم أمر المشروع الجديد الخاص بالـ Toolbox لإنشاء مشروع.

```sh
vapor new HelloWorld -n
```

!!! tip "نصيحة"
    تمنحك الراية `-n` قالباً بأبسط الأساسيات عن طريق الإجابة بـ "لا" على جميع الأسئلة تلقائياً.

![شعار Vapor](../images/vapor-splash.png)

بمجرد انتهاء الأمر، انتقل إلى المجلد المُنشأ حديثاً:

```sh
cd HelloWorld
``` 

### فتح منفذ HTTP

للوصول إلى Vapor على خادمك، افتح منفذ HTTP.

```sh
sudo ufw allow 8080
```

### التشغيل

الآن وبعد أن أُعِدّ Vapor ولدينا منفذ مفتوح، لنشغّله.

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

زُر عنوان IP الخاص بخادمك عبر المتصفح أو الطرفية المحلية، ومن المفترض أن ترى "It works!". عنوان IP في هذا المثال هو `134.122.126.139`.

```
$ curl http://134.122.126.139:8080
It works!
```

بالعودة إلى خادمك، من المفترض أن ترى سجلات لطلب الاختبار.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

استخدم `CTRL+C` لإنهاء الخادم. قد يستغرق الأمر ثانية لإيقاف التشغيل.

تهانينا على تشغيل تطبيق Vapor الخاص بك على DigitalOcean Droplet!

## الخطوات التالية

يشير باقي هذا الدليل إلى موارد إضافية لتحسين نشرك.

### Supervisor

إن Supervisor هو نظام للتحكم في العمليات يمكنه تشغيل ملفك التنفيذي لـ Vapor ومراقبته. مع إعداد Supervisor، يمكن لتطبيقك أن يبدأ تلقائياً عند إقلاع الخادم وأن يُعاد تشغيله في حال تعطّله. تعرّف على المزيد حول [Supervisor](../deploy/supervisor.md).

### Nginx

إن Nginx هو خادم HTTP ووكيل سريع للغاية ومُختبَر بشدة وسهل الإعداد. وبينما يدعم Vapor خدمة طلبات HTTP مباشرة، فإن الوكالة خلف Nginx يمكن أن توفر أداءً وأماناً وسهولة استخدام أعلى. تعرّف على المزيد حول [Nginx](../deploy/nginx.md).
