# Redis والجلسات

يمكن أن يعمل Redis كمزوّد تخزين للتخزين المؤقت لـ [بيانات الجلسة](../advanced/sessions.md#بيانات-الجلسة) مثل بيانات اعتماد المستخدم.

إذا لم يُوفَّر [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) مخصص، فسيُستخدم واحد افتراضي.

## السلوك الافتراضي

### إنشاء SessionID

ما لم تُنفّذ الدالة [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) في [`RedisSessionsDelegate` الخاص بك](#redissessionsdelegate)، فستُنشأ جميع قيم [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) بالقيام بما يلي:

1. توليد 32 بايت من الأحرف العشوائية
1. ترميز القيمة بترميز base64

على سبيل المثال: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### تخزين SessionData

سيخزّن التنفيذ الافتراضي لـ `RedisSessionsDelegate` بيانات [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) كقيمة نصية JSON بسيطة باستخدام `Codable`.

ما لم تُنفّذ الدالة [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) في `RedisSessionsDelegate` الخاص بك، فستُخزَّن `SessionData` في Redis بمفتاح يسبق `SessionID` بالبادئة `vrs-` (**V**apor **R**edis **S**essions)

على سبيل المثال: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## تسجيل مندوب مخصص

لتخصيص كيفية قراءة البيانات من Redis وكتابتها إليه، سجّل كائن `RedisSessionsDelegate` الخاص بك كما يلي:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> توثيق واجهة برمجة التطبيقات: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

يمكن استخدام كائن مطابق لهذا البروتوكول لتغيير كيفية تخزين `SessionData` في Redis.

لا يلزم سوى تنفيذ دالتين من قِبل النوع المطابق للبروتوكول: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) و[`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

كلتاهما مطلوبة، لأن الطريقة التي تخصّص بها كتابة بيانات الجلسة إلى Redis مرتبطة جوهريًا بكيفية قراءتها من Redis.

### مثال Hash لـ RedisSessionsDelegate

على سبيل المثال، إذا أردت تخزين بيانات الجلسة كـ [**Hash** في Redis](https://redis.io/topics/data-types-intro#redis-hashes)، فستُنفّذ شيئًا كالتالي:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // stores each data field as a separate hash field
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash is [String: RESPValue] so we need to try and unwrap the
            // value as a string and store each value in the data container
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
