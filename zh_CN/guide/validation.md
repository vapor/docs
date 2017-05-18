---
currentMenu: guide-validation
---

# Validation

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Vapor 提供多种不同的方式，校验进入你的程序的数据。让我们从看最常见的开始。

## 基本用法 （Common Usage）

默认情况下包括几个有用的方便校验器（validator），你能使用它们校验进入你的应用程序的数据，或者组合它们、创建你自己的。

让我们看看最基本校验数据的方法。

```swift
class Employee {
    var email: Valid<Email>
    var name: Valid<Name>

    init(request: Request) throws {
        name = try request.data["name"].validated()
        email = try request.data["email"].validated()
    }
}
```

这里我们有一个典型的 Employee model，包含 `email` 和 `name` 属性。通过生命它们属性为 `Valid<>`，确保这些属性只能包含有效数据。Swift 类型检查将不会允许任何没有通过类型检查的数据被存储。

为了将数据存储到一个 `Valid<>` 属性中，你必须使用 `.validated()` 方法。这个方法可以在任何通过 `request.data` 返回的数据上使用。

`Email` 是包含在 Vapor 中的一个 `validator`，但是 `Name` 不是。让我们看看如何创建一个 Validator。

```swift
Valid<OnlyAlphanumeric>
Valid<Email>
Valid<Unique<T>>
Valid<Matches<T>>
Valid<In<T>>
Valid<Contains<T>>
Valid<Count<T>>
```

## Validators vs. ValidationSuites

像 `Count`、`Contains` Validator，能够有多个配置项。例如：

```swift
let name: Valid<Count<String>> = try "Vapor".validated(by: Count.max(5))
```

这里我们校验 `String` 长多最多 5 个字符。`Valid<Count>` 类型告诉我们，这个字符已经被校验为一个确定字符个数，但是不能明确的告诉我们字符个数是多少。这个字符串可能已经被校验过少于三个字符或者多余一百万。

因为这一点，`Validators` 不能像某些应用程序期望的那样类型安全。`ValidationSuites` 正好填补了这个。它们组合多个 `Validators` and/or `ValidationSuites` 一起去表示什么类型的数据被认为是合法的。

## Custom Validator

这里我们展示如何创建一个自定义的 `ValidationSuite`。

```swift
class Name: ValidationSuite {
    static func validate(input value: String) throws {
        let evaluation = OnlyAlphanumeric.self
            && Count.min(5)
            && Count.max(20)

        try evaluation.validate(input: value)
    }
}
```

你仅仅必须实现一个方法。在这个方法中，使用其他的 validators 或者逻辑去创建你的自定义的 validator。这里面我们定义了一个 Name，只接受 alphanumeric 字符且字符个数在 5 到 20 之间。

Now we can be sure that anything of type Valid<Name> follows these rules.

## 组合 Validators （Combining Validators）

在 `Name` validator 中，你看到 `&&` 用来组合 validators。你能使用 `&&` 和 `||` 组合任意的 validator，就如你使用的布尔值和 `if` 语句。

你也可以使用 `!` 取反该 validator。

```swift
let symbols = input.validated(by: !OnlyAlphanumeric.self)
```

## Testing Validity

虽然`validated（）throw`是最常用的校验方法，但还有两个。

```swift
let passed = input.passes(Count.min(5))
let valid = try input.tested(Count.min(5))
```

`passes()` 返回一个布尔值，表示 test 是否通过。如果 test 未通过，`tested()` 将会抛出错我。不像 `validated()` 返回  `Valid<>` 类型，`tested()` 返回调用者的原始类型。

## Validation Failures

Vapor 会自动在 `ValidationMiddleware` 捕获校验失败的错我。但是你能够自己捕获，或者定制对某些类型的校验失败的响应。

```swift
do {
    //validation here
} catch let error as ValidationErrorProtocol {
    print(error.message)
}
```
