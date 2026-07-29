# Files

يقدّم Vapor واجهة بسيطة لقراءة الملفات وكتابتها بشكل غير متزامن داخل معالجات المسار. هذه الواجهة مبنية على نوع [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) الخاص بـ NIO.

## القراءة

الطريقة الرئيسية لقراءة ملف تُسلّم قطعًا (chunks) إلى معالج ردّ نداء (callback handler) أثناء قراءتها من القرص. يُحدَّد الملف المراد قراءته بمساره. ستبحث المسارات النسبية في دليل العمل الحالي للعملية.

```swift
// Asynchronously reads a file from disk.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Or

let file = try await req.fileio.readFile(at: "/path/to/file")
for try await chunk in file {
    print(chunk) // ByteBuffer
}
// Read is complete
```

إذا كنت تستخدم `EventLoopFuture`، فسيُشير الـ future المُرجَع عند اكتمال القراءة أو حدوث خطأ. إذا كنت تستخدم `async`/`await`، فبمجرد أن يعود `await` تكون القراءة قد اكتملت. وإذا حدث خطأ فسيُطلِق خطأً.

### البثّ

تُحوّل الطريقة `streamFile` ملفًا مبثوثًا إلى `Response`. ستضبط هذه الطريقة الترويسات المناسبة مثل `ETag` و`Content-Type` تلقائيًا.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

يمكن إرجاع النتيجة مباشرة بواسطة معالج المسار الخاص بك.

### التجميع

تقرأ الطريقة `collectFile` الملف المحدّد إلى مخزن مؤقت (buffer).

```swift
// Reads the file into a buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// or

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning "تحذير"
    تتطلّب هذه الطريقة وجود الملف بأكمله في الذاكرة دفعة واحدة. استخدم القراءة المُقطّعة (chunked) أو المبثوثة للحدّ من استخدام الذاكرة.

## الكتابة

تدعم الطريقة `writeFile` كتابة مخزن مؤقت (buffer) إلى ملف.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

سيُشير الـ future المُرجَع عند اكتمال الكتابة أو حدوث خطأ.

## Middleware

لمزيد من المعلومات حول تقديم الملفات من مجلد _Public_ في مشروعك تلقائيًا، راجع [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## متقدّم

للحالات التي لا تدعمها واجهة Vapor، يمكنك استخدام نوع `NonBlockingFileIO` الخاص بـ NIO مباشرة.

```swift
// Main thread.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In a route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

لمزيد من المعلومات، تفضّل بزيارة [مرجع الواجهة](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) الخاص بـ SwiftNIO.
