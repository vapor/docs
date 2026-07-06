# Supervisor

إن [Supervisor](http://supervisord.org) هو نظام للتحكم في العمليات يجعل من السهل تشغيل تطبيق Vapor الخاص بك وإيقافه وإعادة تشغيله.

## التثبيت

يمكن تثبيت Supervisor عبر مديري الحزم على Linux.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS و Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## الإعداد

يجب أن يكون لكل تطبيق Vapor على خادمك ملف إعداد خاص به. بالنسبة لمشروع `Hello` كمثال، سيكون ملف الإعداد موجوداً في `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

كما هو محدد في ملف الإعداد الخاص بنا، يقع مشروع `Hello` في المجلد الرئيسي للمستخدم `vapor`. تأكد من أن `directory` يشير إلى المجلد الجذري لمشروعك حيث يوجد ملف `Package.swift`.

ستعطّل الراية `--env production` التسجيل المُطوّل.

### البيئة

يمكنك تصدير المتغيرات إلى تطبيق Vapor الخاص بك باستخدام Supervisor. لتصدير عدة قيم بيئية، ضعها كلها في سطر واحد. وفقاً لـ [توثيق Supervisor](http://supervisord.org/configuration.html#program-x-section-values):

> يجب أن تُوضع القيم التي تحتوي على أحرف غير أبجدية-رقمية بين علامتَي اقتباس (مثل ‏KEY="val:123",KEY2="val,456"). وإلا، فإن وضع القيم بين علامتَي اقتباس اختياري لكنه موصى به.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

يمكن استخدام المتغيرات المُصدَّرة في Vapor باستخدام `Environment.get`

```swift
let port = Environment.get("PORT")
```

## البدء

يمكنك الآن تحميل تطبيقك وتشغيله.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "ملاحظة"
    ربما يكون أمر `add` قد شغّل تطبيقك بالفعل.
