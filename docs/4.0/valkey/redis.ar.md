# Redis

إن [Redis](https://redis.io/) هو أحد أكثر مخازن بنى البيانات في الذاكرة شيوعًا، ويُستخدم عادةً للتخزين المؤقت أو كوسيط رسائل.

هذه المكتبة هي تكامل بين Vapor و[**RediStack**](https://github.com/swift-server/RediStack)، وهي المُشغّل الأساسي الذي يتواصل مع Redis.

!!! note "ملاحظة"
    توفّر **RediStack** معظم قدرات Redis.
    نوصي بشدة بالإلمام بتوثيقها.

    _تُوفَّر الروابط حيثما كان ذلك مناسبًا._

## الحزمة

الخطوة الأولى لاستخدام Redis هي إضافته كتبعية إلى مشروعك في بيان حزمة Swift.

> هذا المثال مخصص لحزمة موجودة مسبقًا. للمساعدة في بدء مشروع جديد، راجع دليل [البدء](../getting-started/hello-world.md) الرئيسي.

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
]
// ...
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "Redis", package: "redis")
    ])
]
```

## التهيئة

يستخدم Vapor استراتيجية تجميع (pooling) لنسخ [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection)، وتوجد عدة خيارات لتهيئة الاتصالات الفردية وكذلك التجمّعات نفسها.

الحدّ الأدنى المطلوب لتهيئة Redis هو توفير عنوان URL للاتصال به:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### تهيئة Redis

> توثيق واجهة برمجة التطبيقات: [`RedisConfiguration`](https://api.vapor.codes/redis/redisconfiguration)

#### serverAddresses

إذا كان لديك عدة نقاط نهاية لـ Redis، مثل عنقود من نسخ Redis، فستحتاج إلى إنشاء مجموعة [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) لتمريرها في المُهيّئ بدلًا من ذلك.

الطريقة الأكثر شيوعًا لإنشاء `SocketAddress` هي باستخدام الدالة الساكنة [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

بالنسبة لنقطة نهاية واحدة لـ Redis، قد يكون من الأسهل العمل مع المُهيّئات الميسّرة، إذ ستتولّى إنشاء `SocketAddress` نيابةً عنك:

- [`.init(url:pool)`](https://api.vapor.codes/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (مع `String` أو [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

إذا كانت نسخة Redis الخاصة بك محمية بكلمة مرور، فستحتاج إلى تمريرها كمعامل `password`.

سيُصادَق على كل اتصال عند إنشائه باستخدام كلمة المرور.

#### database

هذا هو فهرس قاعدة البيانات الذي ترغب في تحديده عند إنشاء كل اتصال.

يوفّر هذا عليك الحاجة إلى إرسال الأمر `SELECT` إلى Redis بنفسك.

!!! warning "تحذير"
    لا يُحافظ على تحديد قاعدة البيانات. كن حذرًا عند إرسال الأمر `SELECT` بنفسك.

### خيارات تجمّع الاتصالات

> توثيق واجهة برمجة التطبيقات: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/redisconfiguration/pooloptions)

!!! note "ملاحظة"
    تُبرز هنا الخيارات الأكثر تغييرًا شيوعًا فقط. للاطلاع على جميع الخيارات، راجع توثيق واجهة برمجة التطبيقات.

#### minimumConnectionCount

هذه هي القيمة التي تحدّد عدد الاتصالات التي تريد أن يحافظ عليها كل تجمّع في جميع الأوقات.

إذا كانت قيمتك `0`، فعند فقدان الاتصالات لأي سبب، لن يعيد التجمّع إنشاءها حتى تدعو الحاجة إليها.

يُعرف هذا باتصال "البدء البارد" (cold start)، وينطوي على بعض العبء الإضافي مقارنةً بالحفاظ على حدّ أدنى من عدد الاتصالات.

#### maximumConnectionCount

يحدّد هذا الخيار سلوك كيفية الحفاظ على الحدّ الأقصى لعدد الاتصالات.

!!! seealso "انظر أيضًا"
    راجع واجهة برمجة تطبيقات `RedisConnectionPoolSize` للإلمام بالخيارات المتاحة.

## إرسال أمر

يمكنك إرسال الأوامر باستخدام خاصية `.redis` على أي نسخة من [`Application`](https://api.vapor.codes/vapor/application) أو [`Request`](https://api.vapor.codes/vapor/request)، مما سيتيح لك الوصول إلى [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

يمتلك أي `RedisClient` عدة امتدادات لجميع [أوامر Redis](https://redis.io/commands) المتنوعة.

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### الأوامر غير المدعومة

إذا كانت **RediStack** لا تدعم أمرًا ما بدالة امتداد، فلا يزال بإمكانك إرساله يدويًا.

```swift
// each value after the command is the positional argument that Redis expects
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// or

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## وضع النشر/الاشتراك (Pub/Sub)

يدعم Redis القدرة على الدخول في [وضع "النشر/الاشتراك" (Pub/Sub)](https://redis.io/topics/pubsub) حيث يمكن لاتصال ما الاستماع إلى "قنوات" محددة وتشغيل إغلاقات (closures) محددة عندما تنشر القنوات المشترَك فيها "رسالة" (قيمة بيانات ما).

للاشتراك دورة حياة محددة:

1. **subscribe**: يُستدعى مرة واحدة عند بدء الاشتراك لأول مرة
1. **message**: يُستدعى 0 مرة أو أكثر عند نشر الرسائل إلى القنوات المشترَك فيها
1. **unsubscribe**: يُستدعى مرة واحدة عند انتهاء الاشتراك، إما بناءً على طلب أو بسبب فقدان الاتصال

عند إنشاء اشتراك، يجب أن توفّر على الأقل [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) للتعامل مع جميع الرسائل التي تنشرها القناة المشترَك فيها.

يمكنك اختياريًا توفير `RedisSubscriptionChangeHandler` لكل من `onSubscribe` و`onUnsubscribe` للتعامل مع أحداث دورة الحياة الخاصة بكل منهما.

```swift
// creates 2 subscriptions, one for each given channel
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // do something with the message
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
