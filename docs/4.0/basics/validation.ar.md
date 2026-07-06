# التحقق

تساعدك واجهة التحقق البرمجية (Validation API) في Vapor على التحقق من جسم الطلب الوارد ومُعامِلات استعلامه قبل استخدام واجهة [Content](content.md) البرمجية لفكّ ترميز البيانات.

## مقدمة

يعني تكامل Vapor العميق مع بروتوكول `Codable` الآمن نوعيًا في Swift أنك لا تحتاج إلى القلق بشأن التحقق من البيانات بقدر ما هو الحال في اللغات ذات الأنواع الديناميكية. ومع ذلك، لا تزال هناك بضعة أسباب قد تجعلك ترغب في اختيار التحقق الصريح باستخدام واجهة التحقق البرمجية.

### أخطاء قابلة للقراءة البشرية

سيؤدي فكّ ترميز البُنى (structs) باستخدام واجهة [Content](content.md) البرمجية إلى أخطاء إذا كانت أي من البيانات غير صالحة. ومع ذلك، قد تفتقر رسائل الخطأ هذه أحيانًا إلى قابلية القراءة البشرية. على سبيل المثال، خذ التعداد (enum) المدعوم بنص (string) التالي:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

إذا حاول مستخدم تمرير النص `"purple"` إلى خاصية من نوع `Color`، فسيحصل على خطأ مشابه لما يلي:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

رغم أن هذا الخطأ صحيح تقنيًا وحمى نقطة النهاية بنجاح من قيمة غير صالحة، فإنه كان بإمكانه أن يُبلِغ المستخدم عن الخطأ وعن الخيارات المتاحة على نحو أفضل. باستخدام واجهة التحقق البرمجية، يمكنك توليد أخطاء مثل ما يلي:

```
favoriteColor is not red, blue, or green
```

علاوةً على ذلك، سيتوقّف `Codable` عن محاولة فكّ ترميز نوع بمجرد الوصول إلى أول خطأ. هذا يعني أنه حتى لو كان هناك العديد من الخصائص غير الصالحة في الطلب، فلن يرى المستخدم سوى الخطأ الأول. ستُبلِغ واجهة التحقق البرمجية عن جميع إخفاقات التحقق في طلب واحد.

### تحقق محدّد

يتعامل `Codable` مع التحقق من النوع بشكل جيد، لكنك أحيانًا تريد أكثر من ذلك. على سبيل المثال، التحقق من محتويات نص أو التحقق من حجم عدد صحيح. تحتوي واجهة التحقق البرمجية على مُحقِّقات (validators) للمساعدة في التحقق من بيانات مثل عناوين البريد الإلكتروني ومجموعات الأحرف ونطاقات الأعداد الصحيحة وغيرها.

## Validatable

للتحقق من طلب، ستحتاج إلى توليد مجموعة `Validations`. يتمّ هذا غالبًا عبر جعل نوع موجود يتوافق مع `Validatable`.

لنلقِ نظرة على كيفية إضافة التحقق إلى نقطة النهاية البسيطة هذه `POST /users`. يفترض هذا الدليل أنك على دراية بالفعل بواجهة [Content](content.md) البرمجية.

```swift
enum Color: String, Codable {
    case red, blue, green
}

struct CreateUser: Content {
    var name: String
    var username: String
    var age: Int
    var email: String
    var favoriteColor: Color?
}

app.post("users") { req -> CreateUser in
    let user = try req.content.decode(CreateUser.self)
    // Do something with user.
    return user
}
```

### إضافة عمليات التحقق

الخطوة الأولى هي جعل النوع الذي تفكّ ترميزه، في هذه الحالة `CreateUser`، متوافقًا مع `Validatable`. يمكن فعل هذا في امتداد (extension).

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

ستُستدعى الدالة الساكنة `validations(_:)` عند التحقق من `CreateUser`. ينبغي إضافة أي عمليات تحقق تريد إجراءها إلى مجموعة `Validations` المزوَّدة. لنلقِ نظرة على إضافة عملية تحقق بسيطة تشترط أن يكون بريد المستخدم الإلكتروني صالحًا.

```swift
validations.add("email", as: String.self, is: .email)
```

المُعامِل الأول هو المفتاح المتوقّع للقيمة، في هذه الحالة `"email"`. ينبغي أن يطابق هذا اسم الخاصية على النوع الذي يجري التحقق منه. المُعامِل الثاني، `as`، هو النوع المتوقّع، في هذه الحالة `String`. عادةً ما يطابق النوع نوع الخاصية، لكن ليس دائمًا. أخيرًا، يمكن إضافة مُحقِّق واحد أو أكثر بعد المُعامِل الثالث، `is`. في هذه الحالة، نضيف مُحقِّقًا واحدًا يتحقّق مما إذا كانت القيمة عنوان بريد إلكتروني.

### التحقق من محتوى الطلب

بمجرد أن تجعل نوعك متوافقًا مع `Validatable`، يمكن استخدام الدالة الساكنة `validate(content:)` للتحقق من محتوى الطلب. أضف السطر التالي قبل `req.content.decode(CreateUser.self)` في معالج المسار.

```swift
try CreateUser.validate(content: req)
```

الآن، جرّب إرسال الطلب التالي الذي يحتوي على بريد إلكتروني غير صالح:

```http
POST /users HTTP/1.1
Content-Length: 67
Content-Type: application/json

{
    "age": 4,
    "email": "foo",
    "favoriteColor": "green",
    "name": "Foo",
    "username": "foo"
}
```

ينبغي أن ترى الخطأ التالي مُرجَعًا:

```
email is not a valid email address
```

### التحقق من استعلام الطلب

تمتلك الأنواع المتوافقة مع `Validatable` أيضًا `validate(query:)` التي يمكن استخدامها للتحقق من سلسلة استعلام الطلب. أضف السطرين التاليين إلى معالج المسار.

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

الآن، جرّب إرسال الطلب التالي الذي يحتوي على بريد إلكتروني غير صالح في سلسلة الاستعلام.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

ينبغي أن ترى الخطأ التالي مُرجَعًا:

```
email is not a valid email address
```

### التحقق من الأعداد الصحيحة

رائع، الآن لنجرّب إضافة عملية تحقق لـ `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

يشترط التحقق من العمر أن يكون العمر أكبر من أو يساوي `13`. إذا جرّبت الطلب نفسه من الأعلى، فينبغي أن ترى خطأً جديدًا الآن:

```
age is less than minimum of 13, email is not a valid email address
```

### التحقق من النصوص

بعد ذلك، لنُضِف عمليات تحقق لـ `name` و`username`.

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

يستخدم التحقق من الاسم المُعامِل `!` لعكس التحقق `.empty`. سيشترط هذا ألّا يكون النص فارغًا.

يجمع التحقق من اسم المستخدم بين مُحقِّقين باستخدام `&&`. سيشترط هذا أن يكون طول النص 3 أحرف على الأقل _و_ أن يحتوي على أحرف أبجدية رقمية فقط.

### التحقق من التعدادات

أخيرًا، لنلقِ نظرة على عملية تحقق أكثر تقدّمًا قليلًا للتحقق من أن `favoriteColor` المزوَّد صالح.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

بما أنه من غير الممكن فكّ ترميز `Color` من قيمة غير صالحة، فإن عملية التحقق هذه تستخدم `String` كنوع أساسي. تستخدم المُحقِّق `.in` للتأكّد من أن القيمة خيار صالح: red أو blue أو green. وبما أن هذه القيمة اختيارية، فقد ضُبِط `required` على false للإشارة إلى أن التحقق ينبغي ألّا يفشل إذا كان هذا المفتاح مفقودًا من بيانات الطلب.

لاحظ أنه رغم أن التحقق من اللون المفضّل سينجح إذا كان المفتاح مفقودًا، فإنه لن ينجح إذا زُوِّد `null`. إذا أردت دعم `null`، فغيّر نوع التحقق إلى `String?` واستخدم اختصار `.nil ||` (يُقرأ: "is nil or ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### أخطاء مخصّصة

قد ترغب في إضافة أخطاء مخصّصة قابلة للقراءة البشرية إلى `Validations` أو `Validator` الخاص بك. للقيام بذلك، ببساطة زوّد المُعامِل الإضافي `customFailureDescription` الذي سيتجاوز الخطأ الافتراضي.

```swift
validations.add(
    "name",
    as: String.self,
    is: !.empty,
    customFailureDescription: "Provided name is empty!"
)
validations.add(
    "username",
    as: String.self,
    is: .count(3...) && .alphanumeric,
    customFailureDescription: "Provided username is invalid!"
)
```


## المُحقِّقات

فيما يلي قائمة بالمُحقِّقات المدعومة حاليًا وشرح موجز لما تفعله.

|التحقق|الوصف|
|-|-|
|`.ascii`|يحتوي على أحرف ASCII فقط.|
|`.alphanumeric`|يحتوي على أحرف أبجدية رقمية فقط.|
|`.characterSet(_:)`|يحتوي على أحرف من `CharacterSet` المزوَّدة فقط.|
|`.count(_:)`|عدد عناصر المجموعة ضمن الحدود المزوَّدة.|
|`.email`|يحتوي على بريد إلكتروني صالح.|
|`.empty`|المجموعة فارغة.|
|`.in(_:)`|القيمة موجودة في `Collection` المزوَّدة.|
|`.nil`|القيمة `null`.|
|`.range(_:)`|القيمة ضمن `Range` المزوَّد.|
|`.url`|يحتوي على URL صالح.|
|`.custom(_:, validationClosure: (value) -> Bool)`|تحقق مخصّص لمرة واحدة.|

يمكن أيضًا دمج المُحقِّقات لبناء عمليات تحقق معقّدة باستخدام المُعامِلات. مزيد من المعلومات عن المُحقِّق `.custom` في [المُحقِّقات المخصّصة](#المُحقِّقات-المخصّصة).

|المُعامِل|الموضع|الوصف|
|-|-|-|
|`!`|بادئة|يعكس مُحقِّقًا، مشترطًا العكس.|
|`&&`|وسط|يجمع بين مُحقِّقين، يشترط كليهما.|
|`\|\|`|وسط|يجمع بين مُحقِّقين، يشترط أحدهما.|



## المُحقِّقات المخصّصة

هناك طريقتان لإنشاء مُحقِّقات مخصّصة.

### توسيع واجهة التحقق البرمجية

يُعدّ توسيع واجهة التحقق البرمجية الأنسب للحالات التي تخطّط فيها لاستخدام المُحقِّق المخصّص في أكثر من كائن `Content` واحد. في هذا القسم، سنرشدك عبر خطوات إنشاء مُحقِّق مخصّص للتحقق من الرموز البريدية.

أولًا، أنشئ نوعًا جديدًا لتمثيل نتائج التحقق `ZipCode`. ستكون هذه البنية مسؤولة عن الإبلاغ عمّا إذا كان نص معيّن رمزًا بريديًا صالحًا.

```swift
extension ValidatorResults {
    /// Represents the result of a validator that checks if a string is a valid zip code.
    public struct ZipCode {
        /// Indicates whether the input is a valid zip code.
        public let isValidZipCode: Bool
    }
}
```

بعد ذلك، اجعل النوع الجديد متوافقًا مع `ValidatorResult`، الذي يُعرِّف السلوك المتوقّع من مُحقِّق مخصّص.

```swift
extension ValidatorResults.ZipCode: ValidatorResult {
    public var isFailure: Bool {
        !self.isValidZipCode
    }
    
    public var successDescription: String? {
        "is a valid zip code"
    }
    
    public var failureDescription: String? {
        "is not a valid zip code"
    }
}
```

أخيرًا، نفّذ منطق التحقق للرموز البريدية. استخدم تعبيرًا نمطيًا (regular expression) للتحقق مما إذا كان نص الإدخال يطابق صيغة رمز بريدي أمريكي.

```swift
private let zipCodeRegex: String = "^\\d{5}(?:[-\\s]\\d{4})?$"

extension Validator where T == String {
    /// Validates whether a `String` is a valid zip code.
    public static var zipCode: Validator<T> {
        .init { input in
            guard let range = input.range(of: zipCodeRegex, options: [.regularExpression]),
                  range.lowerBound == input.startIndex && range.upperBound == input.endIndex
            else {
                return ValidatorResults.ZipCode(isValidZipCode: false)
            }
            return ValidatorResults.ZipCode(isValidZipCode: true)
        }
    }
}
```

الآن بعد أن عرّفت المُحقِّق المخصّص `zipCode`، يمكنك استخدامه للتحقق من الرموز البريدية في تطبيقك. ببساطة أضف السطر التالي إلى شيفرة التحقق الخاصة بك:

```swift
validations.add("zipCode", as: String.self, is: .zipCode)
```

### المُحقِّق `Custom`

يُعدّ المُحقِّق `Custom` الأنسب للحالات التي تريد فيها التحقق من خاصية في كائن `Content` واحد فقط. لهذا التنفيذ الميزتان التاليتان مقارنةً بتوسيع واجهة التحقق البرمجية:

- أبسط في تنفيذ منطق التحقق المخصّص.
- صياغة أقصر.

في هذا القسم، سنرشدك عبر خطوات إنشاء مُحقِّق مخصّص للتحقق مما إذا كان موظّف جزءًا من شركتنا عبر النظر إلى الخاصية `nameAndSurname`.

```swift
let allCompanyEmployees: [String] = [
  "Everett Erickson",
  "Sabrina Manning",
  "Seth Gates",
  "Melina Hobbs",
  "Brendan Wade",
  "Evie Richardson",
]

struct Employee: Content {
  var nameAndSurname: String
  var email: String
  var age: Int
  var role: String

  static func validations(_ validations: inout Validations) {
    validations.add(
      "nameAndSurname",
      as: String.self,
      is: .custom("Validates whether employee is part of XYZ company by looking at name and surname.") { nameAndSurname in
          for employee in allCompanyEmployees {
            if employee == nameAndSurname {
              return true
            }
          }
          return false
        }
    )
  }
}
```
