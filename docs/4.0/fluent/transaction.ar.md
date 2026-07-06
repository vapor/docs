# المعاملات

تتيح لك المعاملات ضمان اكتمال عدة عمليات بنجاح قبل حفظ البيانات في قاعدة بياناتك.
بمجرد بدء المعاملة، يمكنك تشغيل استعلامات Fluent كالمعتاد. ومع ذلك، لن تُحفظ أي بيانات في قاعدة البيانات حتى تكتمل المعاملة.
إذا طُرح خطأ في أي نقطة أثناء المعاملة (منك أو من قاعدة البيانات)، فلن تسري أي من التغييرات.

لتنفيذ معاملة، تحتاج إلى الوصول إلى شيء يمكنه الاتصال بقاعدة البيانات. عادةً ما يكون هذا طلب HTTP وارد. لهذا، استخدم `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // use database
}
```
بمجرد دخولك إغلاق المعاملة، يجب أن تستخدم قاعدة البيانات المُمرّرة في معامل الإغلاق (المسماة `database` في المثال) لتنفيذ الاستعلامات.

بمجرد أن يعود هذا الإغلاق بنجاح، ستُثبَّت المعاملة.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
سيحفظ المثال أعلاه `sun` ومن *ثم* `sirius` قبل إكمال المعاملة. إذا فشل حفظ أي من النجمين، فلن يُحفظ أي منهما.

بمجرد اكتمال المعاملة، يمكن تحويل النتيجة إلى future مختلف، على سبيل المثال إلى حالة HTTP للإشارة إلى الاكتمال كما هو موضح أدناه:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

إذا كنت تستخدم `async`/`await` فيمكنك إعادة صياغة الرمز إلى ما يلي:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
