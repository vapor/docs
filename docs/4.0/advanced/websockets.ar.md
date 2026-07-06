# WebSockets

تتيح [WebSockets](https://en.wikipedia.org/wiki/WebSocket) التواصل ثنائي الاتجاه بين العميل والخادم. على خلاف HTTP الذي يعتمد نمط الطلب والاستجابة، يمكن لأطراف WebSocket إرسال عدد عشوائي من الرسائل في أي من الاتجاهين. تتيح لك واجهة WebSocket في Vapor إنشاء كل من العملاء والخوادم التي تعالج الرسائل بشكل غير متزامن.

## الخادم

يمكن إضافة نقاط نهاية WebSocket إلى تطبيق Vapor الحالي باستخدام واجهة التوجيه (Routing API). استخدم الطريقة `webSocket` كما تستخدم `get` أو `post`.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

يمكن تجميع مسارات WebSocket وحمايتها بالوسيطة مثل المسارات العادية.

بالإضافة إلى قبول طلب HTTP الوارد، تقبل معالجات WebSocket اتصال WebSocket الذي أُنشئ حديثًا. راجع أدناه لمزيد من المعلومات حول استخدام WebSocket هذا لإرسال الرسائل وقراءتها.

## العميل

للاتصال بنقطة نهاية WebSocket بعيدة، استخدم `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

تُرجع الطريقة `connect` future يكتمل عند إنشاء الاتصال. بمجرد الاتصال، سيُستدعى الإغلاق (closure) المُقدَّم مع WebSocket المتصل حديثًا. راجع أدناه لمزيد من المعلومات حول استخدام WebSocket هذا لإرسال الرسائل وقراءتها.

## الرسائل

يحتوي الصنف `WebSocket` على طرق لإرسال الرسائل واستقبالها بالإضافة إلى الاستماع للأحداث مثل الإغلاق. يمكن لـ WebSockets نقل البيانات عبر بروتوكولين: نصّي (text) وثنائي (binary). تُفسَّر الرسائل النصية كسلاسل UTF-8، بينما تُفسَّر البيانات الثنائية كمصفوفة من البايتات.

### الإرسال

يمكن إرسال الرسائل باستخدام الطريقة `send` الخاصة بـ WebSocket.

```swift
ws.send("Hello, world")
```

يؤدي تمرير `String` إلى هذه الطريقة إلى إرسال رسالة نصية. يمكن إرسال الرسائل الثنائية بتمرير `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

إرسال الرسائل غير متزامن. يمكنك تزويد الطريقة send بـ `EventLoopPromise` لإخطارك عند انتهاء إرسال الرسالة أو فشلها.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

إذا كنت تستخدم `async`/`await` يمكنك استخدام `await` لانتظار اكتمال العملية غير المتزامنة

```swift
try await ws.send(...)
```

### الاستقبال

تُعالَج الرسائل الواردة عبر ردّي النداء (callbacks) `onText` و`onBinary`.

```swift
ws.onText { ws, text in
    // String received by this WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] received by this WebSocket.
    print(binary)
}
```

يُقدَّم WebSocket نفسه كأول مُعامِل لردود النداء هذه لمنع الدورات المرجعية (reference cycles). استخدم هذا المرجع لاتخاذ إجراء على WebSocket بعد استقبال البيانات. على سبيل المثال، لإرسال ردّ:

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## الإغلاق

لإغلاق WebSocket، استدعِ الطريقة `close`.

```swift
ws.close()
```

تُرجع هذه الطريقة future سيكتمل عندما يُغلَق WebSocket. مثل `send`، يمكنك أيضًا تمرير promise إلى هذه الطريقة.

```swift
ws.close(promise: nil)
```

أو استخدم `await` عليها إذا كنت تستخدم `async`/`await`:

```swift
try await ws.close()
```

لإخطارك عندما يُغلق الطرف الآخر الاتصال، استخدم `onClose`. سيكتمل هذا الـ future عندما يُغلق العميل أو الخادم WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

تُضبط الخاصية `closeCode` عند إغلاق WebSocket. يمكن استخدام ذلك لتحديد سبب إغلاق الطرف الآخر للاتصال.

## Ping / Pong

تُرسَل رسائل ping وpong تلقائيًا بواسطة العميل والخادم للحفاظ على اتصالات WebSocket حيّة. يمكن لتطبيقك الاستماع لهذه الأحداث باستخدام ردّي النداء `onPing` و`onPong`.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
