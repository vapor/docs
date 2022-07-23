# Leaf 概述

Leaf 是一种强大的模板语言，其语法受 Swift 启发。你可以使用它为前端网站生成动态 HTML 页面或生成内容丰富的电子邮件并通过 API 发送。

本指南将大概介绍一下 Leaf 的语法和可用的标签。

## 模板语法

下面是一个基本的 Leaf 标签使用示例。

```leaf
There are #count(users) users.
```

Leaf 标签由四个元素组成：

- 标记 `#`：这表示 leaf 解析器开始寻找的标记。
- 名称 `count`：标签的标识符。
- 参数列表 `(users)`：可以接受零个或多个参数。
- 正文: 可以使用分号和结束标签为某些标签提供可选的正文。

根据标签的实现，这四个元素可以有许多不同的用法。让我们来看几个例子，Leaf 内置标签是如何使用的:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf 还支持 Swift 中你熟悉的许多表达式。

- `+`
- `%`
- `>`
- `==`
- `||`
- etc.

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

## 上下文

在[开始](./getting-started.zh.md)的示例中，我们使用 `[String: String]` 字典将数据传递给 Leaf。但是，你可以传递任何遵循 `Encodable` 协议的内容。 它实际上更喜欢使用 `Encodable` 结构，因为 `[String: Any]` 还不支持。这意味着你*不能*传入数组，而应将其包装在一个结构体中：

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

`title` 和 `numbers` 将暴露给 Leaf 模板，就可以在标签中使用这些变量。如下所示：

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## 用法

以下是一些常见的 Leaf 使用示例。

### 条件

使用 `#if` 标签，Leaf 能够评估一系列条件。例如，如果你提供一个变量，它将检查该变量是否存在于其上下文中：

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

你还可以编写比较，例如：

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

如果你想使用另一个标签作为判断条件的一部分，内部标签应该省略 `#`。例如：

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

你还可以使用 `#elseif` 语句：

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### 循环

如果你提供一个 item 数组，Leaf 可以使用 `#for` 标签遍历每一个 item 并且可以单独操作 item。

例如，我们可以更新 Swift 代码提供行星列表：

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

然后我们可以像这样在 Leaf 中循环它们：

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

这将呈现如下视图：

```
Planets:
- Venus
- Earth
- Mars
```

### 扩展模板

Leaf 的 `#extend` 标签可以将一个模板的内容复制到另一个模板中。使用它时，你应该始终省略模板文件的 .leaf 扩展名。

扩展对于复制标准内容非常有用，例如页脚、广告代码或跨多个页面共享的表格：

```leaf
#extend("footer")
```

此标签对于在另一个模板之上构建一个模板也很有用。例如，你可能有一个 layout.leaf 文件，其中包含网站布局所需的所有代码 —— HTML 结构、CSS 和 JavaScript —— 其中有一些空白表示页面内容的变化。

使用这种方法，你将构造一个子模板，填充其唯一的内容，然后扩展适当放置内容的父模板。为此，你可以使用 `#export` 和 `#import` 标签来存储和稍后从上下文中检索内容。

例如，你可以创建这样的 `child.leaf` 模板：

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

我们调用 `#export` 来存储一些HTML，并使其对我们当前正在扩展的模板可用。然后我们渲染 `master.leaf` 视图，并在需要时使用导出的数据以及从 Swift 传入的其他上下文变量。例如，`master.leaf` 代码可能看起来像这样：

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

这里我们使用 `#import` 获取传递给 `#extend` 标签的内容。传递 `["title": "Hi there!"]` 时，`child.leaf` 将呈现如下内容：

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### 其它标签

#### `#count`

`#count` 标签返回数组中的项目数量。例如：

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

`#lowercased` 标签将字符串转成小写字母。

```leaf
#lowercased(name)
```

#### `#uppercased`

`#uppercased` 标签将字符串转成大写字母。

```leaf
#uppercased(name)
```

#### `#capitalized`

`#capitalized` 标签将字符串中每个单词的首字母大写，其他字母小写。了解 [String.capitalized](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) 更多信息，请参阅。


```leaf
#capitalized(name)
```

#### `#contains`

`#contains` 标签接受一个数组和一个值作为其两个参数，如果参数一中的数组包含参数二中的值，则返回 true。

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

`#date` 标签将日期格式化为可读的字符串。默认情况下，它使用 ISO8601 格式。

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

你可以传递一个自定义日期格式作为第二个参数。了解更多信息，请参阅 Swift [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter)。

```leaf
The date is #date(now, "yyyy-MM-dd")
```

#### `#unsafeHTML`

`#unsafeHTML` 标签就像一个变量标签 - 例如 `#(variable)`。但是，它不会转义任何 `variable` 可能包含的 HTML 标签：

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! 注意 
    使用此标签时应小心，确保你提供的变量不会使你的用户受到 XSS 攻击。
