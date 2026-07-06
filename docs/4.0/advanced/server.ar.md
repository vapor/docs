# الخادم

يتضمن Vapor خادم HTTP عالي الأداء وغير متزامن مبنيًا على [SwiftNIO](https://github.com/apple/swift-nio). يدعم هذا الخادم HTTP/1 وHTTP/2 وترقيات البروتوكول مثل [WebSockets](websockets.md). كما يدعم الخادم تفعيل TLS (SSL).

## الإعداد

يمكن إعداد خادم HTTP الافتراضي في Vapor عبر `app.http.server`.

```swift
// Only support HTTP/2
app.http.server.configuration.supportVersions = [.two]
```

يدعم خادم HTTP عدة خيارات إعداد.

### اسم المضيف (Hostname)

يتحكم اسم المضيف في العنوان الذي سيقبل الخادم عليه اتصالات جديدة. القيمة الافتراضية هي `127.0.0.1`.

```swift
// Configure custom hostname.
app.http.server.configuration.hostname = "dev.local"
```

يمكن تجاوز اسم المضيف في إعداد الخادم عبر تمرير الراية `--hostname` (`-H`) إلى الأمر `serve` أو عبر تمرير المعامل `hostname` إلى `app.server.start(...)`.

```sh
# Override configured hostname.
swift run App serve --hostname dev.local
```

### المنفذ (Port)

يتحكم خيار المنفذ في المنفذ الذي سيقبل الخادم عليه اتصالات جديدة عند العنوان المحدد. القيمة الافتراضية هي `8080`.

```swift
// Configure custom port.
app.http.server.configuration.port = 1337
```

!!! info "معلومة"
    قد يكون `sudo` مطلوبًا للربط بالمنافذ الأقل من `1024`. المنافذ الأكبر من `65535` غير مدعومة.


يمكن تجاوز المنفذ في إعداد الخادم عبر تمرير الراية `--port` (`-p`) إلى الأمر `serve` أو عبر تمرير المعامل `port` إلى `app.server.start(...)`.

```sh
# Override configured port.
swift run App serve --port 1337
```

### قائمة الانتظار المُعلَّقة (Backlog)

يُعرّف المعامل `backlog` الطول الأقصى لقائمة انتظار الاتصالات المُعلَّقة. القيمة الافتراضية هي `256`.

```swift
// Configure custom backlog.
app.http.server.configuration.backlog = 128
```

### إعادة استخدام العنوان (Reuse Address)

يتيح المعامل `reuseAddress` إعادة استخدام العناوين المحلية. القيمة الافتراضية هي `true`.

```swift
// Disable address reuse.
app.http.server.configuration.reuseAddress = false
```

### TCP بلا تأخير (TCP No Delay)

يؤدي تفعيل المعامل `tcpNoDelay` إلى محاولة تقليل تأخير حزم TCP إلى الحد الأدنى. القيمة الافتراضية هي `true`.

```swift
// Minimize packet delay.
app.http.server.configuration.tcpNoDelay = true
```

### ضغط الاستجابة (Response Compression)

يتحكم المعامل `responseCompression` في ضغط استجابة HTTP باستخدام gzip. القيمة الافتراضية هي `.disabled`.

```swift
// Enable HTTP response compression.
app.http.server.configuration.responseCompression = .enabled
```

لتحديد سعة مخزن مؤقت (buffer) أولية، استخدم المعامل `initialByteBufferCapacity`.

```swift
.enabled(initialByteBufferCapacity: 1024)
```

### فك ضغط الطلب (Request Decompression)

يتحكم المعامل `requestDecompression` في فك ضغط طلب HTTP باستخدام gzip. القيمة الافتراضية هي `.disabled`.

```swift
// Enable HTTP request decompression.
app.http.server.configuration.requestDecompression = .enabled
```

لتحديد حد لفك الضغط، استخدم المعامل `limit`. القيمة الافتراضية هي `.ratio(10)`.

```swift
// No decompression size limit
.enabled(limit: .none)
```

الخيارات المتاحة هي:

- `size`: الحجم الأقصى بعد فك الضغط بالبايتات.
- `ratio`: الحجم الأقصى بعد فك الضغط كنسبة من البايتات المضغوطة.
- `none`: بلا حدود للحجم.

يمكن أن يساعد ضبط حدود حجم فك الضغط في منع طلبات HTTP المضغوطة بشكل خبيث من استخدام كميات كبيرة من الذاكرة.

### المعالجة الأنبوبية (Pipelining)

يُفعّل المعامل `supportPipelining` دعم المعالجة الأنبوبية لطلبات واستجابات HTTP. القيمة الافتراضية هي `false`.

```swift
// Support HTTP pipelining.
app.http.server.configuration.supportPipelining = true
```

### الإصدارات (Versions)

يتحكم المعامل `supportVersions` في إصدارات HTTP التي سيستخدمها الخادم. افتراضيًا، سيدعم Vapor كلًا من HTTP/1 وHTTP/2 عند تفعيل TLS. لا يُدعم سوى HTTP/1 عند تعطيل TLS.

```swift
// Disable HTTP/1 support.
app.http.server.configuration.supportVersions = [.two]
```

### TLS

يتحكم المعامل `tlsConfiguration` في ما إذا كان TLS (SSL) مُفعّلًا على الخادم. القيمة الافتراضية هي `nil`.

```swift
// Enable TLS.
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/to/key.pem", format: .pem))
)
```

لكي يُترجَم هذا الإعداد، تحتاج إلى إضافة `import NIOSSL` في أعلى ملف الإعداد لديك. قد تحتاج أيضًا إلى إضافة NIOSSL كاعتمادية (dependency) في ملف Package.swift لديك.

### الاسم (Name)

يتحكم المعامل `serverName` في ترويسة `Server` على استجابات HTTP الصادرة. القيمة الافتراضية هي `nil`.

```swift
// Add 'Server: vapor' header to responses.
app.http.server.configuration.serverName = "vapor"
```

## الأمر serve

لبدء تشغيل خادم Vapor، استخدم الأمر `serve`. سيُشغَّل هذا الأمر افتراضيًا إذا لم تُحدَّد أوامر أخرى.

```swift
swift run App serve
```

يقبل الأمر `serve` المعاملات التالية:

- `hostname` (`-H`): يتجاوز اسم المضيف المُعدّ.
- `port` (`-p`): يتجاوز المنفذ المُعدّ.
- `bind` (`-b`): يتجاوز اسم المضيف والمنفذ المُعدّين مجموعين بـ `:`.

مثال باستخدام الراية `--bind` (`-b`):

```swift
swift run App serve -b 0.0.0.0:80
```

استخدم `swift run App serve --help` لمزيد من المعلومات.

سيستمع الأمر `serve` إلى `SIGTERM` و`SIGINT` لإيقاف تشغيل الخادم بسلاسة. استخدم `ctrl+c` (`^c`) لإرسال إشارة `SIGINT`. عند ضبط مستوى السجل (log level) على `debug` أو أقل، ستُسجَّل معلومات حول حالة الإيقاف السلس.

## البدء اليدوي

يمكن بدء خادم Vapor يدويًا باستخدام `app.server`.

```swift
// Start Vapor's server.
try app.server.start()
// Request server shutdown.
app.server.shutdown()
// Wait for the server to shutdown.
try app.server.onShutdown.wait()
```

## الخوادم

الخادم الذي يستخدمه Vapor قابل للإعداد. افتراضيًا، يُستخدم خادم HTTP المدمج.

```swift
app.servers.use(.http)
```

### خادم مخصص

يمكن استبدال خادم HTTP الافتراضي في Vapor بأي نوع يتوافق مع `Server`.

```swift
import Vapor

final class MyServer: Server {
    ...
}

app.servers.use { app in
    MyServer()
}
```

يمكن للخوادم المخصصة أن تُوسِّع `Application.Servers.Provider` لصياغة النقطة البادئة (leading-dot syntax).

```swift
extension Application.Servers.Provider {
    static var myServer: Self {
        .init {
            $0.servers.use { app in
                MyServer()
            }
        }
    }
}

app.servers.use(.myServer)
```
