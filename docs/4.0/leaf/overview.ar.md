# نظرة عامة على Leaf

إن Leaf لغة قوالب قوية بصياغة مستوحاة من Swift. يمكنك استخدامها لإنشاء صفحات HTML ديناميكية لموقع واجهة أمامية أو إنشاء رسائل بريد إلكتروني غنية لإرسالها من واجهة برمجية.

سيمنحك هذا الدليل نظرة عامة على صياغة Leaf والأوسمة المتاحة.

## صياغة القالب

فيما يلي مثال على استخدام أساسي لوسم Leaf.

```leaf
There are #count(users) users.
```

تتكوّن أوسمة Leaf من أربعة عناصر:

- الرمز `#`: يشير هذا إلى محلّل Leaf ليبدأ البحث عن وسم.
- الاسم `count`: الذي يعرّف الوسم.
- قائمة المعاملات `(users)`: قد تقبل صفرًا أو أكثر من الوسائط.
- الجسم: يمكن تزويد بعض الأوسمة بجسم اختياري باستخدام نقطتين ووسم إغلاق

يمكن أن تكون هناك استخدامات مختلفة كثيرة لهذه العناصر الأربعة اعتمادًا على تنفيذ الوسم. لنلقِ نظرة على بضعة أمثلة على كيفية استخدام أوسمة Leaf المدمجة:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

يدعم Leaf أيضًا العديد من التعبيرات المألوفة لديك في Swift.

- `+`
- `%`
- `>`
- `==`
- `||`
- إلخ.

```leaf
#if(1 + 1 == 2):
    Hello!
#endif

#if(index % 2 == 0):
    This is even index.
#else:
    This is odd index.
#endif
```

## السياق

في المثال الوارد في [البدء](getting-started.md)، استخدمنا قاموس `[String: String]` لتمرير البيانات إلى Leaf. ومع ذلك، يمكنك تمرير أي شيء يتوافق مع `Encodable`. ومن الأفضل في الواقع استخدام هياكل `Encodable` لأن `[String: Any]` غير مدعوم. هذا يعني أنه *لا يمكنك* تمرير مصفوفة، وينبغي بدلًا من ذلك تغليفها في هيكل:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

سيؤدي ذلك إلى إتاحة `title` و`numbers` لقالب Leaf الخاص بنا، والذي يمكن استخدامه بعد ذلك داخل الأوسمة. على سبيل المثال:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## الاستخدام

فيما يلي بعض أمثلة الاستخدام الشائعة لـ Leaf.

### الشروط

يستطيع Leaf تقييم مجموعة من الشروط باستخدام وسمه `#if`. على سبيل المثال، إذا زوّدته بمتغير فسيتحقق من وجود هذا المتغير في سياقه:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

يمكنك أيضًا كتابة مقارنات، على سبيل المثال:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

إذا كنت تريد استخدام وسم آخر كجزء من شرطك، فينبغي أن تحذف `#` للوسم الداخلي. على سبيل المثال:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

يمكنك أيضًا استخدام تعليمات `#elseif`:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### الحلقات

إذا زوّدت مصفوفة من العناصر، فيمكن لـ Leaf التكرار عليها والسماح لك بمعالجة كل عنصر على حدة باستخدام وسمه `#for`.

على سبيل المثال، يمكننا تحديث رمز Swift الخاص بنا لتوفير قائمة بالكواكب:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

يمكننا بعد ذلك التكرار عليها في Leaf هكذا:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

سيؤدي هذا إلى تصيير عرض يبدو كالتالي:

```
Planets:
- Venus
- Earth
- Mars
```

### توسيع القوالب

يتيح لك وسم `#extend` في Leaf نسخ محتويات قالب إلى آخر. عند استخدام هذا، ينبغي أن تحذف دائمًا امتداد ملف القالب .leaf.

يُعد التوسيع مفيدًا لنسخ جزء قياسي من المحتوى، على سبيل المثال تذييل صفحة أو رمز إعلان أو جدول مشترك عبر صفحات متعددة:

```leaf
#extend("footer")
```

هذا الوسم مفيد أيضًا لبناء قالب فوق آخر. على سبيل المثال، قد يكون لديك ملف layout.leaf يتضمن كل الرمز المطلوب لتخطيط موقعك - بنية HTML وCSS وJavaScript - مع بعض الفراغات في أماكنها تمثّل حيث يتفاوت محتوى الصفحة.

باستخدام هذا النهج، ستنشئ قالبًا فرعيًا يملأ محتواه الفريد، ثم يوسّع القالب الأصل الذي يضع المحتوى في مكانه المناسب. للقيام بذلك، يمكنك استخدام وسمَي `#export` و`#import` لتخزين المحتوى من السياق واسترجاعه لاحقًا.

على سبيل المثال، قد تنشئ قالب `child.leaf` هكذا:

```leaf
#extend("main"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

نستدعي `#export` لتخزين بعض HTML وإتاحته للقالب الذي نوسّعه حاليًا. ثم نصيّر `main.leaf` ونستخدم البيانات المصدّرة عند الحاجة إلى جانب أي متغيرات سياق أخرى مُمرّرة من Swift. على سبيل المثال، قد يبدو `main.leaf` هكذا:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

هنا نستخدم `#import` لجلب المحتوى المُمرّر إلى وسم `#extend`. عند تمرير `["title": "Hi there!"]` من Swift، سيُصيَّر `child.leaf` كما يلي:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### أوسمة أخرى

#### `#count`

يُرجع وسم `#count` عدد العناصر في مصفوفة. على سبيل المثال:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

يحوّل وسم `#lowercased` جميع الأحرف في سلسلة نصية إلى أحرف صغيرة.

```leaf
#lowercased(name)
```

#### `#uppercased`

يحوّل وسم `#uppercased` جميع الأحرف في سلسلة نصية إلى أحرف كبيرة.

```leaf
#uppercased(name)
```

#### `#capitalized`

يحوّل وسم `#capitalized` الحرف الأول في كل كلمة من سلسلة نصية إلى حرف كبير ويحوّل البقية إلى أحرف صغيرة. راجع [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) لمزيد من المعلومات.

```leaf
#capitalized(name)
```

#### `#contains`

يقبل وسم `#contains` مصفوفة وقيمة كمعاملَيه الاثنين، ويُرجع true إذا كانت المصفوفة في المعامل الأول تحتوي على القيمة في المعامل الثاني.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

ينسّق وسم `#date` التواريخ إلى سلسلة نصية قابلة للقراءة. يستخدم افتراضيًا تنسيق ISO8601.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

يمكنك تمرير سلسلة منسّق تاريخ مخصصة كوسيط ثانٍ. راجع [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) في Swift لمزيد من المعلومات.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

يمكنك أيضًا تمرير معرّف منطقة زمنية لمنسّق التاريخ كوسيط ثالث. راجع [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) و[`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) في Swift لمزيد من المعلومات.

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

يتصرف وسم `#unsafeHTML` مثل وسم المتغير - مثل `#(variable)`. ومع ذلك فإنه لا يهرّب أي HTML قد يحتويه `variable`:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note "ملاحظة"
    ينبغي أن تكون حذرًا عند استخدام هذا الوسم لضمان أن المتغير الذي تزوّده به لا يعرّض مستخدميك لهجوم XSS.

#### `#comment`

يتيح لك وسم `#comment` إضافة تعليقات توضيحية إلى قوالبك لن تظهر في المخرجات المُصيَّرة. يقبل الوسم معامل سلسلة نصية يُتجاهل تمامًا أثناء التصيير.

```leaf
#comment("This is a single-line comment")
<h1>#(title)</h1>
```

للتعليقات الأطول، يمكنك استخدام صياغة السلاسل النصية متعددة الأسطر:

```leaf
#comment("""
This template renders the home page.
It expects a "title" and "body" variable.
""")
<h1>#(title)</h1>
```

#### `#isEmpty`

يُرجع وسم `#isEmpty` القيمة true إذا كانت خاصية سلسلة نصية مُمرّرة إلى القالب فارغة. يُستخدم عادةً داخل شرط `#if`:

```leaf
#if(isEmpty(title)):
    No title was provided.
#else:
    The title is #(title)
#endif
```

#### `#dumpContext`

يصيّر وسم `#dumpContext` السياق بأكمله إلى سلسلة نصية قابلة للقراءة البشرية. استخدم هذا الوسم لتصحيح ما يُقدَّم
كسياق للتصيير الحالي.

```leaf
Hello, world!
#dumpContext
```
