# ما هو Heroku

Heroku حل استضافة متكامل شائع، يمكنك معرفة المزيد على [heroku.com](https://www.heroku.com)

## التسجيل

ستحتاج إلى حساب Heroku، إذا لم يكن لديك واحد، فسجّل هنا: [https://signup.heroku.com/](https://signup.heroku.com/)

## تثبيت CLI

تأكد من أنك ثبّت أداة heroku cli.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### خيارات تثبيت أخرى

راجع خيارات التثبيت البديلة هنا: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### تسجيل الدخول

بمجرد تثبيت cli، سجّل الدخول بما يلي:

```bash
heroku login
```

تحقق من تسجيل الدخول بالبريد الإلكتروني الصحيح بـ:

```bash
heroku auth:whoami
```

### إنشاء تطبيق

زُر dashboard.heroku.com للوصول إلى حسابك، وأنشئ تطبيقًا جديدًا من القائمة المنسدلة في الزاوية العلوية اليمنى. سيطرح Heroku بعض الأسئلة مثل المنطقة واسم التطبيق، فقط اتّبع مطالباته.

### Git

يستخدم Heroku ‏Git لنشر تطبيقك، لذا ستحتاج إلى وضع مشروعك في مستودع Git، إن لم يكن كذلك بالفعل.

#### تهيئة Git

إذا كنت بحاجة إلى إضافة Git إلى مشروعك، فأدخل الأمر التالي في الطرفية:

```bash
git init
```

#### الفرع الرئيسي (Main)

عليك أن تقرّر فرعًا واحدًا وتلتزم به للنشر إلى Heroku، مثل فرع **main** أو **master**. تأكد من إيداع جميع التغييرات في هذا الفرع قبل الدفع (push).

تحقق من فرعك الحالي بـ:

```bash
git branch
```

تشير علامة النجمة إلى الفرع الحالي.

```bash
* main
  commander
  other-branches
```

!!! note "ملاحظة"
    إذا لم ترَ أي مخرجات وكنت قد نفّذت للتو `git init`. فستحتاج إلى إيداع (commit) كودك أولاً ثم سترى مخرجات من الأمر `git branch`.

إذا كنت _لست_ حاليًا على الفرع الصحيح، فانتقل إليه بإدخال (لـ **main**):

```bash
git checkout main
```

#### إيداع التغييرات

إذا أنتج هذا الأمر مخرجات، فلديك تغييرات غير مُودَعة.

```bash
git status --porcelain
```

أودِعها بما يلي

```bash
git add .
git commit -m "a description of the changes I made"
```

#### الاتصال بـ Heroku

اربط تطبيقك بـ heroku (استبدل باسم تطبيقك).

```bash
$ heroku git:remote -a your-apps-name-here
```

### ضبط Buildpack

اضبط الـ buildpack لتعليم heroku كيفية التعامل مع vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### ملف إصدار Swift

يبحث الـ buildpack الذي أضفناه عن ملف **.swift-version** لمعرفة أي إصدار من swift سيُستخدم. (استبدل 5.8.1 بأي إصدار يتطلّبه مشروعك.)

```bash
echo "5.8.1" > .swift-version
```

ينشئ هذا ملف **.swift-version** بمحتوى `5.8.1`.

### Procfile

يستخدم Heroku ملف **Procfile** لمعرفة كيفية تشغيل تطبيقك، في حالتنا يحتاج أن يبدو هكذا:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

يمكننا إنشاء هذا بأمر الطرفية التالي

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### إيداع التغييرات

لقد أضفنا للتو هذه الملفات، لكنها غير مُودَعة. إذا دفعنا (push)، فلن يجدها heroku.

أودِعها بما يلي.

```bash
git add .
git commit -m "adding heroku build files"
```

### النشر إلى Heroku

أنت جاهز للنشر، شغّل هذا من الطرفية. قد يستغرق البناء بعض الوقت، وهذا أمر طبيعي.

```bash
git push heroku main
```

### التوسّع

بمجرد أن تبني بنجاح، تحتاج إلى إضافة خادم واحد على الأقل. تبدأ الأسعار من 5 دولارات شهريًا لخطة Eco (راجع [التسعير](https://www.heroku.com/pricing#containers))، تأكد من أنك أعددت الدفع على Heroku. ثم لعامل ويب واحد:

```bash
heroku ps:scale web=1
```

### النشر المستمر

في أي وقت تريد فيه التحديث، فقط انقل أحدث التغييرات إلى main وادفعها إلى heroku وسيعيد النشر.

## Postgres

### إضافة قاعدة بيانات PostgreSQL

زُر تطبيقك على dashboard.heroku.com وانتقل إلى قسم **Add-ons**.

من هنا أدخل `postgres` وسترى خيار `Heroku Postgres`. اختره.

اختر خطة Essential 0 مقابل 5 دولارات شهريًا (راجع [التسعير](https://www.heroku.com/pricing#data-services))، وقم بالتوفير (provision). سيتولّى Heroku الباقي.

بمجرد الانتهاء، سترى قاعدة البيانات تظهر ضمن علامة التبويب **Resources**.

### إعداد قاعدة البيانات

علينا الآن إخبار تطبيقنا بكيفية الوصول إلى قاعدة البيانات. في مجلد تطبيقنا، لنشغّل.

```bash
heroku config
```

سيُنتج هذا مخرجات تشبه هذه إلى حد ما

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

يمثّل **DATABASE_URL** هنا قاعدة بيانات postgres الخاصة بنا. **لا تُدرج أبدًا** عنوان URL الثابت من هذا بشكل ثابت في الكود، فسيقوم heroku بتدويره وسيؤدي ذلك إلى تعطّل تطبيقك. كما أنها ممارسة سيئة. بدلاً من ذلك، اقرأ متغير البيئة أثناء وقت التشغيل.

تتطلّب إضافة Heroku Postgres [أن تكون](https://devcenter.heroku.com/changelog-items/2035) جميع الاتصالات مشفّرة. الشهادات التي تستخدمها خوادم Postgres داخلية بالنسبة لـ Heroku، لذلك يجب إعداد اتصال TLS **غير مُتحقّق منه** (unverified).

يوضّح المقطع التالي كيفية تحقيق كليهما:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

لا تنسَ إيداع هذه التغييرات

```bash
git add .
git commit -m "configured heroku database"
```

### التراجع عن قاعدة بياناتك

يمكنك التراجع أو تشغيل أوامر أخرى على heroku باستخدام الأمر `run`.

للتراجع عن قاعدة بياناتك:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

للترحيل (migrate):

```bash
heroku run App -- migrate --env production
```
