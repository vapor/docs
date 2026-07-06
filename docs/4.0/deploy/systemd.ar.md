# Systemd

إن systemd هو مدير النظام والخدمات الافتراضي في معظم توزيعات Linux. وهو مثبَّت افتراضياً في العادة، لذا لا حاجة لتثبيته على توزيعات Swift المدعومة.

## الإعداد

يجب أن يكون لكل تطبيق Vapor على خادمك ملف خدمة خاص به. بالنسبة لمشروع `Hello` كمثال، سيكون ملف الإعداد موجوداً في `/etc/systemd/system/hello.service`. وينبغي أن يبدو هذا الملف كما يلي:

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/App serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

كما هو محدد في ملف الإعداد الخاص بنا، يقع مشروع `Hello` في المجلد الرئيسي للمستخدم `vapor`. تأكد من أن `WorkingDirectory` يشير إلى المجلد الجذري لمشروعك حيث يوجد ملف `Package.swift`.

ستعطّل الراية `--env production` التسجيل المُطوّل.

### البيئة
وإلا، فإن وضع القيم بين علامتَي اقتباس اختياري لكنه موصى به.

يمكنك تصدير المتغيرات بطريقتين عبر systemd. إما بإنشاء ملف بيئة مع ضبط جميع المتغيرات فيه:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


أو يمكنك إضافتها مباشرة إلى ملف الخدمة تحت `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
يمكن استخدام المتغيرات المُصدَّرة في Vapor باستخدام `Environment.get`

```swift
let port = Environment.get("PORT")
```

## البدء

يمكنك الآن تحميل تطبيقك وتفعيله وتشغيله وإيقافه وإعادة تشغيله بتنفيذ ما يلي بوصفك المستخدم root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
