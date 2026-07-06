# الأوسمة المخصصة

يمكنك إنشاء أوسمة Leaf مخصصة باستخدام بروتوكول [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag).

لتوضيح ذلك، لنلقِ نظرة على إنشاء وسم مخصص `#now` يطبع الطابع الزمني الحالي. سيدعم الوسم أيضًا معاملًا واحدًا اختياريًا لتحديد تنسيق التاريخ.

!!! tip "نصيحة"
    إذا كان وسمك المخصص يصيّر HTML، فينبغي أن توائم وسمك المخصص مع `UnsafeUnescapedLeafTag` حتى لا يُهرَّب HTML. تذكّر التحقق من أي مدخلات مستخدم أو تعقيمها.

## `LeafTag`

أولًا أنشئ صنفًا باسم `NowTag` ووائمه مع `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

لننفّذ الآن دالة `render(_:)`. يحتوي سياق `LeafContext` المُمرّر إلى هذه الدالة على كل ما نحتاجه.

```swift
enum NowTagError: Error {
    case invalidFormatParameter
    case tooManyParameters
}

struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let formatter = DateFormatter()
        switch ctx.parameters.count {
        case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        case 1:
            guard let string = ctx.parameters[0].string else {
                throw NowTagError.invalidFormatParameter
            }

            formatter.dateFormat = string
        default:
            throw NowTagError.tooManyParameters
        }
    
        let dateAsString = formatter.string(from: Date())
        return LeafData.string(dateAsString)
    }
}
```

## تهيئة الوسم

الآن وقد نفّذنا `NowTag`، نحتاج فقط إلى إخبار Leaf عنه. يمكنك إضافة أي وسم بهذه الطريقة - حتى لو أتى من حزمة منفصلة. تفعل ذلك عادةً في `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

وهذا كل شيء! يمكننا الآن استخدام وسمنا المخصص في Leaf.

```leaf
The time is #now()
```

## خصائص السياق

يحتوي `LeafContext` على خاصيتين مهمتين. `parameters` و`data` اللتان تحتويان على كل ما نحتاجه.

- `parameters`: مصفوفة تحتوي على معاملات الوسم.
- `data`: قاموس يحتوي على بيانات العرض المُمرّرة إلى `render(_:_:)` كسياق.

### مثال وسم Hello

لنرى كيفية استخدام هذا، لننفّذ وسم hello بسيطًا باستخدام كلتا الخاصيتين.

#### استخدام المعاملات

يمكننا الوصول إلى المعامل الأول الذي سيحتوي على الاسم.

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### استخدام البيانات

يمكننا الوصول إلى قيمة الاسم باستخدام المفتاح "name" داخل خاصية data.

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello()
```

_المتحكّم_:

```swift
return try await req.view.render("home", ["name": "John"])
```
